
create table if not exists public.signal_review_snapshots (
  id uuid primary key default gen_random_uuid(),
  signal_id uuid not null references public.signals(id) on delete cascade,
  scout_run_id uuid references public.scout_runs(id) on delete set null,
  source_count integer not null default 0 check (source_count >= 0),
  evidence_strength text check (evidence_strength is null or evidence_strength in ('Strong','Moderate','Weak')),
  saturation text check (saturation is null or saturation in ('Low','Medium','High')),
  why_now text,
  ba_impact text,
  second_order_implication text,
  editorial_potential text check (editorial_potential is null or editorial_potential in ('Watch','Explore','Candidate')),
  snapshot_reason text not null default 'scout_run',
  created_at timestamptz not null default now()
);
create index if not exists signal_review_snapshots_signal_created_idx on public.signal_review_snapshots(signal_id,created_at desc);
alter table public.signal_review_snapshots enable row level security;
