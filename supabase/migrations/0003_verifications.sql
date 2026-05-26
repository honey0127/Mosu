-- =============================================================================
-- Mosu 미션 인증 (사진 인증 + 방장/관리자 승인)
--
-- 멤버가 활동 사진을 올리면 'pending' 상태로 쌓이고,
-- 방장(owner) 또는 관리자(admin)가 승인(approved)/거절(rejected) 한다.
-- 승인/거절 결과는 캘린더(다음 기능)에서 파랑/빨강으로 쓰인다.
-- =============================================================================

-- ── 0. 관리자(admin) 역할 추가 ────────────────────────────────────────────────
-- room_members.role 허용값을 owner/member → owner/admin/member 로 확장.
alter table public.room_members drop constraint if exists room_members_role_check;
alter table public.room_members
  add constraint room_members_role_check check (role in ('owner', 'admin', 'member'));


-- ── 1. 인증 테이블 ────────────────────────────────────────────────────────────
create table public.verifications (
  id          uuid primary key default gen_random_uuid(),
  room_id     uuid not null references public.rooms(id)    on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  photo_url   text not null,
  caption     text,
  status      text not null default 'pending'
              check (status in ('pending', 'approved', 'rejected')),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at  timestamptz not null default now()
);
create index verifications_room_idx on public.verifications (room_id, created_at desc);
create index verifications_user_idx on public.verifications (user_id, created_at desc);


-- ── 2. 권한 헬퍼 (방장 or 관리자?) ────────────────────────────────────────────
-- security definer 라 RLS를 우회 → 정책 안에서 안전하게 재사용 가능.
create function public.is_room_admin(p_room uuid)
returns boolean language sql security definer set search_path = public stable as $$
  select exists (
    select 1 from public.room_members
    where room_id = p_room
      and user_id = auth.uid()
      and role in ('owner', 'admin')
  );
$$;


-- ── 3. RLS 정책 ───────────────────────────────────────────────────────────────
alter table public.verifications enable row level security;

-- 읽기: 같은 방 멤버만
create policy "verifications_select_member" on public.verifications
  for select to authenticated
  using (public.is_room_member(room_id));

-- 생성: 본인이, 자기가 속한 방에, pending 으로만. (승인 조작은 RPC로만)
create policy "verifications_insert_self" on public.verifications
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and public.is_room_member(room_id)
    and status = 'pending'
  );

-- 삭제: 본인 인증만 (취소용)
create policy "verifications_delete_self" on public.verifications
  for delete to authenticated
  using (user_id = auth.uid());


-- ── 4. 승인/거절 RPC (방장·관리자만) ──────────────────────────────────────────
create function public.review_verification(p_id uuid, p_action text)
returns text
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_v   public.verifications%rowtype;
begin
  if v_uid is null                          then raise exception 'UNAUTHENTICATED'; end if;
  if p_action not in ('approve', 'reject')  then raise exception 'INVALID_ACTION';  end if;

  select * into v_v from public.verifications where id = p_id for update;
  if not found                              then raise exception 'NOT_FOUND';       end if;
  if not public.is_room_admin(v_v.room_id)  then raise exception 'NOT_AUTHORIZED';  end if;
  if v_v.status <> 'pending'                then raise exception 'NOT_PENDING';     end if;

  update public.verifications
     set status      = case when p_action = 'approve' then 'approved' else 'rejected' end,
         reviewed_by = v_uid,
         reviewed_at = now()
   where id = p_id;

  return case when p_action = 'approve' then 'approved' else 'rejected' end;
end;
$$;


-- ── 5. 멤버 역할 변경 RPC (방장만, 관리자 임명/해제) ──────────────────────────
create function public.set_member_role(p_room uuid, p_user uuid, p_role text)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null                       then raise exception 'UNAUTHENTICATED';   end if;
  if p_role not in ('admin', 'member')   then raise exception 'INVALID_ROLE';      end if;
  if p_user = v_uid                      then raise exception 'CANNOT_CHANGE_SELF'; end if;
  if not exists (select 1 from public.rooms where id = p_room and owner_id = v_uid) then
    raise exception 'NOT_ROOM_OWNER';
  end if;

  update public.room_members
     set role = p_role
   where room_id = p_room and user_id = p_user and role <> 'owner';
  if not found then raise exception 'NOT_A_MEMBER'; end if;
end;
$$;


-- ── 6. 조회 RPC (profiles 조인 단순화) ────────────────────────────────────────
-- verifications → profiles FK가 2개(user_id, reviewed_by)라 임베드가 모호 → 함수로 감쌈.

-- 방의 인증 목록 (같은 방 멤버만)
create function public.list_room_verifications(p_room uuid)
returns table (
  id uuid, user_id uuid, photo_url text, caption text, status text,
  reviewed_by uuid, reviewed_at timestamptz, created_at timestamptz,
  handle text, display_name text
)
language sql security definer set search_path = public stable as $$
  select v.id, v.user_id, v.photo_url, v.caption, v.status,
         v.reviewed_by, v.reviewed_at, v.created_at,
         p.handle, p.display_name
  from public.verifications v
  join public.profiles p on p.id = v.user_id
  where v.room_id = p_room
    and public.is_room_member(p_room)
  order by v.created_at desc;
$$;

-- 내 인증 전체 (캘린더용 — 방 이름 포함)
create function public.list_my_verifications()
returns table (
  id uuid, room_id uuid, room_name text, photo_url text, caption text,
  status text, created_at timestamptz, reviewed_at timestamptz
)
language sql security definer set search_path = public stable as $$
  select v.id, v.room_id, r.name, v.photo_url, v.caption,
         v.status, v.created_at, v.reviewed_at
  from public.verifications v
  join public.rooms r on r.id = v.room_id
  where v.user_id = auth.uid()
  order by v.created_at desc;
$$;


-- ── 7. 인증 사진 저장소 ───────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('verifications', 'verifications', true)
on conflict (id) do nothing;

create policy "verif_photos_read" on storage.objects
  for select using (bucket_id = 'verifications');

create policy "verif_photos_insert_own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'verifications'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "verif_photos_delete_own" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'verifications'
    and (storage.foldername(name))[1] = auth.uid()::text
  );


-- ── 8. 실행 권한 ──────────────────────────────────────────────────────────────
grant execute on function public.is_room_admin(uuid)              to authenticated;
grant execute on function public.review_verification(uuid, text)  to authenticated;
grant execute on function public.set_member_role(uuid, uuid, text) to authenticated;
grant execute on function public.list_room_verifications(uuid)    to authenticated;
grant execute on function public.list_my_verifications()          to authenticated;
