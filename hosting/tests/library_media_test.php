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

check(libraryRecordingIdentity('Madar-Seerah-001.mp3') === [1, 'audio']);
check(libraryRecordingIdentity('Madar-Seerah-001.mp4') === [1, 'video']);
check(libraryRecordingIdentity('025.MP3') === [25, 'audio']);
foreach (['../001.mp3', 'Madar-000.mp4', 'Madar-Seerah.mp3', '1.php'] as $bad) {
    try { libraryRecordingIdentity($bad); throw new RuntimeException('Invalid name accepted'); }
    catch (InvalidArgumentException) {}
}
$season = ['episodes' => []];
$fakeStore = fn ($format) => ['file' => $format, 'bytes' => 2048];
$season = attachLibraryRecording($season, 'Madar-Seerah-001.mp3', $fakeStore);
$season['episodes'][0]['title'] = ['ar' => 'المولد', 'en' => 'Birth'];
$season = attachLibraryRecording($season, 'Madar-Seerah-001.mp4', $fakeStore);
check(count($season['episodes']) === 1);
check(count($season['episodes'][0]['media']) === 2);
check($season['episodes'][0]['title']['en'] === 'Birth');
try {
    attachLibraryRecording($season, 'Madar-Seerah-001.mp3', fn () => throw new RuntimeException('Store called for duplicate'));
    throw new RuntimeException('Duplicate media accepted');
} catch (InvalidArgumentException) {}
$season = attachLibraryRecording($season, 'Madar-Seerah-002.mp3', $fakeStore);
check(count($season['episodes']) === 2);

// MCP title edits must leave every non-title field and the published feed untouched.
require __DIR__ . '/../admin/agent.php';
require __DIR__ . '/../admin/storage.php';
$fixture = ['appearance' => ['sections' => [[
    'id' => 'seerah', 'kind' => 'links', 'visible' => true,
    'title' => ['ar' => 'السيرة', 'en' => 'Seerah'],
    'items' => [['url' => 'https://example.org/']],
    'seasons' => [[
        'id' => 'season-1', 'title' => ['ar' => 'الأول', 'en' => 'First'],
        'episodes' => [
            ['id' => 'ep-1', 'number' => 1, 'title' => ['ar' => 'قديم', 'en' => 'Old'],
                'media' => ['audio' => ['file' => 'test.mp3', 'bytes' => 42]]],
            ['id' => 'ep-2', 'number' => 2, 'title' => ['ar' => 'قديم', 'en' => 'Old'],
                'media' => ['video' => ['file' => 'test.mp4', 'bytes' => 99]]],
        ],
    ]],
]]], 'other' => ['untouched' => true]];
$args = ['section_id' => 'seerah', 'season_id' => 'season-1', 'revision' => 7];
$updates = [
    ['episode_id' => 'ep-1', 'ar' => 'العالم قبل البعثة', 'en' => 'Before Prophethood'],
    ['episode_id' => 'ep-2', 'ar' => 'بناء الكعبة', 'en' => 'Building the Kaaba'],
];
$expected = $fixture;
foreach ($updates as $i => $update) {
    $expected['appearance']['sections'][0]['seasons'][0]['episodes'][$i]['title'] =
        ['ar' => $update['ar'], 'en' => $update['en']];
}
check(agentLibraryRename($fixture, $args, $updates) === $expected);
check(agentLibraryIndexes($fixture, $args) === [0, 0]);
check(agentLibraryRename($expected, $args, $updates) === $expected);
foreach ([
    [],
    [$updates[0], $updates[0]],
    [$updates[0], ['episode_id' => 'missing', 'ar' => 'عنوان', 'en' => 'Title']],
    [['episode_id' => 'ep-1', 'ar' => '', 'en' => 'Title']],
    [['episode_id' => 'ep-1', 'ar' => 'عنوان', 'en' => str_repeat('x', 301)]],
    [['episode_id' => 'ep-1', 'ar' => "عنوان\nآخر", 'en' => 'Title']],
] as $invalid) {
    try {
        agentLibraryRename($fixture, $args, $invalid);
        throw new RuntimeException('Invalid MCP title batch accepted');
    } catch (AgentError) {}
}
try {
    agentLibraryRename($fixture, array_replace($args, ['season_id' => 'wrong']), $updates);
    throw new RuntimeException('Invalid season accepted');
} catch (AgentError) {}
$toolMap = array_column(agentTools(), null, 'name');
foreach (['list_library_sections', 'list_seasons', 'list_episodes'] as $tool) {
    check($toolMap[$tool]['annotations']['readOnlyHint'] === true);
}
foreach (['update_episode', 'bulk_update_episode_titles'] as $tool) {
    check($toolMap[$tool]['annotations']['readOnlyHint'] === false);
    check(in_array('revision', $toolMap[$tool]['inputSchema']['required'], true));
}
// Exercise the real revision guard and rollback where SQLite is available.
if (in_array('sqlite', PDO::getAvailableDrivers(), true)) {
    require __DIR__ . '/../admin/governance.php';
    $db = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
    $db->exec('CREATE TABLE library (id INTEGER PRIMARY KEY, draft TEXT NOT NULL, revision INTEGER NOT NULL, published TEXT)');
    $db->exec('CREATE TABLE audit (at INTEGER, user TEXT, action TEXT, section TEXT, detail TEXT)');
    $db->prepare('INSERT INTO library VALUES (1, ?, 7, ?)')->execute([encode($fixture), encode($fixture)]);
    $key = ['label' => 'Test'];
    check(agentCall($db, $key, 'list_episodes', $args)['revision'] === 7);
    try {
        agentCall($db, $key, 'bulk_update_episode_titles', $args + ['updates' => [$updates[0], ['episode_id' => 'missing', 'ar' => 'عنوان', 'en' => 'Title']]]);
        throw new RuntimeException('Invalid batch committed');
    } catch (AgentError) {}
    check((int) library($db)['revision'] === 7);
    check(library($db)['draft'] === encode($fixture));
    $saved = agentCall($db, $key, 'bulk_update_episode_titles', $args + ['updates' => $updates]);
    check($saved['revision'] === 8 && $saved['published'] === false);
    check(library($db)['draft'] === encode($expected));
    check(library($db)['published'] === encode($fixture));
    try {
        agentCall($db, $key, 'update_episode', $args + $updates[0]);
        throw new RuntimeException('Stale revision accepted');
    } catch (AgentError) {}
    check((int) library($db)['revision'] === 8);
    $noChange = agentCall($db, $key, 'update_episode', array_replace($args, ['revision' => 8]) + $updates[0]);
    check($noChange['changed'] === false && $noChange['revision'] === 8);
}

echo "Library media tests passed.\n";
