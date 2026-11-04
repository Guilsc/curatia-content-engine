
alter table public.integration_catalog
  add column if not exists description text,
  add column if not exists toolkit_slug text,
  add column if not exists auth_config_ref text;

update public.integration_catalog
set toolkit_slug=coalesce(toolkit_slug,key),
    description=coalesce(description,
      case key
        when 'linkedin' then 'Profile and publishing access for LinkedIn.'
        when 'metricool' then 'Scheduling and publishing through Metricool.'
        when 'googledrive' then 'Search and read workspace files in Google Drive.'
        when 'github' then 'Repository access for development workflows.'
        when 'gmail' then 'Read and send email through Gmail.'
        else null end)
where toolkit_slug is null or description is null;
