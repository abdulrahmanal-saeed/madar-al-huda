<?php
declare(strict_types=1);
require __DIR__ . '/../admin/fiqh-model.php';

function fiqhExpect(bool $condition, string $message): void {
    if (!$condition) {
        throw new RuntimeException($message);
    }
}

$seed = json_decode(file_get_contents(__DIR__ . '/../../docs/content/fiqh/seed.json'), true, 64, JSON_THROW_ON_ERROR);
fiqhExpect(count($seed['categories']) === 11, 'category count');
fiqhExpect(array_sum(array_column($seed['categories'], 'plannedIssueCount')) === 200, 'planned count');
fiqhExpect(count($seed['sources']) === 17 && count($seed['introductions']) === 8, 'placeholder counts');
fiqhExpect($seed['issues'] === [], 'no religious production fixtures');
fiqhExpect(fiqhCategoryErrors($seed['categories']) === [], 'valid hierarchy');
$cycle = $seed['categories'];
$cycle[0]['parentId'] = $cycle[1]['id'];
$cycle[1]['parentId'] = $cycle[0]['id'];
fiqhExpect(fiqhCategoryErrors($cycle) !== [], 'cycles rejected');
$duplicate = $seed['categories'];
$duplicate[] = $duplicate[0];
fiqhExpect(fiqhCategoryErrors($duplicate) !== [], 'duplicates rejected');
fiqhExpect(!fiqhBilingual(['ar' => 'x', 'en' => ' ']), 'blank translation rejected');
fiqhExpect(in_array('positions.hanafi', fiqhCompletenessErrors([]), true), 'missing madhhab rejected');
fiqhExpect(in_array('evidence', fiqhCompletenessErrors([]), true), 'missing evidence rejected');
fiqhExpect(in_array('agreements.justification', fiqhCompletenessErrors(['agreements' => ['applicable' => false]]), true), 'N/A justification required');
fiqhExpect(fiqhShapeErrors(['title'=>['ar'=>'','en'=>''],'agreements'=>[]])===[],'partial draft allowed');
fiqhExpect(fiqhShapeErrors(['positions'=>['hanafi'=>['review'=>['approved'=>true]]]])!==[],'nested review rejected');
fiqhExpect(fiqhShapeErrors(['evidence'=>[['id'=>'e1','sourceIds'=>[['id'=>'bad']]]]])!==[],'bad source list rejected');
fiqhExpect(fiqhShapeErrors(['title'=>['ar'=>'a','en'=>'b','private'=>'x']])!==[],'extra bilingual field rejected');
fiqhExpect(fiqhShapeErrors(['evidence'=>[['id'=>'e1'],['id'=>'e1']]])!==[],'duplicate evidence rejected');
fiqhExpect(fiqhShapeErrors(['evidence'=>[['id'=>'e1','madhhabs'=>['unknown']]]])!==[],'unknown school rejected');
fiqhExpect(count(FIQH_AYAH_COUNTS)===114&&array_sum(FIQH_AYAH_COUNTS)===6236,'Quran metadata count');
fiqhExpect(fiqhQuranLocatorValid(['surah'=>1,'firstAyah'=>1,'lastAyah'=>7]),'valid verse bounds');
fiqhExpect(!fiqhQuranLocatorValid(['surah'=>1,'firstAyah'=>1,'lastAyah'=>8]),'invalid verse bounds');
fiqhExpect(!fiqhQuranLocatorValid(['surah'=>114,'firstAyah'=>5,'lastAyah'=>4]),'reversed range');
fiqhExpect(!fiqhQuranLocatorValid(['surah'=>115,'firstAyah'=>1,'lastAyah'=>1]),'invalid surah');
fiqhExpect(!fiqhEvidenceUrlValid('javascript:alert(1)'),'unsafe URL rejected');
fiqhExpect(fiqhEvidenceUrlValid('https://example.org/test'),'HTTPS URL');
fiqhExpect(fiqhHadithLocatorValid(['collectionSourceId'=>'synthetic','number'=>['ar'=>'','en'=>'']]),'partial draft hadith locator');
fiqhExpect(!fiqhHadithLocatorValid(['collectionSourceId'=>'synthetic','review'=>true]),'nested approval rejected');
fiqhExpect(in_array('evidence.0.quranLocator',fiqhCompletenessErrors(['evidence'=>[['id'=>'e1','type'=>'quran']]]),true),'Quran locator mandatory for review');
fiqhExpect(in_array('evidence.0.hadithLocator',fiqhCompletenessErrors(['evidence'=>[['id'=>'e1','type'=>'hadith']]]),true),'Hadith locator mandatory for review');
echo "Fiqh foundation checks passed\n";
