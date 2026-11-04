-- Curatia Alpha Foundation A5
-- Authenticated workspace isolation policies.
-- Apply after legacy data has been backfilled and workspace ownership is enforced.

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

-- These helpers must bypass membership-table RLS to avoid recursive policies.
-- They live in a non-exposed schema, validate auth.uid() internally, and expose only booleans.
create or replace function private.is_platform_owner()
returns boolean
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $
  select (select auth.uid()) is not null and exists (
    select 1 from public.platform_roles pr
    where pr.user_id = (select auth.uid())
      and pr.role = 'owner'
  );
$;

create or replace function private.is_workspace_member(p_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $
  select (select auth.uid()) is not null and exists (
    select 1 from public.workspace_members wm
    where wm.workspace_id = p_workspace_id
      and wm.user_id = (select auth.uid())
  );
$;

create or replace function private.can_write_workspace(p_workspace_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $
  select (select auth.uid()) is not null and exists (
    select 1 from public.workspace_members wm
    where wm.workspace_id = p_workspace_id
      and wm.user_id = (select auth.uid())
      and wm.role in ('admin','creator')
  );
$;

revoke all on function private.is_platform_owner() from public, anon;
revoke all on function private.is_workspace_member(uuid) from public, anon;
revoke all on function private.can_write_workspace(uuid) from public, anon;
grant execute on function private.is_platform_owner() to authenticated;
grant execute on function private.is_workspace_member(uuid) to authenticated;
grant execute on function private.can_write_workspace(uuid) to authenticated;

grant select on public.profiles, public.workspaces, public.platform_roles,
  public.workspace_members, public.workspace_entitlements, public.discovery_interests,
  public.scout_runs, public.sources, public.signals, public.signal_sources,
  public.channel_catalog, public.workspace_channels to authenticated;

grant insert, update on public.profiles, public.discovery_interests, public.workspace_channels to authenticated;
grant update on public.signals to authenticated;

-- Profiles
drop policy if exists profiles_read_self_or_owner on public.profiles;
create policy profiles_read_self_or_owner on public.profiles for select to authenticated
using ((select auth.uid()) = user_id or (select private.is_platform_owner()));

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- Workspaces and membership
drop policy if exists workspaces_read_member_or_owner on public.workspaces;
create policy workspaces_read_member_or_owner on public.workspaces for select to authenticated
using ((select private.is_workspace_member(id)) or (select private.is_platform_owner()));

drop policy if exists platform_roles_read_self_or_owner on public.platform_roles;
create policy platform_roles_read_self_or_owner on public.platform_roles for select to authenticated
using (user_id = (select auth.uid()) or (select private.is_platform_owner()));

drop policy if exists workspace_members_read_scope on public.workspace_members;
create policy workspace_members_read_scope on public.workspace_members for select to authenticated
using ((select private.is_workspace_member(workspace_id)) or (select private.is_platform_owner()));

drop policy if exists workspace_entitlements_read_scope on public.workspace_entitlements;
create policy workspace_entitlements_read_scope on public.workspace_entitlements for select to authenticated
using ((select private.is_workspace_member(workspace_id)) or (select private.is_platform_owner()));

-- Discovery interests
drop policy if exists discovery_interests_read_scope on public.discovery_interests;
create policy discovery_interests_read_scope on public.discovery_interests for select to authenticated
using ((select private.is_workspace_member(workspace_id)) or (select private.is_platform_owner()));

drop policy if exists discovery_interests_insert_write_scope on public.discovery_interests;
create policy discovery_interests_insert_write_scope on public.discovery_interests for insert to authenticated
with check ((select private.can_write_workspace(workspace_id)));

drop policy if exists discovery_interests_update_write_scope on public.discovery_interests;
create policy discovery_interests_update_write_scope on public.discovery_interests for update to authenticated
using ((select private.can_write_workspace(workspace_id)))
with check ((select private.can_write_workspace(workspace_id)));

-- Trend Radar
drop policy if exists scout_runs_read_scope on public.scout_runs;
create policy scout_runs_read_scope on public.scout_runs for select to authenticated
using ((select private.is_workspace_member(workspace_id)) or (select private.is_platform_owner()));

drop policy if exists sources_read_scope on public.sources;
create policy sources_read_scope on public.sources for select to authenticated
using ((select private.is_workspace_member(workspace_id)) or (select private.is_platform_owner()));

drop policy if exists signals_read_scope on public.signals;
create policy signals_read_scope on public.signals for select to authenticated
using ((select private.is_workspace_member(workspace_id)) or (select private.is_platform_owner()));

drop policy if exists signals_update_scope on public.signals;
create policy signals_update_scope on public.signals for update to authenticated
using ((select private.can_write_workspace(workspace_id)) or (select private.is_platform_owner()))
with check ((select private.can_write_workspace(workspace_id)) or (select private.is_platform_owner()));

drop policy if exists signal_sources_read_scope on public.signal_sources;
create policy signal_sources_read_scope on public.signal_sources for select to authenticated
using (
  exists (
    select 1 from public.signals s
    where s.id = signal_sources.signal_id
      and ((select private.is_workspace_member(s.workspace_id)) or (select private.is_platform_owner()))
  )
);

-- Channels
drop policy if exists channel_catalog_read_authenticated on public.channel_catalog;
create policy channel_catalog_read_authenticated on public.channel_catalog for select to authenticated
using (active = true);

drop policy if exists workspace_channels_read_scope on public.workspace_channels;
create policy workspace_channels_read_scope on public.workspace_channels for select to authenticated
using ((select private.is_workspace_member(workspace_id)) or (select private.is_platform_owner()));

drop policy if exists workspace_channels_insert_write_scope on public.workspace_channels;
create policy workspace_channels_insert_write_scope on public.workspace_channels for insert to authenticated
with check ((select private.can_write_workspace(workspace_id)));

drop policy if exists workspace_channels_update_write_scope on public.workspace_channels;
create policy workspace_channels_update_write_scope on public.workspace_channels for update to authenticated
using ((select private.can_write_workspace(workspace_id)))
with check ((select private.can_write_workspace(workspace_id)));

-- Audit remains server-write-only; scoped read can be added with the Owner/Admin audit UI.
