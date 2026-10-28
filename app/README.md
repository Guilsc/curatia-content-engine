# Curatia Web Application

This directory contains the Next.js application for Curatia, including Trend Radar, workspace onboarding, settings, and the current Supabase Auth session flow.

## Status

Curatia is moving incrementally toward its portable production runtime. For the current deployment status and operating model, refer to the [repository README](../README.md) and [current-state notes](../docs/CURRENT-STATE.md).

Do not assume that every Alpha capability described in the architecture baseline is already implemented.

## Authentication

The current application uses Supabase Auth for sign-in, sign-up, and sign-out. Server-side sessions are resolved with Supabase SSR cookies; workspace membership and roles are checked before protected operations.

The former personal access-key login description is no longer applicable to the current application code.

## Environment configuration

See [`.env.example`](.env.example) for historical configuration examples, but do not treat `APP_ACCESS_KEY` as the current login mechanism.

The current authentication and server-side data clients reference these environment variables:

```dotenv
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-publishable-key
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_SECRET_KEY=your-server-side-secret-key
```

Keep `SUPABASE_SECRET_KEY` server-side only. Never commit real credentials. Configure production values in the deployment platform's secret settings.

## Architecture

- GitHub: portable application code and operational documentation
- Supabase: authentication and canonical application data
- Hostinger: current/target Next.js deployment runtime
- Curatia Alpha baseline: [`docs/CURATIA-ALPHA-BASELINE.md`](../docs/CURATIA-ALPHA-BASELINE.md)
