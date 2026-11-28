<?php
declare(strict_types=1);
require __DIR__.'/../admin/fiqh-import.php';
function fiCheck(bool $ok,string $message):void { if(!$ok) throw new RuntimeException($message); }
function fiReject(callable $work):void { try{$work();}catch(Exception){return;}throw new RuntimeException('Expected rejection'); }
$db=new PDO('sqlite::memory:',null,null,[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
$seed=json_decode(file_get_contents(__DIR__.'/../../docs/content/fiqh/seed.json'),true,64,JSON_THROW_ON_ERROR);
fiqhMigration($db,$seed);
$issue=['id'=>'synthetic-a','number'=>'FIQH-901','slug'=>'synthetic-a','categoryId'=>'taharah','title'=>['ar'=>'اختبار فقط','en'=>'Synthetic only']];
$row=['operation'=>'create','expectedRevision'=>0,'issue'=>$issue];
$payload=['schemaVersion'=>1,'issues'=>[$row]];
$preview=fiqhImportRun($db,$payload,'user:2');
fiCheck($preview['preview']&&!$preview['saved'],'preview status');
fiCheck(fiqhLatestRevision($db,'synthetic-a')===null,'preview rollback');
fiReject(fn()=>fiqhImportRun($db,$payload,'user:3',$preview['confirmation']));
fiReject(fn()=>fiqhImportRun($db,$payload,'user:2',str_repeat('0',64)));
fiCheck(fiqhLatestRevision($db,'synthetic-a')===null,'invalid confirmation rollback');
fiCheck(fiqhImportRun($db,$payload,'user:2',$preview['confirmation'])['saved'],'commit');
fiReject(fn()=>fiqhImportRun($db,$payload,'user:2',$preview['confirmation']));
$export=fiqhExportDrafts($db);
fiCheck($export['issues'][0]['expectedRevision']===1,'export revision');
$update=$export;
$update['issues'][0]['issue']['title']['en']='Edited synthetic only';
$p=fiqhImportRun($db,$update,'user:2');
fiCheck((int)fiqhLatestRevision($db,'synthetic-a')['revision']===1,'update preview rollback');
fiqhImportRun($db,$update,'user:2',$p['confirmation']);
fiCheck((int)fiqhLatestRevision($db,'synthetic-a')['revision']===2,'update commit');
$bad=$row;
$bad['issue']=array_replace($issue,['id'=>'synthetic-b','number'=>'FIQH-902','slug'=>'synthetic-b']);
$bad2=$bad;
$bad2['issue']=array_replace($bad['issue'],['id'=>'synthetic-c','number'=>'FIQH-903','slug'=>'synthetic-c','categoryId'=>'missing']);
fiReject(fn()=>fiqhImportRun($db,['schemaVersion'=>1,'issues'=>[$bad,$bad2]],'user:2'));
fiCheck(fiqhLatestRevision($db,'synthetic-b')===null,'whole batch rollback');
fiReject(fn()=>fiqhImportRun($db,['schemaVersion'=>1,'issues'=>[$bad,$bad]],'user:2'));
$bad['issue']['review']=['approved'=>true];
fiReject(fn()=>fiqhImportRun($db,['schemaVersion'=>1,'issues'=>[$bad]],'user:2'));
fiCheck((int)$db->query('SELECT COUNT(*) FROM fiqh_events')->fetchColumn()===2,'no preview audit residue');
echo "Fiqh import checks passed\n";
