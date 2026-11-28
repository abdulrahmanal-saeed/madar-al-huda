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
echo "Fiqh foundation checks passed\n";
