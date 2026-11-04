-- Curatia Alpha Foundation A2
-- Owner bootstrap/backfill is intentionally performed by trusted server-side application code
-- using the Supabase secret/service credential after a real Auth identity exists.
--
-- We deliberately do NOT expose SECURITY DEFINER bootstrap functions through the public schema.
-- Authorization is represented by platform_roles/workspace_members and enforced by RLS.
--
-- Production cutover sequence:
-- 1. User authenticates with Supabase Auth.
-- 2. A one-time trusted bootstrap operation creates the Owner platform role and personal workspace.
-- 3. Existing legacy rows are assigned to that workspace in one transaction.
-- 4. Row counts/relationships are validated.
-- 5. The following enforcement/RLS migrations are applied.
--
-- No generated auth UUID and no email/provider identifier is hard-coded in migration SQL.

comment on table public.platform_roles is
  'Platform authorization. Alpha supports owner. Owner assignment is performed only by trusted server-side bootstrap code.';

comment on table public.workspace_members is
  'Workspace authorization. Membership is independent of authentication provider.';
