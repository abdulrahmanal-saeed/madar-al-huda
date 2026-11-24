<?php
declare(strict_types=1);

/*
 * App settings, story titles and adhkar groups, kept in the library draft
 * and published with it like everything else.
 */

/** Features the dashboard can show or hide in the app. */
const APP_FEATURES = [
    'search' => 'البحث الشامل', 'khatma' => 'هدف الختمة', 'memorize' => 'التحفيظ',
    'stats' => 'إحصائياتي', 'zakat' => 'حاسبة الزكاة', 'tasbih' => 'السبحة',
    'radio' => 'الإذاعة', 'ramadan' => 'وضع رمضان', 'hadith' => 'الحديث',
    'stories' => 'قصص الأنبياء', 'qibla' => 'القبلة',
];

function appSettings(array $draft): array
{
    $app = is_array($draft['app'] ?? null) ? $draft['app'] : [];
    $features = [];
    foreach (APP_FEATURES as $key => $_) {
        $features[$key] = ($app['features'][$key] ?? true) !== false;
    }
    $announcement = is_array($app['announcement'] ?? null) ? $app['announcement'] : [];
    return [
        'features' => $features,
        'announcement' => [
            'ar' => (string) ($announcement['ar'] ?? ''),
            'en' => (string) ($announcement['en'] ?? ''),
            'link' => (string) ($announcement['link'] ?? ''),
            'until' => (string) ($announcement['until'] ?? ''),
        ],
    ];
}

function changeAppSettings(array $content): array
{
    $features = [];
    foreach (APP_FEATURES as $key => $_) {
        $features[$key] = isset($_POST['feature'][$key]);
    }
    $link = field('link');
    if ($link !== '' && !preg_match('~\Ahttps://[^\s]+\z~', $link)) {
        throw new InvalidArgumentException('رابط الإعلان يجب أن يبدأ بـ https://');
    }
    $until = field('until');
    if ($until !== '' && !preg_match('/\A\d{4}-\d{2}-\d{2}\z/', $until)) {
        throw new InvalidArgumentException('اكتب تاريخ انتهاء الإعلان بصيغة سنة-شهر-يوم.');
    }
    $ar = field('announcement_ar');
    $en = field('announcement_en');
    if (mb_strlen($ar) > 300 || mb_strlen($en) > 300) {
        throw new InvalidArgumentException('اختصر نص الإعلان إلى ٣٠٠ حرف.');
    }
    $content['app'] = [
        'features' => $features,
        'announcement' => ['ar' => $ar, 'en' => $en, 'link' => $link, 'until' => $until],
    ];
    return $content;
}

/** Prophets in the stories catalog, in order: id => [Arabic, English]. */
function storyProphets(): array
{
    return [
        'adam' => ['آدم', 'Adam'], 'idris' => ['إدريس', 'Idris'], 'nuh' => ['نوح', 'Nuh'],
        'hud' => ['هود', 'Hud'], 'salih' => ['صالح', 'Salih'], 'ibrahim' => ['إبراهيم', 'Ibrahim'],
        'lut' => ['لوط', 'Lut'], 'ismail' => ['إسماعيل', 'Ismail'], 'ishaq' => ['إسحاق', 'Ishaq'],
        'yaqub' => ['يعقوب', 'Yaqub'], 'yusuf' => ['يوسف', 'Yusuf'], 'ayyub' => ['أيوب', 'Ayyub'],
        'shuayb' => ['شعيب', 'Shuayb'], 'musa' => ['موسى', 'Musa'], 'harun' => ['هارون', 'Harun'],
        'dhulkifl' => ['ذو الكفل', 'Dhul-Kifl'], 'dawud' => ['داود', 'Dawud'],
        'sulayman' => ['سليمان', 'Sulayman'], 'ilyas' => ['إلياس', 'Ilyas'],
        'alyasa' => ['اليسع', 'Al-Yasa'], 'yunus' => ['يونس', 'Yunus'],
        'zakariya' => ['زكريا', 'Zakariya'], 'yahya' => ['يحيى', 'Yahya'], 'isa' => ['عيسى', 'Isa'],
        'muhammad' => ['محمد', 'Muhammad'],
    ];
}

/**
 * Reads «1: عنوان الحلقة | Episode title» lines into episode titles.
 *
 * @return array<string, array{ar: string, en: string}>
 */
function parseEpisodeTitles(string $text): array
{
    $episodes = [];
    foreach (preg_split('/\R/', $text) as $line) {
        $line = trim($line);
        if ($line === '') {
            continue;
        }
        if (!preg_match('/\A([0-9٠-٩]{1,4})\s*[:：-]\s*(.+)\z/u', $line, $parts)) {
            throw new InvalidArgumentException("اكتب كل حلقة في سطر: «١: العنوان | Title». السطر: $line");
        }
        $number = (int) strtr($parts[1], ['٠' => '0', '١' => '1', '٢' => '2', '٣' => '3', '٤' => '4', '٥' => '5', '٦' => '6', '٧' => '7', '٨' => '8', '٩' => '9']);
        [$ar, $en] = array_map('trim', array_pad(explode('|', $parts[2], 2), 2, ''));
        if ($number < 1 || mb_strlen($ar) > 120 || mb_strlen($en) > 120) {
            throw new InvalidArgumentException("عنوان الحلقة غير صالح: $line");
        }
        $episodes[(string) $number] = ['ar' => $ar, 'en' => $en];
    }
    ksort($episodes, SORT_NUMERIC);
    return $episodes;
}

function changeStoryTitles(array $content): array
{
    $id = field('story');
    if (!isset(storyProphets()[$id])) {
        throw new InvalidArgumentException('اختر قصة صالحة.');
    }
    $entry = [
        'ar' => field('title_ar'), 'en' => field('title_en'),
        'descriptionAr' => field('description_ar'), 'descriptionEn' => field('description_en'),
        'hidden' => isset($_POST['hidden']),
        'episodes' => parseEpisodeTitles(field('episodes')),
    ];
    foreach (['ar', 'en'] as $key) {
        if (mb_strlen($entry[$key]) > 80) {
            throw new InvalidArgumentException('اختصر عنوان القصة.');
        }
    }
    foreach (['descriptionAr', 'descriptionEn'] as $key) {
        if (mb_strlen($entry[$key]) > 600) {
            throw new InvalidArgumentException('اختصر وصف القصة إلى ٦٠٠ حرف.');
        }
    }
    $content['stories'] = is_array($content['stories'] ?? null) ? $content['stories'] : [];
    $content['stories'][$id] = $entry;
    return $content;
}

function changeAdhkarGroups(array $content): array
{
    $id = field('group');
    $groups = $content['adhkar']['daily']['groups'] ?? [];
    $entries = array_column($content['adhkar']['daily']['entries'] ?? [], null, 'id');
    foreach ($groups as $index => $group) {
        if (($group['id'] ?? null) !== $id) {
            continue;
        }
        $ar = field('title_ar');
        $en = field('title_en');
        if ($ar === '' || $en === '' || mb_strlen($ar) > 60 || mb_strlen($en) > 60) {
            throw new InvalidArgumentException('اكتب عنوان المجموعة بالعربية والإنجليزية (٦٠ حرفًا على الأكثر).');
        }
        $order = array_values(array_filter(array_map('trim', preg_split('/\R/', field('entries')))));
        if ($order === []) {
            throw new InvalidArgumentException('اختر ذكرًا واحدًا على الأقل للمجموعة.');
        }
        foreach ($order as $entry) {
            if (!isset($entries[$entry])) {
                throw new InvalidArgumentException("الذكر «{$entry}» غير موجود في أذكار اليوم.");
            }
        }
        if (count(array_unique($order)) !== count($order)) {
            throw new InvalidArgumentException('ذكر مكرر في المجموعة.');
        }
        $content['adhkar']['daily']['groups'][$index]['title'] = ['ar' => $ar, 'en' => $en];
        $content['adhkar']['daily']['groups'][$index]['entries'] = $order;
        return $content;
    }
    throw new InvalidArgumentException('المجموعة غير موجودة.');
}
