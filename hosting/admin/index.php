<?php
declare(strict_types=1);

const MADAR_ADMIN = true;

ini_set('display_errors', '0');
header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: no-referrer');
if (($_GET['privacy'] ?? '') === '1') {
    require __DIR__ . '/privacy-public.php';
}
require __DIR__ . '/content.php';
require __DIR__ . '/content-news.php';
require __DIR__ . '/advanced.php';
require __DIR__ . '/appearance.php';
require __DIR__ . '/sections.php';
require __DIR__ . '/library-media.php';
require __DIR__ . '/storage.php';
require __DIR__ . '/stories.php';
require __DIR__ . '/apk-signature.php';
require __DIR__ . '/releases.php';
require __DIR__ . '/account.php';
require __DIR__ . '/diff.php';
require __DIR__ . '/manage.php';
require __DIR__ . '/governance.php';
require __DIR__ . '/reports.php';
require __DIR__ . '/agent.php';

try {
    $db = database();
    if (isset($_GET['library_media'])) {
        serveLibraryMedia($db, $_GET['library_media']);
    }
    if (($_GET['feed'] ?? '') === 'content-news') serveContentNews($db);
    if (($_GET['feed'] ?? '') === 'library') {
        serveFeed($db);
    }
    // The ChatGPT connector (/admin/mcp/<secret>, see .htaccess).
    if (is_string($_GET['mcp'] ?? null)) {
        serveMcp($db, $_GET['mcp']);
    }
    if (isset($_GET['report'])) {
        reportsTable($db);
        receiveReport($db);
    }
    if (($_GET['ci'] ?? '') === 'release') {
        releaseTable($db);
        receiveCiRelease($db);
    }
    if (($_GET['feed'] ?? '') === 'updates' || isset($_GET['apk']) || isset($_GET['updates'])) {
        releaseTable($db);
        if (($_GET['feed'] ?? '') === 'updates') {
            serveReleaseFeed($db, $_GET['channel'] ?? 'dev');
        }
        if (isset($_GET['apk'])) {
            serveApk($db, $_GET['apk']);
        }
        require __DIR__ . '/release-public.php';
    }
} catch (Throwable $error) {
    error_log('Madar admin storage: ' . $error->getMessage());
    http_response_code(503);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'تعذّر فتح مخزن الإدارة.';
    exit;
}

header('Cache-Control: no-store');
header("Content-Security-Policy: default-src 'none'; style-src 'self'; script-src 'self'; img-src 'self'; connect-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'");
header('Strict-Transport-Security: max-age=31536000');
// Sessions live in the private storage folder with the same lifetime as a
// sign-in, so shared-hosting cleanup cannot end them early and an open login
// page does not go stale after the host's default 24 minutes.
const SESSION_LIFETIME = 28800;
const SESSION_IDLE = 7200;
try {
    $sessionDir = storage() . '/sessions';
    if (!is_dir($sessionDir)) {
        @mkdir($sessionDir, 0700);
    }
    if (is_dir($sessionDir) && !is_link($sessionDir) && is_writable($sessionDir)) {
        session_save_path($sessionDir);
    }
} catch (Throwable) {
    // Fall back to the host's session folder.
}
ini_set('session.gc_maxlifetime', (string) SESSION_LIFETIME);
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
    // Only the Quranic duas section is split by topic.
    if ($section !== 'duas') {
        $topic = '';
    }
    return './?' . http_build_query(array_filter([
        'section' => $section, 'topic' => $topic, 'edit' => $item,
        'profile' => $section === 'appearance' && isset($_GET['profile'])
            ? paletteProfile($_GET['profile']) : '',
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

/** Requests from the upload page's script expect JSON, not a page. */
function wantsJson(): bool
{
    return str_contains($_SERVER['HTTP_ACCEPT'] ?? '', 'application/json');
}

function fieldValue(mixed $value): string
{
    return is_array($value) && $value !== [] ? encode($value) : '';
}

$sections = [
    'daily' => 'أذكار اليوم', 'daily_duas' => 'دعاء اليوم', 'merits' => 'فضائل الذكر',
    'hisn' => 'حصن المسلم', 'duas' => 'الأدعية القرآنية',
    'stories' => 'قصص الأنبياء', 'history' => 'سجل النشر',
    'fiqh' => 'الفقه المقارن', 'articles' => 'المقالات',
    'lessons' => 'الدروس والاختبارات', 'names' => 'أسماء الله الحسنى', 'reciters' => 'القراء',
    'appearance' => 'الثيم والألوان', 'library_sections' => 'أقسام المكتبة',
    'releases' => 'إصدارات التطبيق', 'app_settings' => 'إعدادات التطبيق',
    'story_titles' => 'عناوين القصص', 'adhkar_groups' => 'مجموعات الأذكار',
    'reports' => 'البلاغات والاقتراحات', 'chatgpt' => 'ChatGPT',
    'users' => 'المستخدمون', 'audit' => 'سجل التعديلات', 'account' => 'حسابي',
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
$active = isset($_SESSION['signed_at'], $_SESSION['seen_at']) &&
    $_SESSION['signed_at'] >= time() - SESSION_LIFETIME &&
    $_SESSION['seen_at'] >= time() - SESSION_IDLE;
if ($active) {
    $_SESSION['seen_at'] = time();
    if (is_string($_GET['job'] ?? null)) {
        header('Content-Type: application/json; charset=utf-8');
        header('Cache-Control: no-store');
        try {
            $file = driveJobFile($_GET['job']);
            echo is_file($file) ? (string) file_get_contents($file) : encode(['state' => 'waiting']);
        } catch (Throwable) {
            http_response_code(400);
            echo encode(['state' => 'failed']);
        }
        exit;
    }
    if (isset($_GET['preview_css'])) {
        servePreviewCss(json_decode(library($db)['draft'], true, 64, JSON_THROW_ON_ERROR));
    }
}
$setup = accountPassword($db) === false;
usersTable($db);
auditTable($db);
$user = $active ? userById($db, (int) ($_SESSION['user'] ?? 1)) : null;
if ($active && $user === null) {
    // The account was disabled or removed: end this session.
    $_SESSION = ['csrf' => bin2hex(random_bytes(32))];
    $active = false;
}
if (isset($_GET['report_image'])) {
    if ($user === null || !canSee($user, 'reports')) {
        http_response_code(404);
        exit;
    }
    serveReportImage($db, $_GET['report_image']);
}
if ($user !== null && !canSee($user, $section)) {
    $section = 'daily';
}
$signedIn = null;
$error = null;
$confirming = null;
$publishedNewsId = null;
const CONFIRMATIONS = [
    'publish' => 'ستُنشر المسودة لكل مستخدمي التطبيق. هل تريد المتابعة؟',
    'delete' => 'سيُحذف هذا العنصر من المسودة. هل تريد المتابعة؟',
    'restore' => 'ستُستبدل المسودة الحالية بالإصدار المختار، وتضيع أي تغييرات لم تُنشر. هل تريد المتابعة؟',
    'archive_story' => 'سيُخفى هذا التسجيل من التطبيق وينتقل إلى الأرشيف. هل تريد المتابعة؟',
    'release_publish' => 'سيصبح هذا الإصدار متاحًا للتنزيل لكل مستخدمي القناة. هل تريد المتابعة؟',
    'release_notify' => 'سيظهر إشعار التحديث على أجهزة المستخدمين. هل تريد المتابعة؟',
    'release_withdraw' => 'سيُسحب هذا الإصدار ويعود الإصدار السابق هو المتاح للتنزيل. الأجهزة التي حدّثت بالفعل لن تعود للإصدار السابق. هل تريد المتابعة؟',
    'totp_disable' => 'سيُوقف التحقق بخطوتين، ويكفي بعدها كلمة المرور للدخول. هل تريد المتابعة؟',
    'report_delete' => 'سيُحذف هذا البلاغ نهائيًا. هل تريد المتابعة؟',
];
$notice = $_SESSION['notice'] ?? null;
unset($_SESSION['notice']);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $action = field('action');
        if (!hash_equals($_SESSION['csrf'], field('csrf'))) {
            // A second click on «دخول», or a login page left open in another
            // tab, arrives after the token was renewed: the user is already in.
            if ($active && in_array($action, ['login', 'setup'], true)) {
                header('Location: ' . route($section, $topic), true, 303);
                exit;
            }
            http_response_code(403);
            throw new InvalidArgumentException($active
                ? 'انتهت صلاحية هذه الصفحة. حدّث الصفحة ثم أعد المحاولة.'
                : 'انتهت صلاحية صفحة الدخول. أدخل كلمة المرور مرة أخرى.');
        }
        if ($action === 'setup' || $action === 'login') {
            if ($action === 'setup') {
                if (!authorize($db, $action, require __DIR__ . '/seed.php')) {
                    throw new InvalidArgumentException('بيانات الدخول غير صالحة أو تجاوزت عدد المحاولات.');
                }
                usersTable($db);
                $signedIn = userById($db, 1);
            } else {
                $signedIn = signIn($db);
            }
            if ($signedIn === null) {
                throw new InvalidArgumentException('بيانات الدخول أو رمز التحقق غير صحيحة، أو تجاوزت عدد المحاولات.');
            }
            session_regenerate_id(true);
            $_SESSION['user'] = (int) $signedIn['id'];
            $_SESSION['signed_at'] = time();
            $_SESSION['seen_at'] = time();
            $_SESSION['csrf'] = bin2hex(random_bytes(32));
        } elseif (!$active) {
            http_response_code(403);
            throw new InvalidArgumentException('سجّل الدخول لإدارة المكتبة.');
        } elseif (!allowedAction($user, $action, $section)) {
            http_response_code(403);
            throw new InvalidArgumentException('صلاحيات حسابك لا تسمح بهذا الإجراء. اطلبه من المالك.');
        } elseif (isset(CONFIRMATIONS[$action]) && field('confirmed') !== 'yes') {
            // Irreversible actions show a confirmation page first; the CSP
            // blocks scripts, so the check happens on the server.
            $confirming = ['action' => $action, 'message' => match (true) {
                $section === 'appearance' && $action === 'delete'
                    => 'سترجع ألوان اللوحة المختارة إلى الهوية الأصلية في المسودة. هل تريد المتابعة؟',
                $section === 'library_sections' && $action === 'delete'
                    => 'سيُحذف هذا القسم وكل روابطه من المسودة. هل تريد المتابعة؟',
                default => CONFIRMATIONS[$action],
            }];
        } elseif ($action === 'logout') {
            $_SESSION = [];
            session_destroy();
        } elseif (in_array($action, ['save', 'delete', 'publish', 'restore', 'review_approve'], true)) {
            $seed = require __DIR__ . '/seed.php';
            $isDuaDrive = $action === 'save' && $section === 'daily_duas' && field('op') === 'drive_dua_audio';
            if ($isDuaDrive) {
                $revision = integer(field('revision'), 1, PHP_INT_MAX);
                $id = field('original');
                $link = field('drive_url');
                set_time_limit(120);
                session_write_close();
                try {
                    importDailyDuaAudio($db, $seed, $revision, $id, $link, $user, function () use ($db, $user): array {
                        $current = userById($db, (int) $user['id']);
                        if ($current === null || !allowedAction($current, 'save', 'daily_duas')) {
                            throw new InvalidArgumentException('لم تعد صلاحية التعديل متاحة.');
                        }
                        return $current;
                    });
                } finally {
                    session_start();
                }
            } elseif ($action === 'save' && $section === 'library_sections' && field('op') === 'bulk_drive') {
                set_time_limit(0);
                session_write_close();
                try {
                    importDriveFile(field('link'), field('name'), field('job'), function ($staged, $filename) use ($db, $action, $seed, $section, $topic, $user): void {
                        $current = userById($db, (int) $user['id']);
                        if ($current === null || !allowedAction($current, 'save', 'library_sections')) {
                            throw new InvalidArgumentException('لم تعد صلاحية التعديل متاحة.');
                        }
                        updateLibrary($db, $action, $seed, $section, $topic, $current, $staged, $filename);
                    });
                } finally {
                    session_start();
                }
            } else {
                $publishedNewsId = updateLibrary($db, $action, $seed, $section, $topic, $user);
            }
            $_SESSION['notice'] = match ($action) {
                'publish' => 'تم نشر تحديث المكتبة.',
                'restore' => 'استُعيد الإصدار إلى المسودة.',
                'delete' => 'حُذف العنصر من المسودة.',
                'review_approve' => 'اعتُمدت المسألة شرعيًا ويمكن نشرها.',
                default => $isDuaDrive ? 'تم جلب التسجيل من Google Drive وحفظه في المسودة.' : 'حُفظت المسودة.',
            };
        } elseif ($action === 'news_publish') {
            $id = locked($db, function () use ($db): int {
                $data = library($db);
                if (!is_string($data['published'])) throw new InvalidArgumentException('انشر المحتوى أولًا.');
                return enqueueContentNews($db, json_decode($data['published'], true, 64, JSON_THROW_ON_ERROR), (int) $data['revision']);
            });
            $_SESSION['notice'] = deliverContentNews($db, $id) ? 'أُرسل إشعار المحتوى.' : 'حُفظ الإشعار، ويمكن إعادة إرسال الدفع من السجل.';
        } elseif ($action === 'news_retry') {
            $id = integer(field('news_id'), 1, PHP_INT_MAX);
            $_SESSION['notice'] = deliverContentNews($db, $id) ? 'أُرسل إشعار المحتوى.' : 'الإشعار لم يُرسل. راجع حالة الإرسال.';
        } elseif ($action === 'drive_import') {
            // The download can take minutes; release the session so the
            // page can keep polling the progress meanwhile.
            set_time_limit(0);
            ignore_user_abort(true);
            session_write_close();
            // The page's script sends one link at a time with a job id for
            // progress; without scripts, every line of the box is imported.
            $lines = field('link') !== ''
                ? [[field('link'), field('name'), field('job')]]
                : array_map(
                    fn (string $line) => [...array_pad(preg_split('/\s+/', trim($line), 2), 2, ''), bin2hex(random_bytes(8))],
                    array_values(array_filter(preg_split('/\R/', field('links')), fn ($line) => trim($line) !== '')),
                );
            if ($lines === [] || count($lines) > 50) {
                throw new InvalidArgumentException('الصق من رابط واحد إلى ٥٠ رابطًا.');
            }
            $names = [];
            foreach ($lines as [$link, $name, $job]) {
                $names[] = importDriveFile($link, trim($name), $job);
            }
            session_start();
            $_SESSION['notice'] = 'نُقل من Google Drive: ' . implode('، ', $names) . '.';
        } elseif (in_array($action, ['upload_story', 'archive_story', 'restore_story'], true)) {
            locked($db, fn () => changeStory($action));
            $_SESSION['notice'] = match ($action) {
                'upload_story' => 'رُفع التسجيل، ويظهر في الفهرس حسب رقمه.',
                'archive_story' => 'أُرشف التسجيل وأُخفي من الفهرس.',
                default => 'استُعيد التسجيل إلى الفهرس.',
            };
        } elseif (in_array($action, ['user_add', 'user_role', 'user_disable', 'user_enable', 'user_reset'], true)) {
            $_SESSION['notice'] = changeUsers($db, $user, $action);
        } elseif (in_array($action, ['password_change', 'totp_enable', 'totp_disable'], true)) {
            $_SESSION['notice'] = changeAccount($db, $user, $action);
        } elseif (in_array($action, ['agent_key_create', 'agent_key_revoke', 'agent_publish_approve', 'agent_publish_reject', 'agent_publish_mode'], true)) {
            $_SESSION['notice'] = changeAgent($db, $user, $action);
        } elseif (in_array($action, ['report_settings', 'report_done', 'report_open', 'report_delete'], true)) {
            $_SESSION['notice'] = changeReports($db, $action);
        } elseif (in_array($action, ['release_upload', 'release_publish', 'release_notify', 'release_withdraw'], true)) {
            releaseTable($db);
            $_SESSION['notice'] = changeRelease($db, $action);
        } else {
            throw new InvalidArgumentException('الإجراء غير متاح.');
        }
        if ($confirming === null && $action === 'publish' && $publishedNewsId !== null) {
            if (deliverContentNews($db, $publishedNewsId)) {
                $_SESSION['notice'] = 'تم نشر المحتوى وأُرسل الإشعار.';
            } else {
                $_SESSION['notice'] = 'تم نشر المحتوى وحُفظ الإشعار في السجل.';
            }
        }
        if ($confirming === null && $action !== 'setup') {
            $who = $signedIn['username'] ?? $user['username'] ?? '?';
            audit($db, $who, $action, $section, auditDetail($action));
        }
        if ($confirming === null && wantsJson()) {
            header('Content-Type: application/json; charset=utf-8');
            $response = ['ok' => true, 'message' => $_SESSION['notice'] ?? ''];
            if ($action === 'save' && $section === 'library_sections') {
                $response['revision'] = (int) field('revision') + 1;
            }
            echo encode($response);
            unset($_SESSION['notice']);
            exit;
        }
        if ($confirming === null) {
            $keepDua = $section === 'daily_duas' && $action !== 'delete' && ($_GET['edit'] ?? '') !== 'new';
            $keep = ($section === 'library_sections' || $keepDua) && is_string($_GET['edit'] ?? null)
                ? $_GET['edit'] : '';
            header('Location: ' . route($section, $topic, $keep), true, 303);
            exit;
        }
    } catch (InvalidArgumentException $failure) {
        $error = $failure->getMessage();
        if (wantsJson()) {
            http_response_code(http_response_code() === 200 ? 422 : http_response_code());
            header('Content-Type: application/json; charset=utf-8');
            echo encode(['ok' => false, 'message' => $error]);
            exit;
        }
    } catch (JsonException) {
        $error = 'راجع تنسيق المراجع أو التكرار.';
    } catch (Throwable $failure) {
        error_log('Madar admin: ' . $failure->getMessage());
        $error = 'تعذّر إتمام العملية. حاول مرة أخرى.';
        if (wantsJson()) {
            http_response_code(500);
            header('Content-Type: application/json; charset=utf-8');
            echo encode(['ok' => false, 'message' => $error]);
            exit;
        }
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
    $rows = in_array($section, BOOK_SECTIONS, true)
        ? ($draft['library'][$section] ?? [])
        : (in_array($section, ['stories', 'history', 'reciters', 'releases', 'appearance', 'library_sections', 'account', 'app_settings', 'story_titles', 'adhkar_groups', 'users', 'audit', 'reports', 'chatgpt'], true)
            ? [] : contentRows($draft, $section, $topic));
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
  <link rel="stylesheet" href="dashboard.css?v=<?= e((string) @filemtime(__DIR__ . '/dashboard.css')) ?>">
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
      <?php if (!$setup): ?>
        <label>اسم المستخدم<input name="username" dir="ltr" autocomplete="username" placeholder="owner"></label>
      <?php endif; ?>
      <label>كلمة المرور<input type="password" name="password" required <?= $setup ? 'minlength="12" autocomplete="new-password"' : 'autocomplete="current-password"' ?>></label>
      <?php if (!$setup): ?>
        <label>رمز التحقق (إن فعّلته)<input name="code" inputmode="numeric" autocomplete="one-time-code" maxlength="8" dir="ltr"></label>
      <?php endif; ?>
      <?php if ($setup): ?>
        <label>تأكيد كلمة المرور<input type="password" name="confirm_password" required minlength="12" autocomplete="new-password"></label>
      <?php endif; ?>
      <button class="primary"><?= $setup ? 'حفظ وإدارة المكتبة' : 'دخول' ?></button>
    </form>
  </section>
</main>
<?php else: ?>
<header class="top">
  <div><p class="brand">مدار الهدى</p><p>إدارة المكتبة · <bdi><?= e($user['username']) ?></bdi> (<?= e(ROLES[$user['role']] ?? $user['role']) ?>)</p></div>
  <form method="post"><?php controls('logout'); ?><button class="quiet">خروج</button></form>
</header>
<div class="layout">
  <nav aria-label="أقسام الإدارة">
    <?php foreach ($sections as $key => $name): ?>
      <?php if (!canSee($user, $key)) continue; ?>
      <a href="<?= e(route($key)) ?>" <?= $section === $key ? 'aria-current="page"' : '' ?>><?= e($name) ?><?php if ($key === 'chatgpt' && agentPendingCount($db) > 0): ?> <span class="badge warn">طلب نشر</span><?php endif; ?></a>
    <?php endforeach; ?>
  </nav>
  <main>
    <header class="section-head">
      <div><h1><?= e($sections[$section]) ?></h1>
        <?php if (!in_array($section, ['stories', 'releases', 'reports', 'chatgpt'], true)): ?><p><?= $dirty ? 'تغييرات في المسودة' : 'المكتبة محدثة' ?> · الحجم <?= e(feedSizeLabel(strlen($state['draft']))) ?></p><?php endif; ?>
      </div>
      <?php if ($dirty && !in_array($section, ['stories', 'releases', 'reports', 'chatgpt'], true)): ?>
        <?php if (allowedAction($user, 'publish', $section)): ?>
        <form method="post"><?php controls('publish', $revision); ?><button class="primary">نشر المسودة للتطبيق</button></form>
        <?php else: ?><p>النشر للمراجع الشرعي أو المالك.</p><?php endif; ?>
        <?php $changes = libraryDiff(json_decode($state['published'] ?? 'null', true), $draft); ?>
        <details class="changes">
          <summary>عرض التغييرات قبل النشر (<?= e(arabicDigits((string) count($changes))) ?>)</summary>
          <?php require __DIR__ . '/diff-view.php'; ?>
        </details>
      <?php endif; ?>
    </header>
    <?php if ($notice): ?><p class="alert" role="status"><?= e($notice) ?></p><?php endif; ?>
    <?php if (!in_array($section, ['stories', 'releases'], true) && strlen($state['draft']) > FEED_LEGACY_BYTES): ?>
      <p class="alert warn" role="status"><?= strlen($state['draft']) > FEED_MAX_BYTES
          ? 'حجم المسودة تجاوز الحد الذي يقبله التطبيق، فلن يمكن نشرها قبل تقليل المحتوى.'
          : 'حجم المكتبة تجاوز ١ ميغابايت: نسخ التطبيق القديمة لن تستقبل هذا التحديث حتى يحدّثها المستخدم.' ?></p>
    <?php endif; ?>
    <?php if ($error): ?><p class="alert error" role="alert"><?= e($error) ?></p><?php endif; ?>

    <?php if ($confirming !== null): ?>
      <section class="panel confirm" aria-labelledby="confirm-title">
        <h2 id="confirm-title">تأكيد الإجراء</h2>
        <p><?= e($confirming['message']) ?></p>
        <?php if ($confirming['action'] === 'publish'): ?>
          <?php $changes = libraryDiff(json_decode($state['published'] ?? 'null', true), $draft); ?>
          <h3>ما سيتغيّر في التطبيق</h3>
          <?php require __DIR__ . '/diff-view.php'; ?>
        <?php endif; ?>
        <div class="row">
          <form method="post">
            <?php foreach ($_POST as $name => $value): ?>
              <?php if (is_string($name) && is_string($value) && !in_array($name, ['csrf', 'confirmed'], true)): ?>
                <input type="hidden" name="<?= e($name) ?>" value="<?= e($value) ?>">
              <?php endif; ?>
            <?php endforeach; ?>
            <input type="hidden" name="csrf" value="<?= e($_SESSION['csrf']) ?>">
            <input type="hidden" name="confirmed" value="yes">
            <?php if ($confirming['action'] === 'publish'): ?>
              <?php $optionalNews = true; $newsContent = $draft; require __DIR__ . '/content-news-fields.php'; ?>
            <?php endif; ?>
            <button class="primary<?= in_array($confirming['action'], ['delete', 'archive_story'], true) ? ' danger' : '' ?>">نعم، تابع</button>
          </form>
          <a class="button quiet" href="<?= e(route($section, $topic, is_string($_GET['edit'] ?? null) ? $_GET['edit'] : '')) ?>">إلغاء</a>
        </div>
      </section>
    <?php endif; ?>

    <?php if ($section === 'history' && allowedAction($user, 'news_publish', $section)): ?>
      <section class="panel">
        <h2>إشعارات المحتوى المنشور</h2>
        <?php if (is_string($state['published'])): ?>
          <form method="post">
            <?php controls('news_publish'); ?>
            <?php $optionalNews = false; $newsContent = json_decode($state['published'], true); require __DIR__ . '/content-news-fields.php'; ?>
            <button class="primary">إرسال الإعلان</button>
          </form>
        <?php endif; ?>
        <?php contentNewsTable($db); ?>
        <?php foreach ($db->query('SELECT * FROM content_news ORDER BY id DESC LIMIT 25')->fetchAll() as $news): ?>
          <div class="row">
            <span><?= e($news['title']) ?> · <?= e($news['channel'] === 'dev' ? 'اختبار' : 'عام') ?> · <?= e(match ($news['state']) {
                'sent' => 'قُبل لدى خدمة الإرسال',
                'failed' => 'تعذر الإرسال',
                'sending' => 'جارٍ الإرسال',
                default => 'بانتظار الإرسال',
            }) ?></span>
            <?php if ($news['state'] !== 'sent'): ?>
              <form method="post">
                <?php controls('news_retry'); ?>
                <input type="hidden" name="news_id" value="<?= e($news['id']) ?>">
                <button class="quiet">إعادة المحاولة</button>
              </form>
            <?php endif; ?>
          </div>
        <?php endforeach; ?>
      </section>
    <?php endif; ?>

    <?php if ($section === 'account'): ?>
      <?php require __DIR__ . '/account-view.php'; ?>
    <?php endif; ?>
    <?php if (in_array($section, ['app_settings', 'story_titles', 'adhkar_groups'], true)): ?>
      <?php require __DIR__ . '/manage-view.php'; ?>
    <?php endif; ?>
    <?php if (in_array($section, ['users', 'audit'], true)): ?>
      <?php require __DIR__ . '/governance-view.php'; ?>
    <?php endif; ?>
    <?php if ($section === 'reports'): ?>
      <?php require __DIR__ . '/reports-view.php'; ?>
    <?php endif; ?>
    <?php if ($section === 'chatgpt'): ?>
      <?php require __DIR__ . '/agent-view.php'; ?>
    <?php endif; ?>
    <?php if ($section === 'stories'): ?>
      <section class="panel">
        <h2>رفع تسجيلات</h2>
        <p>اختر ملفًا أو أكثر بأسماء مثل <bdi>Madar-Idris-007.mp3</bdi> أو <bdi>Madar-Idris-007.mp4</bdi>. تُرفع واحدًا بعد الآخر ويظهر تقدّم كل ملف، وتظهر في الفهرس بعد الرفع.</p>
        <form method="post" enctype="multipart/form-data" class="inline" id="upload-form">
          <?php controls('upload_story'); ?>
          <input type="file" name="recording" accept=".mp3,.mp4" multiple required aria-label="ملفات صوت أو فيديو">
          <button class="primary">رفع</button>
        </form>
        <div id="upload-progress" class="uploads" hidden></div>
      </section>
      <section class="panel">
        <h2>نقل من Google Drive</h2>
        <p>الصق رابط ملف أو أكثر، كل رابط في سطر. اجعل المشاركة «أي شخص لديه الرابط». يُنزَّل الملف على الموقع مباشرة. يُستخدم اسم الملف على Drive، أو اكتب الاسم بعد الرابط بمسافة: <bdi>https://drive.google.com/file/d/… Madar-Idris-007.mp4</bdi></p>
        <form method="post" id="drive-form">
          <?php controls('drive_import'); ?>
          <textarea name="links" rows="4" required dir="ltr" placeholder="https://drive.google.com/file/d/…"></textarea>
          <button class="primary">نقل من Drive</button>
        </form>
        <div id="drive-progress" class="uploads" hidden></div>
      </section>
      <?php foreach (['archive_story' => ['التسجيلات الحالية', ROOT . '/Prophet Stories', 'أرشفة'], 'restore_story' => ['الأرشيف', storage() . '/stories-archive', 'استعادة']] as $action => [$heading, $folder, $verb]): ?>
        <section class="panel">
          <h2><?= e($heading) ?></h2>
          <?php $recordings = listStoryFiles($folder, $action === 'restore_story'); ?>
          <?php if ($recordings === []): ?><p>لا توجد تسجيلات.</p><?php endif; ?>
          <?php foreach (groupStoryFiles($recordings, $action === 'restore_story') as $episode): ?>
            <div class="row">
              <span class="section-name">
                <strong><?= e($episode['label']) ?></strong>
                <?php foreach ($episode['files'] as $format => $recording): ?><span class="badge"><?= $format === 'mp3' ? 'صوت' : 'فيديو' ?></span><?php endforeach; ?>
              </span>
              <span class="section-actions">
                <?php foreach ($episode['files'] as $format => $recording): ?>
                  <form method="post"><?php controls($action); ?><input type="hidden" name="file" value="<?= e($recording) ?>"><button class="quiet"><?= e($verb . ' ' . ($format === 'mp3' ? 'الصوت' : 'الفيديو')) ?></button></form>
                <?php endforeach; ?>
              </span>
            </div>
          <?php endforeach; ?>
        </section>
      <?php endforeach; ?>
    <?php elseif ($section === 'releases'): ?>
      <?php releaseTable($db); require __DIR__ . '/release-view.php'; ?>
    <?php elseif ($section === 'library_sections'): ?>
      <?php require __DIR__ . '/sections-view.php'; ?>
    <?php elseif ($section === 'appearance'): ?>
      <?php require __DIR__ . '/appearance-view.php'; ?>
    <?php elseif ($section === 'history'): ?>
      <section class="panel">
        <h2>الإصدارات المنشورة</h2>
        <?php $publications = $db->query('SELECT revision, published_at FROM publications ORDER BY revision DESC LIMIT 20')->fetchAll(); ?>
        <?php if ($publications === []): ?><p>لا توجد إصدارات منشورة بعد.</p><?php endif; ?>
        <?php foreach ($publications as $publication): ?>
          <div class="row">
            <span>الإصدار <?= e(arabicDigits((string) $publication['revision'])) ?><?php if ($publication['published_at'] !== null): ?> · <bdi><?= e(publishedLabel((int) $publication['published_at'])) ?></bdi><?php endif; ?></span>
            <form method="post"><?php controls('restore', $revision); ?><input type="hidden" name="publication" value="<?= e($publication['revision']) ?>"><button class="quiet">استعادة إلى المسودة</button></form>
          </div>
        <?php endforeach; ?>
      </section>
    <?php elseif (in_array($section, BOOK_SECTIONS, true) || $section === 'reciters'): ?>
      <?php require __DIR__ . '/advanced-view.php'; ?>
    <?php elseif (in_array($section, ['account', 'app_settings', 'story_titles', 'adhkar_groups', 'users', 'audit', 'reports', 'chatgpt'], true)): ?>
      <?php /* Drawn above. */ ?>
    <?php else: ?>
      <?php if ($section === 'duas'): ?>
        <nav class="topics" aria-label="موضوعات الدعاء">
          <?php foreach (topics() as $key => $name): ?><a href="<?= e(route($section, $key)) ?>" <?= $topic === $key ? 'aria-current="page"' : '' ?>><?= e($name) ?></a><?php endforeach; ?>
        </nav>
      <?php endif; ?>
      <details class="panel help">
        <summary>كيف أضيف أو أحذف؟</summary>
        <?php if ($section === 'duas'): ?>
          <ol>
            <li>اختر الموضوع من الشريط أعلاه، ثم اضغط «إضافة».</li>
            <li>اختر السورة واكتب رقم أول آية وآخر آية، ثم «حفظ في المسودة».</li>
            <li>للحذف: افتح الدعاء من القائمة، ثم «حذف من المسودة».</li>
            <li>لا يظهر شيء في التطبيق حتى تضغط «نشر المسودة للتطبيق» أعلى الصفحة.</li>
          </ol>
        <?php elseif ($section === 'daily_duas'): ?>
          <p>هذه قائمة مستقلة للشاشة الرئيسية. اكتب نص الدعاء فقط، ومعناه ومصدره باللغتين. تحفظ التعديلات في المسودة حتى النشر.</p>
        <?php elseif ($section === 'hisn'): ?>
          <ol>
            <li>اضغط «إضافة» لموضوع جديد، أو افتح موضوعًا موجودًا.</li>
            <li>اكتب أذكارك في مربع «أذكار وأدعية خاصة»: كل ذكر فقرة، وبين كل ذكرين سطر فيه <bdi>---</bdi>. يمكنك إضافة «العنوان:» و«المصدر:» في أول أو آخر الفقرة.</li>
            <li>أرقام الأبواب والأحاديث اختيارية؛ امسح أي رقم منها لحذف ما جاء من المصدر.</li>
            <li>لحذف موضوع كامل: افتحه ثم «حذف من المسودة». ثم «نشر المسودة للتطبيق».</li>
          </ol>
        <?php else: ?>
          <ol>
            <li>اضغط «إضافة»، واكتب العنوان بالعربية والإنجليزية ومعرّفًا بحروف إنجليزية صغيرة (مثل <bdi>my-dua-1</bdi>).</li>
            <li>اكتب <strong>نص الذكر بالعربية</strong> بنفسك، والمعنى بالإنجليزية والمصدر إن أردت، واترك رقم الحديث فارغًا. أو اكتب رقم حديث من HadeethEnc ليُجلب نصه تلقائيًا.</li>
            <?php if ($section === 'daily'): ?><li>اختر مجموعة واحدة على الأقل (الصباح، المساء…) ليظهر فيها الذكر.</li><?php endif; ?>
            <li>كل عنصر في القائمة يمكن حذفه، سواء أضفته أنت أو جاء من المصدر: افتحه ثم «حذف من المسودة».</li>
            <li>لا يتغيّر التطبيق حتى تضغط «نشر المسودة للتطبيق» أعلى الصفحة. وتظهر الأذكار التي كتبتها بنفسك في نسخ التطبيق الحديثة فقط.</li>
          </ol>
        <?php endif; ?>
      </details>
      <div class="editor-grid">
        <section class="panel">
          <div class="row head"><h2>العناصر</h2><a class="button quiet" href="<?= e(route($section, $topic, 'new')) ?>">إضافة</a></div>
          <?php if ($rows === []): ?><p>لا توجد عناصر في هذا القسم.</p><?php endif; ?>
          <?php foreach ($rows as $index => $row): ?>
          <?php $key = $row['id'] ?? (string) $index; ?>
          <a class="entry" href="<?= e(route($section, $topic, $key)) ?>" <?= $key === $edit ? 'aria-current="true"' : '' ?>>
            <strong><?= $section === 'duas' ? e(verseRangeLabel($row)) : e($row['title']['ar']) ?></strong>
            <?php if ($section !== 'duas'): ?><span lang="en" dir="ltr"><?= e($row['title']['en']) ?></span><?php endif; ?>
          </a>
          <?php endforeach; ?>
        </section>
        <?php if ($current !== null || $edit === 'new'): ?>
        <section class="panel">
          <h2><?= $current !== null ? 'تعديل العنصر' : 'إضافة عنصر' ?></h2>
          <form method="post" enctype="multipart/form-data">
            <?php controls('save', $revision); ?>
            <input type="hidden" name="original" value="<?= $current !== null ? e($edit) : '' ?>">
            <?php if ($section === 'duas'): ?>
              <label>السورة
                <select name="surah" required>
                  <?php foreach ((require __DIR__ . '/quran-surahs.php') as $index => [$surahName, $verseCount]): ?>
                    <option value="<?= e($index + 1) ?>" <?= (int) ($current[0] ?? 0) === $index + 1 ? 'selected' : '' ?>><?= e(arabicDigits((string) ($index + 1)) . ' · ' . $surahName . ' (' . arabicDigits((string) $verseCount) . ' آية)') ?></option>
                  <?php endforeach; ?>
                </select>
              </label>
              <div class="fields">
                <label>أول آية<input name="first" type="number" min="1" value="<?= e($current[1] ?? '') ?>" required></label>
                <label>آخر آية<input name="last" type="number" min="1" value="<?= e($current[2] ?? '') ?>" required></label>
              </div>
            <?php else: ?>
              <label>العنوان بالعربية<input name="ar" value="<?= e($current['title']['ar'] ?? '') ?>" required></label>
              <label>العنوان بالإنجليزية<input name="en" dir="ltr" value="<?= e($current['title']['en'] ?? '') ?>" required></label>
              <?php if ($section === 'hisn'): ?>
                <label>أذكار وأدعية خاصة بهذا الموضوع
                  <textarea name="own_items" rows="10" placeholder="العنوان: دعاء الكرب&#10;لا إله إلا الله العظيم الحليم...&#10;المصدر: متفق عليه&#10;---&#10;النص التالي..."><?= e(hisnOwnText($current['entries'] ?? [])) ?></textarea>
                </label>
                <p class="hint">افصل بين كل ذكر والذي يليه بسطر فيه <bdi>---</bdi>. السطور التي تبدأ بـ «العنوان:» و«المصدر:» و<bdi>Title:</bdi> و<bdi>Source:</bdi> و<bdi>English:</bdi> اختيارية، وكل سطر غيرها هو نص الذكر. احذف الفقرة لحذف الذكر.</p>
                <label>أرقام أبواب حصن المسلم (اختياري)<input name="chapters" dir="ltr" value="<?= e(implode(', ', $current['chapterIds'] ?? [])) ?>"></label>
                <label>أرقام أحاديث HadeethEnc (اختياري)<input name="hadiths" dir="ltr" value="<?= e(implode(', ', $current['hadiths'] ?? [])) ?>"></label>
              <?php else: ?>
                <?php if ($current === null): ?><label>معرّف الذكر بالإنجليزية<input name="id" dir="ltr" pattern="[a-z0-9][a-z0-9-]{0,63}" required></label><?php endif; ?>
                <label><?= $section === 'daily_duas' ? 'نص الدعاء بالعربية' : 'نص الذكر بالعربية' ?><textarea name="wording" rows="5" <?= $section === 'daily_duas' ? 'required' : '' ?>><?= e($current['wording']['ar'] ?? '') ?></textarea></label>
                <label>المعنى بالإنجليزية<textarea name="meaning" dir="ltr" rows="3" <?= $section === 'daily_duas' ? 'required' : '' ?>><?= e($current['wording']['en'] ?? $current['wording']['draftMeaningEn'] ?? '') ?></textarea></label>
                <div class="fields">
                  <label>المصدر<input <?= $section === 'daily_duas' ? 'required' : '' ?> name="source_ar" value="<?= e($current['source']['ar'] ?? '') ?>" placeholder="رواه مسلم"></label>
                  <label>Source<input <?= $section === 'daily_duas' ? 'required' : '' ?> name="source_en" dir="ltr" value="<?= e($current['source']['en'] ?? '') ?>" placeholder="Muslim"></label>
                </div>
                <?php if ($section !== 'daily_duas'): ?>
                <label>رقم الحديث في HadeethEnc (اتركه فارغًا إن كتبت النص بنفسك)<input name="hadith" type="number" min="1" value="<?= e($current['hadith'] ?? '') ?>"></label>
                <?php if ($section === 'daily'): ?>
                  <fieldset><legend>مجموعات الذكر</legend>
                  <?php foreach ($draft['adhkar']['daily']['groups'] as $group): ?>
                    <label class="check"><input type="checkbox" name="groups[]" value="<?= e($group['id']) ?>" <?= $current !== null && in_array($edit, $group['entries'], true) ? 'checked' : '' ?>><?= e($group['title']['ar']) ?></label>
                  <?php endforeach; ?>
                  </fieldset>
                <?php endif; ?>
                <details>
                  <summary>المراجع والصيغ البديلة</summary>
                  <label>مراجع الآيات <span dir="ltr">[[2,255,255]]</span><textarea name="quran" dir="ltr"><?= e(fieldValue($current['quran'] ?? [])) ?></textarea></label>
                  <label>صيغ بديلة للذكر <span dir="ltr">[{"hadith":5490}]</span><textarea name="variants" dir="ltr"><?= e(fieldValue($current['variants'] ?? [])) ?></textarea></label>
                </details>
                <?php
                require_once __DIR__ . '/repeat-view.php';
                if (!empty($current['variants'])) {
                    foreach ($current['variants'] as $variant) {
                        repeatEditor('variant-' . $variant['hadith'], $variant['repeat'] ?? [], 'عدد التكرارات لصيغة الحديث ' . $variant['hadith']);
                    }
                } else {
                    repeatEditor('main', $current['repeat'] ?? [], 'عدد التكرارات');
                }
                ?>
                <?php endif; ?>
              <?php endif; ?>
            <?php endif; ?>
            <?php if (in_array($section, ['daily', 'merits', 'daily_duas', 'hisn'], true)): ?>
              <fieldset>
                <legend>التسجيلات الصوتية MP3</legend>
                <?php
                $recordings = [];
                if ($section === 'hisn') {
                    foreach ($current['entries'] ?? [] as $entry) {
                        $recordings[$entry['id']] = [$entry['title']['ar'], $entry['recording'] ?? null];
                    }
                } elseif (!empty($current['variants'])) {
                    foreach ($current['variants'] as $variant) {
                        $id = $variant['hadith'];
                        $recordings['main-' . $id] = ['صيغة الحديث ' . $id, $variant['recording'] ?? null];
                    }
                } else {
                    $recordings['main'] = ['تسجيل العنصر', $current['recording'] ?? null];
                }
                ?>
                <?php foreach ($recordings as $slot => [$label, $audio]): ?>
                  <label><?= e($label) ?><input type="file" name="devotional[<?= e($slot) ?>]" accept="audio/mpeg,.mp3"></label>
                  <?php if ($audio !== null): ?>
                    <p class="hint">تسجيل محفوظ. اختَر ملف MP3 جديدًا لاستبداله.</p>
                    <label class="check"><input type="checkbox" name="remove_devotional[<?= e($slot) ?>]" value="1">حذف التسجيل الحالي</label>
                  <?php endif; ?>
                <?php endforeach; ?>
                <?php if ($section === 'hisn' || $section === 'daily' || $section === 'merits'): ?>
                  <p class="hint">احفظ الصيغ الجديدة أولًا ثم أرفق تسجيل كل صيغة من هنا.</p>
                <?php endif; ?>
              </fieldset>
            <?php endif; ?>
            <button class="primary">حفظ في المسودة</button>
          </form>
          <?php if ($current !== null): ?>
            <?php if ($section === 'daily_duas' && allowedAction($user, 'save', $section)): ?>
              <form method="post" data-dua-drive>
                <?php controls('save', $revision); ?>
                <input type="hidden" name="op" value="drive_dua_audio">
                <input type="hidden" name="original" value="<?= e($edit) ?>">
                <label>استيراد MP3 من Google Drive
                  <input type="url" name="drive_url" dir="ltr" placeholder="https://drive.google.com/file/d/…/view" maxlength="2048" required>
                </label>
                <p class="hint">الصق رابط الملف الذي يمكن تنزيله بواسطة «أي شخص لديه الرابط». الاستيراد يستبدل تسجيل هذا الدعاء في المسودة.</p>
                <button class="quiet" data-dua-drive-button>جلب التسجيل وحفظه</button>
                <p class="hint" role="status" data-dua-drive-status hidden></p>
              </form>
            <?php endif; ?>
            <form method="post" class="delete-form">
              <?php controls('delete', $revision); ?>
              <input type="hidden" name="original" value="<?= e($edit) ?>">
              <button class="quiet danger">حذف من المسودة</button>
            </form>
            <?php require __DIR__ . '/preview-view.php'; ?>
          <?php endif; ?>
        </section>
        <?php endif; ?>
      </div>
    <?php endif; ?>
  </main>
</div>
<?php endif; ?>
<script src="admin.js?v=<?= e((string) @filemtime(__DIR__ . '/admin.js')) ?>" defer></script>
</body>
</html>
