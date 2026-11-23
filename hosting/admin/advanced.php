<?php
declare(strict_types=1);

const BOOK_SECTIONS = ['fiqh', 'articles', 'lessons'];
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
    if ($delete) {
        if ($position === null) {
            throw new InvalidArgumentException('اختر عنصرًا لحذفه.');
        }
        array_splice($rows, $position, 1);
    } else {
        $id = $original === '' ? bin2hex(random_bytes(12)) : $original;
        $row = ['id' => $id, 'title' => label()];
        if ($section === 'fiqh') {
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
    $payload['library'][$section] = $rows;
    return $payload;
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
