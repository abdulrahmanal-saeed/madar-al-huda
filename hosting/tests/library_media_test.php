<?php
declare(strict_types=1);
require __DIR__ . '/../admin/content.php';
require __DIR__ . '/../admin/sections.php';
require __DIR__ . '/../admin/library-media.php';
function check(bool $condition): void {
    if (!$condition) throw new RuntimeException('Library media test failed');
}
$payload = ['appearance' => ['sections' => [[
    'id' => 's-test', 'kind' => 'links', 'visible' => true,
    'title' => ['ar' => 'السيرة', 'en' => 'Seerah'],
    'items' => [['title' => ['ar' => 'رابط', 'en' => 'Link'], 'url' => 'https://example.org/']],
]]]];
$_POST = ['op' => 'add_season', 'id' => 's-test', 'season_ar' => 'الموسم الأول', 'season_en' => 'Season 1'];
$payload = changeSections($payload, false);
$season = $payload['appearance']['sections'][0]['seasons'][0]['id'];
$_POST = ['op' => 'add_episode', 'id' => 's-test', 'season' => $season, 'number' => '1', 'episode_ar' => 'الحلقة الأولى', 'episode_en' => 'Episode 1'];
$payload = changeSections($payload, false);
try { changeSections($payload, false); throw new RuntimeException('Duplicate accepted'); }
catch (InvalidArgumentException) {}
check(count($payload['appearance']['sections'][0]['items']) === 1);
$name = 'Library-' . str_repeat('a', 32) . '.mp3';
check(publishedLibraryMedia($payload, $name) === null);
$payload['appearance']['sections'][0]['seasons'][0]['episodes'][0]['media']['audio'] = ['file' => $name, 'bytes' => 2048];
check(publishedLibraryMedia($payload, $name)['bytes'] === 2048);
$payload['appearance']['sections'][0]['visible'] = false;
check(publishedLibraryMedia($payload, $name) === null);
check(libraryByteRange('', 100) === [0, 99]);
check(libraryByteRange('bytes=10-19', 100) === [10, 19]);
check(libraryByteRange('bytes=-20', 100) === [80, 99]);
check(libraryByteRange('bytes=90-', 100) === [90, 99]);
check(libraryByteRange('bytes=100-', 100) === null);
check(libraryByteRange('bytes=20-10', 100) === null);
check(libraryByteRange('bytes=0-1,5-6', 100) === null);
echo "Library media tests passed.\n";
