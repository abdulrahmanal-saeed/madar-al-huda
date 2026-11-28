<?php
declare(strict_types=1);
require __DIR__.'/../admin/fiqh-legacy.php';
function flCheck(bool $ok): void { if (!$ok) throw new RuntimeException('Legacy protection failed'); }
$old=['library'=>['fiqh'=>[['id'=>'old','title'=>'synthetic']],'articles'=>[]]];
$draft=['library'=>['fiqh'=>[['id'=>'new','review'=>['hash'=>'fake']]],'articles'=>[['id'=>'article']]]];
$projection=fiqhGeneralPublication($draft,$old);
flCheck($projection['library']['fiqh']===$old['library']['fiqh']);
flCheck($projection['library']['articles']===$draft['library']['articles']);
flCheck(!isset(fiqhGeneralPublication($draft,null)['library']['fiqh']));
flCheck(!fiqhGeneralChanged(['library'=>['fiqh'=>[], 'articles'=>[]]],$old));
flCheck(fiqhGeneralChanged($draft,$old));
flCheck(fiqhPreserveLegacy($old,$draft)['library']['fiqh']===$draft['library']['fiqh']);
foreach ([['fiqh','save'],['fiqh','delete'],['daily','review_approve']] as [$section,$action]) {
    try { fiqhLegacyAssertAction($section,$action); } catch (InvalidArgumentException) { continue; }
    throw new RuntimeException('Legacy mutation was allowed');
}
fiqhLegacyAssertAction('daily','publish');
echo "Fiqh legacy protection checks passed\n";
