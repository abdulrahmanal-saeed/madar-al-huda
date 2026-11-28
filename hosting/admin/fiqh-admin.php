<?php
declare(strict_types=1);
require_once __DIR__ . '/fiqh-metadata.php';

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
    throw new InvalidArgumentException('Unknown draft action');
}

function fiqhAdminStats(PDO $db): array
{
    $planned = 0;
    foreach (fiqhListMetadata($db, 'category') as $row) {
        if (($row['record']['parentId'] ?? null) === null) $planned += $row['record']['plannedIssueCount'];
    }
    $total = (int) $db->query('SELECT COUNT(*) FROM fiqh_issues')->fetchColumn();
    return ['planned' => $planned, 'created' => $total, 'draft' => $total, 'published' => 0];
}
