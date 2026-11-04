import { createHash } from 'node:crypto';
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const repositoryRoot = fileURLToPath(new URL('../', import.meta.url));
const digest = (bytes) => createHash('sha256').update(bytes).digest('hex');

export function validateMigrationHistory(root = repositoryRoot) {
  const directory = join(root, 'supabase', 'migrations');
  const files = readdirSync(directory).filter((name) => name.endsWith('.sql'));
  const versions = new Set();
  for (const filename of files) {
    const match = /^(\d{14})_[A-Za-z0-9_-]+\.sql$/.exec(filename);
    if (!match) throw new Error(`Invalid migration filename: ${filename}`);
    if (versions.has(match[1])) throw new Error(`Duplicate migration version: ${match[1]}`);
    versions.add(match[1]);
  }
  const manifest = JSON.parse(readFileSync(join(root, 'supabase', 'migration-history.json'), 'utf8'));
  if (manifest.format !== 1 || !Array.isArray(manifest.entries)) throw new Error('Invalid history manifest');
  const recorded = new Set();
  for (const entry of manifest.entries) {
    if (!/^\d{14}$/.test(entry.version) || !/^[A-Za-z0-9_-]+$/.test(entry.name)) throw new Error('Invalid recorded migration identifier');
    const expectedPath = `supabase/migrations/${entry.version}_${entry.name}.sql`;
    if (entry.path !== expectedPath || !versions.has(entry.version) || recorded.has(entry.version)) throw new Error(`Missing or duplicate historical migration: ${entry.version}`);
    const bytes = readFileSync(join(root, entry.path));
    if (digest(bytes) !== entry.file_sha256) throw new Error(`Historical file changed: ${entry.path}`);
    if (entry.terminal_newline_added && bytes.at(-1) !== 10) throw new Error(`Missing terminal newline: ${entry.path}`);
    const statement = entry.terminal_newline_added ? bytes.subarray(0, -1) : bytes;
    if (!statement.toString('utf8').trim() || digest(statement) !== entry.statement_sha256) throw new Error(`Applied statement mismatch: ${entry.path}`);
    recorded.add(entry.version);
  }
  return { historicalVersions: recorded.size, migrationFiles: files.length, newVersions: versions.size - recorded.size };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  console.log(JSON.stringify(validateMigrationHistory()));
}
