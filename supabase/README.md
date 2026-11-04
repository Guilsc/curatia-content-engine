# Supabase migration history

`migrations/` contains the migration versions already recorded as applied in the project's Supabase database. The historical SQL was recovered through read-only Supabase Management API requests, not reconstructed from the current schema or replaced with empty placeholders.

`migration-history.json` records each version, original name, captured-statement SHA-256 and repository-file SHA-256. Statement text is preserved; when an exported statement had no final newline, the repository adds one and records that difference explicitly. Creator identities, access credentials and connection settings are not included.

The reconciliation changed repository files only. It did **not** execute SQL, mark migrations applied/reverted, alter production migration records, or change application data. All recovered versions were already applied before this repair.

## Validate locally

```bash
node scripts/validate-migration-history.mjs
node --test scripts/validate-migration-history.test.mjs
```

Run these commands from the repository root. Validation requires only Node.js and makes no network or database requests. It rejects date-only draft filenames, duplicate versions, missing historical files and historical statement edits. New migrations must have a unique 14-digit timestamp prefix and remain subject to the project's explicit database-change approval rules.

## Archived drafts

The six earlier `20260929_00N_*.sql` planning files are preserved unchanged in [`drafts/`](drafts/README.md). They were not the versions recorded in production and must not be treated as pending production migrations. Keeping those eight-digit prefixes in the active migration directory both obscured the applied history and introduced conflicting draft version identifiers.

Do not run `supabase migration repair` or apply archived drafts merely to make an integration check green. Compare the applied history first and retain the actual SQL provenance.
