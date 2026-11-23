<?php
declare(strict_types=1);

/*
 * App appearance managed from the dashboard: colours, corner radius and text
 * size. Stored in the library draft under "appearance" and published with it,
 * so the app picks it up from the feed it already downloads and keeps it
 * offline.
 */

const THEME_PRESETS = [
    'brand' => ['name' => 'الهوية الأصلية', 'note' => 'الأخضر والذهبي',
        'primary' => '#0F4A43', 'gold' => '#B8893A', 'background' => '#F5F0E6', 'ink' => '#12332F'],
    'ramadan' => ['name' => 'رمضان', 'note' => 'كحلي وذهبي',
        'primary' => '#1E2A4A', 'gold' => '#C9A24A', 'background' => '#F7F1E3', 'ink' => '#1A1F33'],
    'calm' => ['name' => 'هادئ', 'note' => 'أخضر فاتح',
        'primary' => '#2F5D50', 'gold' => '#A77B3B', 'background' => '#F2F4F1', 'ink' => '#1D2B27'],
    'sand' => ['name' => 'رملي', 'note' => 'بني دافئ',
        'primary' => '#5A3E22', 'gold' => '#B8893A', 'background' => '#F6EEDF', 'ink' => '#2E2214'],
];

const THEME_COLORS = [
    'primary' => 'اللون الأساسي',
    'gold' => 'اللون الذهبي',
    'background' => 'الخلفية',
    'ink' => 'لون النص',
];

function defaultTheme(): array
{
    $brand = THEME_PRESETS['brand'];
    return [
        'preset' => 'brand',
        'primary' => $brand['primary'],
        'gold' => $brand['gold'],
        'background' => $brand['background'],
        'ink' => $brand['ink'],
        'radius' => 16,
        'textScale' => 100,
        'ramadanAuto' => true,
    ];
}

/** The draft's theme with defaults filled in for older drafts. */
function currentTheme(array $draft): array
{
    $theme = $draft['appearance']['theme'] ?? [];
    return is_array($theme) ? array_merge(defaultTheme(), $theme) : defaultTheme();
}

function relativeLuminance(string $hex): float
{
    $channels = array_map(
        static function (string $pair): float {
            $value = hexdec($pair) / 255;
            return $value <= 0.03928 ? $value / 12.92 : (($value + 0.055) / 1.055) ** 2.4;
        },
        str_split(substr($hex, 1), 2),
    );
    return 0.2126 * $channels[0] + 0.7152 * $channels[1] + 0.0722 * $channels[2];
}

function contrastRatio(string $a, string $b): float
{
    $first = relativeLuminance($a);
    $second = relativeLuminance($b);
    return (max($first, $second) + 0.05) / (min($first, $second) + 0.05);
}

/**
 * Readability checks shown beside the editor; publishing is refused while
 * any of them fails (WCAG AA, 4.5:1 for body text).
 *
 * @return list<array{label: string, ratio: float, ok: bool}>
 */
function themeChecks(array $theme): array
{
    $checks = [
        ['label' => 'وضوح النص على الخلفية', 'ratio' => contrastRatio($theme['ink'], $theme['background'])],
        ['label' => 'وضوح الأزرار على اللون الأساسي', 'ratio' => contrastRatio('#FFFDF8', $theme['primary'])],
        ['label' => 'وضوح اللون الأساسي على الخلفية', 'ratio' => contrastRatio($theme['primary'], $theme['background'])],
    ];
    foreach ($checks as &$check) {
        $check['ok'] = $check['ratio'] >= 4.5;
    }
    unset($check);
    return $checks;
}

function themeColor(string $key): string
{
    $value = strtoupper(field($key));
    if (!preg_match('/\A#[0-9A-F]{6}\z/D', $value)) {
        throw new InvalidArgumentException('اختر لونًا صالحًا لكل حقل.');
    }
    return $value;
}

/** Applies the appearance form to the draft (action "save" or "delete"). */
function changeAppearance(array $payload, bool $reset): array
{
    if ($reset) {
        $payload['appearance']['theme'] = defaultTheme();
        return $payload;
    }
    $preset = field('preset');
    $theme = [
        'preset' => isset(THEME_PRESETS[$preset]) ? $preset : 'custom',
        'radius' => integer(field('radius'), 4, 32),
        'textScale' => integer(field('textScale'), 90, 125),
        'ramadanAuto' => field('ramadanAuto') === '1',
    ];
    // A preset button fills its colours; otherwise the colour fields apply.
    $applyPreset = field('apply_preset');
    if (isset(THEME_PRESETS[$applyPreset])) {
        $theme['preset'] = $applyPreset;
        foreach (array_keys(THEME_COLORS) as $key) {
            $theme[$key] = THEME_PRESETS[$applyPreset][$key];
        }
    } else {
        foreach (array_keys(THEME_COLORS) as $key) {
            $theme[$key] = themeColor($key);
        }
        $match = null;
        foreach (THEME_PRESETS as $id => $values) {
            $same = true;
            foreach (array_keys(THEME_COLORS) as $key) {
                $same = $same && $values[$key] === $theme[$key];
            }
            if ($same) {
                $match = $id;
            }
        }
        $theme['preset'] = $match ?? 'custom';
    }
    $payload['appearance']['theme'] = $theme;
    return $payload;
}

/** Refuses to publish a draft whose theme is hard to read. */
function assertReadableTheme(array $draft): void
{
    foreach (themeChecks(currentTheme($draft)) as $check) {
        if (!$check['ok']) {
            throw new InvalidArgumentException('ألوان الثيم غير واضحة بما يكفي (' . $check['label'] .
                '). عدّل الألوان من صفحة الثيم ثم انشر.');
        }
    }
}

/** Stylesheet for the dashboard's live preview, built from the draft. */
function servePreviewCss(array $draft): never
{
    $theme = currentTheme($draft);
    header('Content-Type: text/css; charset=utf-8');
    header('Cache-Control: no-store');
    $radius = (int) $theme['radius'];
    $scale = (int) $theme['textScale'] / 100;
    $values = [
        '--p-primary' => $theme['primary'],
        '--p-gold' => $theme['gold'],
        '--p-background' => $theme['background'],
        '--p-ink' => $theme['ink'],
        '--p-radius' => $radius . 'px',
        '--p-radius-small' => max(6, $radius - 6) . 'px',
        '--p-scale' => (string) $scale,
    ];
    echo '.phone{';
    foreach ($values as $name => $value) {
        // Values are validated hex colours and integers.
        echo $name . ':' . $value . ';';
    }
    echo '}';
    exit;
}
