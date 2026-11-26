<?php
declare(strict_types=1);

/** Readable names for the parts of the library shown in a diff. */
const DIFF_LABELS = [
    'adhkar' => 'الأذكار', 'daily' => 'أذكار اليوم', 'groups' => 'المجموعات', 'entries' => 'الأذكار',
    'dailyDuas' => 'دعاء اليوم', 'merits' => 'فضائل الذكر', 'hisn' => 'حصن المسلم', 'topics' => 'الموضوعات',
    'chapterTitles' => 'عناوين الأبواب', 'quranDuas' => 'الأدعية القرآنية', 'duas' => 'الأدعية',
    'forgiveness' => 'المغفرة', 'guidance' => 'الهداية', 'family' => 'الأهل', 'hardship' => 'الشدة',
    'gratitude' => 'الشكر', 'worship' => 'العبادة', 'hereafter' => 'الآخرة', 'protection' => 'الحفظ',
    'reciters' => 'القراء', 'appearance' => 'الثيم والأقسام', 'theme' => 'الألوان', 'sections' => 'أقسام المكتبة',
    'library' => 'المكتبة', 'fiqh' => 'الفقه', 'articles' => 'المقالات', 'lessons' => 'الدروس',
    'title' => 'العنوان', 'ar' => 'العربية', 'en' => 'الإنجليزية', 'enabled' => 'التفعيل', 'visible' => 'الظهور',
];

function diffLabel(array $path): string
{
    return implode(' › ', array_map(
        fn ($part) => is_int($part) ? '#' . arabicDigits((string) ($part + 1)) : (DIFF_LABELS[$part] ?? $part),
        $path,
    ));
}

function diffValue(mixed $value): string
{
    $text = is_scalar($value) || $value === null
        ? var_export($value, true)
        : encode($value);
    $text = trim($text, "'");
    return mb_strlen($text) > 80 ? mb_substr($text, 0, 80) . '…' : $text;
}

/** A short label for a list item: its id, or its title. */
function diffItem(array $item, int|string $key): string
{
    $title = $item['title']['ar'] ?? $item['ar'] ?? $item['title'] ?? null;
    $id = $item['id'] ?? $key;
    return is_string($title) ? "$title ($id)" : (string) $id;
}

/**
 * What would change if the draft were published, as readable lines:
 * items added, removed or edited (matched by id where items have one) and
 * values changed.
 *
 * @return list<array{kind: string, path: string, detail: string}>
 */
function libraryDiff(mixed $before, mixed $after, array $path = [], int $limit = 200): array
{
    $lines = [];
    $add = function (string $kind, array $where, string $detail) use (&$lines, $limit): void {
        if (count($lines) < $limit) {
            $lines[] = ['kind' => $kind, 'path' => diffLabel($where), 'detail' => $detail];
        }
    };
    if ($before === $after) {
        return [];
    }
    if (is_array($before) && is_array($after)) {
        $keyed = array_is_list($before) && array_is_list($after)
            && array_reduce([...$before, ...$after], fn ($ok, $item) => $ok && is_array($item) && isset($item['id']), true);
        if ($keyed) {
            $old = array_column($before, null, 'id');
            $new = array_column($after, null, 'id');
            foreach ($new as $id => $item) {
                if (!isset($old[$id])) {
                    $add('added', $path, diffItem($item, $id));
                } elseif ($old[$id] !== $item) {
                    foreach (libraryDiff($old[$id], $item, [...$path, diffItem($item, $id)], $limit) as $line) {
                        $lines[] = $line;
                    }
                }
            }
            foreach ($old as $id => $item) {
                if (!isset($new[$id])) {
                    $add('removed', $path, diffItem($item, $id));
                }
            }
            if (array_keys($old) !== array_keys($new) && array_intersect_key($old, $new) === $old && count($old) === count($new)) {
                $add('changed', $path, 'تغيّر الترتيب');
            }
            return array_slice($lines, 0, $limit);
        }
        if (array_is_list($before) && array_is_list($after) && count($before) !== count($after)
            && !array_filter([...$before, ...$after], 'is_array')) {
            $add('changed', $path, arabicDigits((string) count($before)) . ' ← ' . arabicDigits((string) count($after)) . ' عنصر');
            return $lines;
        }
        foreach (array_unique([...array_keys($before), ...array_keys($after)]) as $key) {
            if (!array_key_exists($key, $before)) {
                $add('added', [...$path, $key], diffValue($after[$key]));
            } elseif (!array_key_exists($key, $after)) {
                $add('removed', [...$path, $key], diffValue($before[$key]));
            } else {
                foreach (libraryDiff($before[$key], $after[$key], [...$path, $key], $limit) as $line) {
                    $lines[] = $line;
                }
            }
        }
        return array_slice($lines, 0, $limit);
    }
    $add('changed', $path, diffValue($before) . ' ← ' . diffValue($after));
    return $lines;
}
