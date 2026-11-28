<?php
declare(strict_types=1);
require __DIR__.'/../admin/fiqh-review.php';
function fsCheck(bool $ok,string $message):void { if(!$ok) throw new RuntimeException($message); }
function fsReject(callable $f):void { try{$f();}catch(Exception){return;}throw new RuntimeException('Expected rejection'); }
$db=new PDO('sqlite::memory:',null,null,[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
$seed=json_decode(file_get_contents(__DIR__.'/../../docs/content/fiqh/seed.json'),true,64,JSON_THROW_ON_ERROR);
fiqhMigration($db,$seed);fiqhMetadataMigration($db);
$bi=['ar'=>'اختبار','en'=>'Synthetic'];
$q=['id'=>'test-quran','title'=>$bi,'sourceType'=>'quran','status'=>'draft','documentationStatus'=>'documented'];
fsCheck(fiqhSourceMissing($q)===[],'Quran has no human author or edition requirements');
$h=['id'=>'test-hadith','title'=>$bi,'author'=>$bi,'sourceType'=>'hadith_collection','status'=>'draft','documentationStatus'=>'pending'];
fsCheck(in_array('edition',fiqhSourceMissing($h),true),'hadith edition required');
fsReject(fn()=>fiqhSaveMetadata($db,'source',$q+['author'=>$bi],null,'test'));
$batch=[['record'=>$q,'expectedToken'=>null],['record'=>$h,'expectedToken'=>null]];
fsCheck(!fiqhBulkSources($db,$batch,'test',true)['saved'],'preview');
fsReject(fn()=>fiqhGetSource($db,'test-quran'));
fiqhBulkSources($db,$batch,'test');
$issue=['id'=>'synthetic','number'=>'FIQH-999','slug'=>'synthetic','categoryId'=>'taharah','title'=>$bi,
    'evidence'=>[['id'=>'q','type'=>'quran','text'=>$bi,'reference'=>$bi,'explanation'=>$bi,'sourceIds'=>['test-quran'],'quranLocator'=>['surah'=>1,'firstAyah'=>1,'lastAyah'=>1]],
    ['id'=>'h','type'=>'hadith','text'=>$bi,'reference'=>$bi,'explanation'=>$bi,'sourceIds'=>['test-hadith'],'hadithLocator'=>['collectionSourceId'=>'test-hadith','number'=>$bi,'book'=>$bi,'chapter'=>$bi,'editionLocator'=>$bi],'grading'=>$bi,'gradingAttribution'=>$bi]]];
fiqhSaveDraft($db,$issue,0,'test');
$before=fiqhLatestRevision($db,'synthetic');
fsCheck(in_array('sources.test-hadith.edition',fiqhDraftValidationErrors($before),true),'source error');
$h=array_replace($h,['publisher'=>'Synthetic','edition'=>'Synthetic','license'=>'Synthetic','documentationStatus'=>'documented']);
$token=fiqhGetSource($db,'test-hadith')['editToken'];
$rows=[['record'=>$h,'expectedToken'=>$token],['record'=>array_replace($q,['editorialNotes'=>'Synthetic']),'expectedToken'=>fiqhGetSource($db,'test-quran')['editToken']]];
$r=fiqhBulkSources($db,$rows,'test');
$after=fiqhLatestRevision($db,'synthetic');
fsCheck(count($r['affectedIssues'])===1&&(int)$after['revision']===2,'one refreshed draft');
fsCheck($after['body']===$before['body'],'identity and body preserved');
fsCheck(!in_array('sources.test-hadith.edition',fiqhDraftValidationErrors($after),true),'source fixed');
fsReject(fn()=>fiqhBulkSources($db,$rows,'test'));
fsCheck((int)fiqhLatestRevision($db,'synthetic')['revision']===2,'stale batch no changes');
fsReject(fn()=>fiqhBulkSources($db,[['record'=>array_replace($q,['id'=>'rollback-source']),'expectedToken'=>null],['record'=>$h,'expectedToken'=>null]],'test'));
fsReject(fn()=>fiqhGetSource($db,'rollback-source'));
echo "Fiqh source library checks passed\n";
