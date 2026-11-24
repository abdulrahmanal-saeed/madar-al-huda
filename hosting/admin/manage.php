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
    $verses = [];
    foreach ($app['prayer_verses'] ?? [] as $range) {
        if (is_array($range) && count($range) === 3) {
            $verses[] = $range[1] === $range[2] ? "{$range[0]}:{$range[1]}" : "{$range[0]}:{$range[1]}-{$range[2]}";
        }
    }
    return [
        'features' => $features,
        'radio_url' => (string) ($app['radio_url'] ?? ''),
        'prayer_verses' => implode("\n", $verses),
        'announcement' => [
            'ar' => (string) ($announcement['ar'] ?? ''),
            'en' => (string) ($announcement['en'] ?? ''),
            'link' => (string) ($announcement['link'] ?? ''),
            'until' => (string) ($announcement['until'] ?? ''),
        ],
    ];
}

function changeAppSettings(array $content, array $ayahCounts): array
{
    $radio = field('radio_url');
    if ($radio !== '' && (!preg_match('~\Ahttps://[^\s]+\z~', $radio) || mb_strlen($radio) > 500)) {
        throw new InvalidArgumentException('رابط بث الإذاعة يجب أن يبدأ بـ https://');
    }
    $verses = [];
    foreach (preg_split('/\R/u', field('prayer_verses')) as $line) {
        $line = trim(strtr($line, ['٠' => '0', '١' => '1', '٢' => '2', '٣' => '3', '٤' => '4', '٥' => '5', '٦' => '6', '٧' => '7', '٨' => '8', '٩' => '9', '–' => '-']));
        if ($line === '') {
            continue;
        }
        if (!preg_match('/\A(\d{1,3})\s*:\s*(\d{1,3})(?:\s*-\s*(\d{1,3}))?\z/', $line, $parts)) {
            throw new InvalidArgumentException("اكتب كل آية في سطر بصيغة سورة:آية أو سورة:من-إلى. السطر: {$line}");
        }
        $verses[] = verseRange((int) $parts[1], (int) $parts[2], (int) ($parts[3] ?? $parts[2]), $ayahCounts);
    }
    if (count($verses) > 60) {
        throw new InvalidArgumentException('٦٠ آية على الأكثر في تنبيهات الصلاة.');
    }
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
    $minimum = field('min_app_version');
    if ($minimum !== '' && !preg_match('/\A[0-9]{1,9}\z/', $minimum)) {
        throw new InvalidArgumentException('أقل رقم بناء للتطبيق رقم صحيح.');
    }
    // Builds older than this keep their last library instead of this one.
    $content['minAppVersion'] = (int) $minimum;
    $content['app'] = array_filter([
        'features' => $features,
        'announcement' => ['ar' => $ar, 'en' => $en, 'link' => $link, 'until' => $until],
        // Empty values keep the app's own defaults.
        'radio_url' => $radio,
        'prayer_verses' => $verses,
    ], static fn ($value) => $value !== '' && $value !== []);
    return $content;
}

/**
 * Prophets in the stories catalog, in order: id => [Arabic, English,
 * aliases]. The dashboard's list, when it has one, replaces the default.
 */
function storyProphets(?array $content = null): array
{
    $custom = [];
    foreach (($content['storyProphets'] ?? []) as $row) {
        if (is_array($row) && is_string($row[0] ?? null) && is_string($row[1] ?? null) && is_string($row[2] ?? null)) {
            $custom[$row[0]] = [$row[1], $row[2], is_array($row[3] ?? null) ? $row[3] : []];
        }
    }
    if ($custom !== []) {
        return $custom;
    }
    // Same list and file-name aliases as prophet-stories/catalog.php.
    return [
        'adam' => ['آدم', 'Adam', []],
        'idris' => ['إدريس', 'Idris', []],
        'nuh' => ['نوح', 'Nuh', ['noah']],
        'hud' => ['هود', 'Hud', []],
        'salih' => ['صالح', 'Salih', ['saleh']],
        'ibrahim' => ['إبراهيم', 'Ibrahim', ['abraham', 'ibraheem']],
        'lut' => ['لوط', 'Lut', ['lot']],
        'ismail' => ['إسماعيل', 'Ismail', ['ishmael']],
        'ishaq' => ['إسحاق', 'Ishaq', ['isaac']],
        'yaqub' => ['يعقوب', 'Yaqub', ['jacob', 'yaqoob']],
        'yusuf' => ['يوسف', 'Yusuf', ['joseph', 'yousef']],
        'ayyub' => ['أيوب', 'Ayyub', ['job', 'ayoub']],
        'shuayb' => ['شعيب', 'Shuayb', ['shuaib', 'shoaib']],
        'musa' => ['موسى', 'Musa', ['moses', 'mousa']],
        'harun' => ['هارون', 'Harun', ['aaron', 'haroon']],
        'dhulkifl' => ['ذو الكفل', 'Dhul-Kifl', ['dhul-kifl', 'dhualkifl', 'dhu-al-kifl']],
        'dawud' => ['داود', 'Dawud', ['david', 'dawood']],
        'sulayman' => ['سليمان', 'Sulayman', ['solomon', 'sulaiman']],
        'ilyas' => ['إلياس', 'Ilyas', ['elijah', 'elias']],
        'alyasa' => ['اليسع', 'Al-Yasa', ['al-yasa', 'elisha']],
        'yunus' => ['يونس', 'Yunus', ['jonah', 'younes']],
        'zakariya' => ['زكريا', 'Zakariya', ['zechariah', 'zakaria']],
        'yahya' => ['يحيى', 'Yahya', ['john']],
        'isa' => ['عيسى', 'Isa', ['jesus', 'eesa']],
        'muhammad' => ['محمد', 'Muhammad', ['mohamed', 'mohammed']],
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

/** «id | الاسم | English | alias, alias» lines into the prophets list. */
function changeStoryProphets(array $content): array
{
    $rows = [];
    $tokens = [];
    foreach (preg_split('/\R/u', field('prophets')) as $line) {
        if (trim($line) === '') {
            continue;
        }
        [$id, $ar, $en, $aliases] = array_map('trim', array_pad(explode('|', $line, 4), 4, ''));
        $id = strtolower($id);
        $aliases = array_values(array_filter(array_map(static fn ($a) => strtolower(trim($a)), explode(',', $aliases))));
        if (!preg_match('/\A[a-z][a-z-]{1,30}\z/', $id) || $ar === '' || $en === '' || mb_strlen($ar) > 40 || mb_strlen($en) > 60) {
            throw new InvalidArgumentException("اكتب كل نبي في سطر: المعرّف | الاسم | English | أسماء ملفات بديلة. السطر: {$line}");
        }
        foreach ([$id, ...$aliases] as $token) {
            if (!preg_match('/\A[a-z][a-z-]{1,30}\z/', $token) || isset($tokens[$token])) {
                throw new InvalidArgumentException("الاسم «{$token}» مكرر أو غير صالح؛ استخدم حروفًا إنجليزية صغيرة وشرطة.");
            }
            $tokens[$token] = true;
        }
        $rows[] = [$id, $ar, $en, $aliases];
    }
    if ($rows === [] || count($rows) > 60) {
        throw new InvalidArgumentException('أضف نبيًا واحدًا على الأقل (٦٠ على الأكثر).');
    }
    $content['storyProphets'] = $rows;
    return $content;
}

function changeStoryTitles(array $content): array
{
    if (isset($_POST['prophets'])) {
        return changeStoryProphets($content);
    }
    $id = field('story');
    if (!isset(storyProphets($content)[$id])) {
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
