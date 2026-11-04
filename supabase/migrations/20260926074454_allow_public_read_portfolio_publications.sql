create policy "Public can read portfolio publications"
on public.portfolio_publications
for select
to anon, authenticated
using (portfolio = true and channel = 'linkedin');
