<?php
declare(strict_types=1);

const MAX_LIBRARY_SEASONS = 30;
const MAX_SEASON_EPISODES = 200;

function seasonIndex(array $rows, string $id): int
{
    foreach ($rows as $i => $row) {
        if (($row['id'] ?? '') === $id) return $i;
    }
    throw new InvalidArgumentException('الموسم أو الحلقة غير موجودة.');
}

function libraryMediaDirectory(): string
{
    $dir = storage() . '/library-media';
    if ((!is_dir($dir) && !@mkdir($dir, 0700) && !is_dir($dir)) || is_link($dir)) {
        throw new RuntimeException('Media storage unavailable');
    }
    return $dir;
}

/** Immutable files are kept privately, including those needed by old publications. */
function storeLibraryMedia(string $tmp, string $format, bool $uploaded): array
{
    $extension = match ($format) {
        'audio' => 'mp3', 'video' => 'mp4',
        default => throw new InvalidArgumentException('اختر صوت MP3 أو فيديو MP4.'),
    };
    if (!is_file($tmp) || is_link($tmp) || ($uploaded && !is_uploaded_file($tmp))) {
        throw new InvalidArgumentException('ملف الرفع غير صالح.');
    }
    $bytes = filesize($tmp);
    $allowed = $format === 'audio' ? ['audio/mpeg'] : ['video/mp4', 'application/mp4'];
    if ($bytes === false || $bytes < 1024 || $bytes > MAX_STORY_BYTES ||
        !in_array((new finfo(FILEINFO_MIME_TYPE))->file($tmp), $allowed, true)) {
        throw new InvalidArgumentException('الصيغة أو الحجم غير صالح (الحد الأقصى ١٫٥ جيجابايت).');
    }
    $name = 'Library-' . bin2hex(random_bytes(16)) . '.' . $extension;
    $target = libraryMediaDirectory() . '/' . $name;
    if (!($uploaded ? move_uploaded_file($tmp, $target) : rename($tmp, $target))) {
        throw new RuntimeException('Media upload failed');
    }
    chmod($target, 0600);
    return ['file' => $name, 'bytes' => $bytes];
}

function uploadLibraryMedia(string $format): array
{
    $file = $_FILES['recording'] ?? [];
    $tmp = $file['tmp_name'] ?? '';
    if (($file['error'] ?? null) !== UPLOAD_ERR_OK || !is_string($tmp)) {
        throw new InvalidArgumentException('تعذّر رفع الملف. تحقّق من الحد المسموح به في الاستضافة.');
    }
    return storeLibraryMedia($tmp, $format, true);
}

/** Final number identifies the episode; the season is chosen explicitly. */
function libraryRecordingIdentity(string $name): array
{
    if (strlen($name) > 200 || !preg_match('/\A(?:[A-Za-z0-9][A-Za-z0-9_-]*[-_])?([0-9]{1,6})\.(mp3|mp4)\z/i', $name, $m) || (int) $m[1] < 1) {
        throw new InvalidArgumentException('استخدم اسمًا مثل Madar-Seerah-001.mp3 أو 001.mp4.');
    }
    return [(int) $m[1], strtolower($m[2]) === 'mp3' ? 'audio' : 'video'];
}

/** Pair audio/video by number. Existing titles and recordings are never overwritten in bulk. */
function attachLibraryRecording(array $season, string $name, callable $store): array
{
    [$number, $format] = libraryRecordingIdentity($name);
    $index = array_search($number, array_column($season['episodes'], 'number'), true);
    if ($index === false) {
        if (count($season['episodes']) >= MAX_SEASON_EPISODES) {
            throw new InvalidArgumentException('بلغ الموسم الحد الأقصى للحلقات.');
        }
        $index = count($season['episodes']);
        $season['episodes'][] = [
            'id' => 'ep-' . bin2hex(random_bytes(8)),
            'number' => $number,
            'title' => ['ar' => 'الحلقة ' . $number, 'en' => 'Episode ' . $number],
            'media' => [],
        ];
    }
    if (isset($season['episodes'][$index]['media'][$format])) {
        throw new InvalidArgumentException('التسجيل موجود. استخدم زر الاستبدال داخل الحلقة.');
    }
    $season['episodes'][$index]['media'][$format] = $store($format);
    return $season;
}

/** Only metadata changes are published; removing an episode never deletes its file. */
function changeLibrarySeason(array $section, string $operation, ?string $staged = null, ?string $filename = null): array
{
    $seasons = $section['seasons'] ?? [];
    if ($operation === 'add_season') {
        if (count($seasons) >= MAX_LIBRARY_SEASONS) throw new InvalidArgumentException('وصلت للحد الأقصى للمواسم.');
        $seasons[] = ['id' => 'season-' . bin2hex(random_bytes(8)), 'title' => bilingual('season'), 'episodes' => []];
    } else {
        $index = seasonIndex($seasons, field('season'));
        $season = &$seasons[$index];
        if ($operation === 'rename_season') {
            $season['title'] = bilingual('season');
        } elseif ($operation === 'remove_season') {
            array_splice($seasons, $index, 1);
        } elseif ($operation === 'season_up' || $operation === 'season_down') {
            $next = $index + ($operation === 'season_up' ? -1 : 1);
            if (isset($seasons[$next])) {
                unset($season);
                [$seasons[$index], $seasons[$next]] = [$seasons[$next], $seasons[$index]];
            }
        } elseif ($operation === 'bulk_upload' || $operation === 'bulk_drive') {
            if ($operation === 'bulk_drive') {
                if ($staged === null || $filename === null) throw new InvalidArgumentException('لم يُنزّل الملف.');
                $season = attachLibraryRecording($season, $filename, fn ($format) => storeLibraryMedia($staged, $format, false));
            } else {
                $name = $_FILES['recording']['name'] ?? '';
                if (!is_string($name)) throw new InvalidArgumentException('اسم الملف غير صالح.');
                $season = attachLibraryRecording($season, $name, fn ($format) => uploadLibraryMedia($format));
            }
        } elseif ($operation === 'add_episode') {
            $number = integer(field('number'), 1, 999999);
            if (count($season['episodes']) >= MAX_SEASON_EPISODES || in_array($number, array_column($season['episodes'], 'number'), true)) {
                throw new InvalidArgumentException('رقم الحلقة موجود أو بلغ الموسم الحد الأقصى.');
            }
            $season['episodes'][] = ['id' => 'ep-' . bin2hex(random_bytes(8)), 'number' => $number, 'title' => bilingual('episode'), 'media' => []];
        } else {
            $episodeIndex = seasonIndex($season['episodes'], field('episode'));
            $episode = &$season['episodes'][$episodeIndex];
            switch ($operation) {
                case 'rename_episode':
                    $number = integer(field('number'), 1, 999999);
                    foreach ($season['episodes'] as $i => $other) {
                        if ($i !== $episodeIndex && $other['number'] === $number) throw new InvalidArgumentException('رقم الحلقة موجود.');
                    }
                    $episode['number'] = $number;
                    $episode['title'] = bilingual('episode');
                    break;
                case 'remove_episode':
                    array_splice($season['episodes'], $episodeIndex, 1);
                    break;
                case 'upload_episode':
                    $format = field('format');
                    $episode['media'][$format] = uploadLibraryMedia($format);
                    break;
                case 'remove_media':
                    $format = field('format');
                    if (!in_array($format, ['audio', 'video'], true)) throw new InvalidArgumentException('صيغة غير صالحة.');
                    unset($episode['media'][$format]);
                    break;
                default:
                    throw new InvalidArgumentException('إجراء غير متاح.');
            }
        }
    }
    unset($episode, $season);
    $section['seasons'] = array_values($seasons);
    return $section;
}

function publishedLibraryMedia(array $payload, string $name): ?array
{
    foreach ($payload['appearance']['sections'] ?? [] as $section) {
        if (($section['kind'] ?? '') !== 'links' || ($section['visible'] ?? true) === false) continue;
        foreach ($section['seasons'] ?? [] as $season) {
            foreach ($season['episodes'] ?? [] as $episode) {
                foreach (['audio', 'video'] as $format) {
                    $media = $episode['media'][$format] ?? null;
                    if (($media['file'] ?? null) === $name) return $media;
                }
            }
        }
    }
    return null;
}

/** Single byte ranges for Android video/audio seeking; rejects invalid ranges. */
function libraryByteRange(string $range, int $size): ?array
{
    if ($range === '') return [0, $size - 1];
    if (!preg_match('/\Abytes=([0-9]{0,18})-([0-9]{0,18})\z/', $range, $m) || ($m[1] === '' && $m[2] === '')) return null;
    if ($m[1] === '') {
        $suffix = (int) $m[2];
        return $suffix > 0 ? [max(0, $size - $suffix), $size - 1] : null;
    }
    $start = (int) $m[1];
    $end = $m[2] === '' ? $size - 1 : min($size - 1, (int) $m[2]);
    return $start < $size && $start <= $end ? [$start, $end] : null;
}

function serveLibraryMedia(PDO $db, mixed $name): never
{
    $method = $_SERVER['REQUEST_METHOD'] ?? '';
    if (!in_array($method, ['GET', 'HEAD'], true)) {
        header('Allow: GET, HEAD');
        http_response_code(405);
        exit;
    }
    if (!is_string($name) || !preg_match('/\ALibrary-[a-f0-9]{32}\.(mp3|mp4)\z/', $name)) {
        http_response_code(404);
        exit;
    }
    $body = $db->query('SELECT published FROM library WHERE id = 1')->fetchColumn();
    $media = is_string($body) ? publishedLibraryMedia(json_decode($body, true, 64, JSON_THROW_ON_ERROR), $name) : null;
    $path = libraryMediaDirectory() . '/' . $name;
    if ($media === null || !is_file($path) || is_link($path) || filesize($path) !== $media['bytes']) {
        http_response_code(404);
        exit;
    }
    $size = $media['bytes'];
    $range = $_SERVER['HTTP_RANGE'] ?? '';
    $bounds = libraryByteRange($range, $size);
    header('Accept-Ranges: bytes');
    header('Cache-Control: no-store');
    if ($bounds === null) {
        header('Content-Range: bytes */' . $size);
        http_response_code(416);
        exit;
    }
    [$start, $end] = $bounds;
    $remaining = $end - $start + 1;
    header('Content-Type: ' . (str_ends_with($name, '.mp3') ? 'audio/mpeg' : 'video/mp4'));
    header('Content-Length: ' . $remaining);
    if ($range !== '') {
        http_response_code(206);
        header("Content-Range: bytes $start-$end/$size");
    }
    if ($method === 'HEAD') exit;
    $file = fopen($path, 'rb');
    if ($file === false) exit;
    set_time_limit(0);
    fseek($file, $start);
    while ($remaining > 0 && !feof($file) && !connection_aborted()) {
        $chunk = fread($file, min(1048576, $remaining));
        if ($chunk === false || $chunk === '') break;
        echo $chunk;
        $remaining -= strlen($chunk);
        flush();
    }
    fclose($file);
    exit;
}
