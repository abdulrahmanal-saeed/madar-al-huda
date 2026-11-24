<?php
declare(strict_types=1);

const BOOK_SECTIONS = ['fiqh', 'articles', 'lessons', 'names'];
const SCHOOLS = [
    'hanafi' => 'الحنفي', 'maliki' => 'المالكي',
    'shafii' => 'الشافعي', 'hanbali' => 'الحنبلي',
];

function contentText(string $key, int $limit = 18000, bool $required = true): string
{
    $value = field($key);
    if (strlen($value) > $limit || ($required && $value === '')) {
        throw new InvalidArgumentException('راجع الحقول المطلوبة وطول النص.');
    }
    return $value;
}

function sourceLink(string $key): string
{
    $url = contentText($key, 2048);
    $parts = parse_url($url);
    if ($parts === false || ($parts['scheme'] ?? '') !== 'https' ||
        empty($parts['host']) || isset($parts['user']) || isset($parts['pass'])) {
        throw new InvalidArgumentException('أدخل رابط مصدر صالحًا يبدأ بـ HTTPS.');
    }
    return $url;
}

function lessonQuestions(): array
{
    $questions = [];
    $length = integer(field('questions_count'), 0, 100);
    for ($i = 0; $i < $length; $i++) {
        if (field("skip_question_$i") === '1') {
            continue;
        }
        $ar = field("question_ar_$i");
        $en = field("question_en_$i");
        if ($ar === '' && $en === '') {
            continue;
        }
        $prompt = [
            'ar' => contentText("question_ar_$i", 1000),
            'en' => contentText("question_en_$i", 1000),
        ];
        $choices = [];
        for ($choice = 0; $choice < 4; $choice++) {
            $choices[] = [
                'ar' => contentText("choice_ar_{$i}_$choice", 540),
                'en' => contentText("choice_en_{$i}_$choice", 540),
            ];
        }
        $questions[] = [
            'prompt' => $prompt,
            'choices' => $choices,
            'answer' => integer(field("answer_$i"), 0, 3),
        ];
    }
    return $questions;
}

function changeBook(array $payload, string $section, bool $delete): array
{
    $rows = $payload['library'][$section] ?? [];
    $original = field('original');
    $position = null;
    foreach ($rows as $index => $row) {
        if ($row['id'] === $original) {
            $position = $index;
            break;
        }
    }
    if ($original !== '' && $position === null) {
        throw new InvalidArgumentException('العنصر غير موجود في المسودة.');
    }
    if ($section === 'names' && !$delete && $original === '' && field('bulk') !== '') {
        $payload['library'][$section] = namesWithBulk($rows, field('bulk'));
        return $payload;
    }
    if ($delete) {
        if ($position === null) {
            throw new InvalidArgumentException('اختر عنصرًا لحذفه.');
        }
        array_splice($rows, $position, 1);
    } else {
        $id = $original === '' ? bin2hex(random_bytes(12)) : $original;
        $row = ['id' => $id, 'title' => label()];
        if ($section === 'names') {
            $row = ['id' => $id, 'number' => integer(field('number'), 1, 999)] + $row;
            $row['body'] = ['ar' => contentText('body_ar', 6000), 'en' => contentText('body_en', 6000, false)];
            $vocalized = contentText('vocalized', 120, false);
            if ($vocalized !== '') {
                $row['vocalized'] = $vocalized;
            }
            foreach (array_keys(NAME_TEXTS) as $key) {
                $pair = array_filter([
                    'ar' => contentText("{$key}_ar", 12000, false),
                    'en' => contentText("{$key}_en", 12000, false),
                ], static fn (string $value): bool => $value !== '');
                if ($pair !== []) {
                    $row[$key] = $pair;
                }
            }
            if (field('source') !== '') {
                $row['source'] = sourceLink('source');
            }
        } elseif ($section === 'fiqh') {
            $row['positions'] = [];
            foreach (SCHOOLS as $key => $school) {
                if (field("ar_$key") === '' && field("en_$key") === '') {
                    continue;
                }
                $row['positions'][] = [
                    'school' => $key,
                    'body' => ['ar' => contentText("ar_$key"), 'en' => contentText("en_$key")],
                    'source' => sourceLink("source_$key"),
                ];
            }
            if ($row['positions'] === []) {
                throw new InvalidArgumentException('أضف قولًا موثقًا لمذهب واحد على الأقل.');
            }
        } else {
            $row['body'] = ['ar' => contentText('body_ar'), 'en' => contentText('body_en')];
            $row['source'] = sourceLink('source');
            if ($section === 'lessons') {
                $row['questions'] = lessonQuestions();
            }
        }
        if ($position === null) {
            $rows[] = $row;
        } else {
            $rows[$position] = $row;
        }
    }
    if ($section === 'names') {
        usort($rows, static fn (array $a, array $b): int => ($a['number'] ?? 0) <=> ($b['number'] ?? 0));
    }
    $payload['library'][$section] = $rows;
    return $payload;
}

/** The longer texts of a name, each in Arabic and English, in display order. */
const NAME_TEXTS = [
    'description' => 'الشرح التفصيلي',
    'evidence' => 'الدليل الشرعي',
    'impact' => 'أثر الإيمان بالاسم',
    'dua' => 'الدعاء',
];

/** The 13 bulk fields, in order; the first four match the original format. */
const NAME_BULK_FIELDS = [
    'name_ar', 'transliteration', 'meaning_ar', 'meaning_en', 'name_ar_vocalized',
    'description_ar', 'description_en', 'evidence_ar', 'evidence_en',
    'impact_ar', 'impact_en', 'dua_ar', 'dua_en',
];

/**
 * Adds names pasted one per line, fields separated by «|» in the order of
 * NAME_BULK_FIELDS (only the first three are required). A line for a name
 * already listed updates it: filled fields replace, empty ones keep what
 * is there.
 */
function namesWithBulk(array $rows, string $text): array
{
    $byName = [];
    foreach ($rows as $index => $row) {
        $byName[$row['title']['ar']] = $index;
    }
    $added = 0;
    foreach (preg_split('/\R/u', $text) as $line) {
        if (trim($line) === '') {
            continue;
        }
        $parts = array_map('trim', explode('|', $line));
        if (count($parts) > count(NAME_BULK_FIELDS)) {
            throw new InvalidArgumentException('السطر فيه أكثر من ١٣ حقلًا؛ لا تستخدم «|» داخل النص. السطر: ' . mb_substr($line, 0, 60));
        }
        $parts = array_pad($parts, count(NAME_BULK_FIELDS), '');
        $value = array_combine(NAME_BULK_FIELDS, $parts);
        if ($value['name_ar'] === '' || $value['meaning_ar'] === '') {
            throw new InvalidArgumentException('كل سطر يحتاج على الأقل: الاسم | النطق بالإنجليزية | المعنى بالعربية. السطر: ' . mb_substr($line, 0, 60));
        }
        if (mb_strlen($value['name_ar']) > 60 || mb_strlen($value['transliteration']) > 80 ||
            mb_strlen($value['name_ar_vocalized']) > 120) {
            throw new InvalidArgumentException('الاسم أو نطقه أطول من المسموح. السطر: ' . mb_substr($line, 0, 60));
        }
        foreach ($value as $field => $content) {
            if (mb_strlen($content) > 12000) {
                throw new InvalidArgumentException("الحقل {$field} أطول من المسموح.");
            }
        }
        $name = $value['name_ar'];
        $existing = isset($byName[$name]) ? $rows[$byName[$name]] : [];
        // Filled fields replace; empty ones keep the existing text.
        $pick = static fn (string $new, ?string $old): string => $new !== '' ? $new : (string) $old;
        $row = $existing;
        $row['title'] = [
            'ar' => $name,
            'en' => $pick($value['transliteration'], $existing['title']['en'] ?? null) ?: $name,
        ];
        $row['body'] = [
            'ar' => $value['meaning_ar'],
            'en' => $pick($value['meaning_en'], $existing['body']['en'] ?? null),
        ];
        $vocalized = $pick($value['name_ar_vocalized'], $existing['vocalized'] ?? null);
        if ($vocalized !== '') {
            $row['vocalized'] = $vocalized;
        }
        foreach (array_keys(NAME_TEXTS) as $key) {
            $pair = array_filter([
                'ar' => $pick($value["{$key}_ar"], $existing[$key]['ar'] ?? null),
                'en' => $pick($value["{$key}_en"], $existing[$key]['en'] ?? null),
            ], static fn (string $text): bool => $text !== '');
            if ($pair !== []) {
                $row[$key] = $pair;
            }
        }
        if (isset($byName[$name])) {
            $rows[$byName[$name]] = $row;
        } else {
            $rows[] = ['id' => bin2hex(random_bytes(12)), 'number' => count($rows) + 1] + $row;
            $byName[$name] = count($rows) - 1;
        }
        $added++;
    }
    if ($added === 0 || count($rows) > 150) {
        throw new InvalidArgumentException('الصق سطرًا واحدًا على الأقل (١٥٠ اسمًا على الأكثر).');
    }
    usort($rows, static fn (array $a, array $b): int => ($a['number'] ?? 0) <=> ($b['number'] ?? 0));
    return $rows;
}

function defaultReaders(): array
{
    return [
        ['id' => '159', 'ar' => 'ماهر المعيقلي', 'en' => 'Maher Al Muaiqly', 'source' => 'Quran Foundation · MP3Quran', 'enabled' => true],
        ['id' => 'mp3quran-121', 'ar' => 'محمود علي البنا', 'en' => 'Mahmoud Ali Al-Banna', 'source' => 'Yousef Heiba · MP3Quran', 'enabled' => true],
        ['id' => 'mp3quran-253', 'ar' => 'إسلام صبحي', 'en' => 'Islam Sobhi', 'source' => 'Yousef Heiba · MP3Quran', 'enabled' => true],
    ];
}

function availableReaders(): array
{
    $licensed = require __DIR__ . '/reader-sources.php';
    return array_column(array_merge(defaultReaders(), $licensed), null, 'id');
}

function changeReaders(array $payload, bool $delete): array
{
    $readers = $payload['reciters'] ?? defaultReaders();
    $catalog = availableReaders();
    $id = field('reader');
    if ($delete) {
        foreach ($readers as &$reader) {
            if ($reader['id'] === $id) {
                $reader['enabled'] = false;
            }
        }
        unset($reader);
    } else {
        if (!isset($catalog[$id])) {
            throw new InvalidArgumentException('القارئ المطلوب غير موجود في قائمة المصادر.');
        }
        $current = $catalog[$id];
        $current['enabled'] = true;
        $indexed = array_column($readers, null, 'id');
        $indexed[$id] = $current;
        $readers = array_values($indexed);
    }
    $payload['reciters'] = $readers;
    return $payload;
}
