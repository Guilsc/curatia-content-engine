create or replace function public.bootstrap_curatia_user(p_user_id uuid, p_email text, p_display_name text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_workspace_id uuid; v_has_members boolean;
begin
 insert into public.profiles(user_id,display_name)
 values(p_user_id,coalesce(nullif(p_display_name,''),split_part(p_email,'@',1)))
 on conflict(user_id) do update set display_name=coalesce(public.profiles.display_name,excluded.display_name),updated_at=now();

 select wm.workspace_id into v_workspace_id from public.workspace_members wm where wm.user_id=p_user_id limit 1;
 if v_workspace_id is null then
   select exists(select 1 from public.workspace_members) into v_has_members;
   if v_has_members then raise exception 'Workspace access has not been granted for this user'; end if;

   insert into public.workspaces(name,slug,created_by) values('Curatia','curatia',p_user_id) returning id into v_workspace_id;
   insert into public.workspace_members(workspace_id,user_id,role) values(v_workspace_id,p_user_id,'admin');
   insert into public.platform_roles(user_id,role) values(p_user_id,'super_admin') on conflict do nothing;
   insert into public.workspace_entitlements(workspace_id) values(v_workspace_id) on conflict do nothing;
   insert into public.workspace_channels(workspace_id,channel_key,enabled,is_primary)
     select v_workspace_id,cc.key,true,(cc.key='linkedin') from public.channel_catalog cc on conflict do nothing;
   update public.signals set workspace_id=v_workspace_id where workspace_id is null;
   update public.sources set workspace_id=v_workspace_id where workspace_id is null;
   update public.scout_runs set workspace_id=v_workspace_id where workspace_id is null;
   update public.content_items set workspace_id=v_workspace_id where workspace_id is null;
 end if;
 return v_workspace_id;
end; $$;
