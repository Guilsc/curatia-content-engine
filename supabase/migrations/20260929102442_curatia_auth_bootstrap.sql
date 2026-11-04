
create or replace function public.bootstrap_curatia_user(p_user_id uuid, p_email text, p_display_name text default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_workspace_id uuid;
  v_existing_count bigint;
begin
  if p_user_id is null then raise exception 'User id is required'; end if;
  insert into public.profiles(user_id,display_name)
  values(p_user_id,coalesce(nullif(p_display_name,''),split_part(coalesce(p_email,'Curatia User'),'@',1)))
  on conflict(user_id) do update set display_name=coalesce(public.profiles.display_name,excluded.display_name);

  select wm.workspace_id into v_workspace_id
  from public.workspace_members wm where wm.user_id=p_user_id order by wm.created_at limit 1;

  if v_workspace_id is null then
    select count(*) into v_existing_count from public.workspace_members;
    if v_existing_count=0 then
      insert into public.workspaces(name,slug,created_by,onboarding_completed_at)
      values('Curatia','curatia',p_user_id,now()) returning id into v_workspace_id;
      insert into public.workspace_members(workspace_id,user_id,role) values(v_workspace_id,p_user_id,'Owner');
      insert into public.platform_roles(user_id,role) values(p_user_id,'super_admin') on conflict do nothing;
      insert into public.workspace_entitlements(workspace_id) values(v_workspace_id) on conflict do nothing;
      insert into public.workspace_channels(workspace_id,channel_key,enabled,is_primary)
        select v_workspace_id,key,true,(key='linkedin') from public.channel_catalog
        on conflict(workspace_id,channel_key) do nothing;
      update public.signals set workspace_id=v_workspace_id where workspace_id is null;
      update public.sources set workspace_id=v_workspace_id where workspace_id is null;
      update public.scout_runs set workspace_id=v_workspace_id where workspace_id is null;
      update public.content_items set workspace_id=v_workspace_id where workspace_id is null;
    else
      raise exception 'Workspace access has not been granted for this user';
    end if;
  end if;
  return v_workspace_id;
end;
$$;
revoke all on function public.bootstrap_curatia_user(uuid,text,text) from public, anon, authenticated;
grant execute on function public.bootstrap_curatia_user(uuid,text,text) to service_role;
