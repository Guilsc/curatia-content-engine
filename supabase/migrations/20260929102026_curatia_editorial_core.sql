
create table if not exists public.content_items (
  id text primary key,
  title text not null,
  series text,
  topic text,
  publishing_channel text not null default 'linkedin',
  core_idea text,
  why_now text,
  ba_implication text,
  second_order_implication text,
  strongest_angle text,
  saturation text,
  evidence_strength text,
  source_origin text,
  status text not null default 'Idea' check (status in ('Idea','Candidate','Research','Draft','Visual Ready','Approved','Scheduled','Published','Learning')),
  target_date date,
  publication_date date,
  publication_time time,
  sources jsonb not null default '[]'::jsonb,
  verified_facts jsonb not null default '[]'::jsonb,
  limitations jsonb not null default '[]'::jsonb,
  evidence_gaps jsonb not null default '[]'::jsonb,
  revised_thesis text,
  draft_copy text,
  final_copy text,
  visual_concept text,
  visual_brief text,
  final_visual_reference text,
  approved_by_user boolean not null default false,
  approval_timestamp timestamptz,
  approval_note text,
  impressions integer,
  reactions integer,
  comments integer,
  reposts integer,
  saves integer,
  sends integer,
  profile_visits integer,
  new_followers integer,
  qualitative_feedback text,
  learning_summary text,
  learning_confidence text,
  metadata jsonb not null default '{}'::jsonb,
  workspace_id uuid references public.workspaces(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists content_items_status_idx on public.content_items(status);
create index if not exists content_items_target_date_idx on public.content_items(target_date);
alter table public.content_items enable row level security;
drop trigger if exists content_items_set_updated_at on public.content_items;
create trigger content_items_set_updated_at before update on public.content_items for each row execute function public.set_updated_at();

create table if not exists public.content_item_signals (
  content_item_id text not null references public.content_items(id) on delete cascade,
  signal_id uuid not null references public.signals(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (content_item_id, signal_id)
);
alter table public.content_item_signals enable row level security;

create table if not exists public.content_item_sources (
  content_item_id text not null references public.content_items(id) on delete cascade,
  source_id uuid not null references public.sources(id) on delete cascade,
  role text not null default 'inherited' check (role in ('inherited','research','supporting','counter')),
  created_at timestamptz not null default now(),
  primary key (content_item_id, source_id)
);
alter table public.content_item_sources enable row level security;
