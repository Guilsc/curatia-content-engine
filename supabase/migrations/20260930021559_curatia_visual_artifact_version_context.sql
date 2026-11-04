
alter table public.content_visual_assets add column if not exists publishing_channel text;
alter table public.content_visual_assets add column if not exists content_format text;
alter table public.content_visual_assets add column if not exists file_name text;
alter table public.content_visual_assets add column if not exists mime_type text;
alter table public.content_visual_assets add column if not exists file_size bigint;
create index if not exists content_visual_assets_item_version_idx on public.content_visual_assets(workspace_id,content_item_id,version desc);
