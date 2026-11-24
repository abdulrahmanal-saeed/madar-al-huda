<?php
declare(strict_types=1);

ini_set('display_errors', '0');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-cache');
header('X-Content-Type-Options: nosniff');

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
if ($method !== 'GET' && $method !== 'HEAD') {
    header('Allow: GET, HEAD');
    http_response_code(405);
    exit;
}

// Editorial display order. Alternate tokens preserve common English spellings.
$prophets = [
    ['adam', 'آدم', 'Adam', []],
    ['idris', 'إدريس', 'Idris', []],
    ['nuh', 'نوح', 'Nuh', ['noah']],
    ['hud', 'هود', 'Hud', []],
    ['salih', 'صالح', 'Salih', ['saleh']],
    ['ibrahim', 'إبراهيم', 'Ibrahim', ['abraham', 'ibraheem']],
    ['lut', 'لوط', 'Lut', ['lot']],
    ['ismail', 'إسماعيل', 'Ismail', ['ishmael']],
    ['ishaq', 'إسحاق', 'Ishaq', ['isaac']],
    ['yaqub', 'يعقوب', 'Yaqub', ['jacob', 'yaqoob']],
    ['yusuf', 'يوسف', 'Yusuf', ['joseph', 'yousef']],
    ['ayyub', 'أيوب', 'Ayyub', ['job', 'ayoub']],
    ['shuayb', 'شعيب', 'Shuayb', ['shuaib', 'shoaib']],
    ['musa', 'موسى', 'Musa', ['moses', 'mousa']],
    ['harun', 'هارون', 'Harun', ['aaron', 'haroon']],
    ['dhulkifl', 'ذو الكفل', 'Dhul-Kifl', ['dhul-kifl', 'dhualkifl', 'dhu-al-kifl']],
    ['dawud', 'داود', 'Dawud', ['david', 'dawood']],
    ['sulayman', 'سليمان', 'Sulayman', ['solomon', 'sulaiman']],
    ['ilyas', 'إلياس', 'Ilyas', ['elijah', 'elias']],
    ['alyasa', 'اليسع', 'Al-Yasa', ['al-yasa', 'elisha']],
    ['yunus', 'يونس', 'Yunus', ['jonah', 'younes']],
    ['zakariya', 'زكريا', 'Zakariya', ['zechariah', 'zakaria']],
    ['yahya', 'يحيى', 'Yahya', ['john']],
    ['isa', 'عيسى', 'Isa', ['jesus', 'eesa']],
    ['muhammad', 'محمد', 'Muhammad', ['mohamed', 'mohammed']],
];

$tokens = [];
foreach ($prophets as [$id, $arabic, $english, $aliases]) {
    foreach (array_merge([$id], $aliases) as $token) {
        $tokens[$token] = $id;
    }
}

$files = @scandir(__DIR__);
if ($files === false) {
    http_response_code(503);
    if ($method === 'GET') {
        echo '{"error":"catalog_unavailable"}';
    }
    exit;
}

$recordings = [];
foreach ($files as $file) {
    if (!preg_match('/\AMadar-([A-Za-z][A-Za-z-]*)-([0-9]{1,6})\.(mp3|mp4)\z/', $file, $parts)) {
        continue;
    }
    $id = $tokens[strtolower($parts[1])] ?? null;
    $number = (int) $parts[2];
    $format = $parts[3] === 'mp3' ? 'audio' : 'video';
    if ($id === null || $number === 0 || isset($recordings[$id][$number][$format])) {
        continue;
    }
    $path = __DIR__ . DIRECTORY_SEPARATOR . $file;
    if (is_link($path) || !is_file($path) || !is_readable($path)) {
        continue;
    }
    $bytes = @filesize($path);
    if ($bytes !== false && $bytes > 0) {
        $recordings[$id][$number][$format] = ['file' => $file, 'bytes' => $bytes];
    }
}

// Titles, descriptions and hidden stories edited in the dashboard, from the
// published library (read-only; the catalogue still works without it).
$edited = [];
try {
    $database = dirname(__DIR__, 2) . '/.madar-admin/library.sqlite3';
    if (is_file($database)) {
        $db = new PDO('sqlite:' . $database, null, null, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::SQLITE_ATTR_OPEN_FLAGS => PDO::SQLITE_OPEN_READONLY,
        ]);
        $published = $db->query('SELECT published FROM library WHERE id = 1')->fetchColumn();
        $library = is_string($published) ? json_decode($published, true) : null;
        if (is_array($library['stories'] ?? null)) {
            $edited = $library['stories'];
        }
    }
} catch (Throwable) {
    $edited = [];
}
$text = static fn (mixed $value): string => is_string($value) ? trim($value) : '';

$series = [];
foreach ($prophets as [$id, $arabic, $english]) {
    $meta = is_array($edited[$id] ?? null) ? $edited[$id] : [];
    if (!empty($meta['hidden'])) {
        continue;
    }
    $matches = $recordings[$id] ?? [];
    if ($matches === [] && $id !== 'adam' && $id !== 'idris') {
        continue;
    }
    ksort($matches, SORT_NUMERIC);
    $episodes = [];
    foreach ($matches as $number => $media) {
        $episode = ['number' => $number, 'media' => $media];
        $title = $meta['episodes'][(string) $number] ?? null;
        if (is_array($title) && $text($title['ar'] ?? null) !== '') {
            $episode['title'] = ['ar' => $text($title['ar']), 'en' => $text($title['en'] ?? null) ?: $text($title['ar'])];
        }
        $episodes[] = $episode;
    }
    $entry = [
        'id' => $id,
        'ar' => $text($meta['ar'] ?? null) ?: 'سيدنا ' . $arabic . ($id === 'muhammad' ? ' صلى الله عليه وسلم' : ' عليه السلام'),
        'en' => $text($meta['en'] ?? null) ?: $english . ', peace be upon him',
        'episodes' => $episodes,
    ];
    if ($text($meta['descriptionAr'] ?? null) !== '') {
        $entry['description'] = [
            'ar' => $text($meta['descriptionAr']),
            'en' => $text($meta['descriptionEn'] ?? null) ?: $text($meta['descriptionAr']),
        ];
    }
    $series[] = $entry;
}

$json = json_encode(['version' => 1, 'series' => $series], JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
$etag = '"' . hash('sha256', $json) . '"';
header('ETag: ' . $etag);
if (trim($_SERVER['HTTP_IF_NONE_MATCH'] ?? '') === $etag) {
    http_response_code(304);
    exit;
}
if ($method === 'GET') {
    echo $json;
}
