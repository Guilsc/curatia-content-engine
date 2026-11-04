
create table if not exists public.integration_catalog (
  key text primary key,
  display_name text not null,
  category text not null default 'Other',
  provider text not null default 'composio',
  active boolean not null default true,
  setup_status text not null default 'ready' check (setup_status in ('ready','setup_required','disabled')),
  capabilities text[] not null default '{}',
  sort_order integer not null default 100,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.integration_catalog enable row level security;

insert into public.integration_catalog(key,display_name,category,provider,active,setup_status,capabilities,sort_order)
values
 ('linkedin','LinkedIn','Publishing','composio',true,'ready',array['Profile','Publishing'],10),
 ('metricool','Metricool','Publishing','composio',true,'setup_required',array['Scheduling','Publishing'],20),
 ('googledrive','Google Drive','Knowledge & Files','composio',true,'ready',array['Search','Read files'],30),
 ('github','GitHub','Development','composio',true,'ready',array['Repositories'],40),
 ('gmail','Gmail','Communication','composio',true,'ready',array['Read mail','Send mail'],50)
on conflict (key) do update set
 display_name=excluded.display_name, category=excluded.category, provider=excluded.provider,
 active=excluded.active, setup_status=excluded.setup_status, capabilities=excluded.capabilities,
 sort_order=excluded.sort_order, updated_at=now();

alter table public.profiles add column if not exists platform_role text not null default 'user'
  check (platform_role in ('user','platform_owner'));
update public.profiles
set platform_role='platform_owner'
where user_id in (
 select user_id from public.workspace_members
 order by created_at
 limit 1
);
