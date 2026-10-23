-- Run only after reviewing the preview branch. Requires ezp_role_caps and ezp_app_role().
create or replace function public.ezp_set_role_caps(p_changes jsonb)
returns void language plpgsql security definer set search_path = ''
as $$
declare item jsonb; cap_key text; next_roles text[];
begin
  if (select auth.uid()) is null or public.ezp_app_role() is distinct from 'admin' then
    raise exception 'Only an active Superadmin may change role permissions' using errcode='42501';
  end if;
  if jsonb_typeof(p_changes) is distinct from 'array' or jsonb_array_length(p_changes) > 18 then
    raise exception 'Invalid permission matrix';
  end if;
  for item in select value from jsonb_array_elements(p_changes) loop
    cap_key := item->>'cap';
    if cap_key is null or not exists(select 1 from public.ezp_role_caps where cap=cap_key) then
      raise exception 'Unknown capability';
    end if;
    if jsonb_typeof(item->'roles') is distinct from 'array' then raise exception 'Invalid roles'; end if;
    select coalesce(array_agg(distinct x),array[]::text[]) into next_roles
    from jsonb_array_elements_text(item->'roles') as x
    where x in ('admin','supervisor','staff','viewer');
    if (select count(*) from jsonb_array_elements_text(item->'roles')) <>
       (select count(*) from jsonb_array_elements_text(item->'roles') as x where x in ('admin','supervisor','staff','viewer')) then
      raise exception 'Invalid role';
    end if;
    if not ('admin'=any(next_roles)) then raise exception 'Superadmin must retain access'; end if;
    if cap_key in ('user.manage','config.manage','data.restore') and next_roles <> array['admin']::text[] then
      raise exception 'Protected capability cannot be delegated';
    end if;
    update public.ezp_role_caps set roles=next_roles where cap=cap_key;
  end loop;
end $$;
revoke all on function public.ezp_set_role_caps(jsonb) from public, anon;
grant execute on function public.ezp_set_role_caps(jsonb) to authenticated;
