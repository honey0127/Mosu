-- 거절 사유 컬럼 추가 + review_verification 함수 업데이트

alter table public.verifications
  add column if not exists reject_reason text;

-- 기존 함수를 reject_reason 저장 가능하도록 교체
create or replace function public.review_verification(
  p_id     uuid,
  p_action text,
  p_reason text default null
)
returns text
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_v   public.verifications%rowtype;
begin
  if v_uid is null                         then raise exception 'UNAUTHENTICATED'; end if;
  if p_action not in ('approve', 'reject') then raise exception 'INVALID_ACTION';  end if;

  select * into v_v from public.verifications where id = p_id for update;
  if not found                             then raise exception 'NOT_FOUND';       end if;
  if not public.is_room_admin(v_v.room_id) then raise exception 'NOT_AUTHORIZED';  end if;
  if v_v.status <> 'pending'              then raise exception 'NOT_PENDING';     end if;

  update public.verifications
     set status        = case when p_action = 'approve' then 'approved' else 'rejected' end,
         reviewed_by   = v_uid,
         reviewed_at   = now(),
         reject_reason = case when p_action = 'reject' then p_reason else null end
   where id = p_id;

  return case when p_action = 'approve' then 'approved' else 'rejected' end;
end;
$$;

grant execute on function public.review_verification(uuid, text, text) to authenticated;
