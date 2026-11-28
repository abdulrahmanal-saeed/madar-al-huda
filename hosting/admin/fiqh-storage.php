<?php
declare(strict_types=1);

require_once __DIR__ . '/fiqh-model.php';

/**
 * Versioned fiqh storage inside the existing private library.sqlite3.
 * Explicit migration only: never execute on a public request.
 * No publication or approval capability is exposed in this milestone.
 */
function fiqhTransaction(PDO $db, callable $callback): mixed
{
    $db->exec('PRAGMA foreign_keys = ON');
    if ((int) $db->query('PRAGMA foreign_keys')->fetchColumn() !== 1) {
        throw new RuntimeException('Fiqh requires SQLite foreign keys');
    }
    $db->exec('BEGIN IMMEDIATE');
    try {
        $result = $callback();
        $db->exec('COMMIT');
        return $result;
    } catch (Throwable $error) {
        $db->exec('ROLLBACK');
        throw $error;
    }
}

function fiqhJson(array $value): string
{
    return json_encode($value, JSON_THROW_ON_ERROR | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}

function fiqhCanonical(mixed $value): mixed
{
    if (!is_array($value)) {
        return $value;
    }
    if (!array_is_list($value)) {
        ksort($value, SORT_STRING);
    }
    return array_map('fiqhCanonical', $value);
}

function fiqhMigration(PDO $db, array $seed): void
{
    fiqhTransaction($db, function () use ($db, $seed): void {
        $db->exec('CREATE TABLE IF NOT EXISTS fiqh_migrations (version INTEGER PRIMARY KEY, applied_at INTEGER NOT NULL)');
        if ($db->query('SELECT 1 FROM fiqh_migrations WHERE version = 1')->fetchColumn()) {
            return;
        }
        if (fiqhCategoryErrors($seed['categories'] ?? []) !== [] || empty($seed['categories'])
            || ($seed['issues'] ?? null) !== []) {
            throw new InvalidArgumentException('Invalid fiqh metadata seed');
        }
        $db->exec(<<<'SQL'
CREATE TABLE fiqh_categories (
    id TEXT PRIMARY KEY, parent_id TEXT REFERENCES fiqh_categories(id) DEFERRABLE INITIALLY DEFERRED,
    body TEXT NOT NULL CHECK(json_valid(body)), updated_at INTEGER NOT NULL,
    CHECK(parent_id IS NULL OR parent_id <> id)
);
CREATE INDEX fiqh_category_parent ON fiqh_categories(parent_id);
CREATE TABLE fiqh_sources (
    id TEXT PRIMARY KEY, body TEXT NOT NULL CHECK(json_valid(body)), updated_at INTEGER NOT NULL
);
CREATE TABLE fiqh_issues (
    id TEXT PRIMARY KEY, number TEXT NOT NULL UNIQUE, slug TEXT NOT NULL UNIQUE,
    created_at INTEGER NOT NULL
);
CREATE TABLE fiqh_revisions (
    issue_id TEXT NOT NULL REFERENCES fiqh_issues(id),
    revision INTEGER NOT NULL CHECK(revision > 0),
    category_id TEXT NOT NULL REFERENCES fiqh_categories(id),
    subcategory_id TEXT REFERENCES fiqh_categories(id),
    body TEXT NOT NULL CHECK(json_valid(body)),
    source_snapshot TEXT NOT NULL CHECK(json_valid(source_snapshot)),
    content_hash TEXT NOT NULL CHECK(length(content_hash) = 64),
    created_at INTEGER NOT NULL, actor TEXT NOT NULL,
    PRIMARY KEY(issue_id, revision)
);
CREATE INDEX fiqh_revision_category ON fiqh_revisions(category_id, issue_id);
CREATE TABLE fiqh_revision_categories (
    issue_id TEXT NOT NULL, revision INTEGER NOT NULL,
    category_id TEXT NOT NULL REFERENCES fiqh_categories(id),
    PRIMARY KEY(issue_id, revision, category_id),
    FOREIGN KEY(issue_id, revision) REFERENCES fiqh_revisions(issue_id, revision)
);
CREATE INDEX fiqh_related_category ON fiqh_revision_categories(category_id);
CREATE TABLE fiqh_revision_related (
    issue_id TEXT NOT NULL, revision INTEGER NOT NULL,
    related_id TEXT NOT NULL REFERENCES fiqh_issues(id),
    CHECK(issue_id <> related_id),
    PRIMARY KEY(issue_id, revision, related_id),
    FOREIGN KEY(issue_id, revision) REFERENCES fiqh_revisions(issue_id, revision)
);
CREATE TABLE fiqh_revision_sources (
    issue_id TEXT NOT NULL, revision INTEGER NOT NULL,
    source_id TEXT NOT NULL REFERENCES fiqh_sources(id),
    PRIMARY KEY(issue_id, revision, source_id),
    FOREIGN KEY(issue_id, revision) REFERENCES fiqh_revisions(issue_id, revision)
);
CREATE INDEX fiqh_related_source ON fiqh_revision_sources(source_id);
CREATE TABLE fiqh_introductions (
    id TEXT PRIMARY KEY, body TEXT NOT NULL CHECK(json_valid(body))
);
CREATE TABLE fiqh_settings (
    key TEXT PRIMARY KEY, body TEXT NOT NULL CHECK(json_valid(body))
);
CREATE TABLE fiqh_events (
    id INTEGER PRIMARY KEY, issue_id TEXT NOT NULL, revision INTEGER NOT NULL,
    action TEXT NOT NULL, actor TEXT NOT NULL, at INTEGER NOT NULL,
    FOREIGN KEY(issue_id, revision) REFERENCES fiqh_revisions(issue_id, revision)
);
CREATE TRIGGER fiqh_revision_no_update BEFORE UPDATE ON fiqh_revisions
BEGIN SELECT RAISE(ABORT, 'immutable fiqh revision'); END;
CREATE TRIGGER fiqh_revision_no_delete BEFORE DELETE ON fiqh_revisions
BEGIN SELECT RAISE(ABORT, 'immutable fiqh revision'); END;
CREATE TRIGGER fiqh_event_no_update BEFORE UPDATE ON fiqh_events
BEGIN SELECT RAISE(ABORT, 'immutable fiqh event'); END;
CREATE TRIGGER fiqh_event_no_delete BEFORE DELETE ON fiqh_events
BEGIN SELECT RAISE(ABORT, 'immutable fiqh event'); END;
SQL);
        $now = time();
        $category = $db->prepare('INSERT INTO fiqh_categories VALUES (?, ?, ?, ?)');
        foreach ($seed['categories'] as $row) {
            $category->execute([$row['id'], $row['parentId'] ?? null, fiqhJson($row), $now]);
        }
        $source = $db->prepare('INSERT INTO fiqh_sources VALUES (?, ?, ?)');
        foreach ($seed['sources'] ?? [] as $row) {
            if (!fiqhStableId($row['id'] ?? null) || !fiqhBilingual($row['title'] ?? null)
                || ($row['status'] ?? null) !== 'placeholder') {
                throw new InvalidArgumentException('Invalid bibliographic placeholder');
            }
            $source->execute([$row['id'], fiqhJson($row), $now]);
        }
        $intro = $db->prepare('INSERT INTO fiqh_introductions VALUES (?, ?)');
        foreach ($seed['introductions'] ?? [] as $row) {
            if (!fiqhStableId($row['id'] ?? null) || ($row['status'] ?? null) !== 'draft') {
                throw new InvalidArgumentException('Invalid introduction placeholder');
            }
            $intro->execute([$row['id'], fiqhJson($row)]);
        }
        if (!fiqhBilingual($seed['disclaimer'] ?? null)) {
            throw new InvalidArgumentException('Invalid disclaimer');
        }
        $db->prepare('INSERT INTO fiqh_settings VALUES (?, ?)')->execute(['disclaimer', fiqhJson($seed['disclaimer'])]);
        $db->prepare('INSERT INTO fiqh_migrations VALUES (1, ?)')->execute([$now]);
    });
}

/** All link identifiers must be explicit, distinct and valid. */
function fiqhIds(mixed $value): array
{
    if (!is_array($value) || !array_is_list($value)) {
        throw new InvalidArgumentException('Expected a list of identifiers');
    }
    foreach ($value as $id) {
        if (!fiqhStableId($id)) {
            throw new InvalidArgumentException('Invalid linked identifier');
        }
    }
    if (count(array_unique($value)) !== count($value)) {
        throw new InvalidArgumentException('Duplicate linked identifier');
    }
    return $value;
}

/** Collect all source IDs from supported citation structures, including alternatives. */
function fiqhCollectSources(array $data): array
{
    $ids = [];
    foreach ($data as $key => $value) {
        if ($key === 'sourceId') {
            if (!fiqhStableId($value)) {
                throw new InvalidArgumentException('Invalid source identifier');
            }
            $ids[] = $value;
        } elseif ($key === 'sourceIds') {
            $ids = array_merge($ids, fiqhIds($value));
        } elseif (is_array($value)) {
            $ids = array_merge($ids, fiqhCollectSources($value));
        }
    }
    $ids = array_values(array_unique($ids));
    sort($ids, SORT_STRING);
    return $ids;
}

function fiqhRevisionHashValid(array $revision): bool
{
    return is_string($revision['body'] ?? null)&&is_string($revision['source_snapshot'] ?? null)
        &&is_string($revision['content_hash'] ?? null)
        &&hash_equals($revision['content_hash'],hash('sha256',fiqhJson([$revision['body'],$revision['source_snapshot']])));
}

function fiqhLatestRevision(PDO $db, string $id): ?array
{
    $query = $db->prepare('SELECT r.* FROM fiqh_revisions r WHERE issue_id = ? ORDER BY revision DESC LIMIT 1');
    $query->execute([$id]);
    $row = $query->fetch(PDO::FETCH_ASSOC);
    return $row === false ? null : $row;
}

/** Draft-only operation. Caller must supply authenticated actor and enforce permissions.
 * expectedRevision=0 creates only; updates require the exact current revision.
 * No review metadata is accepted from imports. No issue is published here.
 */
function fiqhSaveDraft(PDO $db, array $body, int $expectedRevision, string $actor): array
{
    return fiqhTransaction($db, fn () => fiqhSaveDraftLocked($db, $body, $expectedRevision, $actor));
}

/** Internal transaction primitive; must be called under fiqhTransaction. */
function fiqhSaveDraftLocked(PDO $db, array $body, int $expectedRevision, string $actor): array
{
    $allowed = ['id', 'number', 'slug', 'categoryId', 'subcategoryId', 'relatedCategoryIds',
        'relatedIssueIds', 'title', 'summary', 'introduction', 'scope', 'keywords', 'displayOrder',
        'difficulty', 'positions', 'evidence', 'agreements', 'disagreements', 'reasonsForDifferences',
        'scholarlySummary', 'practicalExamples', 'importantNotes', 'terminology'];
    if (array_diff(array_keys($body), $allowed) !== [] || trim($actor) === '' || $expectedRevision < 0) {
        throw new InvalidArgumentException('Invalid draft fields or revision');
    }
    foreach (['id', 'slug', 'categoryId'] as $field) {
        if (!fiqhStableId($body[$field] ?? null)) {
            throw new InvalidArgumentException('Invalid ' . $field);
        }
    }
    if (!is_string($body['number'] ?? null) || !preg_match('/^FIQH-[0-9]{3,}$/D', $body['number'])
        || !fiqhBilingual($body['title'] ?? null)) {
        throw new InvalidArgumentException('Issue number and bilingual title are required');
    }
    $shape = fiqhShapeErrors($body);
    if ($shape !== []) throw new InvalidArgumentException('Invalid issue fields: '.implode(', ', $shape));
    if (strlen(fiqhJson($body)) > 524288) throw new InvalidArgumentException('Issue exceeds 512 KiB');
    $id = $body['id'];
    $category = $body['categoryId'];
    $sub = $body['subcategoryId'] ?? null;
    if ($sub !== null) {
        if (!fiqhStableId($sub)) {
            throw new InvalidArgumentException('Invalid subcategory');
        }
        $query = $db->prepare('SELECT parent_id FROM fiqh_categories WHERE id = ?');
        $query->execute([$sub]);
        if ($query->fetchColumn() !== $category) {
            throw new InvalidArgumentException('Subcategory must belong to the primary category');
        }
    }
    $categories = fiqhIds($body['relatedCategoryIds'] ?? []);
    $related = fiqhIds($body['relatedIssueIds'] ?? []);
    if (in_array($id, $related, true)) {
        throw new InvalidArgumentException('An issue cannot reference itself');
    }
    $old = fiqhLatestRevision($db, $id);
    $version = $old === null ? 0 : (int) $old['revision'];
    if ($version !== $expectedRevision) {
        throw new RuntimeException('Fiqh revision conflict');
    }
    if ($old !== null) {
        $identity = json_decode($old['body'], true, 64, JSON_THROW_ON_ERROR);
        if ($identity['number'] !== $body['number'] || $identity['slug'] !== $body['slug']) {
            throw new InvalidArgumentException('Stable issue identity cannot change');
        }
    }
    $sourceIds = fiqhCollectSources($body);
    $snapshot = [];
    $sourceQuery = $db->prepare('SELECT body FROM fiqh_sources WHERE id = ?');
    foreach ($sourceIds as $sourceId) {
        $sourceQuery->execute([$sourceId]);
        $source = $sourceQuery->fetchColumn();
        if ($source === false) {
            throw new InvalidArgumentException('Unknown source: ' . $sourceId);
        }
        $snapshot[$sourceId] = json_decode($source, true, 64, JSON_THROW_ON_ERROR);
    }
    $json = fiqhJson(fiqhCanonical($body));
    $snapshotJson = fiqhJson(fiqhCanonical($snapshot));
    $hash = hash('sha256', fiqhJson([$json, $snapshotJson]));
    if ($old !== null && hash_equals($old['content_hash'], $hash)) {
        return ['id' => $id, 'revision' => $version, 'changed' => false];
    }
    $now = time();
    if ($old === null) {
        $db->prepare('INSERT INTO fiqh_issues VALUES (?, ?, ?, ?)')->execute([$id, $body['number'], $body['slug'], $now]);
    }
    $next = $version + 1;
    $db->prepare('INSERT INTO fiqh_revisions VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)')
        ->execute([$id, $next, $category, $sub, $json, $snapshotJson, $hash, $now, $actor]);
    foreach ([
        ['INSERT INTO fiqh_revision_categories VALUES (?, ?, ?)', $categories],
        ['INSERT INTO fiqh_revision_related VALUES (?, ?, ?)', $related],
        ['INSERT INTO fiqh_revision_sources VALUES (?, ?, ?)', $sourceIds],
    ] as [$sql, $ids]) {
        $insert = $db->prepare($sql);
        foreach ($ids as $linked) {
            $insert->execute([$id, $next, $linked]);
        }
    }
    $db->prepare('INSERT INTO fiqh_events (issue_id, revision, action, actor, at) VALUES (?, ?, ?, ?, ?)')
        ->execute([$id, $next, 'draft_saved', $actor, $now]);
    return ['id' => $id, 'revision' => $next, 'changed' => true];
}
