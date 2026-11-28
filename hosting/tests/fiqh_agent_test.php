<?php
declare(strict_types=1);
require __DIR__.'/../admin/agent.php';
function fagCheck(bool $ok,string $message):void { if(!$ok) throw new RuntimeException($message); }
function fagReject(callable $work):void { try{$work();}catch(AgentError|InvalidArgumentException){return;}throw new RuntimeException('Expected rejection'); }
$db=new PDO('sqlite::memory:',null,null,[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
$key=['id'=>5,'label'=>'synthetic'];
fagCheck(!fiqhAgentCall($db,$key,'fiqh_import_contract',[])['available'],'unmigrated');
fagReject(fn()=>fiqhAgentCall($db,$key,'fiqh_list_sources',[]));
$seed=json_decode(file_get_contents(__DIR__.'/../../docs/content/fiqh/seed.json'),true,64,JSON_THROW_ON_ERROR);
fiqhMigration($db,$seed);fiqhMetadataMigration($db);
fagCheck(count(fiqhAgentCall($db,$key,'fiqh_list_categories',[])['records'])===11,'categories');
fagCheck(count(fiqhAgentCall($db,$key,'fiqh_list_sources',[])['records'])===17,'sources');
$csv="id,number,slug,categoryId,title_ar,title_en\nsynthetic,FIQH-999,synthetic,taharah,اختبار,Synthetic";
$payload=fiqhParseMetadataCsv($csv);
$preview=fiqhAgentCall($db,$key,'fiqh_preview_import',['payload'=>$payload]);
fagCheck(!$preview['saved']&&!$preview['published'],'preview only');
$args=['payload'=>$payload,'confirmation'=>$preview['confirmation'],'ownerConfirmed'=>true];
fagReject(fn()=>fiqhAgentCall($db,['id'=>6],'fiqh_commit_import',$args));
fagReject(fn()=>fiqhAgentCall($db,$key,'fiqh_commit_import',array_replace($args,['ownerConfirmed'=>false])));
fagReject(fn()=>fiqhAgentCall($db,$key,'fiqh_commit_import',$args+['publish'=>true]));
fagCheck(fiqhAgentCall($db,$key,'fiqh_commit_import',$args)['saved'],'save');
fagCheck(fiqhAgentCall($db,$key,'fiqh_get_draft',['id'=>'synthetic'])['revision']===1,'get');
fagCheck(fiqhLatestRevision($db,'synthetic')['actor']==='mcp-key:5','stable actor');
fagCheck(str_contains(fiqhExportMetadataCsv($db),'FIQH-999'),'CSV export');
fagReject(fn()=>fiqhAgentCall($db,$key,'fiqh_approve',['id'=>'synthetic']));
fagReject(fn()=>fiqhAgentCall($db,$key,'fiqh_publish',['id'=>'synthetic']));
fagReject(fn()=>fiqhParseMetadataCsv("bad,header\na,b"));
echo "Fiqh MCP and CSV checks passed\n";
