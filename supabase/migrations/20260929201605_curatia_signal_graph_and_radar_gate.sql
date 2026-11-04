
alter table public.signals
  add column if not exists radar_status text not null default 'detected'
  check (radar_status in ('detected','radar','dismissed')),
  add column if not exists radar_entered_at timestamptz,
  add column if not exists radar_entry_reason text;

update public.signals
set radar_status='radar',
    radar_entered_at=coalesce(radar_entered_at,detected_at),
    radar_entry_reason=coalesce(radar_entry_reason,'Existing Trend Radar signal migrated into explicit radar gate')
where state in ('New','Watch','Explore','Promoted');

create table if not exists public.signal_relationships (
  from_signal_id uuid not null references public.signals(id) on delete cascade,
  to_signal_id uuid not null references public.signals(id) on delete cascade,
  relationship_type text not null default 'related_to'
    check (relationship_type in ('related_to','supports','contradicts','evolves_from','converging_with')),
  strength numeric(4,3) not null default 0.5 check (strength >= 0 and strength <= 1),
  reason text,
  discovered_by text not null default 'scout',
  first_detected_at timestamptz not null default now(),
  last_updated_at timestamptz not null default now(),
  primary key(from_signal_id,to_signal_id,relationship_type),
  check (from_signal_id <> to_signal_id)
);
alter table public.signal_relationships enable row level security;
create index if not exists signal_relationships_from_idx on public.signal_relationships(from_signal_id);
create index if not exists signal_relationships_to_idx on public.signal_relationships(to_signal_id);
