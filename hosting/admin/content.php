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
    $wording = field('wording');
    $meaning = field('meaning');
    if (strlen($wording) > 12000 || strlen($meaning) > 12000) {
        throw new InvalidArgumentException('اختصر نص الذكر أو الترجمة.');
    }
    // Without a HadeethEnc number the dhikr is the dashboard's own text.
    $own = $variants === [] && field('hadith') === '';
    if ($own && $wording === '') {
        throw new InvalidArgumentException('اكتب نص الذكر بالعربية، أو رقم الحديث في HadeethEnc.');
    }
    if ($variants === []) {
        if (!$own) {
            $data['hadith'] = integer(field('hadith'), 1, 99999999);
        }
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
    if ($wording !== '' || $meaning !== '') {
        // An own dhikr's English is its meaning; a narration's stays a draft
        // beside the source's own translation.
        $data['wording'] = array_filter([
            'ar' => $wording, $own ? 'en' : 'draftMeaningEn' => $meaning,
        ], fn ($value) => $value !== '');
    }
    $source = sourceLabel();
    if ($source !== null) {
        $data['source'] = $source;
    }
    return $data;
}

/** The «المصدر» line shown under an own dhikr, e.g. «رواه مسلم». */
function sourceLabel(): ?array
{
    $ar = field('source_ar');
    $en = field('source_en');
    if (mb_strlen($ar) > 300 || mb_strlen($en) > 300) {
        throw new InvalidArgumentException('اختصر سطر المصدر.');
    }
    return $ar === '' && $en === '' ? null : array_filter(['ar' => $ar, 'en' => $en], fn ($v) => $v !== '');
}

/**
 * Own items of a Hisn al-Muslim topic, written as blocks separated by a
 * line «---». Inside a block: «العنوان:», «Title:», «المصدر:», «Source:»
 * and «English:» lines; every other line is the Arabic text.
 */
function hisnOwnItems(string $text): array
{
    $items = [];
    foreach (preg_split('/^\s*-{3,}\s*$/mu', str_replace("\r", '', $text)) as $block) {
        $fields = ['ar' => [], 'title' => '', 'titleEn' => '', 'source' => '', 'sourceEn' => '', 'en' => []];
        foreach (explode("\n", $block) as $line) {
            $trimmed = trim($line);
            if (preg_match('/\A(العنوان|Title|المصدر|Source|English)\s*:\s*(.*)\z/u', $trimmed, $match)) {
                match ($match[1]) {
                    'العنوان' => $fields['title'] = $match[2],
                    'Title' => $fields['titleEn'] = $match[2],
                    'المصدر' => $fields['source'] = $match[2],
                    'Source' => $fields['sourceEn'] = $match[2],
                    default => $fields['en'][] = $match[2],
                };
            } else {
                $fields['ar'][] = $trimmed;
            }
        }
        $arabic = trim(implode("\n", $fields['ar']));
        if ($arabic === '') {
            continue;
        }
        if (mb_strlen($arabic) > 6000 || count($items) >= 60) {
            throw new InvalidArgumentException('اختصر الأذكار الخاصة بالموضوع (٦٠ ذكرًا على الأكثر).');
        }
        $words = preg_split('/\s+/u', $arabic);
        $title = $fields['title'] !== '' ? $fields['title']
            : implode(' ', array_slice($words, 0, 6)) . (count($words) > 6 ? '…' : '');
        $item = [
            'id' => 'own-' . substr(hash('sha256', $arabic), 0, 12),
            'title' => ['ar' => $title, 'en' => $fields['titleEn'] !== '' ? $fields['titleEn'] : $title],
            'wording' => array_filter(['ar' => $arabic, 'en' => trim(implode("\n", $fields['en']))], fn ($v) => $v !== ''),
        ];
        if ($fields['source'] !== '' || $fields['sourceEn'] !== '') {
            $item['source'] = array_filter(['ar' => $fields['source'], 'en' => $fields['sourceEn']], fn ($v) => $v !== '');
        }
        $items[] = $item;
    }
    return $items;
}

/** The same items written back in the editor's text format. */
function hisnOwnText(array $items): string
{
    $blocks = [];
    foreach ($items as $item) {
        $lines = [];
        $lines[] = 'العنوان: ' . ($item['title']['ar'] ?? '');
        if (($item['title']['en'] ?? '') !== ($item['title']['ar'] ?? '')) {
            $lines[] = 'Title: ' . $item['title']['en'];
        }
        $lines[] = $item['wording']['ar'] ?? '';
        if (($item['wording']['en'] ?? '') !== '') {
            $lines[] = 'English: ' . $item['wording']['en'];
        }
        if (($item['source']['ar'] ?? '') !== '') {
            $lines[] = 'المصدر: ' . $item['source']['ar'];
        }
        if (($item['source']['en'] ?? '') !== '') {
            $lines[] = 'Source: ' . $item['source']['en'];
        }
        $blocks[] = implode("\n", $lines);
    }
    return implode("\n---\n", $blocks);
}

/** Whether the library holds dashboard-written adhkar (feed shape 2). */
function hasOwnAdhkar(array $payload): bool
{
    $adhkar = $payload['adhkar'] ?? [];
    foreach ([...($adhkar['daily']['entries'] ?? []), ...($adhkar['merits'] ?? [])] as $entry) {
        if (!isset($entry['hadith']) && !isset($entry['variants'])) {
            return true;
        }
    }
    foreach ($adhkar['hisn']['topics'] ?? [] as $topic) {
        if (($topic['entries'] ?? []) !== []) {
            return true;
        }
    }
    return false;
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
        'daily_duas' => $payload['dailyDuas'] ?? (require __DIR__ . '/daily-duas-seed.php'),
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
            $key = in_array($section, ['daily', 'merits', 'daily_duas'], true) ? $item['id'] : (string) ($item['id'] ?? $index);
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
            'hisn' => array_filter([
                'title' => label(),
                'chapterIds' => numberList(
                    field('chapters'), 0, count($payload['adhkar']['hisn']['chapterTitles']) - 1,
                ),
                'hadiths' => numberList(field('hadiths'), 1, 99999999),
                'entries' => hisnOwnItems(field('own_items')),
            ], fn ($value, $key) => $key !== 'entries' || $value !== [], ARRAY_FILTER_USE_BOTH),
            default => dhikr($original ?: field('id'), $ayahCounts),
        };
        $previous = $position === null ? [] : $rows[$position];
        if (in_array($section, ['daily', 'merits', 'daily_duas'], true)) {
            $item = devotionalEntryAudio($item, $previous, 'main');
        } elseif ($section === 'hisn' && isset($item['entries'])) {
            $old = array_column($previous['entries'] ?? [], null, 'id');
            foreach ($item['entries'] as &$entry) {
                $id = $entry['id'];
                $entry = devotionalEntryAudio($entry, $old[$id] ?? [], $id);
            }
            unset($entry);
        }
        // A Hisn topic keeps its id across edits.
        if ($section === 'hisn' && $position !== null && isset($rows[$position]['id'])) {
            $item = ['id' => $rows[$position]['id']] + $item;
        }
        if ($section === 'hisn' && $item['chapterIds'] === [] && $item['hadiths'] === [] && !isset($item['entries'])) {
            throw new InvalidArgumentException('أضف ذكرًا خاصًا أو مرجعًا واحدًا على الأقل للموضوع.');
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

    if ($section === 'daily_duas') {
        if ($rows === []) {
            throw new InvalidArgumentException('احتفظ بدعاء واحد على الأقل.');
        }
        $texts = [];
        foreach ($rows as $row) {
            $text = trim($row['wording']['ar'] ?? '');
            if ($text === '' || trim($row['wording']['en'] ?? '') === '' ||
                trim($row['source']['ar'] ?? '') === '' || trim($row['source']['en'] ?? '') === '' ||
                isset($row['hadith']) || isset($row['variants'])) {
                throw new InvalidArgumentException('اكتب نص الدعاء وترجمته ومصدره بالعربية والإنجليزية دون جلب حديث آلي.');
            }
            if (isset($texts[$text])) {
                throw new InvalidArgumentException('نص الدعاء موجود بالفعل.');
            }
            $texts[$text] = true;
        }
        $payload['dailyDuas'] = $rows;
    } elseif ($section === 'daily') {
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
