<?php
declare(strict_types=1);

const ROOT = __DIR__ . '/..';
// The app refuses a library feed above this size (HostedFeed.maxBytes).
const FEED_MAX_BYTES = 4 * 1024 * 1024;
// App builds released before the limit was raised stop at 1 MB.
const FEED_LEGACY_BYTES = 1024 * 1024;
// Raise only when the feed changes in a way older apps cannot read; the app
// accepts this version or lower (ManagedFeedVersion.schema).
const FEED_SCHEMA_VERSION = 1;
// Dashboard-written adhkar (no HadeethEnc number, or Hisn own items) need
// shape 2; older apps keep their last library instead of failing on them.
const FEED_SCHEMA_OWN_ADHKAR = 2;

function arabicDigits(string $text): string
{
    return strtr($text, ['0' => '٠', '1' => '١', '2' => '٢', '3' => '٣', '4' => '٤',
        '5' => '٥', '6' => '٦', '7' => '٧', '8' => '٨', '9' => '٩']);
}

/** «آل عمران ١٦» or «الأعراف ١٥٥–١٥٦» for a [surah, first, last] range. */
function verseRangeLabel(array $range): string
{
    static $surahs = null;
    $surahs ??= require __DIR__ . '/quran-surahs.php';
    [$surah, $first, $last] = $range;
    $name = $surahs[$surah - 1][0] ?? ('سورة ' . $surah);
    return $name . ' ' . arabicDigits($first === $last ? (string) $first : "{$first}–{$last}");
}

/** The publish time of a history entry, in the owner's time zone. */
function publishedLabel(?int $timestamp): string
{
    if ($timestamp === null) {
        return '';
    }
    $date = new DateTimeImmutable('@' . $timestamp);
    return arabicDigits($date->setTimezone(new DateTimeZone('Asia/Dubai'))->format('Y-m-d H:i'));
}

function feedSizeLabel(int $bytes): string
{
    $digits = static fn (string $text): string => strtr($text, ['0' => '٠', '1' => '١', '2' => '٢', '3' => '٣', '4' => '٤', '5' => '٥', '6' => '٦', '7' => '٧', '8' => '٨', '9' => '٩', '.' => '٫']);
    return $bytes >= 1024 * 1024
        ? $digits(number_format($bytes / 1048576, 1)) . ' ميغابايت'
        : $digits((string) max(1, (int) round($bytes / 1024))) . ' كيلوبايت';
}

function encode(array $data): string
{
    return json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR);
}

function storage(): string
{
    $web = realpath(ROOT);
    if ($web === false) {
        throw new RuntimeException('Document root is unavailable');
    }
    $directory = dirname($web) . DIRECTORY_SEPARATOR . '.madar-admin';
    if (!is_dir($directory) && !@mkdir($directory, 0700) && !is_dir($directory)) {
        throw new RuntimeException('Private storage is unavailable');
    }
    if (is_link($directory) || !is_writable($directory)) {
        throw new RuntimeException('Private storage is invalid');
    }
    return $directory;
}

function database(): PDO
{
    umask(0077);
    $db = new PDO('sqlite:' . storage() . '/library.sqlite3', null, null, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    $db->exec('PRAGMA busy_timeout = 4000');
    $db->exec('CREATE TABLE IF NOT EXISTS admin (id INTEGER PRIMARY KEY, password TEXT NOT NULL)');
    $db->exec('CREATE TABLE IF NOT EXISTS auth_attempts (bucket TEXT PRIMARY KEY, started INTEGER NOT NULL, count INTEGER NOT NULL)');
    $db->exec('CREATE TABLE IF NOT EXISTS library (id INTEGER PRIMARY KEY, draft TEXT NOT NULL, revision INTEGER NOT NULL, published TEXT)');
    $db->exec('CREATE TABLE IF NOT EXISTS publications (revision INTEGER PRIMARY KEY, body TEXT NOT NULL)');
    $columns = array_column($db->query('PRAGMA table_info(publications)')->fetchAll(), 'name');
    if (!in_array('published_at', $columns, true)) {
        $db->exec('ALTER TABLE publications ADD COLUMN published_at INTEGER');
    }
    return $db;
}

function locked(PDO $db, callable $work): mixed
{
    $db->exec('BEGIN IMMEDIATE');
    try {
        $result = $work();
        $db->exec('COMMIT');
        return $result;
    } catch (Throwable $error) {
        $db->exec('ROLLBACK');
        throw $error;
    }
}

function accountPassword(PDO $db): string|false
{
    return $db->query('SELECT password FROM admin WHERE id = 1')->fetchColumn();
}

function authorize(PDO $db, string $action, array $seed): bool
{
    $password = $_POST['password'] ?? '';
    if (!is_string($password) || strlen($password) > 72) {
        return false;
    }
    $bucket = hash('sha256', $action . '|' . ($_SERVER['REMOTE_ADDR'] ?? 'local'));
    $now = time();
    return locked($db, function () use ($db, $action, $password, $seed, $bucket, $now): bool {
        $query = $db->prepare('SELECT started, count FROM auth_attempts WHERE bucket = ?');
        $query->execute([$bucket]);
        $previous = $query->fetch();
        $recent = $previous !== false && $now - (int) $previous['started'] < 600;
        if ($recent && (int) $previous['count'] >= 8) {
            return false;
        }
        $hash = accountPassword($db);
        $ok = false;
        if ($action === 'setup' && $hash === false) {
            $config = __DIR__ . '/setup-config.php';
            $expected = is_file($config) ? require $config : null;
            $provided = field('setup_code');
            $confirmation = $_POST['confirm_password'] ?? '';
            if (is_string($expected) && strlen($password) >= 12 &&
                $password === $confirmation &&
                hash_equals($expected, hash('sha256', $provided))) {
                $insert = $db->prepare('INSERT INTO admin (id, password) VALUES (1, ?)');
                $insert->execute([password_hash($password, PASSWORD_DEFAULT)]);
                $initialize = $db->prepare(
                    'INSERT INTO library (id, draft, revision, published) VALUES (1, ?, 1, NULL)',
                );
                $initialize->execute([encode($seed['library'])]);
                // The one-time setup code is no longer needed once an owner exists.
                @unlink($config);
                $ok = true;
            }
        } elseif ($action === 'login' && $hash !== false) {
            $ok = password_verify($password, $hash);
        }
        if ($ok) {
            $clear = $db->prepare('DELETE FROM auth_attempts WHERE bucket = ?');
            $clear->execute([$bucket]);
        } else {
            $insert = $db->prepare(
                'INSERT INTO auth_attempts (bucket, started, count) VALUES (?, ?, ?) '
                . 'ON CONFLICT(bucket) DO UPDATE SET started = excluded.started, count = excluded.count',
            );
            $insert->execute([
                $bucket,
                $recent ? (int) $previous['started'] : $now,
                $recent ? (int) $previous['count'] + 1 : 1,
            ]);
        }
        return $ok;
    });
}

function library(PDO $db): array
{
    $row = $db->query('SELECT draft, revision, published FROM library WHERE id = 1')->fetch();
    if ($row === false) {
        throw new RuntimeException('Library is not initialized');
    }
    return $row;
}

function updateLibrary(PDO $db, string $action, array $seed, string $section, string $topic, ?array $user = null): void
{
    $revision = integer(field('revision'), 1, PHP_INT_MAX);
    locked($db, function () use ($db, $revision, $action, $seed, $section, $topic, $user): void {
        $row = library($db);
        if ((int) $row['revision'] !== $revision) {
            throw new InvalidArgumentException('تغيّرت المسودة. أعِد فتح العنصر ثم احفظ التعديل.');
        }
        $draft = $row['draft'];
        if ($action === 'publish') {
            $payload = json_decode($draft, true, 64, JSON_THROW_ON_ERROR);
            assertReadableTheme($payload);
            // Fiqh goes out only as a scholarly reviewer approved it.
            $pending = unreviewedFiqh($payload);
            if ($pending !== []) {
                throw new InvalidArgumentException('مسائل فقه تحتاج اعتمادًا شرعيًا قبل النشر: '
                    . implode('، ', array_map(fn ($item) => $item['title']['ar'] ?? $item['id'], $pending)) . '.');
            }
            if (strlen($draft) > FEED_MAX_BYTES) {
                throw new InvalidArgumentException('حجم المكتبة ' . feedSizeLabel(strlen($draft)) .
                    ' ويتجاوز الحد الذي يقبله التطبيق (' . feedSizeLabel(FEED_MAX_BYTES) . '). احذف أو اختصر بعض المحتوى ثم انشر.');
            }
            $current = $db->prepare('UPDATE library SET published = ? WHERE id = 1');
            $current->execute([$draft]);
            $history = $db->prepare('INSERT OR IGNORE INTO publications (revision, body, published_at) VALUES (?, ?, ?)');
            $history->execute([$revision, $draft, time()]);
            return;
        }
        if ($action === 'restore') {
            $old = $db->prepare('SELECT body FROM publications WHERE revision = ?');
            $old->execute([integer(field('publication'), 1, PHP_INT_MAX)]);
            $draft = $old->fetchColumn();
            if ($draft === false) {
                throw new InvalidArgumentException('الإصدار غير موجود.');
            }
        } else {
            $content = json_decode($draft, true, 64, JSON_THROW_ON_ERROR);
            $delete = $action === 'delete';
            $draft = encode(match (true) {
                $action === 'review_approve' => approveFiqh($content, $user ?? []),
                $section === 'reciters' => changeReaders($content, $delete),
                $section === 'appearance' => changeAppearance($content, $delete),
                $section === 'app_settings' => changeAppSettings($content),
                $section === 'story_titles' => changeStoryTitles($content),
                $section === 'adhkar_groups' => changeAdhkarGroups($content),
                $section === 'library_sections' => changeSections($content, $delete),
                in_array($section, BOOK_SECTIONS, true) => changeBook($content, $section, $delete),
                default => changeContent($content, $seed['ayahCounts'], $section, $topic, $delete),
            });
        }
        $save = $db->prepare('UPDATE library SET draft = ?, revision = revision + 1 WHERE id = 1');
        $save->execute([$draft]);
    });
}

function serveFeed(PDO $db): never
{
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-cache');
    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    if (!in_array($method, ['GET', 'HEAD'], true)) {
        header('Allow: GET, HEAD');
        http_response_code(405);
        exit;
    }
    $body = $db->query('SELECT published FROM library WHERE id = 1')->fetchColumn();
    if (!is_string($body)) {
        http_response_code(404);
        if ($method === 'GET') {
            echo '{"error":"no_publication"}';
        }
        exit;
    }
    // Every feed states its shape, so an app that cannot read a later shape
    // keeps the last feed it could (see FEED_SCHEMA_VERSION).
    $payload = json_decode($body, true, 64, JSON_THROW_ON_ERROR);
    $schema = hasOwnAdhkar($payload['library'] ?? $payload) ? FEED_SCHEMA_OWN_ADHKAR : FEED_SCHEMA_VERSION;
    $payload = ['schemaVersion' => $schema] + $payload;
    $body = encode($payload);
    $etag = '"' . hash('sha256', $body) . '"';
    header('ETag: ' . $etag);
    if (trim($_SERVER['HTTP_IF_NONE_MATCH'] ?? '') === $etag) {
        http_response_code(304);
        exit;
    }
    if ($method === 'GET') {
        echo $body;
    }
    exit;
}
