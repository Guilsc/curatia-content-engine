# Public API Contract

Status: **implemented in Supabase — pending consumer production configuration**

The BA Content Engine may expose a small, versioned, read-only API for approved public content. The API is an integration boundary: consumers must not depend on the BA Content Engine database schema, Supabase project, internal workflow tables, or service credentials.

## v1 publications

Logical endpoint:

```http
GET /api/v1/publications?channel=linkedin&portfolio=true&limit=3
```

Runtime: Supabase Edge Function `publications-v1`.

Production endpoint:

```text
https://jzceajrfqtrdemptlfbp.supabase.co/functions/v1/publications-v1
```

The function reads a private `public.portfolio_publications` projection. Browser/anonymous roles cannot query the table directly; the function returns only portfolio-approved public fields.

### Response

```json
{
  "version": "1",
  "publications": [
    {
      "id": "stable-public-id",
      "channel": "linkedin",
      "title": "The requirements phase is over.",
      "summary": "A short portfolio-safe summary.",
      "category": "Business Analysis",
      "url": "https://www.linkedin.com/feed/update/...",
      "publishedAt": "2026-09-23T11:45:21-03:00"
    }
  ]
}
```

### Field semantics

- `id`: stable public identifier; consumers must not depend on an internal database primary key.
- `channel`: publication channel, initially `linkedin`.
- `title`: display title appropriate for external consumers.
- `summary`: short public summary/excerpt.
- `category`: optional public-facing category.
- `url`: canonical public destination for the publication.
- `publishedAt`: ISO-8601 publication timestamp.

### Query semantics

- `channel`: optional channel filter.
- `portfolio=true`: return only items explicitly approved for portfolio/public-site consumption.
- `limit`: maximum number of items requested; the API should return newest publications first.

## Security and ownership

The API must expose only deliberately public publication data. It must not expose drafts, approval state, scheduling metadata, Metricool identifiers, private editorial notes, internal Supabase keys, or internal table structure.

BA Content Engine owns the publication data and the API contract. Consumer projects own their own presentation and fallback behavior.

## Compatibility

Breaking changes require a new API version. Additive optional fields may be introduced in v1 if existing consumers remain valid.

The personal site should consume this contract through a configurable endpoint URL rather than hardcoding database details.
