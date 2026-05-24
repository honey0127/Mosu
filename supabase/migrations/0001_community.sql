-- =============================================================================
-- Mosu 커뮤니티 기능 스키마 (프로필 · 친구 · 방 · 초대코드)
-- 적용 대상: Supabase (PostgreSQL + Auth + RLS)
--
-- 설계 원칙 (3계층):
--   1) 제약조건(CONSTRAINT) : DB가 무조건 지키는 불변식 (정원 초과/중복 차단)
--   2) RLS 정책             : "누가 어떤 행을 읽고/지울 수 있나" (인가)
--   3) RPC 함수             : 잠금이 필요한 원자적 로직 (방 입장, 친구 자동수락)
-- =============================================================================

create extension if not exists pgcrypto;  -- gen_random_uuid()


-- ─────────────────────────── 1. 테이블 ───────────────────────────────────────

-- 프로필: Supabase Auth 사용자와 1:1
create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  handle       text unique check (handle ~ '^[a-z0-9_]{3,20}$'),  -- 유일성은 UNIQUE로 공짜
  display_name text,
  photo_url    text,
  created_at   timestamptz not null default now()
);

create table public.rooms (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  goal_description text,
  deadline         timestamptz,
  owner_id         uuid not null references public.profiles(id) on delete cascade,
  max_members      int  not null default 50 check (max_members > 0),
  member_count     int  not null default 0  check (member_count >= 0),
  created_at       timestamptz not null default now(),
  -- 정원 초과는 DB 차원에서 물리적으로 불가능하게:
  constraint room_not_overfull check (member_count <= max_members)
);

create table public.room_members (
  room_id   uuid not null references public.rooms(id) on delete cascade,
  user_id   uuid not null references public.profiles(id) on delete cascade,
  role      text not null default 'member' check (role in ('owner','member')),
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)              -- 같은 방 중복 가입 불가
);
create index room_members_user_idx on public.room_members (user_id);  -- "내 방" 조회용

create table public.friendships (
  id            bigint generated always as identity primary key,
  requester_id  uuid not null references public.profiles(id) on delete cascade,
  addressee_id  uuid not null references public.profiles(id) on delete cascade,
  status        text not null default 'pending'
                check (status in ('pending','accepted','blocked')),
  created_at    timestamptz not null default now(),
  responded_at  timestamptz,
  check (requester_id <> addressee_id)
);
-- 한 쌍당 관계 1개 (방향 무관) → 역방향 중복까지 차단
create unique index friendships_pair_uniq
  on public.friendships (least(requester_id, addressee_id),
                         greatest(requester_id, addressee_id));

create table public.invite_codes (
  code       text primary key,                  -- 코드 자체가 PK → O(1) 조회
  room_id    uuid not null references public.rooms(id) on delete cascade,
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  max_uses   int  check (max_uses is null or max_uses > 0),
  use_count  int  not null default 0 check (use_count >= 0),
  active     boolean not null default true,
  constraint code_not_overused check (max_uses is null or use_count <= max_uses)
);


-- ─────────────────────── 2. 가입 시 프로필 자동 생성 ──────────────────────────

create function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ─────────────────────── 3. 멤버 수 자동 동기화 트리거 ────────────────────────

create function public.sync_member_count()
returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then
    update public.rooms set member_count = member_count + 1 where id = new.room_id;
  elsif tg_op = 'DELETE' then
    update public.rooms set member_count = member_count - 1 where id = old.room_id;
  end if;
  return null;
end;
$$;

create trigger trg_sync_member_count
  after insert or delete on public.room_members
  for each row execute function public.sync_member_count();


-- ─────────────────────── 4. RLS 재귀 방지 헬퍼 ───────────────────────────────
-- rooms ↔ room_members 정책이 서로를 참조하면 무한 재귀가 난다.
-- security definer 함수는 RLS를 우회하므로 그 고리를 끊어준다.

create function public.is_room_member(p_room uuid)
returns boolean language sql security definer set search_path = public stable as $$
  select exists (
    select 1 from public.room_members
    where room_id = p_room and user_id = auth.uid()
  );
$$;


-- ─────────────────────────── 5. RLS 정책 ─────────────────────────────────────

alter table public.profiles      enable row level security;
alter table public.friendships   enable row level security;
alter table public.rooms         enable row level security;
alter table public.room_members  enable row level security;
alter table public.invite_codes  enable row level security;

-- profiles: 누구나 검색 가능, 자기 것만 수정
create policy "profiles_readable" on public.profiles
  for select to authenticated using (true);
create policy "profiles_update_own" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- friendships: 조회/삭제만 RLS, 생성/수정은 아래 RPC로만 (자동수락 로직 때문)
create policy "friendships_select_mine" on public.friendships
  for select to authenticated
  using (auth.uid() in (requester_id, addressee_id));
create policy "friendships_delete_mine" on public.friendships
  for delete to authenticated
  using (auth.uid() in (requester_id, addressee_id));

-- rooms: 멤버/방장만 조회, 방장만 정보 수정 (생성/삭제는 RPC)
create policy "rooms_select_member" on public.rooms
  for select to authenticated
  using (owner_id = auth.uid() or public.is_room_member(id));
create policy "rooms_update_owner" on public.rooms
  for update to authenticated
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
-- 수정 가능한 컬럼 제한 (Supabase 기본 grant가 넓으므로 member_count 조작 차단)
revoke update on public.rooms from authenticated;
grant  update (name, goal_description, deadline, max_members) on public.rooms to authenticated;

-- room_members: 같은 방 멤버만 조회, 본인 탈퇴(삭제)만 허용. 가입은 RPC로만.
create policy "members_select_co" on public.room_members
  for select to authenticated using (public.is_room_member(room_id));
create policy "members_leave_self" on public.room_members
  for delete to authenticated using (user_id = auth.uid());

-- invite_codes: 정책 없음 → 클라이언트 직접 접근 전면 차단. 오직 RPC로만.


-- ─────────────────────── 6. 방 생성 / 입장 RPC ───────────────────────────────

-- 방 생성: 방 + 방장 멤버를 한 트랜잭션으로 (member_count는 트리거가 1로 설정)
create function public.create_room(
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
  insert into public.rooms (name, goal_description, deadline, owner_id, max_members)
    values (p_name, p_goal, p_deadline, v_uid, p_max)
    returning id into v_room;
  insert into public.room_members (room_id, user_id, role)
    values (v_room, v_uid, 'owner');
  return v_room;
end;
$$;

-- 초대코드 생성 (방장만). 충돌 시 최대 5회 재시도.
create function public.create_invite_code(
  p_room_id uuid,
  p_max_uses int default null,    -- null = 무제한
  p_ttl_hours int default null    -- null = 만료 없음
) returns text
language plpgsql security definer set search_path = public as $$
declare
  v_uid      uuid := auth.uid();
  v_alphabet text := '23456789ABCDEFGHJKMNPQRSTVWXYZ';  -- 헷갈리는 0/O/1/I/L 제외
  v_code     text;
  v_expires  timestamptz;
  i int;
begin
  if v_uid is null then raise exception 'UNAUTHENTICATED'; end if;
  if not exists (select 1 from public.rooms where id = p_room_id and owner_id = v_uid) then
    raise exception 'NOT_ROOM_OWNER';
  end if;

  v_expires := case when p_ttl_hours is null then null
                    else now() + make_interval(hours => p_ttl_hours) end;

  for attempt in 1..5 loop
    v_code := '';
    for i in 1..6 loop
      v_code := v_code || substr(v_alphabet, floor(random() * length(v_alphabet))::int + 1, 1);
    end loop;
    begin
      insert into public.invite_codes (code, room_id, created_by, expires_at, max_uses)
        values (v_code, p_room_id, v_uid, v_expires, p_max_uses);
      return v_code;
    exception when unique_violation then
      -- 코드 충돌 → 재시도
    end;
  end loop;
  raise exception 'CODE_GENERATION_FAILED';
end;
$$;

-- ⭐ 원자적 방 입장: FOR UPDATE 행 잠금으로 동시성(정원 초과) 완전 차단
create function public.redeem_invite_code(p_code text)
returns table (room_id uuid, room_name text)
language plpgsql security definer set search_path = public as $$
declare
  v_uid  uuid := auth.uid();
  v_code public.invite_codes%rowtype;
  v_room public.rooms%rowtype;
begin
  if v_uid is null then raise exception 'UNAUTHENTICATED'; end if;
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


-- ─────────────────── 7. 친구 RPC (⭐ 자동 수락 포함) ──────────────────────────

-- 친구 요청 보내기.
--   - 상대가 이미 나에게 보낸 요청이 있으면 → 즉시 친구 성사('accepted' 반환)
--   - 그 외에는 새 요청 생성('pending' 반환)
create function public.send_friend_request(p_addressee uuid)
returns text
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_f   public.friendships%rowtype;
begin
  if v_uid is null            then raise exception 'UNAUTHENTICATED';   end if;
  if p_addressee = v_uid      then raise exception 'CANNOT_FRIEND_SELF'; end if;
  if not exists (select 1 from public.profiles where id = p_addressee) then
    raise exception 'USER_NOT_FOUND';
  end if;

  -- 두 사람 사이의 기존 관계를 (방향 무관) 잠금 조회
  select * into v_f from public.friendships
   where (requester_id = v_uid and addressee_id = p_addressee)
      or (requester_id = p_addressee and addressee_id = v_uid)
   for update;

  if found then
    if v_f.status = 'accepted' then
      raise exception 'ALREADY_FRIENDS';
    elsif v_f.status = 'blocked' then
      raise exception 'BLOCKED';
    elsif v_f.requester_id = p_addressee then
      -- 상대가 먼저 보낸 요청이 존재 → ⭐ 자동 수락
      update public.friendships set status = 'accepted', responded_at = now()
       where id = v_f.id;
      return 'accepted';
    else
      raise exception 'REQUEST_ALREADY_SENT';  -- 내가 이미 보냄
    end if;
  end if;

  -- 기존 관계 없음 → 새 요청 생성
  insert into public.friendships (requester_id, addressee_id, status)
    values (v_uid, p_addressee, 'pending');
  return 'pending';
end;
$$;

-- 친구 요청 응답 (받은 사람만). action: 'accept' | 'decline' | 'block'
create function public.respond_to_friend_request(p_request_id bigint, p_action text)
returns text
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_f   public.friendships%rowtype;
begin
  if v_uid is null then raise exception 'UNAUTHENTICATED'; end if;
  if p_action not in ('accept','decline','block') then raise exception 'INVALID_ACTION'; end if;

  select * into v_f from public.friendships where id = p_request_id for update;
  if not found                  then raise exception 'REQUEST_NOT_FOUND'; end if;
  if v_f.addressee_id <> v_uid  then raise exception 'NOT_AUTHORIZED';    end if;  -- 받은 사람만
  if v_f.status <> 'pending'    then raise exception 'NOT_PENDING';       end if;

  if p_action = 'accept' then
    update public.friendships set status = 'accepted', responded_at = now() where id = v_f.id;
    return 'accepted';
  elsif p_action = 'block' then
    update public.friendships set status = 'blocked', responded_at = now() where id = v_f.id;
    return 'blocked';
  else
    delete from public.friendships where id = v_f.id;  -- 거절은 행 삭제
    return 'declined';
  end if;
end;
$$;


-- ─────────────────── 8. 목록 조회 RPC (조인 단순화용) ─────────────────────────
-- friendships엔 profiles로 향하는 FK가 2개라 PostgREST 임베드가 모호해진다.
-- 함수로 감싸 클라이언트(Dart)를 단순하게 유지.

create function public.list_friends()
returns table (friendship_id bigint, friend_id uuid, handle text,
               display_name text, photo_url text, since timestamptz)
language sql security definer set search_path = public stable as $$
  select f.id,
         case when f.requester_id = auth.uid() then f.addressee_id else f.requester_id end,
         p.handle, p.display_name, p.photo_url, f.responded_at
  from public.friendships f
  join public.profiles p
    on p.id = case when f.requester_id = auth.uid() then f.addressee_id else f.requester_id end
  where f.status = 'accepted'
    and auth.uid() in (f.requester_id, f.addressee_id);
$$;

create function public.list_incoming_requests()
returns table (friendship_id bigint, requester_id uuid, handle text,
               display_name text, photo_url text, created_at timestamptz)
language sql security definer set search_path = public stable as $$
  select f.id, f.requester_id, p.handle, p.display_name, p.photo_url, f.created_at
  from public.friendships f
  join public.profiles p on p.id = f.requester_id
  where f.addressee_id = auth.uid() and f.status = 'pending';
$$;

create function public.list_my_rooms()
returns table (id uuid, name text, goal_description text, deadline timestamptz,
               owner_id uuid, member_count int, max_members int, role text, joined_at timestamptz)
language sql security definer set search_path = public stable as $$
  select r.id, r.name, r.goal_description, r.deadline, r.owner_id,
         r.member_count, r.max_members, m.role, m.joined_at
  from public.room_members m
  join public.rooms r on r.id = m.room_id
  where m.user_id = auth.uid()
  order by m.joined_at desc;
$$;


-- ─────────────────────────── 9. 실행 권한 ────────────────────────────────────

grant execute on function public.create_room(text, text, timestamptz, int)        to authenticated;
grant execute on function public.create_invite_code(uuid, int, int)               to authenticated;
grant execute on function public.redeem_invite_code(text)                         to authenticated;
grant execute on function public.send_friend_request(uuid)                        to authenticated;
grant execute on function public.respond_to_friend_request(bigint, text)          to authenticated;
grant execute on function public.list_friends()                                   to authenticated;
grant execute on function public.list_incoming_requests()                         to authenticated;
grant execute on function public.list_my_rooms()                                  to authenticated;
