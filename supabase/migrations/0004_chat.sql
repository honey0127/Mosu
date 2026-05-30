-- =============================================================================
-- Mosu 방 채팅 (실시간)
--
-- 같은 방 멤버끼리 주고받는 메시지. Supabase Realtime publication 에 추가해
-- 클라이언트가 .stream() 으로 실시간 수신한다.
-- =============================================================================

-- ── 1. 메시지 테이블 ──────────────────────────────────────────────────────────
create table public.room_messages (
  id         uuid primary key default gen_random_uuid(),
  room_id    uuid not null references public.rooms(id)    on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  content    text not null check (char_length(content) between 1 and 1000),
  created_at timestamptz not null default now()
);
create index room_messages_room_idx on public.room_messages (room_id, created_at);


-- ── 2. RLS 정책 ───────────────────────────────────────────────────────────────
alter table public.room_messages enable row level security;

-- 읽기: 같은 방 멤버만
create policy "messages_select_member" on public.room_messages
  for select to authenticated
  using (public.is_room_member(room_id));

-- 보내기: 본인 명의로, 자기가 속한 방에만
create policy "messages_insert_self" on public.room_messages
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and public.is_room_member(room_id)
  );


-- ── 3. 실시간 publication 등록 ────────────────────────────────────────────────
-- 이게 있어야 클라이언트 .stream() 으로 INSERT 가 실시간 전달된다.
alter publication supabase_realtime add table public.room_messages;
