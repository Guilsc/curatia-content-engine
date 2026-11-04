
delete from public.ai_provider_catalog where key='cloudflare';
update public.ai_capability_routing
set preferred_model='nano-banana-2', fallback_mode='auto', updated_at=now()
where scope='platform' and workspace_id is null and capability='image_generation';
