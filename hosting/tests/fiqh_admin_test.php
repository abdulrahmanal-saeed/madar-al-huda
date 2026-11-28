<?php
declare(strict_types=1);
require __DIR__ . '/../admin/fiqh-admin.php';
function faCheck(bool $ok): void { if (!$ok) throw new RuntimeException('Assertion failed'); }
function faReject(callable $work): void { try { $work(); } catch (InvalidArgumentException) { return; } throw new RuntimeException('Expected rejection'); }
$db = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
faCheck(!fiqhAdminReady($db));
$seed = json_decode(file_get_contents(__DIR__ . '/../../docs/content/fiqh/seed.json'), true, 64, JSON_THROW_ON_ERROR);
fiqhMigration($db, $seed);
faCheck(!fiqhAdminReady($db));
fiqhMetadataMigration($db);
faCheck(fiqhAdminReady($db));
faCheck(fiqhAdminStats($db) === ['planned'=>200,'created'=>0,'draft'=>0,'published'=>0]);
$post = ['id'=>'synthetic','number'=>'FIQH-999','slug'=>'synthetic','categoryId'=>'taharah','title_ar'=>'اختبار','title_en'=>'Synthetic test','displayOrder'=>'0'];
$body = fiqhAdminIssueFromPost($post);
faCheck(count($body['positions']) === 4);
faCheck(!isset($body['review']) && !isset($body['status']));
faReject(fn()=>fiqhAdminIssueFromPost($post + ['hanafi_details'=>'{"review":"approved"}']));
faReject(fn()=>fiqhAdminIssueFromPost($post + ['evidence'=>'not JSON']));
faReject(fn()=>fiqhAdminChange($db, ['role'=>'publisher','id'=>1], 'fiqh_draft_save'));
faReject(fn()=>fiqhAdminChange($db, ['role'=>'owner','id'=>1], 'publish'));
echo "Fiqh admin checks passed\n";
