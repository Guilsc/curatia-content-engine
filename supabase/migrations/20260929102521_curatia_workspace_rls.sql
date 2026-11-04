
create or replace function public.is_curatia_member(p_workspace_id uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.workspace_members where workspace_id=p_workspace_id and user_id=auth.uid()) $$;
revoke all on function public.is_curatia_member(uuid) from public,anon;
grant execute on function public.is_curatia_member(uuid) to authenticated;

create policy "members_read_profiles" on public.profiles for select to authenticated using (user_id=auth.uid() or exists(select 1 from public.workspace_members me join public.workspace_members them on them.workspace_id=me.workspace_id where me.user_id=auth.uid() and them.user_id=profiles.user_id));
create policy "self_update_profile" on public.profiles for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "members_read_workspaces" on public.workspaces for select to authenticated using(public.is_curatia_member(id));
create policy "members_read_members" on public.workspace_members for select to authenticated using(public.is_curatia_member(workspace_id));
create policy "members_read_entitlements" on public.workspace_entitlements for select to authenticated using(public.is_curatia_member(workspace_id));
create policy "members_read_channels" on public.workspace_channels for select to authenticated using(public.is_curatia_member(workspace_id));
create policy "members_read_interests" on public.discovery_interests for select to authenticated using(public.is_curatia_member(workspace_id));
create policy "members_read_signals" on public.signals for select to authenticated using(public.is_curatia_member(workspace_id));
create policy "members_read_sources" on public.sources for select to authenticated using(public.is_curatia_member(workspace_id));
create policy "members_read_scout_runs" on public.scout_runs for select to authenticated using(public.is_curatia_member(workspace_id));
create policy "members_read_content" on public.content_items for select to authenticated using(public.is_curatia_member(workspace_id));
create policy "members_read_audit" on public.audit_events for select to authenticated using(workspace_id is not null and public.is_curatia_member(workspace_id));
