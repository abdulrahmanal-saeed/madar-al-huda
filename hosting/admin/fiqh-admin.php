<?php
declare(strict_types=1);
require_once __DIR__ . '/fiqh-review.php';
require_once __DIR__ . '/fiqh-import.php';

function fiqhAdminReady(PDO $db): bool
{
    $table = $db->query("SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'fiqh_migrations'")->fetchColumn();
    return $table !== false && (bool) $db->query('SELECT 1 FROM fiqh_migrations WHERE version = 2')->fetchColumn();
}

function fiqhAdminJson(string $raw): array
{
    if (strlen($raw) > 524288) {
        throw new InvalidArgumentException('JSON exceeds 512 KiB');
    }
    try {
        $value = json_decode($raw, true, 64, JSON_THROW_ON_ERROR);
    } catch (JsonException) {
        throw new InvalidArgumentException('راجع صيغة JSON.');
    }
    if (!is_array($value)) {
        throw new InvalidArgumentException('JSON must be an object or array');
    }
    return $value;
}

function fiqhAdminSections(): array
{
    return [
        'evidence' => 'الأدلة / Evidence',
        'agreements' => 'مواضع الاتفاق / Agreement',
        'disagreements' => 'مواضع الاختلاف / Disagreement',
        'reasonsForDifferences' => 'أسباب الاختلاف / Reasons',
        'practicalExamples' => 'الأمثلة التطبيقية / Examples',
        'importantNotes' => 'التنبيهات والاستثناءات / Notes',
        'terminology' => 'المصطلحات / Terminology',
    ];
}

function fiqhAdminIssueFromPost(array $post): array
{
    $read = static function (string $key) use ($post): string {
        $value = $post[$key] ?? '';
        if (!is_string($value)) throw new InvalidArgumentException('Invalid field: ' . $key);
        return trim($value);
    };
    $body = [];
    foreach (['id', 'number', 'slug', 'categoryId'] as $key) $body[$key] = $read($key);
    $body['subcategoryId'] = $read('subcategoryId') ?: null;
    foreach (['title', 'summary', 'introduction', 'scope', 'scholarlySummary'] as $key) {
        $body[$key] = ['ar' => $read($key . '_ar'), 'en' => $read($key . '_en')];
    }
    foreach (['relatedCategoryIds', 'relatedIssueIds', 'keywords'] as $key) {
        $body[$key] = fiqhAdminJson($read($key) ?: '[]');
    }
    $order = filter_var($read('displayOrder'), FILTER_VALIDATE_INT, ['options' => ['min_range' => 0]]);
    if ($order === false) throw new InvalidArgumentException('Invalid display order');
    $body['displayOrder'] = $order;
    $body['difficulty'] = $read('difficulty');
    if (!in_array($body['difficulty'], ['', 'beginner', 'intermediate', 'advanced'], true)) {
        throw new InvalidArgumentException('Invalid difficulty');
    }
    $body['positions'] = [];
    foreach (FIQH_SCHOOLS as $school) {
        $position = fiqhAdminJson($read($school . '_details') ?: '{}');
        $allowed = ['conditions', 'exceptions', 'alternativeOpinions', 'classification', 'evidenceIds', 'sourceReferences'];
        if (array_diff(array_keys($position), $allowed) !== []) {
            throw new InvalidArgumentException('Invalid position details: ' . $school);
        }
        foreach (['ruling', 'explanation', 'reasoning'] as $key) {
            $position[$key] = ['ar' => $read($school . '_' . $key . '_ar'), 'en' => $read($school . '_' . $key . '_en')];
        }
        $body['positions'][$school] = $position;
    }
    foreach (fiqhAdminSections() as $key => $label) {
        $body[$key] = fiqhAdminJson($read($key) ?: '[]');
    }
    return $body;
}

/** Only invoked after existing session, CSRF and role validation in index.php. */
function fiqhAdminChange(PDO $db, array $user, string $action): string
{
    if (!fiqhAdminReady($db) || !in_array($user['role'] ?? '', ['owner', 'editor', 'reviewer'], true)
        || !is_int($user['id'] ?? null) && !ctype_digit((string) ($user['id'] ?? ''))) {
        throw new InvalidArgumentException('Fiqh staging is unavailable or access denied');
    }
    $actor = 'user:' . (int) $user['id'];
    if ($action === 'fiqh_import_commit') {
        if (field('fiqh_confirm') !== 'yes') throw new InvalidArgumentException('Confirm the preview first');
        $payload=fiqhAdminJson(field('import_payload'));
        $token=field('import_confirmation');
        if ($token==='') throw new InvalidArgumentException('Preview token required');
        $result=fiqhImportRun($db,$payload,$actor,$token);
        return 'حُفظت الدفعة في المسودات فقط: ' . count($result['results']);
    }
    if ($action === 'fiqh_draft_save') {
        $body = fiqhAdminIssueFromPost($_POST);
        $result = fiqhSaveDraft($db, $body, integer(field('fiqh_revision'), 0, PHP_INT_MAX), $actor);
        return 'حُفظت المسودة فقط: ' . $result['id'] . ' · v' . $result['revision'];
    }
    if ($action === 'fiqh_metadata_save') {
        $kind = field('kind');
        $row = fiqhAdminJson(field('record'));
        $result = fiqhSaveMetadata($db, $kind, $row, field('edit_token') ?: null, $actor);
        return 'حُفظت بيانات المسودة: ' . $result['id'];
    }
    if (in_array($action,['fiqh_publish','fiqh_archive'],true)) {
        if (!fiqhDirectReady($db)) throw new InvalidArgumentException('يلزم اكتمال تحديث قاعدة البيانات.');
        if (field('fiqh_confirm') !== 'yes') throw new InvalidArgumentException('أكد الإجراء أولًا.');
        $uid=(int)$user['id'];
        if ($action==='fiqh_publish') {
            fiqhPublishDraft($db,$uid,field('id'),integer(field('fiqh_revision'),1,PHP_INT_MAX),
                integer(field('fiqh_review_event'),0,PHP_INT_MAX));
            return 'تم نشر المسألة على التطبيق والموقع.';
        }
        fiqhArchivePublication($db,$uid,field('id'),integer(field('fiqh_revision'),1,PHP_INT_MAX),field('notes'));
        return 'تم سحب المسألة من النشر مع الاحتفاظ بالمسودة والسجل.';
    }
    throw new InvalidArgumentException('Unknown draft action');
}

function fiqhAdminStats(PDO $db): array
{
    $planned = 0;
    foreach (fiqhListMetadata($db, 'category') as $row) {
        if (($row['record']['parentId'] ?? null) === null) $planned += $row['record']['plannedIssueCount'];
    }
    $total = (int) $db->query('SELECT COUNT(*) FROM fiqh_issues')->fetchColumn();
    $stats = ['planned' => $planned, 'created' => $total, 'draft' => $total, 'published' => 0];
    if (fiqhReviewReady($db)) {
        $stats['published']=(int)$db->query('SELECT COUNT(*) FROM fiqh_published')->fetchColumn();
        $stats['draft']=(int)$db->query("SELECT COUNT(*) FROM fiqh_issues i
            WHERE NOT EXISTS (SELECT 1 FROM fiqh_published p WHERE p.issue_id=i.id
            AND p.revision=(SELECT MAX(r.revision) FROM fiqh_revisions r WHERE r.issue_id=i.id))")->fetchColumn();
    }
    return $stats;
}

/** Preserve raw submitted strings, including invalid JSON, without changing the edit lease. */
function fiqhEditorValue(array $posted, string $key, string|int $fallback = ''): string
{
    return is_string($posted[$key] ?? null) ? $posted[$key] : (string) $fallback;
}

/** Field-level changes across immutable revision bodies and source snapshots. */
function fiqhRevisionDiff(mixed $before, mixed $after, string $path = ''): array
{
    if ($before === $after) return [];
    if (is_array($before) && is_array($after) && !array_is_list($before) && !array_is_list($after)) {
        $changes = [];
        $keys = array_unique(array_merge(array_keys($before), array_keys($after)));
        sort($keys, SORT_STRING);
        foreach ($keys as $key) {
            $child = $path === '' ? (string) $key : $path . '.' . $key;
            if (!array_key_exists($key, $before) || !array_key_exists($key, $after)) {
                $changes[] = ['path' => $child, 'before' => $before[$key] ?? null, 'after' => $after[$key] ?? null,
                    'kind' => array_key_exists($key, $before) ? 'removed' : 'added'];
            } else {
                $changes = array_merge($changes, fiqhRevisionDiff($before[$key], $after[$key], $child));
            }
        }
        return $changes;
    }
    return [['path' => $path, 'before' => $before, 'after' => $after, 'kind' => 'changed']];
}

function fiqhGetRevision(PDO $db, string $id, int $revision): ?array
{
    if (!fiqhStableId($id) || $revision < 1) return null;
    $stmt = $db->prepare('SELECT * FROM fiqh_revisions WHERE issue_id = ? AND revision = ?');
    $stmt->execute([$id, $revision]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    return $row === false ? null : $row;
}

function fiqhAdminImportPreview(PDO $db,array $user,string $raw,string $format):array
{
    if (!fiqhAdminReady($db) || !in_array($user['role'] ?? '', ['owner','editor','reviewer'],true))
        throw new InvalidArgumentException('Fiqh staging is unavailable or access denied');
    if (!in_array($format,['json','csv'],true)) throw new InvalidArgumentException('Invalid format');
    if (strlen($raw)>524288) throw new InvalidArgumentException('Maximum admin input: 512 KiB');
    $payload=$format==='csv'?fiqhParseMetadataCsv($raw):fiqhAdminJson($raw);
    return ['payload'=>$payload,'result'=>fiqhImportRun($db,$payload,'user:'.(int)$user['id'])];
}


/** Autosave is explicitly enabled in an existing editor, never a creation or
 * review action. The same immutable revision lease and validation apply. */
function fiqhAdminAutosave(PDO $db,array $user,array $post):array
{
    if (!fiqhAdminReady($db)||!in_array($user['role'] ?? '', ['owner','editor','reviewer'],true)
        ||(int)($user['id'] ?? 0)<1||($post['autosave_enabled'] ?? null)!=='yes')
        throw new InvalidArgumentException('Autosave not authorized');
    $raw=$post['fiqh_revision'] ?? null;
    $revision=is_string($raw)?filter_var($raw,FILTER_VALIDATE_INT,['options'=>['min_range'=>1]]):false;
    if ($revision===false) throw new InvalidArgumentException('Save the initial draft manually');
    $body=fiqhAdminIssueFromPost($post);
    return fiqhSaveDraft($db,$body,$revision,'user:'.(int)$user['id']);
}
