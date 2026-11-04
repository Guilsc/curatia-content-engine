import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { validateMigrationHistory } from './validate-migration-history.mjs';

const hash = (value) => createHash('sha256').update(value).digest('hex');
function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), 'curatia-history-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  mkdirSync(join(root, 'supabase', 'migrations'), { recursive: true });
  const path = 'supabase/migrations/20240101000000_synthetic_fixture.sql';
  const statement = '-- Synthetic fixture; never executed.\nselect 1;';
  writeFileSync(join(root, path), statement + '\n');
  writeFileSync(join(root, 'supabase', 'migration-history.json'), JSON.stringify({ format: 1, entries: [{
    version: '20240101000000', name: 'synthetic_fixture', path,
    statement_sha256: hash(statement), file_sha256: hash(statement + '\n'), terminal_newline_added: true,
  }] }));
  return { root, path };
}

test('recorded statements validate without a database connection', (t) => {
  const { root } = fixture(t);
  assert.deepEqual(validateMigrationHistory(root), { historicalVersions: 1, migrationFiles: 1, newVersions: 0 });
});
test('draft date-only filenames cannot enter active migrations', (t) => {
  const { root } = fixture(t);
  writeFileSync(join(root, 'supabase/migrations/20240101_draft.sql'), '-- Synthetic draft');
  assert.throws(() => validateMigrationHistory(root), /Invalid migration filename/);
});
test('duplicate canonical versions fail closed', (t) => {
  const { root } = fixture(t);
  writeFileSync(join(root, 'supabase/migrations/20240101000000_duplicate.sql'), '-- Synthetic duplicate');
  assert.throws(() => validateMigrationHistory(root), /Duplicate migration version/);
});
test('historical statement edits are detected', (t) => {
  const { root, path } = fixture(t);
  writeFileSync(join(root, path), readFileSync(join(root, path), 'utf8') + '-- Changed fixture');
  assert.throws(() => validateMigrationHistory(root), /Historical file changed/);
});
