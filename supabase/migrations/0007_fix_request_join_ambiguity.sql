-- ─────────── Fix: 42702 column reference "room_id" is ambiguous ──────────────
-- request_join 의 RETURNS TABLE 컬럼명(room_id)이 함수 본문 내부에서
-- 변수로 잡혀 같은 이름의 테이블 컬럼과 충돌함. plpgsql 지시문으로
-- 충돌 시 컬럼을 우선하도록 변경.

create or replace function public.request_join(p_code text)
returns table (room_id uuid, room_name text, status text)
language plpgsql security definer set search_path = public as $$
#variable_conflict use_column
declare
  v_uid      uuid := auth.uid();
  v_room     public.rooms%rowtype;
  v_existing public.room_join_requests%rowtype;
begin
  if v_uid is null then raise exception 'UNAUTHENTICATED'; end if;
  insert into public.profiles (id) values (v_uid) on conflict (id) do nothing;

  p_code := upper(trim(p_code));
  select * into v_room from public.rooms r where r.code = p_code;
  if not found then raise exception 'CODE_NOT_FOUND'; end if;

  if exists (select 1 from public.room_members m
             where m.room_id = v_room.id and m.user_id = v_uid) then
    raise exception 'ALREADY_MEMBER';
  end if;
  if v_room.member_count >= v_room.max_members then
    raise exception 'ROOM_FULL';
  end if;

  select * into v_existing from public.room_join_requests jr
    where jr.room_id = v_room.id and jr.user_id = v_uid;
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

grant execute on function public.request_join(text) to authenticated;


-- ─────────── Fix: list_join_requests 의 user_id ambiguous ────────────────────
-- RETURNS TABLE 에 user_id 가 있어 함수 본문 WHERE user_id = v_uid 가 충돌함.
-- 모든 컬럼 참조에 테이블 alias 부여 + #variable_conflict 지시문 추가.

create or replace function public.list_join_requests(p_room uuid)
returns table (request_id bigint, user_id uuid, handle text,
               display_name text, photo_url text, created_at timestamptz)
language plpgsql security definer set search_path = public as $$
#variable_conflict use_column
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'UNAUTHENTICATED'; end if;
  if not exists (select 1 from public.room_members rm
                 where rm.room_id = p_room and rm.user_id = v_uid
                   and rm.role in ('owner','admin')) then
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

grant execute on function public.list_join_requests(uuid) to authenticated;
