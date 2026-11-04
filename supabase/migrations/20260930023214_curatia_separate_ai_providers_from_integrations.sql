
create table if not exists public.ai_provider_catalog (
  key text primary key,
  display_name text not null,
  active boolean not null default true,
  setup_status text not null default 'setup_required' check (setup_status in ('ready','setup_required','disabled')),
  capabilities text[] not null default '{}',
  credential_source text not null default 'platform' check (credential_source in ('platform','workspace')),
  metadata jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.ai_provider_catalog enable row level security;
drop policy if exists "authenticated read ai provider catalog" on public.ai_provider_catalog;
create policy "authenticated read ai provider catalog" on public.ai_provider_catalog for select to authenticated using (true);

insert into public.ai_provider_catalog(key,display_name,active,setup_status,capabilities,credential_source,metadata)
values ('cloudflare-workers-ai','Cloudflare Workers AI',true,'ready',array['Text generation','Image generation'],'platform',
'{"credential_env":["CLOUDFLARE_ACCOUNT_ID","CLOUDFLARE_API_TOKEN"],"managed_by":"platform_owner"}'::jsonb)
on conflict (key) do update set display_name=excluded.display_name,active=excluded.active,setup_status=excluded.setup_status,capabilities=excluded.capabilities,credential_source=excluded.credential_source,metadata=excluded.metadata,updated_at=now();

delete from public.integration_catalog where key='cloudflare-workers-ai';
