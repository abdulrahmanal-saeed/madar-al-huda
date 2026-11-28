<?php
declare(strict_types=1);
require __DIR__ . '/../admin/fiqh-storage.php';

function fsAssert(bool $condition, string $message): void
{
    if (!$condition) {
        throw new RuntimeException($message);
    }
}
function fsReject(callable $work): void
{
    try {
        $work();
    } catch (Exception $e) {
        return;
    }
    throw new RuntimeException('Expected operation to fail');
}
$db = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$db->exec('CREATE TABLE library (id INTEGER PRIMARY KEY, draft TEXT, revision INTEGER, published TEXT)');
$db->exec("INSERT INTO library VALUES (1, 'legacy draft', 7, 'legacy published')");
$seed = json_decode(file_get_contents(__DIR__ . '/../../docs/content/fiqh/seed.json'), true, 64, JSON_THROW_ON_ERROR);
fiqhMigration($db, $seed);
fiqhMigration($db, $seed);
fsAssert((int) $db->query('SELECT COUNT(*) FROM fiqh_categories')->fetchColumn() === 11, 'category migration');
fsAssert((int) $db->query('SELECT COUNT(*) FROM fiqh_sources')->fetchColumn() === 17, 'source migration');
fsAssert($db->query('SELECT published FROM library')->fetchColumn() === 'legacy published', 'legacy untouched');
$draft = ['id' => 'synthetic', 'number' => 'FIQH-999', 'slug' => 'synthetic',
    'categoryId' => 'taharah', 'title' => ['ar' => 'اختبار اصطناعي', 'en' => 'Synthetic test only'],
    'positions' => ['hanafi' => ['sourceReferences' => [['sourceId' => 'badai']]]]];
$first = fiqhSaveDraft($db, $draft, 0, 'test');
fsAssert($first['revision'] === 1 && $first['changed'], 'create');
fsAssert(fiqhSaveDraft($db, array_reverse($draft, true), 1, 'test')['changed'] === false, 'canonical idempotence');
fsReject(fn () => fiqhSaveDraft($db, $draft, 0, 'test'));
$old = fiqhLatestRevision($db, 'synthetic');
$db->exec("UPDATE fiqh_sources SET body = '{\"title\":\"changed\"}' WHERE id = 'badai'");
$second = fiqhSaveDraft($db, $draft, 1, 'test');
fsAssert($second['revision'] === 2, 'source change creates revision');
fsAssert($old['source_snapshot'] !== fiqhLatestRevision($db, 'synthetic')['source_snapshot'], 'frozen source');
fsAssert($old['source_snapshot'] === $db->query("SELECT source_snapshot FROM fiqh_revisions WHERE revision = 1")->fetchColumn(), 'old snapshot retained');
fsReject(fn () => $db->exec("UPDATE fiqh_revisions SET body = '{}' WHERE revision = 1"));
fsReject(fn () => $db->exec('DELETE FROM fiqh_revisions WHERE revision = 1'));
fsReject(fn () => fiqhSaveDraft($db, $draft + ['review' => ['approved' => true]], 2, 'test'));
$bad = $draft;
$bad['relatedCategoryIds'] = ['does-not-exist'];
fsReject(fn () => fiqhSaveDraft($db, $bad, 2, 'test'));
fsAssert((int) $db->query('SELECT COUNT(*) FROM fiqh_revisions')->fetchColumn() === 2, 'rollback');
$other = array_replace($draft, ['id' => 'other', 'slug' => 'other']);
fsReject(fn () => fiqhSaveDraft($db, $other, 0, 'test'));
fsAssert((int) $db->query('SELECT COUNT(*) FROM fiqh_issues')->fetchColumn() === 1, 'duplicate number rejected');
fsAssert((int) $db->query('SELECT COUNT(*) FROM fiqh_events')->fetchColumn() === 2, 'audit history');
fsAssert($db->query('PRAGMA foreign_key_check')->fetchAll() === [], 'referential integrity');
$invalid = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$badSeed = $seed;
$badSeed['sources'][] = $badSeed['sources'][0];
fsReject(fn () => fiqhMigration($invalid, $badSeed));
fsAssert((int) $invalid->query("SELECT COUNT(*) FROM sqlite_master WHERE name LIKE 'fiqh_%'")->fetchColumn() === 0, 'migration rollback');
echo "Fiqh storage checks passed\n";
