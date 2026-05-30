-- =============================================================================
-- 0006_room_code_and_join_requests.sql
-- 변경 사항 2가지
--   1) 방마다 "영구 초대 코드" — 방 생성 시 1개 생성되고 절대 바뀌지 않는다.
--      (기존 invite_codes 테이블/RPC는 그대로 두되 더 이상 앱에서 사용하지 않음)
--   2) 코드로 입장 = 즉시 가입이 아니라 "가입 요청" → 방장/관리자가 승인/거절.
-- =============================================================================

-- ─────────────────────── 1. 방 영구 코드 ─────────────────────────────────────
alter table public.rooms add column if not exists code text;
create unique index if not exists rooms_code_key on public.rooms (code);

-- 기존 방(코드 없음)에 코드 backfill
do $$
declare
  r record;
  v_alphabet text := '23456789ABCDEFGHJKMNPQRSTVWXYZ';
  v_code text;
  i int;
begin
  for r in select id from public.rooms where code is null loop
    loop
      v_code := '';
      for i in 1..6 loop
        v_code := v_code || substr(v_alphabet, floor(random() * length(v_alphabet))::int + 1, 1);
      end loop;
      exit when not exists (select 1 from public.rooms where code = v_code);
    end loop;
    update public.rooms set code = v_code where id = r.id;
  end loop;
end $$;


-- ─────────────────────── 2. 가입 요청 테이블 ──────────────────────────────────
create table if not exists public.room_join_requests (
  id         bigint generated always as identity primary key,
  room_id    uuid not null references public.rooms(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  status     text not null default 'pending'
             check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  decided_at timestamptz,
  decided_by uuid references public.profiles(id),
  unique (room_id, user_id)   -- 한 방에 요청 1개 (재요청은 같은 행 갱신)
);
create index if not exists room_join_requests_room_idx
  on public.room_join_requests (room_id);

-- RLS: 정책 없음 → 클라이언트 직접 접근 차단. 오직 아래 RPC(security definer)로만.
alter table public.room_join_requests enable row level security;


-- ─────────────────────── 3. create_room (코드 생성 포함) ──────────────────────
-- 0005 의 프로필 보장 로직 유지 + 영구 코드 생성 추가.
create or replace function public.create_room(
  p_name text,
  p_goal text default null,
  p_deadline timestamptz default null,
  p_max int default 50
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid      uuid := auth.uid();
  v_room     uuid;
  v_alphabet text := '23456789ABCDEFGHJKMNPQRSTVWXYZ';
  v_code     text;
  i int;
begin
  if v_uid is null then raise exception 'UNAUTHENTICATED'; end if;
  insert into public.profiles (id) values (v_uid) on conflict (id) do nothing;

  -- 충돌 없는 영구 코드 생성
  for attempt in 1..10 loop
    v_code := '';
    for i in 1..6 loop
      v_code := v_code || substr(v_alphabet, floor(random() * length(v_alphabet))::int + 1, 1);
    end loop;
    exit when not exists (select 1 from public.rooms where code = v_code);
  end loop;

  insert into public.rooms (name, goal_description, deadline, owner_id, max_members, code)
    values (p_name, p_goal, p_deadline, v_uid, p_max, v_code)
    returning id into v_room;
  insert into public.room_members (room_id, user_id, role)
    values (v_room, v_uid, 'owner');
  return v_room;
end;
$$;


-- ─────────────────────── 4. 코드 조회 (멤버만) ────────────────────────────────
create or replace function public.get_room_code(p_room uuid)
returns text
language plpgsql security definer set search_path = public as $$
declare
  v_uid  uuid := auth.uid();
  v_code text;
begin
  if v_uid is null then raise exception 'UNAUTHENTICATED'; end if;
  if not exists (select 1 from public.room_members
                 where room_id = p_room and user_id = v_uid) then
    raise exception 'NOT_A_MEMBER';
  end if;
  select code into v_code from public.rooms where id = p_room;
  if v_code is null then raise exception 'ROOM_NOT_FOUND'; end if;
  return v_code;
end;
$$;


-- ─────────────────────── 5. 가입 요청 보내기 ──────────────────────────────────
-- 즉시 입장 X. pending 요청을 만든다(또는 거절됐던 요청을 다시 pending 으로).
create or replace function public.request_join(p_code text)
returns table (room_id uuid, room_name text, status text)
language plpgsql security definer set search_path = public as $$
declare
  v_uid      uuid := auth.uid();
  v_room     public.rooms%rowtype;
  v_existing public.room_join_requests%rowtype;
begin
  if v_uid is null then raise exception 'UNAUTHENTICATED'; end if;
  insert into public.profiles (id) values (v_uid) on conflict (id) do nothing;

  p_code := upper(trim(p_code));
  select * into v_room from public.rooms where code = p_code;
  if not found then raise exception 'CODE_NOT_FOUND'; end if;

  if exists (select 1 from public.room_members
             where room_id = v_room.id and user_id = v_uid) then
    raise exception 'ALREADY_MEMBER';
  end if;
  if v_room.member_count >= v_room.max_members then
    raise exception 'ROOM_FULL';
  end if;

  select * into v_existing from public.room_join_requests
    where room_id = v_room.id and user_id = v_uid;
  if found then
    if v_existing.status <> 'pending' then
      update public.room_join_requests
        set status = 'pending', created_at = now(),
            decided_at = null, decided_by = null
        where id = v_existing.id;
    end if;
  else
    insert into public.room_join_requests (room_id, user_id)
      values (v_room.id, v_uid);
  end if;

  return query select v_room.id, v_room.name, 'pending'::text;
end;
$$;


-- ─────────────────────── 6. 가입 요청 목록 (방장/관리자) ──────────────────────
create or replace function public.list_join_requests(p_room uuid)
returns table (request_id bigint, user_id uuid, handle text,
               display_name text, photo_url text, created_at timestamptz)
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'UNAUTHENTICATED'; end if;
  if not exists (select 1 from public.room_members
                 where room_id = p_room and user_id = v_uid
                   and role in ('owner','admin')) then
    raise exception 'NOT_AUTHORIZED';
  end if;
  return query
    select jr.id, jr.user_id, p.handle, p.display_name, p.photo_url, jr.created_at
    from public.room_join_requests jr
    join public.profiles p on p.id = jr.user_id
    where jr.room_id = p_room and jr.status = 'pending'
    order by jr.created_at;
end;
$$;


-- ─────────────────────── 7. 가입 요청 승인/거절 (방장/관리자) ─────────────────
create or replace function public.review_join_request(p_request_id bigint, p_action text)
returns text
language plpgsql security definer set search_path = public as $$
declare
  v_uid  uuid := auth.uid();
  v_req  public.room_join_requests%rowtype;
  v_room public.rooms%rowtype;
begin
  if v_uid is null then raise exception 'UNAUTHENTICATED'; end if;
  if p_action not in ('approve','reject') then raise exception 'INVALID_ACTION'; end if;

  select * into v_req from public.room_join_requests where id = p_request_id for update;
  if not found then raise exception 'REQUEST_NOT_FOUND'; end if;
  if v_req.status <> 'pending' then raise exception 'NOT_PENDING'; end if;

  if not exists (select 1 from public.room_members
                 where room_id = v_req.room_id and user_id = v_uid
                   and role in ('owner','admin')) then
    raise exception 'NOT_AUTHORIZED';
  end if;

  if p_action = 'reject' then
    update public.room_join_requests
      set status = 'rejected', decided_at = now(), decided_by = v_uid
      where id = v_req.id;
    return 'rejected';
  end if;

  -- approve: 방 행 잠금 후 정원/중복 재확인 → 멤버 추가
  select * into v_room from public.rooms where id = v_req.room_id for update;
  if not exists (select 1 from public.room_members
                 where room_id = v_room.id and user_id = v_req.user_id) then
    if v_room.member_count >= v_room.max_members then raise exception 'ROOM_FULL'; end if;
    insert into public.room_members (room_id, user_id, role)
      values (v_room.id, v_req.user_id, 'member');
  end if;
  update public.room_join_requests
    set status = 'approved', decided_at = now(), decided_by = v_uid
    where id = v_req.id;
  return 'approved';
end;
$$;


-- ─────────────────────── 8. 실행 권한 ─────────────────────────────────────────
grant execute on function public.get_room_code(uuid)                  to authenticated;
grant execute on function public.request_join(text)                   to authenticated;
grant execute on function public.list_join_requests(uuid)             to authenticated;
grant execute on function public.review_join_request(bigint, text)    to authenticated;
