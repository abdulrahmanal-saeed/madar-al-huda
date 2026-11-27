<?php
declare(strict_types=1);

require_once __DIR__ . '/palette-defaults.php';

const PALETTE_PROFILES = [
    'regular-light' => 'العادي · فاتح', 'regular-dark' => 'العادي · داكن',
    'ramadan-light' => 'رمضان · فاتح', 'ramadan-dark' => 'رمضان · داكن',
    'eid-light' => 'العيد · فاتح', 'eid-dark' => 'العيد · داكن',
];
const PALETTE_ROLE_GROUPS = [
    'الأزرار والعناصر المميزة' => [
        'primary' => 'اللون الأساسي', 'onPrimary' => 'النص على الأساسي',
        'primaryContainer' => 'حاوية اللون الأساسي', 'onPrimaryContainer' => 'النص على الحاوية الأساسية',
        'secondary' => 'اللون الثانوي', 'onSecondary' => 'النص على الثانوي',
        'secondaryContainer' => 'حاوية اللون الثانوي', 'onSecondaryContainer' => 'النص على الحاوية الثانوية',
        'tertiary' => 'اللون الثالث', 'onTertiary' => 'النص على اللون الثالث',
        'tertiaryContainer' => 'حاوية اللون الثالث', 'onTertiaryContainer' => 'النص على الحاوية الثالثة',
    ],
    'الخلفيات والنصوص' => [
        'surface' => 'الخلفية', 'onSurface' => 'النص الأساسي', 'onSurfaceVariant' => 'النص الثانوي',
        'surfaceDim' => 'الخلفية الخافتة', 'surfaceBright' => 'الخلفية البارزة',
        'surfaceContainerLowest' => 'أخف حاوية', 'surfaceContainerLow' => 'خلفية البطاقات',
        'surfaceContainer' => 'الحاوية العادية', 'surfaceContainerHigh' => 'الحاوية المرتفعة',
        'surfaceContainerHighest' => 'الحاوية الأبرز', 'outline' => 'الحدود', 'outlineVariant' => 'الفواصل',
        'inverseSurface' => 'الخلفية المعكوسة', 'onInverseSurface' => 'النص على المعكوسة',
        'inversePrimary' => 'الأساسي على المعكوسة',
    ],
    'واجهة اليوم والافتتاح' => [
        'heroStart' => 'بداية تدرج بطاقة القراءة', 'heroEnd' => 'نهاية التدرج',
        'heroInk' => 'نص بطاقة القراءة', 'splash' => 'الخلفية حول صورة الافتتاح',
    ],
    'الحالات والتأثيرات' => [
        'error' => 'لون الخطأ', 'onError' => 'النص على الخطأ',
        'errorContainer' => 'خلفية رسالة الخطأ', 'onErrorContainer' => 'نص رسالة الخطأ',
        'shadow' => 'الظل', 'scrim' => 'التعتيم', 'surfaceTint' => 'صبغة الخلفية',
    ],
];

function defaultTheme(): array
{
    return [
        'preset' => 'brand',
        'primary' => PALETTE_LEGACY['primaryGreen'],
        'gold' => PALETTE_LEGACY['mutedGold'],
        'background' => PALETTE_LEGACY['ivory'],
        'ink' => PALETTE_LEGACY['darkInk'],
        'radius' => 16,
        'textScale' => 100,
        'ramadanAuto' => true,
    ];
}

function currentTheme(array $draft): array
{
    $theme = $draft['appearance']['theme'] ?? [];
    return is_array($theme) ? array_merge(defaultTheme(), $theme) : defaultTheme();
}

function paletteProfile(mixed $profile): string
{
    return is_string($profile) && isset(PALETTE_PROFILES[$profile]) ? $profile : 'regular-light';
}

function relativeLuminance(string $hex): float
{
    $channels = array_map(
        static function (string $pair): float {
            $value = hexdec($pair) / 255;
            return $value <= 0.04045 ? $value / 12.92 : (($value + 0.055) / 1.055) ** 2.4;
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

function paletteAlpha(string $role): bool
{
    return in_array($role, ['outlineVariant', 'surfaceTint'], true);
}

function paletteColor(string $role, mixed $color): bool
{
    return is_string($color) && preg_match(
        paletteAlpha($role) ? '/\A#(?:[0-9A-F]{6}|[0-9A-F]{8})\z/iD' : '/\A#[0-9A-F]{6}\z/iD',
        $color,
    ) === 1;
}

function currentPalettes(array $draft): array
{
    $saved = $draft['appearance']['palettes']['profiles'] ?? null;
    if (is_array($saved)) {
        $profiles = PALETTE_DEFAULTS;
        foreach ($profiles as $profile => &$colors) {
            foreach ($colors as $role => &$color) {
                $submitted = $saved[$profile][$role] ?? null;
                if (paletteColor($role, $submitted)) {
                    $color = $submitted;
                }
            }
            unset($color);
        }
        unset($colors);
        return $profiles;
    }

    $profiles = PALETTE_DEFAULTS;
    $legacy = currentTheme($draft);
    if (!legacyThemeReadable($legacy)) {
        return $profiles;
    }
    // Preserve an existing custom palette on first edit, while the legacy
    // built-in green values already mapped to the new brand in Flutter.
    $stock = defaultTheme();
    $roles = ['primary', 'gold', 'background', 'ink'];
    if (array_map(fn ($role) => $legacy[$role], $roles) ===
        array_map(fn ($role) => $stock[$role], $roles)) {
        return $profiles;
    }

    $light = $profiles['regular-light'];
    foreach (['surface', 'surfaceDim', 'surfaceBright', 'surfaceContainerLowest',
        'surfaceContainerLow', 'surfaceContainer', 'surfaceContainerHigh', 'surfaceContainerHighest',
        'onInverseSurface'] as $role) {
        $light[$role] = $legacy['background'];
    }
    foreach (['onSurface', 'onSurfaceVariant', 'inverseSurface', 'outline'] as $role) {
        $light[$role] = $legacy['ink'];
    }
    $light['primary'] = $legacy['primary'];
    $light['onPrimary'] = PALETTE_LEGACY['paper'];
    if (contrastRatio($legacy['gold'], $legacy['background']) >= 4.5) {
        $light['secondary'] = $legacy['gold'];
        $light['onSecondary'] = contrastRatio('#FFFFFF', $legacy['gold']) >= 4.5 ? '#FFFFFF' : '#000000';
    } elseif (contrastRatio($light['secondary'], $light['surface']) < 4.5) {
        $light['secondary'] = $light['primary'];
        $light['onSecondary'] = $light['onPrimary'];
    }
    $profiles['regular-light'] = $light;
    return $profiles;
}

function legacyThemeReadable(array $theme): bool
{
    foreach (['primary', 'gold', 'background', 'ink'] as $role) {
        if (!paletteColor($role, $theme[$role] ?? null)) {
            return false;
        }
    }
    return contrastRatio($theme['ink'], $theme['background']) >= 4.5 &&
        contrastRatio(PALETTE_LEGACY['paper'], $theme['primary']) >= 4.5 &&
        contrastRatio($theme['primary'], $theme['background']) >= 4.5;
}

function paletteChecks(array $colors): array
{
    $labels = array_merge(...array_values(PALETTE_ROLE_GROUPS));
    $checks = [];
    foreach (PALETTE_CONTRAST_PAIRS as [$foreground, $background]) {
        $ratio = contrastRatio($colors[$foreground], $colors[$background]);
        $checks[] = ['label' => $labels[$foreground] . ' / ' . $labels[$background],
            'ratio' => $ratio, 'ok' => $ratio >= 4.5];
    }
    return $checks;
}

function changeAppearance(array $payload, bool $reset): array
{
    $profiles = currentPalettes($payload);
    $profile = paletteProfile($_GET['profile'] ?? null);
    $theme = currentTheme($payload);
    if ($reset) {
        $profiles[$profile] = PALETTE_DEFAULTS[$profile];
    } else {
        $posted = $_POST['palette'] ?? null;
        if (!is_array($posted)) {
            throw new InvalidArgumentException('اختر ألوان اللوحة.');
        }
        foreach ($profiles[$profile] as $role => &$color) {
            $value = $posted[$role] ?? null;
            if (!paletteColor($role, $value)) {
                throw new InvalidArgumentException('راجع تنسيق ألوان اللوحة.');
            }
            $color = strtoupper($value);
        }
        unset($color);
        $theme['radius'] = integer(field('radius'), 4, 32);
        $theme['textScale'] = integer(field('textScale'), 90, 125);
    }

    $payload['appearance']['theme'] = legacyThemeReadable($theme)
        ? $theme
        : array_replace(defaultTheme(), array_intersect_key($theme, array_flip(['radius', 'textScale'])));
    $payload['appearance']['palettes'] = ['version' => 1, 'profiles' => $profiles];
    return $payload;
}

function assertReadableTheme(array $draft): void
{
    $palettes = $draft['appearance']['palettes'] ?? null;
    if ($palettes === null) {
        if (!legacyThemeReadable(currentTheme($draft))) {
            throw new InvalidArgumentException('ألوان الثيم غير واضحة بما يكفي. عدّلها من صفحة المظهر ثم انشر.');
        }
        return;
    }

    if (!is_array($palettes) || ($palettes['version'] ?? null) !== 1 ||
        !is_array($palettes['profiles'] ?? null)) {
        throw new InvalidArgumentException('تنسيق لوحات الألوان غير صالح. احفظها من صفحة المظهر.');
    }
    foreach (PALETTE_DEFAULTS as $profile => $defaults) {
        $colors = $palettes['profiles'][$profile] ?? [];
        foreach (array_keys($defaults) as $role) {
            if (!paletteColor($role, $colors[$role] ?? null)) {
                throw new InvalidArgumentException('لون غير صالح في لوحة ' . PALETTE_PROFILES[$profile] . '.');
            }
        }
        foreach (paletteChecks($colors) as $check) {
            if (!$check['ok']) {
                throw new InvalidArgumentException('راجع التباين في لوحة ' . PALETTE_PROFILES[$profile] .
                    ' (' . $check['label'] . ') قبل النشر.');
            }
        }
    }
}

function servePreviewCss(array $draft): never
{
    $theme = currentTheme($draft);
    $colors = currentPalettes($draft)[paletteProfile($_GET['profile'] ?? null)];
    header('Content-Type: text/css; charset=utf-8');
    header('Cache-Control: no-store');
    $radius = max(4, min(32, (int) $theme['radius']));
    $scale = max(90, min(125, (int) $theme['textScale'])) / 100;
    $values = [
        '--p-primary' => $colors['primary'], '--p-on-primary' => $colors['onPrimary'],
        '--p-gold' => $colors['secondary'], '--p-background' => $colors['surface'],
        '--p-ink' => $colors['onSurface'], '--p-muted' => $colors['onSurfaceVariant'],
        '--p-card' => $colors['surfaceContainerLow'], '--p-border' => $colors['outline'],
        '--p-hero-start' => $colors['heroStart'], '--p-hero-end' => $colors['heroEnd'],
        '--p-hero-ink' => $colors['heroInk'], '--p-radius' => $radius . 'px',
        '--p-radius-small' => max(6, $radius - 6) . 'px', '--p-scale' => (string) $scale,
    ];
    echo '.phone.appearance-phone{';
    foreach ($values as $name => $value) {
        echo $name . ':' . $value . ';';
    }
    echo '}';
    exit;
}
