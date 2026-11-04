
create or replace function public.begin_curatia_watch_run(p_workspace_id uuid)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare v_run uuid;
begin
  insert into public.scout_runs(run_key,status,discovery_window_hours,workspace_id,discovery_interest_snapshot,metadata)
  values (
    'watch-'||p_workspace_id::text||'-'||to_char(now(),'YYYYMMDDHH24MISSMS'),
    'running',48,p_workspace_id,
    coalesce((select to_jsonb(discovery_interests) from public.workspace_preferences where workspace_id=p_workspace_id),'[]'::jsonb),
    jsonb_build_object('mode','watch_revisit')
  ) returning id into v_run;

  insert into public.signal_review_snapshots(signal_id,scout_run_id,source_count,evidence_strength,saturation,why_now,ba_impact,second_order_implication,editorial_potential,snapshot_reason)
  select s.id,v_run,count(ss.source_id)::int,s.evidence_strength,s.saturation,s.why_now,s.ba_impact,s.second_order_implication,s.editorial_potential,'watch_revisit_before'
  from public.signals s
  left join public.signal_sources ss on ss.signal_id=s.id
  where s.workspace_id=p_workspace_id and s.state='Watch'
  group by s.id;

  return v_run;
end $$;

create or replace function public.complete_curatia_watch_run(p_run_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
begin
  update public.scout_runs r set
    completed_at=now(),
    status='completed',
    signals_found=(select count(*) from public.signals s where s.last_seen_run_id=p_run_id),
    new_signals=(select count(*) from public.signals s where s.first_seen_run_id=p_run_id)
  where r.id=p_run_id;
end $$;
