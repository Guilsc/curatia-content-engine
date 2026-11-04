
update public.integration_catalog
set active=false, updated_at=now()
where key='cloudflare-workers-ai' and provider='cloudflare';
