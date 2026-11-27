<?php
declare(strict_types=1);

require __DIR__ . '/../admin/content-news.php';

function field(string $name): string
{
    return trim($_POST[$name] ?? '');
}

function encode(mixed $value): string
{
    return json_encode($value, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
}

function expectNews(bool $condition, string $message): void
{
    if (!$condition) throw new RuntimeException($message);
}

$db = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$payload = ['appearance' => ['sections' => [[
    'kind' => 'links', 'id' => 'seerah', 'title' => ['ar' => 'السيرة'],
    'seasons' => [[
        'id' => 'seven', 'title' => ['ar' => 'الموسم السابع'],
        'episodes' => [['number' => 3, 'title' => ['ar' => 'الحلقة الثالثة'], 'media' => ['audio' => true]]],
    ]],
]]]];
$_POST = [
    'news_title' => 'حلقة جديدة', 'news_body' => 'الحلقة الثالثة متاحة الآن.',
    'news_route' => '/library/s/seerah?season=seven&episode=3', 'news_channel' => 'dev',
];

$id = enqueueContentNews($db, $payload, 7);
expectNews($id > 0, 'The publisher must queue the episode notification.');
expectNews(enqueueContentNews($db, $payload, 7) === $id, 'A repeated publication must reuse its message.');
expectNews((int) $db->query('SELECT count(*) FROM content_news')->fetchColumn() === 1, 'The queue must have one row.');

$_POST['news_route'] = '/library/s/seerah?season=seven&episode=99';
try {
    enqueueContentNews($db, $payload, 7);
    throw new RuntimeException('A removed or unknown episode cannot be a notification target.');
} catch (InvalidArgumentException) {
}
echo "Content news tests passed.\n";
