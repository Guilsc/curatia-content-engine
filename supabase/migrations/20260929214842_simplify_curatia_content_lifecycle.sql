
alter table public.content_items drop constraint if exists content_items_status_check;
update public.content_items set status='In Progress' where status in ('Candidate','Research','Draft');
update public.content_items set status='Ready' where status='Visual Ready';
update public.content_items set status='Published' where status='Learning';
alter table public.content_items add constraint content_items_status_check
check (status = any (array['Idea'::text,'In Progress'::text,'Ready'::text,'Approved'::text,'Scheduled'::text,'Published'::text]));
create index if not exists content_items_status_idx on public.content_items(workspace_id,status);
