<?php
declare(strict_types=1);

require_once __DIR__ . '/fiqh-storage.php';

/** Explicit additive migration after fiqhMigration; not wired to production. */
function fiqhMetadataMigration(PDO $db, bool $withinTransaction = false): void
{
    $work = function () use ($db): void {
        if (!$db->query('SELECT 1 FROM fiqh_migrations WHERE version = 1')->fetchColumn()) {
            throw new RuntimeException('Apply fiqh schema version 1 first');
        }
        if ($db->query('SELECT 1 FROM fiqh_migrations WHERE version = 2')->fetchColumn()) {
            return;
        }
        $db->exec(<<<'SQL'
CREATE TABLE fiqh_metadata_events (
    id INTEGER PRIMARY KEY, kind TEXT NOT NULL, record_id TEXT NOT NULL,
    previous_body TEXT, next_body TEXT NOT NULL, actor TEXT NOT NULL, at INTEGER NOT NULL
);
CREATE INDEX fiqh_metadata_history ON fiqh_metadata_events(kind, record_id, id);
CREATE TRIGGER fiqh_metadata_event_no_update BEFORE UPDATE ON fiqh_metadata_events
BEGIN SELECT RAISE(ABORT, 'immutable metadata event'); END;
CREATE TRIGGER fiqh_metadata_event_no_delete BEFORE DELETE ON fiqh_metadata_events
BEGIN SELECT RAISE(ABORT, 'immutable metadata event'); END;
SQL);
        $db->prepare('INSERT INTO fiqh_migrations VALUES (2, ?)')->execute([time()]);
    };
    if ($withinTransaction) $work();
    else fiqhTransaction($db, $work);
}

/** Opaque edit token based on stored bytes; null is create-only. */
function fiqhMetadataToken(string $body): string
{
    return hash('sha256', $body);
}

function fiqhMetadataTable(string $kind): string
{
    return match ($kind) {
        'category' => 'fiqh_categories',
        'source' => 'fiqh_sources',
        default => throw new InvalidArgumentException('Unknown metadata kind'),
    };
}

function fiqhListMetadata(PDO $db, string $kind): array
{
    $table = fiqhMetadataTable($kind);
    $rows = [];
    foreach ($db->query("SELECT body FROM $table ORDER BY id")->fetchAll(PDO::FETCH_COLUMN) as $body) {
        $rows[] = ['record' => json_decode($body, true, 64, JSON_THROW_ON_ERROR),
            'editToken' => fiqhMetadataToken($body)];
    }
    if ($kind === 'category') {
        usort($rows, fn ($a, $b) => [$a['record']['order'], $a['record']['id']] <=> [$b['record']['order'], $b['record']['id']]);
    }
    return $rows;
}

function fiqhOptionalBilingual(mixed $value): bool
{
    return is_array($value) && count($value) === 2
        && is_string($value['ar'] ?? null) && is_string($value['en'] ?? null);
}

function fiqhValidateCategory(array $row): void
{
    $allowed = ['id', 'title', 'description', 'icon', 'order', 'parentId', 'plannedIssueCount', 'visible', 'status'];
    if (array_diff(array_keys($row), $allowed) !== []
        || !fiqhStableId($row['id'] ?? null) || !fiqhBilingual($row['title'] ?? null)
        || !fiqhOptionalBilingual($row['description'] ?? null)
        || !fiqhStableId($row['icon'] ?? null) || !is_int($row['order'] ?? null) || $row['order'] < 0
        || !is_int($row['plannedIssueCount'] ?? null) || $row['plannedIssueCount'] < 0
        || !is_bool($row['visible'] ?? null) || ($row['status'] ?? null) !== 'draft'
        || (($row['parentId'] ?? null) !== null && !fiqhStableId($row['parentId']))) {
        throw new InvalidArgumentException('Invalid draft category');
    }
}

function fiqhValidateSource(array $row): void
{
    $allowed = ['id', 'title', 'author', 'madhhab', 'sourceType', 'publisher', 'edition',
        'publicationYear', 'volume', 'pages', 'chapter', 'section', 'url', 'license', 'editorialNotes', 'status'];
    if (array_diff(array_keys($row), $allowed) !== []
        || !fiqhStableId($row['id'] ?? null) || !fiqhBilingual($row['title'] ?? null)
        || !fiqhOptionalBilingual($row['author'] ?? null)
        || !in_array($row['madhhab'] ?? null, [null, ...FIQH_SCHOOLS], true)
        || !in_array($row['sourceType'] ?? null, ['book', 'institution', 'article', 'collection', 'other'], true)
        || !in_array($row['status'] ?? null, ['placeholder', 'draft'], true)) {
        throw new InvalidArgumentException('Invalid draft source');
    }
    foreach (['publisher', 'edition', 'volume', 'pages', 'chapter', 'section', 'license', 'editorialNotes'] as $key) {
        if (isset($row[$key]) && !is_string($row[$key])) {
            throw new InvalidArgumentException('Invalid source field: ' . $key);
        }
    }
    if (isset($row['publicationYear']) && !is_string($row['publicationYear']) && !is_int($row['publicationYear'])) {
        throw new InvalidArgumentException('Invalid publication year');
    }
    if (isset($row['url']) && (!is_string($row['url'])
        || filter_var($row['url'], FILTER_VALIDATE_URL) === false
        || !in_array(parse_url($row['url'], PHP_URL_SCHEME), ['https', 'http'], true))) {
        throw new InvalidArgumentException('Invalid source URL');
    }
}

/** Draft-only metadata write. The authenticated caller must enforce role permissions. */
function fiqhSaveMetadata(PDO $db, string $kind, array $row, ?string $expectedToken, string $actor): array
{
    return fiqhTransaction($db, function () use ($db, $kind, $row, $expectedToken, $actor): array {
        if (trim($actor) === '') {
            throw new InvalidArgumentException('Actor required');
        }
        $table = fiqhMetadataTable($kind);
        if ($kind === 'category') {
            fiqhValidateCategory($row);
        } else {
            fiqhValidateSource($row);
        }
        $id = $row['id'];
        $query = $db->prepare("SELECT body FROM $table WHERE id = ?");
        $query->execute([$id]);
        $old = $query->fetchColumn();
        if ($old === false ? $expectedToken !== null
            : ($expectedToken === null || !hash_equals(fiqhMetadataToken($old), $expectedToken))) {
            throw new RuntimeException('Fiqh metadata edit conflict');
        }
        $next = fiqhJson(fiqhCanonical($row));
        if ($old !== false && fiqhJson(fiqhCanonical(json_decode($old, true, 64, JSON_THROW_ON_ERROR))) === $next) {
            return ['id' => $id, 'editToken' => fiqhMetadataToken($old), 'changed' => false];
        }
        if ($kind === 'category') {
            $parents = [];
            foreach ($db->query('SELECT id, parent_id FROM fiqh_categories')->fetchAll(PDO::FETCH_ASSOC) as $category) {
                $parents[$category['id']] = $category['parent_id'];
            }
            $parent = $row['parentId'] ?? null;
            $parents[$id] = $parent;
            $visited = [$id => true];
            for ($node = $parent; $node !== null; $node = $parents[$node]) {
                if (!array_key_exists($node, $parents) || isset($visited[$node])) {
                    throw new InvalidArgumentException('Unknown parent or category cycle');
                }
                $visited[$node] = true;
            }
            // Existing immutable revisions must retain their original primary/subcategory relation.
            if ($old !== false && (json_decode($old, true, 64, JSON_THROW_ON_ERROR)['parentId'] ?? null) !== $parent) {
                $used = $db->prepare('SELECT 1 FROM fiqh_revisions WHERE category_id = ? OR subcategory_id = ? LIMIT 1');
                $used->execute([$id, $id]);
                if ($used->fetchColumn()) {
                    throw new InvalidArgumentException('Cannot reparent a category referenced by an immutable revision');
                }
            }
            $db->prepare('INSERT INTO fiqh_categories (id, parent_id, body, updated_at) VALUES (?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET parent_id = excluded.parent_id, body = excluded.body, updated_at = excluded.updated_at')
                ->execute([$id, $parent, $next, time()]);
        } else {
            $db->prepare('INSERT INTO fiqh_sources (id, body, updated_at) VALUES (?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET body = excluded.body, updated_at = excluded.updated_at')
                ->execute([$id, $next, time()]);
        }
        $db->prepare('INSERT INTO fiqh_metadata_events (kind, record_id, previous_body, next_body, actor, at) VALUES (?, ?, ?, ?, ?, ?)')
            ->execute([$kind, $id, $old === false ? null : $old, $next, $actor, time()]);
        return ['id' => $id, 'editToken' => fiqhMetadataToken($next), 'changed' => true];
    });
}

/** List latest canonical draft rows, never a public feed. Bounded pagination. */
function fiqhListDrafts(PDO $db, ?string $category = null, int $limit = 50, int $offset = 0): array
{
    if ($limit < 1 || $limit > 200 || $offset < 0 || ($category !== null && !fiqhStableId($category))) {
        throw new InvalidArgumentException('Invalid draft listing');
    }
    $sql = 'SELECT r.* FROM fiqh_revisions r WHERE r.revision =
        (SELECT MAX(rr.revision) FROM fiqh_revisions rr WHERE rr.issue_id = r.issue_id)';
    if ($category !== null) {
        $sql .= ' AND (r.category_id = :primary OR r.subcategory_id = :sub OR EXISTS (
            SELECT 1 FROM fiqh_revision_categories rc WHERE rc.issue_id = r.issue_id
            AND rc.revision = r.revision AND rc.category_id = :related))';
    }
    $sql .= ' ORDER BY r.issue_id LIMIT :lim OFFSET :off';
    $query = $db->prepare($sql);
    if ($category !== null) {
        foreach ([':primary', ':sub', ':related'] as $parameter) {
            $query->bindValue($parameter, $category);
        }
    }
    $query->bindValue(':lim', $limit, PDO::PARAM_INT);
    $query->bindValue(':off', $offset, PDO::PARAM_INT);
    $query->execute();
    return array_map(function ($row) {
        $body = json_decode($row['body'], true, 64, JSON_THROW_ON_ERROR);
        return ['issue' => $body, 'revision' => (int) $row['revision'], 'createdAt' => (int) $row['created_at'],
            'completenessErrors' => fiqhCompletenessErrors($body)];
    }, $query->fetchAll(PDO::FETCH_ASSOC));
}
