
create policy "authenticated_read_channel_catalog" on public.channel_catalog for select to authenticated using(true);
create policy "self_read_platform_role" on public.platform_roles for select to authenticated using(user_id=auth.uid());
create policy "members_read_signal_sources" on public.signal_sources for select to authenticated using(exists(select 1 from public.signals s where s.id=signal_sources.signal_id and public.is_curatia_member(s.workspace_id)));
create policy "members_read_content_signals" on public.content_item_signals for select to authenticated using(exists(select 1 from public.content_items c where c.id=content_item_signals.content_item_id and public.is_curatia_member(c.workspace_id)));
create policy "members_read_content_sources" on public.content_item_sources for select to authenticated using(exists(select 1 from public.content_items c where c.id=content_item_sources.content_item_id and public.is_curatia_member(c.workspace_id)));
create policy "members_read_claims" on public.claims for select to authenticated using(exists(select 1 from public.content_items c where c.id=claims.content_item_id and public.is_curatia_member(c.workspace_id)));
create policy "members_read_evidence" on public.evidence_notes for select to authenticated using(exists(select 1 from public.sources s where s.id=evidence_notes.source_id and public.is_curatia_member(s.workspace_id)));
