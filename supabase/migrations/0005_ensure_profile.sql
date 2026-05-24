-- =============================================================================
-- 0005_ensure_profile.sql
-- 방 만들기/코드 입장이 "잠시 후 다시 시도해 주세요." 로 실패하는 버그 수정.
--
-- 원인:
--   rooms.owner_id / room_members.user_id 는 profiles(id) 를 참조한다.
--   profiles 행은 보통 handle_new_user 트리거가 가입 시 만들어 주지만,
--   트리거/마이그레이션 적용 "전"에 익명 로그인으로 생성된 유저는 profiles 행이 없다.
--   → create_room / redeem_invite_code 의 INSERT 가 FK 위반(23503)으로 실패하고,
--     클라이언트는 이를 일반 메시지로 감싸 원인이 보이지 않았다.
--
-- 수정:
--   1) 기존 유저 중 profiles 행이 빠진 사람을 backfill (현재 막힌 유저 즉시 해결)
--   2) create_room / redeem_invite_code 가 호출자 profiles 행을 보장하도록 self-heal
--      (security definer 라 RLS 우회 가능, on conflict 로 멱등)
-- =============================================================================

-- 1) 누락된 프로필 backfill
insert into public.profiles (id)
select u.id
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null;


-- 2) create_room: 프로필 보장 후 방/방장 멤버 생성
create or replace function public.create_room(
  p_name text,
  p_goal text default null,
  p_deadline timestamptz default null,
  p_max int default 50
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid  uuid := auth.uid();
  v_room uuid;
begin
  if v_uid is null then raise exception 'UNAUTHENTICATED'; end if;
  -- 호출자 프로필 보장 (트리거 이전에 생성된 익명 유저 대비)
  insert into public.profiles (id) values (v_uid) on conflict (id) do nothing;

  insert into public.rooms (name, goal_description, deadline, owner_id, max_members)
    values (p_name, p_goal, p_deadline, v_uid, p_max)
    returning id into v_room;
  insert into public.room_members (room_id, user_id, role)
    values (v_room, v_uid, 'owner');
  return v_room;
end;
$$;


-- 3) redeem_invite_code: 프로필 보장 후 기존 입장 로직 그대로
create or replace function public.redeem_invite_code(p_code text)
returns table (room_id uuid, room_name text)
language plpgsql security definer set search_path = public as $$
declare
  v_uid  uuid := auth.uid();
  v_code public.invite_codes%rowtype;
  v_room public.rooms%rowtype;
begin
  if v_uid is null then raise exception 'UNAUTHENTICATED'; end if;
  -- 호출자 프로필 보장 (트리거 이전에 생성된 익명 유저 대비)
  insert into public.profiles (id) values (v_uid) on conflict (id) do nothing;

  p_code := upper(trim(p_code));

  -- 코드 행 잠금: 같은 코드 동시 사용이 여기서 직렬화됨
  select * into v_code from public.invite_codes where code = p_code for update;
  if not found                                                 then raise exception 'CODE_NOT_FOUND'; end if;
  if not v_code.active                                         then raise exception 'CODE_INACTIVE';  end if;
  if v_code.expires_at is not null and v_code.expires_at <= now()
                                                              then raise exception 'CODE_EXPIRED';   end if;
  if v_code.max_uses is not null and v_code.use_count >= v_code.max_uses
                                                              then raise exception 'CODE_EXHAUSTED'; end if;

  -- 방 행 잠금: 정원 경쟁이 여기서 직렬화됨
  select * into v_room from public.rooms where id = v_code.room_id for update;
  if not found then raise exception 'ROOM_NOT_FOUND'; end if;

  if exists (select 1 from public.room_members
             where room_id = v_room.id and user_id = v_uid)    then raise exception 'ALREADY_MEMBER'; end if;
  if v_room.member_count >= v_room.max_members                 then raise exception 'ROOM_FULL';      end if;

  -- 모든 검증 통과 → 변경 (행이 잠겨 있으므로 경쟁 없음)
  insert into public.room_members (room_id, user_id, role) values (v_room.id, v_uid, 'member');
  update public.invite_codes set use_count = use_count + 1 where code = p_code;
  -- member_count는 트리거가 +1 처리

  return query select v_room.id, v_room.name;
end;
$$;
