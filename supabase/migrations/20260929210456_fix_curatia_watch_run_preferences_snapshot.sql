
create or replace function public.begin_curatia_watch_run(p_workspace_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_run_id uuid;
  v_snapshot jsonb;
begin
  select jsonb_build_object(
    'baselines', coalesce(to_jsonb(discovery_baselines), '[]'::jsonb),
    'watchlists', coalesce(to_jsonb(discovery_watchlists), '[]'::jsonb)
  )
  into v_snapshot
  from public.workspace_preferences
  where workspace_id = p_workspace_id;

  insert into public.scout_runs(
    run_key,status,discovery_window_hours,workspace_id,discovery_interest_snapshot,metadata
  )
  values(
    'watch-' || p_workspace_id::text || '-' || extract(epoch from clock_timestamp())::bigint::text,
    'running',48,p_workspace_id,coalesce(v_snapshot,'{}'::jsonb),jsonb_build_object('mode','watch_revisit')
  )
  returning id into v_run_id;

  insert into public.signal_review_snapshots(
    signal_id,scout_run_id,source_count,evidence_strength,saturation,why_now,ba_impact,
    second_order_implication,editorial_potential,snapshot_reason
  )
  select
    s.id,v_run_id,count(ss.source_id)::integer,s.evidence_strength,s.saturation,s.why_now,s.ba_impact,
    s.second_order_implication,s.editorial_potential,'watch_revisit_before'
  from public.signals s
  left join public.signal_sources ss on ss.signal_id=s.id
  where s.workspace_id=p_workspace_id and s.state='Watch'
  group by s.id;

  return v_run_id;
end;
$$;
