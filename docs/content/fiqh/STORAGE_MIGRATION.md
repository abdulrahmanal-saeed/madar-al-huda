# FIQH-DEV-02 — SQLite storage staging and rollback

The existing Hostinger private SQLite database is authoritative. The additive schema is implemented in hosting/admin/fiqh-storage.php; it is intentionally not invoked by the live database bootstrap or by any HTTP/MCP endpoint.

## Schema
- fiqh_migrations tracks explicit schema versions.
- fiqh_categories stores hierarchical metadata; parent IDs reference categories.
- fiqh_sources holds reusable bibliographic records. Referenced source records are frozen into every immutable issue revision.
- fiqh_issues has unique stable IDs, issue numbers and slugs.
- fiqh_revisions stores canonical nested bilingual JSON (positions/evidence/analysis) with category FKs, source snapshot, hash and actor. Related category, issue and source indexes are transactionally derived from this JSON; they are not a second editable source.
- fiqh_events records draft creation/revisions; DB triggers prohibit direct revision/event updates and deletes.
- fiqh_introductions and fiqh_settings contain draft placeholders/disclaimer.
- There is deliberately no review approval or publication table/API yet. Existing legacy feed cannot see these new tables.

## Staging procedure
1. On a staging copy of the production database, use the SQLite online backup API or sqlite3 .backup (not a plain file copy of an active WAL database). Protect backup with permissions equivalent to original. Verify integrity and preserve pre-migration backup.
2. With PHP CLI, PDO SQLite and JSON support, load hosting/admin/fiqh-storage.php and docs/content/fiqh/seed.json. Connect to the staging copy, with PDO ERRMODE_EXCEPTION, and call fiqhMigration($db, $seed). Do not point this at production.
3. Run PRAGMA integrity_check and PRAGMA foreign_key_check; verify legacy library draft/published values and revisions unchanged, 11 categories, 17 placeholder sources, 8 introduction records and zero new issues. Run the migration a second time and confirm counts unchanged.
4. Run php hosting/tests/fiqh_model_test.php and php hosting/tests/fiqh_storage_test.php. Full CI and staging backup/restore must pass before authorizing production.
5. Rollback before any actual editorial use: discard staging copy; on a future approved production rollout, prefer restoring the pre-migration backup during a coordinated maintenance window only if no intervening writes need preservation. Never drop tables or restore an old whole-library backup over newer editorial changes. After use, roll back code first (old code ignores additive tables) and preserve new records; prepare a separately verified reconciliation plan.

## Boundaries
This is a storage foundation, not a production authorization boundary. The draft helper requires callers to derive actor identity and permission from the existing authenticated session or MCP key. No caller is wired yet. Draft input supports incomplete content; comprehensive nested validation, category/source CRUD, edition records, review state transitions, immutable approvals, published-only snapshots, legacy migration and endpoint guards remain future milestones. Test data is synthetic and confined to in-memory tests. No live migration or release has been performed.
