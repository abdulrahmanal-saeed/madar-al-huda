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

## Version 2: editable metadata
After version 1, load hosting/admin/fiqh-metadata.php and explicitly invoke fiqhMetadataMigration($db) on the staging database. It adds an append-only metadata audit table and version marker. Run php hosting/tests/fiqh_metadata_test.php. Category/source writes use create-only null tokens or exact stored-body edit tokens; reparenting a category referenced by an immutable issue revision is prohibited. Category writes are draft-only; hide rather than delete. Source edits affect subsequent draft saves, never previous source snapshots. Listings are private and bounded; actual published counts remain unavailable until the publication model exists. No HTTP route or live migration is enabled. Separate edition entities, authenticated callers, complete nested validation and source verification remain outstanding.

## FIQH-DEV-09: first-release staging rehearsal
Run from a trusted checkout on a private machine (PHP CLI with PDO SQLite and SQLite3::backup):

    php hosting/fiqh-stage.php /private/path/library.sqlite3 /private/path/fiqh-rehearsal-01

The destination must not exist; its parent must be private and outside any served document root. The utility opens the source read-only, makes an online SQLite snapshot, verifies it, creates a separate offline staging copy, runs versions 1–4 twice, checks integrity and foreign keys, compares fingerprints of library/publications/users, and requires exactly 11 categories, 17 sources, 8 introductions, zero issues, zero grants and no public activation. It writes a private report with checksums. It refuses an already-migrated source or reused destination. A failed run can leave a partial private directory for investigation; never upload the snapshot, staging DB, or report to a public directory or CI artifact. The path check is not a substitute for an operator verifying private storage. A synthetic WAL-source rehearsal is added to CI. The tool is outside hosting/admin, so code-only Hostinger deployment does not expose it.

Production rollout remains a separate approved maintenance operation: verify full CI and staging rehearsal on an authorized private production snapshot; confirm current code and backup, legacy freeze impact, migration plan and permissions; apply additive migrations only with qualified operator approval and verified backups; verify old feeds and draft counts, leave public_enabled absent; test human review, draft-only MCP and APK on staging; activate public feed only after a separate approval and review of legacy content. Roll back code first; never restore a whole stale DB over newer writes. No automatic live migration, no public activation, no signing or deployment was triggered here.

## Main production rollout
The owner requested direct main deployment after the successful private Hostinger rehearsal (run 46179547463). The main deployment now executes the CLI-only production migration after code health checks and its private SQLite online backup. Versions 1–4 are applied in one write transaction, with integrity/foreign-key checks, unchanged legacy digest, and expected initial counts. Failed migration rolls back all versions; an already complete schema is left untouched. No synthetic content, scholarly approvals, or privileges are created. If the old published fiqh list is empty, enable the approved-only public feed; otherwise preserve the existing public experience and keep the dedicated feed disabled until an explicit cutover. No DB file is uploaded to GitHub. The code rollback never restores a stale database. CI exercises both legacy cases, failure rollback and idempotence; the owner will test the live admin/app. This change is authorized on main, not a new staging branch.
