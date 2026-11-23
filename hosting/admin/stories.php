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

function changeStory(string $action): void
{
    $media = realpath(ROOT . '/Prophet Stories');
    if ($media === false || $media !== realpath(ROOT) . DIRECTORY_SEPARATOR . 'Prophet Stories') {
        throw new RuntimeException('The media folder is unavailable');
    }
    $archive = storage() . '/stories-archive';
    if (!is_dir($archive) && !@mkdir($archive, 0700) && !is_dir($archive)) {
        throw new RuntimeException('The story archive is unavailable');
    }
    if (is_link($archive)) {
        throw new RuntimeException('The story archive is invalid');
    }

    if ($action === 'upload_story') {
        $file = $_FILES['recording'] ?? [];
        if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK ||
            !is_uploaded_file($file['tmp_name'] ?? '')) {
            throw new InvalidArgumentException('تعذّر رفع التسجيل. تحقّق من حجم الملف.');
        }
        $name = storyName($file['name']);
        $target = $media . '/' . $name;
        if (file_exists($target) || is_link($target)) {
            throw new InvalidArgumentException('الملف موجود بالفعل. أرشف النسخة القديمة أولًا إذا كنت تستبدلها.');
        }
        $type = (new finfo(FILEINFO_MIME_TYPE))->file($file['tmp_name']);
        $allowed = str_ends_with($name, '.mp3') ? ['audio/mpeg'] : ['video/mp4', 'application/mp4'];
        if (!in_array($type, $allowed, true)) {
            throw new InvalidArgumentException('امتداد الملف لا يطابق صيغة التسجيل.');
        }
        $pending = tempnam($archive, 'upload-');
        if ($pending === false) {
            throw new RuntimeException('An upload staging path could not be created');
        }
        try {
            if (!move_uploaded_file($file['tmp_name'], $pending) ||
                !chmod($pending, 0644) || !rename($pending, $target)) {
                throw new RuntimeException('The upload could not be published');
            }
        } finally {
            if (is_file($pending)) {
                unlink($pending);
            }
        }
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
