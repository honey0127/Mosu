-- =============================================================================
-- 방 나가기 RPC (방장 위임 / 방 삭제 포함)
--   - 일반 멤버  → 그냥 탈퇴            ('LEFT')
--   - 방장 + 다른 멤버 有 → 최선임에게 위임 후 탈퇴 ('TRANSFERRED')
--   - 방장 + 혼자        → 방 삭제       ('DELETED')
-- 0001 적용 후 별도로 실행할 것.
-- =============================================================================

create or replace function public.leave_room(p_room_id uuid)
returns text                       -- 'LEFT' | 'TRANSFERRED' | 'DELETED'
language plpgsql security definer set search_path = public as $$
declare
  v_uid       uuid := auth.uid();
  v_room      public.rooms%rowtype;
  v_new_owner uuid;
begin
  if v_uid is null then raise exception 'UNAUTHENTICATED'; end if;

  -- 방 행 잠금: 소유권 변경 경쟁 방지
  select * into v_room from public.rooms where id = p_room_id for update;
  if not found then raise exception 'ROOM_NOT_FOUND'; end if;

  if not exists (select 1 from public.room_members
                 where room_id = p_room_id and user_id = v_uid) then
    raise exception 'NOT_A_MEMBER';
  end if;

  -- 1) 일반 멤버 → 단순 탈퇴 (member_count는 트리거가 감소)
  if v_room.owner_id <> v_uid then
    delete from public.room_members where room_id = p_room_id and user_id = v_uid;
    return 'LEFT';
  end if;

  -- 2) 방장인 경우: 남은 멤버 중 가장 먼저 들어온 사람 찾기
  select user_id into v_new_owner
  from public.room_members
  where room_id = p_room_id and user_id <> v_uid
  order by joined_at asc
  limit 1;

  -- 2a) 남은 멤버 없음 → 방 삭제
  if v_new_owner is null then
    -- 멤버 먼저 지우고 방을 지운다 (CASCADE 중 트리거 순서 모호함 회피)
    delete from public.room_members where room_id = p_room_id;
    delete from public.rooms where id = p_room_id;  -- 초대코드도 CASCADE 삭제
    return 'DELETED';
  end if;

  -- 2b) 위임: 새 방장 지정 후 본인 탈퇴
  update public.rooms set owner_id = v_new_owner where id = p_room_id;
  update public.room_members set role = 'owner'
    where room_id = p_room_id and user_id = v_new_owner;
  delete from public.room_members where room_id = p_room_id and user_id = v_uid;
  return 'TRANSFERRED';
end;
$$;

grant execute on function public.leave_room(uuid) to authenticated;
