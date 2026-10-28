# Current State - 2026-09-22

## Status at end of session

The Curatia is operational through ChatGPT Sites with Supabase as the canonical Trend Radar data store.

Production URL:

`https://curatia-content-engine.guilhermecosta.tech/`

GitHub remains the portable recovery/source repository so the project is not dependent on one ChatGPT account.

## Current platform split

- GitHub = portable source/configuration/recovery
- Supabase = canonical live application data
- ChatGPT Project = editorial intelligence workspace
- ChatGPT Site = current operational UI
- Scheduled Tasks = background workers
- Hostinger = DNS/domain management

## Supabase

Project: `curatia-content-engine`

Region: `sa-east-1` (Sao Paulo)

Project ref: `jzceajrfqtrdemptlfbp`

Project URL: `https://jzceajrfqtrdemptlfbp.supabase.co`

Phase 1 tables:
- `public.sources`
- `public.signals`
- `public.signal_sources`
- `public.scout_runs`

RLS is enabled. Anonymous/browser direct access remains closed.

### Current canonical data

Validated on 2026-09-22 after Site migration:
- 7 Signals
- 11 Sources
- 13 Signal-Source links
- 0 Scout Runs

Signal states:
- 4 Watch
- 3 Explore

Integrity checks:
- all 7 Signals have at least one linked Source
- no duplicate canonical Source URLs were detected

## Site ↔ Supabase integration

Phase 1 Trend Radar migration completed.

Validated:
1. Existing Signals were migrated into Supabase.
2. Existing Sources were migrated and linked.
3. Existing editorial state was preserved.
4. A temporary Signal inserted directly into Supabase appeared in the live Trend Radar without a Site code change.
5. The temporary Signal and Source were deleted after validation.

This proves the live Site is reading Supabase rather than relying only on a one-time local copy.

A separate write-action acceptance check should still be retained in the future regression checklist whenever Site behavior changes.

## Site authentication

During the Site update flow, Google was selected as the authentication method.

No authentication secrets are stored in Git.

## Custom domain

Live Site:

`https://curatia-content-engine.guilhermecosta.tech/`

DNS is managed in Hostinger.

The root domain `guilhermecosta.tech` remains reserved for Guilherme's personal site/portfolio.

Planned portfolio pattern:
- `guilhermecosta.tech` → personal site
- `guilhermecosta.tech/projects` → project gallery
- `guilhermecosta.tech/projects/curatia-content-engine` → project/case page
- `curatia-content-engine.guilhermecosta.tech` → live application

## Scheduled Tasks

### BA Trend Scout

Enabled.

Schedule:
- Monday, Wednesday, Friday
- 08:37 America/Sao_Paulo
- discovery window approximately 48 hours

Responsibilities:
- discover genuinely new qualified signals
- create/reuse Sources
- create New Signals only
- create Signal-Source relationships
- create/update Scout Run metadata
- never create Idea/Candidate automatically
- never infer approval

Pending validation:
- observe the next scheduled run and confirm it actually writes to Supabase autonomously

### Trend Radar Weekly Review

Enabled.

Schedule:
- Saturday
- 09:00 America/Sao_Paulo

Responsibilities:
- evaluate unresolved New/Watch/Explore Signals
- write evaluation fields back to Supabase
- may move New -> Watch / Explore / Ignored
- never create Idea/Candidate automatically
- never set Promoted automatically

Pending validation:
- confirm first real review run reads/writes canonical Supabase state

## GitHub

Private repository:

`Guilsc/curatia-content-engine`

Portable content currently committed:
- Project Instructions
- editorial Resources
- workflow Skills
- Trend Scout Skill
- Source Registry schema/contracts
- automation specifications
- lifecycle/governance
- architecture/current-state documentation
- Supabase migration
- Site state/recovery documentation
- fallback Next.js application

## Fallback application

A Phase 1 Next.js implementation remains under `app/`.

It:
- compiles successfully in GitHub Actions
- reads Supabase server-side
- renders Trend Radar and Sources
- supports server-side Radar state changes
- has a private access-key flow

It is currently a fallback/reference implementation, **not** the production UI.

Do not deploy it while the ChatGPT Site is working unless an explicit architecture decision is made.

## Not migrated yet

Supabase Phase 2+ still pending:
- Ideas
- Content Items
- Claims
- Evidence Notes
- workflow history
- Idea Tank
- Content Pipeline
- Editorial Studio
- Publishing & Learnings

Do not create or migrate these automatically. Continue incrementally.

## Next session

1. Let the existing Scout schedule run normally. Do not create an extra test run tonight.
2. After the next Scout run, inspect `scout_runs`, `signals`, `sources`, and `signal_sources`.
3. Confirm the new/updated Signal is visible in the live Site.
4. Later validate the Saturday Weekly Review write-back.
5. Only after Phase 1 background-worker validation, plan Supabase Phase 2 for Idea Tank / Content Items.

No further changes are required tonight.


## Public publications API

Implemented as a deliberately narrow portfolio projection:

- private table: `public.portfolio_publications`
- public Edge Function: `publications-v1`
- contract: `docs/PUBLIC-API.md`
- direct table access remains closed to anonymous/authenticated clients
- the function returns only rows explicitly marked `portfolio = true`
- no draft, workflow, scheduling, Metricool, or credential data is exposed

Personal-site consumer configuration still required:

- set `BA_CONTENT_PUBLICATIONS_URL` in Hostinger to the deployed Edge Function URL
- validate the production portfolio against the live endpoint

## Enhancement backlog
- [ ] When publishing automation is designed, reconcile only the specific scheduled publication after its known publish time (for the current Wednesday cadence, a small delay such as +5 minutes is sufficient before the first verification attempt).
