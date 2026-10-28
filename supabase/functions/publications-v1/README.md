# publications-v1 Edge Function

Public, read-only implementation of the BA Content Engine publications `v1` contract.

Deployment requirement:

- deploy with JWT verification disabled because the endpoint deliberately exposes only portfolio-approved public records;
- the function itself holds no checked-in credential;
- it queries `public.portfolio_publications` server-side with the Supabase-provided secret/service-role environment credential;
- the underlying table remains inaccessible to `anon` and `authenticated` roles.

Production URL pattern:

```text
https://<project-ref>.supabase.co/functions/v1/publications-v1
```

The function always filters to `portfolio = true`, caps `limit` at 20, and returns only the stable public contract fields.
