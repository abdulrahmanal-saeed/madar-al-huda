<?php
declare(strict_types=1);

require __DIR__ . '/../admin/content.php';
require __DIR__ . '/../admin/appearance.php';

function check(bool $condition, string $message): void
{
    if (!$condition) {
        throw new RuntimeException($message);
    }
}

check(count(PALETTE_DEFAULTS) === 6, 'Every season must have both display modes');
$roles = array_merge(...array_values(PALETTE_ROLE_GROUPS));
check(array_diff_key(PALETTE_DEFAULTS['regular-light'], $roles) === [], 'Every palette role must be editable');
assertReadableTheme(['appearance' => ['palettes' => ['version' => 1, 'profiles' => PALETTE_DEFAULTS]]]);
check(currentPalettes([]) === PALETTE_DEFAULTS, 'Empty appearance uses the brand palette');

$legacy = defaultTheme();
$legacy['primary'] = '#1E2A4A';
$legacy['background'] = '#F7F1E3';
$draft = ['appearance' => ['theme' => $legacy]];
check(currentPalettes($draft)['regular-light']['primary'] === '#1E2A4A', 'A custom legacy primary is retained');
$_GET['profile'] = 'eid-dark';
$_POST = ['palette' => array_replace(PALETTE_DEFAULTS['eid-dark'], ['heroStart' => '#214232']),
    'radius' => '18', 'textScale' => '105'];
$saved = changeAppearance($draft, false);
check($saved['appearance']['theme']['radius'] === 18, 'Shared settings are saved');
check($saved['appearance']['palettes']['profiles']['eid-dark']['heroStart'] === '#214232', 'The selected palette was saved');
check($saved['appearance']['palettes']['profiles']['regular-light']['primary'] === '#1E2A4A', 'Editing one profile keeps the others');
assertReadableTheme($saved);
$reset = changeAppearance($saved, true);
check(currentPalettes($reset)['eid-dark'] === PALETTE_DEFAULTS['eid-dark'], 'Reset restores just the selected palette');
check(currentPalettes($reset)['regular-light']['primary'] === '#1E2A4A', 'Reset preserves other profiles');

$invalid = $saved;
$invalid['appearance']['palettes']['profiles']['eid-dark']['onSurface'] = $invalid['appearance']['palettes']['profiles']['eid-dark']['surface'];
try {
    assertReadableTheme($invalid);
    throw new RuntimeException('An unreadable palette passed validation');
} catch (InvalidArgumentException) {
    // An unreadable draft can be previewed but cannot be published.
}

$_POST = [
    'ar' => 'الاستغفار', 'en' => 'Seeking forgiveness', 'hadith' => '10947',
    'repetition' => ['main' => ['editor' => '1', 'count' => ['3', ''], 'unit' => ['seeking_forgiveness', '']]],
];
check(dhikr('after-prayer', [])['repeat'] === [['unit' => 'seeking_forgiveness', 'count' => 3]], 'The count is persisted in the existing feed shape');
$_POST['variants'] = '[{"hadith":10947,"repeat":[{"unit":"seeking_forgiveness","count":3}]},{"hadith":3}]';
$_POST['repetition']['variant-10947'] = ['editor' => '1', 'count' => [], 'unit' => []];
$entry = dhikr('after-prayer', []);
check(!isset($entry['variants'][0]['repeat']), 'The author can remove a variant count');
check($entry['variants'][1]['hadith'] === 3, 'Other variant records remain intact');
echo "Appearance and repetition editor checks passed.\n";
