<?php
declare(strict_types=1);

function field(string $key): string
{
    $value = $_POST[$key] ?? '';
    if (!is_string($value)) {
        throw new InvalidArgumentException('قيمة الحقل غير صالحة.');
    }
    return trim($value);
}

function integer(string $value, int $min, int $max): int
{
    $number = filter_var($value, FILTER_VALIDATE_INT, [
        'options' => ['min_range' => $min, 'max_range' => $max],
    ]);
    if ($number === false) {
        throw new InvalidArgumentException('راجع الأرقام في النموذج.');
    }
    return $number;
}

function label(): array
{
    $ar = field('ar');
    $en = field('en');
    if ($ar === '' || $en === '' || strlen($ar) > 540 || strlen($en) > 540) {
        throw new InvalidArgumentException('اكتب عنوانًا بالعربية وآخر بالإنجليزية.');
    }
    return ['ar' => $ar, 'en' => $en];
}

function topics(): array
{
    return [
        'forgiveness' => 'الاستغفار', 'guidance' => 'الهداية',
        'family' => 'الوالدان والأسرة', 'hardship' => 'الشدائد',
        'gratitude' => 'الشكر', 'worship' => 'العبادة',
        'hereafter' => 'الآخرة', 'protection' => 'الحفظ والاستعاذة',
    ];
}

function verseRange(int $surah, int $first, int $last, array $ayahCounts): array
{
    if ($surah < 1 || !isset($ayahCounts[$surah - 1]) ||
        $first < 1 || $last < $first || $last > $ayahCounts[$surah - 1]) {
        throw new InvalidArgumentException('مرجع الآيات خارج حدود السورة.');
    }
    return [$surah, $first, $last];
}

function optionalJson(string $key): array
{
    $value = field($key);
    if ($value === '') {
        return [];
    }
    $decoded = json_decode($value, true, 16, JSON_THROW_ON_ERROR);
    if (!is_array($decoded) || !array_is_list($decoded)) {
        throw new InvalidArgumentException('تنسيق قائمة المراجع أو التكرار غير صالح.');
    }
    return $decoded;
}

function dhikr(string $id, array $ayahCounts): array
{
    if ($id === 'new' || !preg_match('/\A[a-z0-9][a-z0-9-]{0,63}\z/', $id)) {
        throw new InvalidArgumentException('معرّف الذكر بحروف إنجليزية صغيرة وأرقام وشرطة.');
    }
    $data = ['id' => $id, 'title' => label()];
    $variants = optionalJson('variants');
    if ($variants === []) {
        $data['hadith'] = integer(field('hadith'), 1, 99999999);
        $repeat = optionalJson('repeat');
        if ($repeat !== []) {
            validateRepeat($repeat);
            $data['repeat'] = $repeat;
        }
    } else {
        foreach ($variants as $variant) {
            if (!is_array($variant) || !is_int($variant['hadith'] ?? null) ||
                $variant['hadith'] < 1 || $variant['hadith'] > 99999999) {
                throw new InvalidArgumentException('كل صيغة تحتاج رقم حديث صحيحًا.');
            }
            validateRepeat($variant['repeat'] ?? []);
        }
        $data['variants'] = $variants;
    }
    $ranges = [];
    foreach (optionalJson('quran') as $range) {
        if (!is_array($range) || !array_is_list($range) || count($range) !== 3 ||
            array_filter($range, fn ($n) => !is_int($n)) !== []) {
            throw new InvalidArgumentException('مرجع القرآن يتكوّن من رقم السورة وأول وآخر آية.');
        }
        $ranges[] = verseRange($range[0], $range[1], $range[2], $ayahCounts);
    }
    if ($ranges !== []) {
        $data['quran'] = $ranges;
    }
    $wording = field('wording');
    $meaning = field('meaning');
    if (strlen($wording) > 12000 || strlen($meaning) > 12000) {
        throw new InvalidArgumentException('اختصر نص الذكر أو الترجمة.');
    }
    if ($wording !== '' || $meaning !== '') {
        $data['wording'] = array_filter([
            'ar' => $wording, 'draftMeaningEn' => $meaning,
        ], fn ($value) => $value !== '');
    }
    return $data;
}

function validateRepeat(mixed $repeat): void
{
    if (!is_array($repeat) || !array_is_list($repeat) || count($repeat) > 25) {
        throw new InvalidArgumentException('قائمة التكرار غير صالحة.');
    }
    foreach ($repeat as $step) {
        if (!is_array($step) || !is_string($step['unit'] ?? null) ||
            trim($step['unit']) === '' || strlen($step['unit']) > 120 ||
            !is_int($step['count'] ?? null) || $step['count'] < 1 || $step['count'] > 1000) {
            throw new InvalidArgumentException('كل خطوة تحتاج اسمًا وعدد تكرار صحيحًا.');
        }
    }
}

function contentRows(array $payload, string $section, string $topic): array
{
    return match ($section) {
        'daily' => $payload['adhkar']['daily']['entries'],
        'merits' => $payload['adhkar']['merits'],
        'hisn' => $payload['adhkar']['hisn']['topics'],
        'duas' => $payload['duas'][$topic],
        default => throw new InvalidArgumentException('القسم غير موجود.'),
    };
}

function numberList(string $text, int $minimum, int $maximum): array
{
    if ($text === '') {
        return [];
    }
    $values = preg_split('/[\s,،]+/u', $text, -1, PREG_SPLIT_NO_EMPTY);
    return array_values(array_unique(array_map(
        fn ($value) => integer($value, $minimum, $maximum),
        $values,
    )));
}

function changeContent(array $payload, array $ayahCounts, string $section, string $topic, bool $delete): array
{
    $rows = contentRows($payload, $section, $topic);
    $original = field('original');
    $position = null;
    if ($original !== '') {
        foreach ($rows as $index => $item) {
            $key = in_array($section, ['daily', 'merits'], true) ? $item['id'] : (string) $index;
            if ($key === $original) {
                $position = $index;
                break;
            }
        }
        if ($position === null) {
            throw new InvalidArgumentException('العنصر غير موجود في المسودة.');
        }
    }

    if ($delete) {
        if ($position === null) {
            throw new InvalidArgumentException('اختر العنصر المطلوب حذفه.');
        }
        array_splice($rows, $position, 1);
    } else {
        $item = match ($section) {
            'duas' => verseRange(
                integer(field('surah'), 1, 114),
                integer(field('first'), 1, 286),
                integer(field('last'), 1, 286),
                $ayahCounts,
            ),
            'hisn' => [
                'title' => label(),
                'chapterIds' => numberList(
                    field('chapters'), 0, count($payload['adhkar']['hisn']['chapterTitles']) - 1,
                ),
                'hadiths' => numberList(field('hadiths'), 1, 99999999),
            ],
            default => dhikr($original ?: field('id'), $ayahCounts),
        };
        if ($section === 'hisn' && $item['chapterIds'] === [] && $item['hadiths'] === []) {
            throw new InvalidArgumentException('أضف مرجعًا واحدًا على الأقل للموضوع.');
        }
        foreach ($rows as $index => $row) {
            if ($index !== $position &&
                (($section === 'duas' && $row === $item) ||
                 (isset($item['id']) && $row['id'] === $item['id']))) {
                throw new InvalidArgumentException('العنصر موجود بالفعل.');
            }
        }
        if ($position === null) {
            $rows[] = $item;
        } else {
            $rows[$position] = $item;
        }
    }

    if ($section === 'daily') {
        $payload['adhkar']['daily']['entries'] = $rows;
        $id = $original ?: field('id');
        $groups = $delete ? [] : ($_POST['groups'] ?? []);
        if (!is_array($groups) || (!$delete && $groups === []) ||
            array_filter($groups, fn ($group) => !is_string($group)) !== [] ||
            array_diff($groups, array_column($payload['adhkar']['daily']['groups'], 'id')) !== []) {
            throw new InvalidArgumentException('اختر مجموعة واحدة على الأقل للذكر.');
        }
        foreach ($payload['adhkar']['daily']['groups'] as &$group) {
            $included = in_array($id, $group['entries'], true);
            $selected = in_array($group['id'], $groups, true);
            if ($selected && !$included) {
                $group['entries'][] = $id;
            } elseif ($included && !$selected) {
                $group['entries'] = array_values(array_diff($group['entries'], [$id]));
            }
        }
        unset($group);
    } elseif ($section === 'merits') {
        $payload['adhkar']['merits'] = $rows;
    } elseif ($section === 'hisn') {
        $payload['adhkar']['hisn']['topics'] = $rows;
    } else {
        $payload['duas'][$topic] = $rows;
    }
    return $payload;
}
