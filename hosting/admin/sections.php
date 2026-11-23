<?php
declare(strict_types=1);

/*
 * Library sections managed from the dashboard: order, visibility, and new
 * sections made of titled links (for example a series of tafsir videos).
 * Stored in the draft under "appearance.sections" and published with it.
 */

/** Built-in library entries; they can be hidden or moved, never deleted. */
const BUILTIN_SECTIONS = [
    'duas' => 'الأدعية القرآنية',
    'hadith' => 'الحديث',
    'fiqh' => 'الفقه المقارن',
    'articles' => 'المقالات',
    'stories' => 'قصص الأنبياء',
    'lessons' => 'الأكاديمية (الدروس والاختبارات)',
    'radio' => 'إذاعة القرآن من القاهرة',
];

const MAX_CUSTOM_SECTIONS = 20;
const MAX_SECTION_ITEMS = 200;

function defaultSections(): array
{
    return array_map(
        static fn (string $id): array => ['id' => $id, 'kind' => 'builtin', 'visible' => true],
        array_keys(BUILTIN_SECTIONS),
    );
}

/** The draft's sections, with any built-in entry missing from it appended. */
function currentSections(array $draft): array
{
    $sections = $draft['appearance']['sections'] ?? null;
    if (!is_array($sections)) {
        return defaultSections();
    }
    $present = array_column($sections, 'id');
    foreach (array_keys(BUILTIN_SECTIONS) as $id) {
        if (!in_array($id, $present, true)) {
            $sections[] = ['id' => $id, 'kind' => 'builtin', 'visible' => true];
        }
    }
    return array_values($sections);
}

function sectionLabel(array $section): string
{
    return $section['kind'] === 'builtin'
        ? BUILTIN_SECTIONS[$section['id']] ?? $section['id']
        : (string) ($section['title']['ar'] ?? $section['id']);
}

function sectionIndex(array $sections, string $id): int
{
    foreach ($sections as $index => $section) {
        if ($section['id'] === $id) {
            return $index;
        }
    }
    throw new InvalidArgumentException('القسم غير موجود في المسودة.');
}

function httpsLink(string $key): string
{
    $url = field($key);
    $parts = parse_url($url);
    if ($url === '' || strlen($url) > 2048 || $parts === false ||
        ($parts['scheme'] ?? '') !== 'https' || empty($parts['host']) ||
        isset($parts['user']) || isset($parts['pass'])) {
        throw new InvalidArgumentException('أدخل رابطًا صالحًا يبدأ بـ HTTPS.');
    }
    return $url;
}

function bilingual(string $prefix, bool $required = true, int $limit = 300): array
{
    $ar = field($prefix . '_ar');
    $en = field($prefix . '_en');
    if (($required && ($ar === '' || $en === '')) || strlen($ar) > $limit || strlen($en) > $limit) {
        throw new InvalidArgumentException('اكتب العنوان بالعربية والإنجليزية.');
    }
    return ['ar' => $ar, 'en' => $en];
}

/** Applies one sections change to the draft ("save" ops, or "delete"). */
function changeSections(array $payload, bool $delete): array
{
    $sections = currentSections($payload);
    $operation = $delete ? 'delete' : field('op');
    $id = field('id');
    switch ($operation) {
        case 'toggle':
            $index = sectionIndex($sections, $id);
            $sections[$index]['visible'] = !($sections[$index]['visible'] ?? true);
            break;
        case 'up':
        case 'down':
            $index = sectionIndex($sections, $id);
            $target = $operation === 'up' ? $index - 1 : $index + 1;
            if ($target >= 0 && $target < count($sections)) {
                [$sections[$index], $sections[$target]] = [$sections[$target], $sections[$index]];
            }
            break;
        case 'add':
            $custom = array_filter($sections, static fn (array $s): bool => $s['kind'] !== 'builtin');
            if (count($custom) >= MAX_CUSTOM_SECTIONS) {
                throw new InvalidArgumentException('وصلت للحد الأقصى من الأقسام الإضافية.');
            }
            $sections[] = [
                'id' => 's-' . bin2hex(random_bytes(6)),
                'kind' => 'links',
                'visible' => true,
                'title' => bilingual('title'),
                'subtitle' => bilingual('subtitle', false),
                'items' => [],
            ];
            break;
        case 'rename':
            $index = sectionIndex($sections, $id);
            if ($sections[$index]['kind'] === 'builtin') {
                throw new InvalidArgumentException('لا يمكن تغيير اسم قسم أساسي.');
            }
            $sections[$index]['title'] = bilingual('title');
            $sections[$index]['subtitle'] = bilingual('subtitle', false);
            break;
        case 'add_item':
            $index = sectionIndex($sections, $id);
            if ($sections[$index]['kind'] !== 'links') {
                throw new InvalidArgumentException('أضف الروابط إلى قسم إضافي فقط.');
            }
            if (count($sections[$index]['items']) >= MAX_SECTION_ITEMS) {
                throw new InvalidArgumentException('وصل القسم للحد الأقصى من الروابط.');
            }
            $sections[$index]['items'][] = ['title' => bilingual('item'), 'url' => httpsLink('url')];
            break;
        case 'remove_item':
            $index = sectionIndex($sections, $id);
            $item = integer(field('item'), 0, MAX_SECTION_ITEMS);
            if (!isset($sections[$index]['items'][$item])) {
                throw new InvalidArgumentException('الرابط غير موجود.');
            }
            array_splice($sections[$index]['items'], $item, 1);
            break;
        case 'delete':
            $index = sectionIndex($sections, $id);
            if ($sections[$index]['kind'] === 'builtin') {
                throw new InvalidArgumentException('الأقسام الأساسية تُخفى ولا تُحذف.');
            }
            array_splice($sections, $index, 1);
            break;
        default:
            throw new InvalidArgumentException('الإجراء غير متاح.');
    }
    $payload['appearance']['sections'] = array_values($sections);
    return $payload;
}
