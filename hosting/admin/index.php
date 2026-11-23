<?php
declare(strict_types=1);

ini_set('display_errors', '0');
header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: no-referrer');
require __DIR__ . '/content.php';
require __DIR__ . '/storage.php';
require __DIR__ . '/stories.php';

try {
    $db = database();
    if (($_GET['feed'] ?? '') === 'library') {
        serveFeed($db);
    }
} catch (Throwable $error) {
    error_log('Madar admin storage: ' . $error->getMessage());
    http_response_code(503);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'تعذّر فتح مخزن الإدارة.';
    exit;
}

header('Cache-Control: no-store');
header("Content-Security-Policy: default-src 'none'; style-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'");
session_name('MADARADMIN');
session_start([
    'use_strict_mode' => true,
    'use_only_cookies' => true,
    'cookie_secure' => true,
    'cookie_httponly' => true,
    'cookie_samesite' => 'Strict',
    'cookie_path' => '/admin/',
]);

function e(string|int $value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function route(string $section, string $topic = '', string $item = ''): string
{
    return './?' . http_build_query(array_filter([
        'section' => $section, 'topic' => $topic, 'edit' => $item,
    ], fn ($value) => $value !== ''));
}

function controls(string $action, ?int $revision = null): void
{
    echo '<input type="hidden" name="csrf" value="' . e($_SESSION['csrf']) . '">';
    echo '<input type="hidden" name="action" value="' . e($action) . '">';
    if ($revision !== null) {
        echo '<input type="hidden" name="revision" value="' . e($revision) . '">';
    }
}

function fieldValue(mixed $value): string
{
    return is_array($value) && $value !== [] ? encode($value) : '';
}

$sections = [
    'daily' => 'أذكار اليوم', 'merits' => 'فضائل الذكر',
    'hisn' => 'حصن المسلم', 'duas' => 'الأدعية القرآنية',
    'stories' => 'قصص الأنبياء', 'history' => 'سجل النشر',
];
$section = $_GET['section'] ?? 'daily';
if (!is_string($section) || !isset($sections[$section])) {
    $section = 'daily';
}
$topic = $_GET['topic'] ?? 'forgiveness';
if (!is_string($topic) || !isset(topics()[$topic])) {
    $topic = 'forgiveness';
}
$_SESSION['csrf'] ??= bin2hex(random_bytes(32));
$active = isset($_SESSION['signed_at']) && $_SESSION['signed_at'] >= time() - 28800;
$setup = accountPassword($db) === false;
$error = null;
$notice = $_SESSION['notice'] ?? null;
unset($_SESSION['notice']);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (!hash_equals($_SESSION['csrf'], field('csrf'))) {
            http_response_code(403);
            throw new InvalidArgumentException('انتهت الجلسة. أعد فتح اللوحة.');
        }
        $action = field('action');
        if ($action === 'setup' || $action === 'login') {
            $seed = $action === 'setup' ? require __DIR__ . '/seed.php' : [];
            if (!authorize($db, $action, $seed)) {
                throw new InvalidArgumentException('بيانات الدخول غير صالحة أو تجاوزت عدد المحاولات.');
            }
            session_regenerate_id(true);
            $_SESSION['signed_at'] = time();
            $_SESSION['csrf'] = bin2hex(random_bytes(32));
        } elseif (!$active) {
            http_response_code(403);
            throw new InvalidArgumentException('سجّل الدخول لإدارة المكتبة.');
        } elseif ($action === 'logout') {
            $_SESSION = [];
            session_destroy();
        } elseif (in_array($action, ['save', 'delete', 'publish', 'restore'], true)) {
            $seed = require __DIR__ . '/seed.php';
            updateLibrary($db, $action, $seed, $section, $topic);
            $_SESSION['notice'] = match ($action) {
                'publish' => 'تم نشر تحديث المكتبة.',
                'restore' => 'استُعيد الإصدار إلى المسودة.',
                'delete' => 'حُذف العنصر من المسودة.',
                default => 'حُفظت المسودة.',
            };
        } elseif (in_array($action, ['upload_story', 'archive_story', 'restore_story'], true)) {
            locked($db, fn () => changeStory($action));
            $_SESSION['notice'] = match ($action) {
                'upload_story' => 'رُفع التسجيل، ويظهر في الفهرس حسب رقمه.',
                'archive_story' => 'أُرشف التسجيل وأُخفي من الفهرس.',
                default => 'استُعيد التسجيل إلى الفهرس.',
            };
        } else {
            throw new InvalidArgumentException('الإجراء غير متاح.');
        }
        header('Location: ' . route($section, $topic), true, 303);
        exit;
    } catch (InvalidArgumentException $failure) {
        $error = $failure->getMessage();
    } catch (JsonException) {
        $error = 'راجع تنسيق المراجع أو التكرار.';
    } catch (Throwable $failure) {
        error_log('Madar admin: ' . $failure->getMessage());
        $error = 'تعذّر إتمام العملية. حاول مرة أخرى.';
    }
}

if ($active) {
    $state = library($db);
    $draft = json_decode($state['draft'], true, 64, JSON_THROW_ON_ERROR);
    $revision = (int) $state['revision'];
    $dirty = $state['published'] !== $state['draft'];
    $edit = $_GET['edit'] ?? '';
    if (!is_string($edit)) {
        $edit = '';
    }
    $rows = !in_array($section, ['stories', 'history'], true)
        ? contentRows($draft, $section, $topic)
        : [];
    $current = null;
    foreach ($rows as $index => $row) {
        $id = $row['id'] ?? (string) $index;
        if ($id === $edit) {
            $current = $row;
            break;
        }
    }
}
?><!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex, nofollow">
  <title>إدارة المكتبة · مدار الهدى</title>
  <link rel="stylesheet" href="dashboard.css">
</head>
<body>
<?php if (!$active): ?>
<main class="auth-wrap">
  <section class="panel auth">
    <p class="brand">مدار الهدى</p>
    <h1><?= $setup ? 'إعداد لوحة الإدارة' : 'الدخول إلى لوحة الإدارة' ?></h1>
    <?php if ($error): ?><p class="alert error" role="alert"><?= e($error) ?></p><?php endif; ?>
    <form method="post">
      <?php controls($setup ? 'setup' : 'login'); ?>
      <?php if ($setup): ?>
        <label>مفتاح الإعداد<input type="password" name="setup_code" required autocomplete="off"></label>
      <?php endif; ?>
      <label>كلمة المرور<input type="password" name="password" required <?= $setup ? 'minlength="12" autocomplete="new-password"' : 'autocomplete="current-password"' ?>></label>
      <?php if ($setup): ?>
        <label>تأكيد كلمة المرور<input type="password" name="confirm_password" required minlength="12" autocomplete="new-password"></label>
      <?php endif; ?>
      <button class="primary"><?= $setup ? 'حفظ وإدارة المكتبة' : 'دخول' ?></button>
    </form>
  </section>
</main>
<?php else: ?>
<header class="top">
  <div><p class="brand">مدار الهدى</p><p>إدارة المكتبة</p></div>
  <form method="post"><?php controls('logout'); ?><button class="quiet">خروج</button></form>
</header>
<div class="layout">
  <nav aria-label="أقسام الإدارة">
    <?php foreach ($sections as $key => $name): ?>
      <a href="<?= e(route($key)) ?>" <?= $section === $key ? 'aria-current="page"' : '' ?>><?= e($name) ?></a>
    <?php endforeach; ?>
  </nav>
  <main>
    <header class="section-head">
      <div><h1><?= e($sections[$section]) ?></h1>
        <?php if ($section !== 'stories'): ?><p><?= $dirty ? 'تغييرات في المسودة' : 'المكتبة محدثة' ?></p><?php endif; ?>
      </div>
      <?php if ($dirty && $section !== 'stories'): ?>
        <form method="post"><?php controls('publish', $revision); ?><button class="primary">نشر المسودة للتطبيق</button></form>
      <?php endif; ?>
    </header>
    <?php if ($notice): ?><p class="alert" role="status"><?= e($notice) ?></p><?php endif; ?>
    <?php if ($error): ?><p class="alert error" role="alert"><?= e($error) ?></p><?php endif; ?>

    <?php if ($section === 'stories'): ?>
      <section class="panel">
        <h2>رفع تسجيل</h2>
        <p>استخدم اسمًا مثل <bdi>Madar-Idris-007.mp3</bdi> أو <bdi>Madar-Idris-007.mp4</bdi>. يظهر التسجيل في الفهرس بعد الرفع.</p>
        <form method="post" enctype="multipart/form-data" class="inline">
          <?php controls('upload_story'); ?>
          <input type="file" name="recording" accept=".mp3,.mp4" required aria-label="ملف صوت أو فيديو">
          <button class="primary">رفع التسجيل</button>
        </form>
      </section>
      <?php foreach (['archive_story' => ['التسجيلات الحالية', ROOT . '/Prophet Stories', 'أرشفة'], 'restore_story' => ['الأرشيف', storage() . '/stories-archive', 'استعادة']] as $action => [$heading, $folder, $verb]): ?>
        <section class="panel">
          <h2><?= e($heading) ?></h2>
          <?php $recordings = listStoryFiles($folder, $action === 'restore_story'); ?>
          <?php if ($recordings === []): ?><p>لا توجد تسجيلات.</p><?php endif; ?>
          <?php foreach ($recordings as $recording): ?>
            <div class="row">
              <bdi><?= e($action === 'restore_story' ? substr($recording, 18) : $recording) ?></bdi>
              <form method="post"><?php controls($action); ?><input type="hidden" name="file" value="<?= e($recording) ?>"><button class="quiet"><?= e($verb) ?></button></form>
            </div>
          <?php endforeach; ?>
        </section>
      <?php endforeach; ?>
    <?php elseif ($section === 'history'): ?>
      <section class="panel">
        <h2>الإصدارات المنشورة</h2>
        <?php $publications = $db->query('SELECT revision FROM publications ORDER BY revision DESC LIMIT 20')->fetchAll(); ?>
        <?php if ($publications === []): ?><p>لا توجد إصدارات منشورة بعد.</p><?php endif; ?>
        <?php foreach ($publications as $publication): ?>
          <div class="row">
            <span>الإصدار <?= e($publication['revision']) ?></span>
            <form method="post"><?php controls('restore', $revision); ?><input type="hidden" name="publication" value="<?= e($publication['revision']) ?>"><button class="quiet">استعادة إلى المسودة</button></form>
          </div>
        <?php endforeach; ?>
      </section>
    <?php else: ?>
      <?php if ($section === 'duas'): ?>
        <nav class="topics" aria-label="موضوعات الدعاء">
          <?php foreach (topics() as $key => $name): ?><a href="<?= e(route($section, $key)) ?>" <?= $topic === $key ? 'aria-current="page"' : '' ?>><?= e($name) ?></a><?php endforeach; ?>
        </nav>
      <?php endif; ?>
      <div class="editor-grid">
        <section class="panel">
          <div class="row head"><h2>العناصر</h2><a class="button quiet" href="<?= e(route($section, $topic, 'new')) ?>">إضافة</a></div>
          <?php if ($rows === []): ?><p>لا توجد عناصر في هذا القسم.</p><?php endif; ?>
          <?php foreach ($rows as $index => $row): ?>
          <?php $key = $row['id'] ?? (string) $index; ?>
          <a class="entry" href="<?= e(route($section, $topic, $key)) ?>" <?= $key === $edit ? 'aria-current="true"' : '' ?>>
            <strong><?= $section === 'duas' ? e('سورة ' . $row[0] . ' · الآيات ' . $row[1] . '–' . $row[2]) : e($row['title']['ar']) ?></strong>
            <?php if ($section !== 'duas'): ?><span lang="en" dir="ltr"><?= e($row['title']['en']) ?></span><?php endif; ?>
          </a>
          <?php endforeach; ?>
        </section>
        <?php if ($current !== null || $edit === 'new'): ?>
        <section class="panel">
          <h2><?= $current !== null ? 'تعديل العنصر' : 'إضافة عنصر' ?></h2>
          <form method="post">
            <?php controls('save', $revision); ?>
            <input type="hidden" name="original" value="<?= $current !== null ? e($edit) : '' ?>">
            <?php if ($section === 'duas'): ?>
              <label>رقم السورة<input name="surah" type="number" min="1" max="114" value="<?= e($current[0] ?? '') ?>" required></label>
              <div class="fields">
                <label>أول آية<input name="first" type="number" min="1" value="<?= e($current[1] ?? '') ?>" required></label>
                <label>آخر آية<input name="last" type="number" min="1" value="<?= e($current[2] ?? '') ?>" required></label>
              </div>
            <?php else: ?>
              <label>العنوان بالعربية<input name="ar" value="<?= e($current['title']['ar'] ?? '') ?>" required></label>
              <label>العنوان بالإنجليزية<input name="en" dir="ltr" value="<?= e($current['title']['en'] ?? '') ?>" required></label>
              <?php if ($section === 'hisn'): ?>
                <label>أرقام أبواب حصن المسلم<input name="chapters" dir="ltr" value="<?= e(implode(', ', $current['chapterIds'] ?? [])) ?>"></label>
                <label>أرقام أحاديث HadeethEnc<input name="hadiths" dir="ltr" value="<?= e(implode(', ', $current['hadiths'] ?? [])) ?>"></label>
              <?php else: ?>
                <?php if ($current === null): ?><label>معرّف الذكر بالإنجليزية<input name="id" dir="ltr" pattern="[a-z0-9][a-z0-9-]{0,63}" required></label><?php endif; ?>
                <label>رقم الحديث في HadeethEnc<input name="hadith" type="number" min="1" value="<?= e($current['hadith'] ?? '') ?>"></label>
                <?php if ($section === 'daily'): ?>
                  <fieldset><legend>مجموعات الذكر</legend>
                  <?php foreach ($draft['adhkar']['daily']['groups'] as $group): ?>
                    <label class="check"><input type="checkbox" name="groups[]" value="<?= e($group['id']) ?>" <?= $current !== null && in_array($edit, $group['entries'], true) ? 'checked' : '' ?>><?= e($group['title']['ar']) ?></label>
                  <?php endforeach; ?>
                  </fieldset>
                <?php endif; ?>
                <details>
                  <summary>النص والمراجع والتكرار</summary>
                  <label>نص الذكر بالعربية<textarea name="wording"><?= e($current['wording']['ar'] ?? '') ?></textarea></label>
                  <label>المعنى بالإنجليزية<textarea name="meaning" dir="ltr"><?= e($current['wording']['draftMeaningEn'] ?? '') ?></textarea></label>
                  <label>مراجع الآيات <span dir="ltr">[[2,255,255]]</span><textarea name="quran" dir="ltr"><?= e(fieldValue($current['quran'] ?? [])) ?></textarea></label>
                  <label>خطوات التكرار <span dir="ltr">[{"unit":"tasbih","count":33}]</span><textarea name="repeat" dir="ltr"><?= e(fieldValue($current['repeat'] ?? [])) ?></textarea></label>
                  <label>صيغ بديلة للذكر <span dir="ltr">[{"hadith":5490}]</span><textarea name="variants" dir="ltr"><?= e(fieldValue($current['variants'] ?? [])) ?></textarea></label>
                </details>
              <?php endif; ?>
            <?php endif; ?>
            <button class="primary">حفظ في المسودة</button>
          </form>
          <?php if ($current !== null): ?>
            <form method="post" class="delete-form">
              <?php controls('delete', $revision); ?>
              <input type="hidden" name="original" value="<?= e($edit) ?>">
              <button class="quiet danger">حذف من المسودة</button>
            </form>
          <?php endif; ?>
        </section>
        <?php endif; ?>
      </div>
    <?php endif; ?>
  </main>
</div>
<?php endif; ?>
</body>
</html>
