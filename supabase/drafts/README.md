# Archived migration drafts — do not deploy

These six files retain their original filenames and contents for design history. They are pre-deployment drafts, not the canonical versions recorded in the production migration history.

Do not copy them back into `supabase/migrations/`, execute them as pending migrations, or assign them guessed production timestamps. The authoritative applied versions are in [`../migrations/`](../migrations/), with captured-statement provenance in [`../migration-history.json`](../migration-history.json).

See [migration-history guidance](../README.md) before proposing database changes. Restoring source history does not authorize SQL execution or migration-history repair.
