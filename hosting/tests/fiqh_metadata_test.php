<?php
declare(strict_types=1);
require __DIR__ . '/../admin/fiqh-metadata.php';

function fmCheck(bool $condition, string $message): void {
    if (!$condition) throw new RuntimeException($message);
}
function fmReject(callable $work): void {
    try { $work(); } catch (Exception $error) { return; }
    throw new RuntimeException('Expected rejection');
}

$db = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$seed = json_decode(file_get_contents(__DIR__ . '/../../docs/content/fiqh/seed.json'), true, 64, JSON_THROW_ON_ERROR);
fiqhMigration($db, $seed);
fiqhMetadataMigration($db);
fiqhMetadataMigration($db);
$categories = fiqhListMetadata($db, 'category');
fmCheck(count($categories) === 11 && $categories[0]['record']['id'] === 'taharah', 'ordered categories');
$child = array_replace($categories[0]['record'], ['id' => 'synthetic-child', 'parentId' => 'taharah',
    'plannedIssueCount' => 0, 'title' => ['ar' => 'اختبار', 'en' => 'Synthetic test']]);
$created = fiqhSaveMetadata($db, 'category', $child, null, 'test');
fmReject(fn () => fiqhSaveMetadata($db, 'category', $child, null, 'test'));
$hidden = array_replace($child, ['visible' => false, 'order' => 99]);
$changed = fiqhSaveMetadata($db, 'category', $hidden, $created['editToken'], 'test');
fmCheck($changed['changed'] && $changed['editToken'] !== $created['editToken'], 'hide/reorder');
fmReject(fn () => fiqhSaveMetadata($db, 'category', $child, $created['editToken'], 'test'));
fmCheck(!fiqhSaveMetadata($db, 'category', $hidden, $changed['editToken'], 'test')['changed'], 'idempotent metadata');
fmReject(fn () => fiqhSaveMetadata($db, 'category', array_replace($categories[0]['record'],
    ['parentId' => 'synthetic-child']), $categories[0]['editToken'], 'test'));
fmReject(fn () => fiqhSaveMetadata($db, 'category', array_replace($hidden,
    ['parentId' => 'missing']), $changed['editToken'], 'test'));
fmReject(fn () => fiqhSaveMetadata($db, 'category', array_replace($hidden,
    ['status' => 'published']), $changed['editToken'], 'test'));
$sources = fiqhListMetadata($db, 'source');
$source = $sources[0]['record'];
$updated = fiqhSaveMetadata($db, 'source', array_replace($source, ['editorialNotes' => 'Synthetic test']),
    $sources[0]['editToken'], 'test');
fmCheck($updated['changed'], 'source edit');
fmReject(fn () => fiqhSaveMetadata($db, 'source', array_replace($source, ['url' => 'javascript:alert(1)']),
    $updated['editToken'], 'test'));
$issue = ['id' => 'synthetic', 'number' => 'FIQH-999', 'slug' => 'synthetic', 'categoryId' => 'taharah',
    'subcategoryId' => 'synthetic-child', 'relatedCategoryIds' => ['salah'], 'title' => ['ar' => 'اختبار', 'en' => 'Synthetic test']];
fiqhSaveDraft($db, $issue, 0, 'test');
fmReject(fn () => fiqhSaveMetadata($db, 'category', array_replace($hidden, ['parentId' => 'salah']), $changed['editToken'], 'test'));
fmCheck(count(fiqhListDrafts($db, 'salah')) === 1, 'related category filter');
fmCheck(count(fiqhListDrafts($db, 'synthetic-child')) === 1, 'subcategory filter');
fmCheck(fiqhListDrafts($db, 'zakat') === [], 'unrelated category filter');
fmCheck(fiqhListDrafts($db)[0]['completenessErrors'] !== [], 'incomplete draft indicator');
fmCheck((int) $db->query('SELECT COUNT(*) FROM fiqh_metadata_events')->fetchColumn() === 3, 'audit and no-op history');
fmReject(fn () => $db->exec('DELETE FROM fiqh_metadata_events'));
echo "Fiqh metadata checks passed\n";
