<?php
declare(strict_types=1);

function storyName(string $name): string
{
    if (!preg_match('/\AMadar-[A-Za-z][A-Za-z-]*-[0-9]{1,6}\.(mp3|mp4)\z/', $name)) {
        throw new InvalidArgumentException('استخدم اسمًا مثل Madar-Idris-007.mp3 أو Madar-Idris-007.mp4.');
    }
    return $name;
}

function listStoryFiles(string $directory, bool $archived): array
{
    $files = is_dir($directory) ? scandir($directory) : [];
    $prefix = $archived ? '[a-f0-9]{16}--' : '';
    return array_values(array_filter($files ?: [], fn ($name) =>
        preg_match('/\A' . $prefix . 'Madar-[A-Za-z][A-Za-z-]*-[0-9]{1,6}\.(mp3|mp4)\z/', $name) &&
        is_file($directory . '/' . $name) && !is_link($directory . '/' . $name)
    ));
}

/**
 * One row per episode: «آدم · الحلقة ١» with its audio and video files.
 *
 * @return list<array{label: string, files: array<string, string>}>
 */
function groupStoryFiles(array $files, bool $archived): array
{
    $episodes = [];
    foreach ($files as $file) {
        $name = $archived ? substr($file, 18) : $file;
        if (!preg_match('/\AMadar-([A-Za-z][A-Za-z-]*)-([0-9]{1,6})\.(mp3|mp4)\z/', $name, $parts)) {
            continue;
        }
        $key = $parts[1] . '-' . $parts[2];
        $episodes[$key] ??= [
            'label' => str_replace('-', ' ', $parts[1]) . ' · الحلقة ' . arabicDigits((string) (int) $parts[2]),
            'files' => [],
        ];
        $episodes[$key]['files'][$parts[3]] = $file;
    }
    foreach ($episodes as &$episode) {
        ksort($episode['files']);
    }
    unset($episode);
    return array_values($episodes);
}

function changeStory(string $action): void
{
    $media = storyMedia();
    $archive = storyStaging();

    if ($action === 'upload_story') {
        $file = $_FILES['recording'] ?? [];
        if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK ||
            !is_uploaded_file($file['tmp_name'] ?? '')) {
            throw new InvalidArgumentException('تعذّر رفع التسجيل. تحقّق من حجم الملف.');
        }
        storyName($file['name']);
        $pending = tempnam($archive, 'upload-');
        if ($pending === false || !move_uploaded_file($file['tmp_name'], $pending)) {
            throw new RuntimeException('An upload staging path could not be created');
        }
        publishStoryFile($pending, $file['name']);
        return;
    }

    $submitted = field('file');
    if ($action === 'archive_story') {
        $name = storyName($submitted);
        $from = $media . '/' . $name;
        $to = $archive . '/' . bin2hex(random_bytes(8)) . '--' . $name;
    } else {
        if (!preg_match('/\A[a-f0-9]{16}--(.+)\z/', $submitted, $parts)) {
            throw new InvalidArgumentException('معرّف التسجيل المؤرشف غير صالح.');
        }
        $name = storyName($parts[1]);
        $from = $archive . '/' . $submitted;
        $to = $media . '/' . $name;
    }
    if (!is_file($from) || is_link($from) || file_exists($to) || is_link($to)) {
        throw new InvalidArgumentException('تعذّر نقل التسجيل. تحقّق من وجوده ومن عدم تكرار الاسم.');
    }
    if (!rename($from, $to)) {
        throw new RuntimeException('The recording could not be moved');
    }
}

const MAX_STORY_BYTES = 1536 * 1024 * 1024;

/** The private folder where uploads wait until they are checked. */
function storyStaging(): string
{
    $archive = storage() . '/stories-archive';
    if (!is_dir($archive) && !@mkdir($archive, 0700) && !is_dir($archive)) {
        throw new RuntimeException('The story archive is unavailable');
    }
    if (is_link($archive)) {
        throw new RuntimeException('The story archive is invalid');
    }
    return $archive;
}

function storyMedia(): string
{
    $media = realpath(ROOT . '/Prophet Stories');
    if ($media === false || $media !== realpath(ROOT) . DIRECTORY_SEPARATOR . 'Prophet Stories') {
        throw new RuntimeException('The media folder is unavailable');
    }
    return $media;
}

/**
 * Checks a staged file and publishes it under [$name]. The staged file is
 * always gone afterwards.
 */
function publishStoryFile(string $staged, string $name): void
{
    try {
        $name = storyName($name);
        $target = storyMedia() . '/' . $name;
        if (file_exists($target) || is_link($target)) {
            throw new InvalidArgumentException("الملف $name موجود بالفعل. أرشف النسخة القديمة أولًا إذا كنت تستبدلها.");
        }
        $size = filesize($staged);
        if ($size === false || $size < 1024 || $size > MAX_STORY_BYTES) {
            throw new InvalidArgumentException("حجم $name غير مقبول (الحد الأقصى ١٫٥ جيجابايت).");
        }
        $type = (new finfo(FILEINFO_MIME_TYPE))->file($staged);
        $allowed = str_ends_with($name, '.mp3') ? ['audio/mpeg'] : ['video/mp4', 'application/mp4'];
        if (!in_array($type, $allowed, true)) {
            throw new InvalidArgumentException("محتوى $name لا يطابق صيغته (" . ($type ?: 'غير معروف') . ').');
        }
        if (!chmod($staged, 0644) || !rename($staged, $target)) {
            throw new RuntimeException('The upload could not be published');
        }
    } finally {
        if (is_file($staged)) {
            @unlink($staged);
        }
    }
}

/** The file id in a Google Drive share link, or null. */
function driveFileId(string $link): ?string
{
    $link = trim($link);
    if (preg_match('~\Ahttps://(?:drive|docs)\.google\.com/(?:file/d/|open\?id=|uc\?(?:[^#]*&)?id=)([A-Za-z0-9_-]{20,80})~', $link, $parts)) {
        return $parts[1];
    }
    if (preg_match('~\Ahttps://drive\.usercontent\.google\.com/download\?(?:[^#]*&)?id=([A-Za-z0-9_-]{20,80})~', $link, $parts)) {
        return $parts[1];
    }
    return null;
}

/** Where an import's progress is kept for the page to poll. */
function driveJobFile(string $job): string
{
    if (!preg_match('/\A[a-f0-9]{16,64}\z/', $job)) {
        throw new InvalidArgumentException('معرّف الرفع غير صالح.');
    }
    $folder = storage() . '/jobs';
    if (!is_dir($folder) && !@mkdir($folder, 0700) && !is_dir($folder)) {
        throw new RuntimeException('The job folder is unavailable');
    }
    // Old progress files are not needed after a day.
    foreach (glob($folder . '/*.json') ?: [] as $old) {
        if (filemtime($old) < time() - 86400) {
            @unlink($old);
        }
    }
    return $folder . '/' . $job . '.json';
}

function writeDriveJob(string $file, array $state): void
{
    @file_put_contents($file, encode($state), LOCK_EX);
}

/**
 * Downloads a publicly shared Google Drive file straight to the server and
 * publishes it. Without [$name], the file's own name on Drive is used.
 */
function importDriveFile(
    string $link,
    string $name,
    string $job,
    ?callable $receive = null,
    int $maxBytes = MAX_STORY_BYTES,
): string
{
    $id = driveFileId($link);
    if ($id === null) {
        throw new InvalidArgumentException('الصق رابط ملف من Google Drive (drive.google.com/file/d/…).');
    }
    $jobFile = driveJobFile($job);
    writeDriveJob($jobFile, ['state' => 'downloading', 'received' => 0, 'total' => 0]);
    $staged = tempnam(storyStaging(), 'drive-');
    if ($staged === false) {
        throw new RuntimeException('An upload staging path could not be created');
    }
    $out = fopen($staged, 'wb');
    $headers = [];
    $lastWrite = 0.0;
    $curl = curl_init('https://drive.usercontent.google.com/download?' . http_build_query([
        'id' => $id, 'export' => 'download', 'confirm' => 't',
    ]));
    curl_setopt_array($curl, [
        CURLOPT_FILE => $out,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_MAXREDIRS => 5,
        CURLOPT_PROTOCOLS => CURLPROTO_HTTPS,
        CURLOPT_REDIR_PROTOCOLS => CURLPROTO_HTTPS,
        CURLOPT_CONNECTTIMEOUT => 20,
        CURLOPT_MAXFILESIZE_LARGE => $maxBytes,
        CURLOPT_TIMEOUT => $maxBytes < MAX_STORY_BYTES ? 90 : 0,
        CURLOPT_LOW_SPEED_LIMIT => 1024,
        CURLOPT_LOW_SPEED_TIME => 60,
        CURLOPT_NOPROGRESS => false,
        CURLOPT_HEADERFUNCTION => function ($curl, string $line) use (&$headers, $receive): int {
            if ($receive !== null && stripos($line, 'Location:') === 0) {
                $location = trim(substr($line, 9));
                $parts = parse_url($location);
                if ($parts === false || ($parts['scheme'] ?? '') !== 'https' || isset($parts['user']) || isset($parts['pass']) || isset($parts['port']) || !preg_match('/\A(?:[a-z0-9-]+\.)*(?:google\.com|googleusercontent\.com)\z/i', $parts['host'] ?? '')) return 0;
            }
            if (str_contains($line, ':')) {
                [$key, $value] = explode(':', $line, 2);
                $headers[strtolower(trim($key))] = trim($value);
            }
            return strlen($line);
        },
        CURLOPT_XFERINFOFUNCTION => function ($curl, $total, $received) use ($jobFile, &$lastWrite, $maxBytes): int {
            if ($received > $maxBytes || $total > $maxBytes) {
                return 1;
            }
            $now = microtime(true);
            if ($now - $lastWrite >= 0.5) {
                $lastWrite = $now;
                writeDriveJob($jobFile, ['state' => 'downloading', 'received' => $received, 'total' => $total]);
            }
            return 0;
        },
    ]);
    try {
        $ok = curl_exec($curl);
        fclose($out);
        $status = curl_getinfo($curl, CURLINFO_RESPONSE_CODE);
        $host = parse_url((string) curl_getinfo($curl, CURLINFO_EFFECTIVE_URL), PHP_URL_HOST) ?: '';
        if (curl_errno($curl) === CURLE_FILESIZE_EXCEEDED ||
            (int) curl_getinfo($curl, CURLINFO_SIZE_DOWNLOAD) > $maxBytes ||
            (int) curl_getinfo($curl, CURLINFO_CONTENT_LENGTH_DOWNLOAD) > $maxBytes) {
            throw new InvalidArgumentException('حجم الملف يتجاوز الحد المسموح به.');
        }
        if ($ok !== true || $status !== 200) {
            throw new InvalidArgumentException('تعذّر تنزيل الملف من Drive. تأكّد أن المشاركة «أي شخص لديه الرابط».');
        }
        if (!preg_match('/(\A|\.)(google\.com|googleusercontent\.com)\z/', $host)) {
            throw new InvalidArgumentException('أعاد Drive التحويل إلى عنوان غير متوقع.');
        }
        if (str_starts_with($headers['content-type'] ?? '', 'text/html')) {
            throw new InvalidArgumentException('الملف غير متاح للتنزيل. اجعل المشاركة «أي شخص لديه الرابط».');
        }
        if ($name === '' && preg_match('/filename\*?=(?:UTF-8\'\')?"?([^";]+)"?/i', $headers['content-disposition'] ?? '', $match)) {
            $name = rawurldecode($match[1]);
        }
        if ($name === '') {
            throw new InvalidArgumentException('اكتب اسم الملف بجانب الرابط، مثل Madar-Idris-007.mp4.');
        }
        writeDriveJob($jobFile, ['state' => 'checking', 'received' => filesize($staged), 'total' => filesize($staged)]);
        if ($receive === null) {
            publishStoryFile($staged, $name);
        } else {
            $receive($staged, $name);
        }
        writeDriveJob($jobFile, ['state' => 'done', 'name' => $name]);
        return $name;
    } catch (Throwable $failure) {
        writeDriveJob($jobFile, ['state' => 'failed']);
        throw $failure;
    } finally {
        if (is_resource($out)) {
            fclose($out);
        }
        if (is_file($staged)) {
            @unlink($staged);
        }
    }
}
