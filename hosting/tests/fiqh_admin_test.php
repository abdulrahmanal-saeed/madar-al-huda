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
faCheck(fiqhEditorValue(['evidence'=>'{invalid'], 'evidence', '[]') === '{invalid');
faCheck(fiqhEditorValue(['fiqh_revision'=>'1'], 'fiqh_revision', 2) === '1');
faCheck(fiqhEditorValue(['title_ar'=>['bad']], 'title_ar', 'fallback') === 'fallback');
$diff = fiqhRevisionDiff(['title'=>['ar'=>'a','en'=>'b']], ['title'=>['ar'=>'a','en'=>'c']]);
faCheck(count($diff) === 1 && $diff[0]['path'] === 'title.en' && $diff[0]['before'] === 'b');
faCheck(fiqhRevisionDiff(['a'=>1], ['a'=>1]) === []);
faCheck(fiqhRevisionDiff(['a'=>null], ['b'=>null])[0]['kind'] === 'removed');
faCheck(fiqhGetRevision($db, 'missing', 1) === null);
faReject(fn()=>fiqhAdminAutosave($db,['role'=>'editor','id'=>2],$post+['fiqh_revision'=>'0','autosave_enabled'=>'yes']));
faReject(fn()=>fiqhAdminAutosave($db,['role'=>'publisher','id'=>2],$post+['fiqh_revision'=>'1','autosave_enabled'=>'yes']));
fiqhSaveDraft($db,$body,0,'user:2');
$auto=$post+['fiqh_revision'=>'1','autosave_enabled'=>'yes','summary_ar'=>'اختبار','summary_en'=>'Synthetic change'];
faCheck(fiqhAdminAutosave($db,['role'=>'editor','id'=>2],$auto)['revision']===2);
try { fiqhAdminAutosave($db,['role'=>'editor','id'=>2],$auto); throw new LogicException('Stale autosave accepted'); }
catch (RuntimeException $error) { faCheck($error->getMessage()==='Fiqh revision conflict'); }
echo "Fiqh admin checks passed\n";
