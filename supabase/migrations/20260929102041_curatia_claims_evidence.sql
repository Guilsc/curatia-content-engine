
create table if not exists public.claims (
  id uuid primary key default gen_random_uuid(),
  content_item_id text not null references public.content_items(id) on delete cascade,
  claim_text text not null,
  claim_type text,
  status text not null default 'Unverified' check (status in ('Unverified','Supported','Mixed','Rejected')),
  confidence text check (confidence is null or confidence in ('Low','Moderate','High')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.claims enable row level security;
drop trigger if exists claims_set_updated_at on public.claims;
create trigger claims_set_updated_at before update on public.claims for each row execute function public.set_updated_at();

create table if not exists public.evidence_notes (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references public.sources(id) on delete cascade,
  claim_id uuid references public.claims(id) on delete cascade,
  evidence_type text not null check (evidence_type in ('Supports','Contradicts','Limits','Context','Example','Background')),
  note text not null,
  strength text check (strength is null or strength in ('Strong','Moderate','Weak')),
  limitations text,
  created_by_workflow text,
  created_at timestamptz not null default now()
);
alter table public.evidence_notes enable row level security;
create index if not exists evidence_notes_source_idx on public.evidence_notes(source_id);
create index if not exists evidence_notes_claim_idx on public.evidence_notes(claim_id);
