<?php
declare(strict_types=1);

const RELEASE_CHANNELS = ['dev', 'preview'];
const MAX_APK_BYTES = 200 * 1024 * 1024;

function releaseTable(PDO $db): void
{
    $db->exec('CREATE TABLE IF NOT EXISTS app_releases (
        channel TEXT NOT NULL, code INTEGER NOT NULL, name TEXT NOT NULL,
        bytes INTEGER NOT NULL, sha256 TEXT NOT NULL, notes TEXT NOT NULL,
        published INTEGER NOT NULL DEFAULT 0, notify INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (channel, code)
    )');
}

function releaseFile(string $channel, int $code): string
{
    return storage() . "/apk/$channel-$code.apk";
}

function currentRelease(PDO $db, string $channel): ?array
{
    $query = $db->prepare('SELECT * FROM app_releases WHERE channel = ? AND published = 1 ORDER BY code DESC LIMIT 1');
    $query->execute([$channel]);
    return $query->fetch() ?: null;
}

function releasesRequest(): void
{
    if (!in_array($_SERVER['REQUEST_METHOD'] ?? '', ['GET', 'HEAD'], true)) {
        header('Allow: GET, HEAD');
        http_response_code(405);
        exit;
    }
}

function releaseChannel(mixed $value): string
{
    if (!in_array($value, RELEASE_CHANNELS, true)) {
        throw new InvalidArgumentException('اختر قناة إصدار صالحة.');
    }
    return $value;
}

function verifiedApkFile(string $file, int $size): bool
{
    $zip = new ZipArchive();
    if ($zip->open($file, ZipArchive::RDONLY) !== true) {
        return false;
    }
    try {
        if ($zip->locateName('AndroidManifest.xml') === false ||
            $zip->locateName('classes.dex') === false) {
            return false;
        }
    } finally {
        $zip->close();
    }
    // Modern signed APKs declare an APK Signing Block before the ZIP directory.
    // Android verifies the signer, certificate continuity and manifest on install.
    $handle = fopen($file, 'rb');
    if ($handle === false) {
        return false;
    }
    try {
        $directory = apkCentralDirectory($handle, $size);
        return $directory !== null &&
            fseek($handle, $directory - 16) === 0 &&
            fread($handle, 16) === 'APK Sig Block 42';
    } finally {
        fclose($handle);
    }
}

function stageRelease(PDO $db, string $channel, int $code): void
{
    $name = field('name');
    if (!preg_match('/\A\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?\z/D', $name) ||
        ($channel === 'dev' && !str_ends_with($name, "-dev.$code"))) {
        throw new InvalidArgumentException('أدخل اسم الإصدار المطابق للـAPK.');
    }
    $upload = $_FILES['apk'] ?? null;
    if (!is_array($upload) || $upload['error'] !== UPLOAD_ERR_OK ||
        !is_string($upload['tmp_name']) || !is_uploaded_file($upload['tmp_name']) ||
        !is_string($upload['name']) || !str_ends_with(strtolower($upload['name']), '.apk')) {
        throw new InvalidArgumentException('اختَر APK ضمن حد الرفع المسموح في إعدادات الاستضافة.');
    }
    $temporary = $upload['tmp_name'];
    $size = filesize($temporary);
    if ($size === false || $size < 1024 || $size > MAX_APK_BYTES ||
        !verifiedApkFile($temporary, $size)) {
        throw new InvalidArgumentException('ارفع APK موقّعًا بحجم أقصاه ٢٠٠ ميغابايت.');
    }
    if (!apkMatchesChannelSigner($temporary, $channel)) {
        throw new InvalidArgumentException('الـAPK موقّع بمفتاح مختلف عن مفتاح القناة، فلن يُحدِّث التطبيق المثبّت.');
    }
    $sha = hash_file('sha256', $temporary);
    if ($sha === false) {
        throw new RuntimeException('Cannot calculate APK hash');
    }
    $notes = ['ar' => field('notes_ar'), 'en' => field('notes_en')];
    if (max(strlen($notes['ar']), strlen($notes['en'])) > 4000) {
        throw new InvalidArgumentException('اختصر ملاحظات الإصدار.');
    }
    $target = releaseFile($channel, $code);
    $folder = dirname($target);
    if ((!is_dir($folder) && !@mkdir($folder, 0700) && !is_dir($folder)) || is_link($folder)) {
        throw new RuntimeException('Private APK storage unavailable');
    }
    $moved = false;
    try {
        locked($db, function () use ($db, $channel, $code, $name, $size, $sha, $notes, $temporary, $target, &$moved): void {
            $current = currentRelease($db, $channel);
            if ($current !== null && (int) $current['code'] >= $code) {
                throw new InvalidArgumentException('استخدم رقم بناء أكبر من آخر إصدار منشور.');
            }
            $insert = $db->prepare('INSERT OR IGNORE INTO app_releases
                (channel, code, name, bytes, sha256, notes) VALUES (?, ?, ?, ?, ?, ?)');
            $insert->execute([$channel, $code, $name, $size, $sha, encode($notes)]);
            if ($insert->rowCount() !== 1) {
                throw new InvalidArgumentException('رقم البناء موجود في القناة بالفعل.');
            }
            if (!move_uploaded_file($temporary, $target)) {
                throw new RuntimeException('Cannot store APK upload');
            }
            $moved = true;
            chmod($target, 0600);
        });
    } catch (Throwable $failure) {
        if ($moved) {
            @unlink($target);
        }
        throw $failure;
    }
}

function changeRelease(PDO $db, string $action): string
{
    $channel = releaseChannel(field('channel'));
    $code = integer(field('code'), 1, 2100000000);
    if ($action === 'release_upload') {
        stageRelease($db, $channel, $code);
        return 'تم حفظ APK كمسودة.';
    }
    return locked($db, function () use ($db, $action, $channel, $code): string {
        $active = currentRelease($db, $channel);
        if ($action === 'release_withdraw') {
            if ($active === null || (int) $active['code'] !== $code) {
                throw new InvalidArgumentException('يمكن سحب الإصدار المنشور الحالي فقط.');
            }
            $db->prepare('UPDATE app_releases SET published = 0, notify = 0 WHERE channel = ? AND code = ?')
                ->execute([$channel, $code]);
            $previous = currentRelease($db, $channel);
            return $previous === null
                ? 'سُحب الإصدار. لا يوجد إصدار منشور في هذه القناة الآن.'
                : 'سُحب الإصدار، والمتاح الآن ' . $previous['name'] . '.';
        }
        if ($action === 'release_notify') {
            if ($active === null || (int) $active['code'] !== $code) {
                throw new InvalidArgumentException('الإشعار متاح لآخر إصدار منشور.');
            }
            $db->prepare('UPDATE app_releases SET notify = 1 WHERE channel = ? AND code = ?')
                ->execute([$channel, $code]);
            return 'تم تفعيل إشعار التحديث للأجهزة عند فحص التحديثات.';
        }
        if (($active !== null && (int) $active['code'] >= $code) ||
            !is_file(releaseFile($channel, $code))) {
            throw new InvalidArgumentException('اختر مسودة برقم بناء أكبر من الإصدار المنشور.');
        }
        $query = $db->prepare('UPDATE app_releases SET published = 1 WHERE channel = ? AND code = ? AND published = 0');
        $query->execute([$channel, $code]);
        if ($query->rowCount() !== 1) {
            throw new InvalidArgumentException('مسودة الإصدار غير متاحة.');
        }
        return 'اتاح الموقع تنزيل الإصدار.';
    });
}

function serveReleaseFeed(PDO $db, mixed $value): never
{
    releasesRequest();
    try {
        $channel = releaseChannel($value);
    } catch (InvalidArgumentException) {
        http_response_code(400);
        exit;
    }
    $row = currentRelease($db, $channel);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-cache');
    if ($_SERVER['REQUEST_METHOD'] !== 'HEAD') {
        echo encode(['version' => 1, 'release' => $row === null ? null : [
            'code' => (int) $row['code'],
            'name' => $row['name'],
            'bytes' => (int) $row['bytes'],
            'sha256' => $row['sha256'],
            'notify' => (bool) $row['notify'],
            'notes' => json_decode($row['notes'], true, 8, JSON_THROW_ON_ERROR),
        ]]);
    }
    exit;
}

function serveApk(PDO $db, mixed $id): never
{
    releasesRequest();
    if (!is_string($id) || !preg_match('/\A(dev|preview)-([1-9]\d{0,9})\z/D', $id, $parts)) {
        http_response_code(404);
        exit;
    }
    $query = $db->prepare('SELECT name, bytes FROM app_releases WHERE channel = ? AND code = ? AND published = 1');
    $query->execute([$parts[1], (int) $parts[2]]);
    $row = $query->fetch();
    $path = releaseFile($parts[1], (int) $parts[2]);
    if ($row === false || !is_file($path) || filesize($path) !== (int) $row['bytes']) {
        http_response_code(404);
        exit;
    }
    header('Content-Type: application/vnd.android.package-archive');
    header('Content-Length: ' . $row['bytes']);
    header('Content-Disposition: attachment; filename="madar-al-huda-' . $row['name'] . '.apk"');
    header('Cache-Control: public, max-age=86400, immutable');
    if ($_SERVER['REQUEST_METHOD'] !== 'HEAD') {
        readfile($path);
    }
    exit;
}

/**
 * Publishes a dev build sent by the release workflow. The request carries a
 * token whose SHA-256 is kept in private storage (ci-release-token.sha256);
 * without that file the endpoint does not exist. The APK passes the same
 * checks as a manual upload: signed APK, the dev channel's signing key, a
 * matching name and a build number above the published one.
 */
function receiveCiRelease(PDO $db): never
{
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    $respond = static function (int $status, string $message): never {
        http_response_code($status);
        echo encode(['message' => $message]);
        exit;
    };
    $tokenFile = storage() . '/ci-release-token.sha256';
    $expected = is_file($tokenFile) ? trim((string) file_get_contents($tokenFile)) : '';
    if (!preg_match('/\A[0-9a-f]{64}\z/D', $expected)) {
        $respond(404, 'not found');
    }
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
        header('Allow: POST');
        $respond(405, 'POST only');
    }
    $token = $_SERVER['HTTP_X_MADAR_TOKEN'] ?? '';
    if (!is_string($token) || strlen($token) < 32 || !hash_equals($expected, hash('sha256', $token))) {
        sleep(1);
        $respond(403, 'forbidden');
    }
    $channel = 'dev';
    $code = (int) ($_SERVER['HTTP_X_RELEASE_CODE'] ?? 0);
    $name = (string) ($_SERVER['HTTP_X_RELEASE_NAME'] ?? '');
    if ($code < 1 || $code > 2100000000 ||
        !preg_match('/\A\d+\.\d+\.\d+-dev\.' . $code . '\z/D', $name)) {
        $respond(422, 'name and code do not match');
    }
    $notes = ['ar' => 'تحديث تجريبي جديد من مدار الهدى.', 'en' => 'New development build of Madar Al-Huda.'];
    $sent = base64_decode((string) ($_SERVER['HTTP_X_RELEASE_NOTES'] ?? ''), true);
    if ($sent !== false && $sent !== '') {
        $decoded = json_decode($sent, true);
        if (is_array($decoded)) {
            foreach (['ar', 'en'] as $language) {
                if (is_string($decoded[$language] ?? null) && trim($decoded[$language]) !== '') {
                    $notes[$language] = mb_substr(trim($decoded[$language]), 0, 1000);
                }
            }
        }
    }

    $folder = storage() . '/apk';
    if ((!is_dir($folder) && !@mkdir($folder, 0700) && !is_dir($folder)) || is_link($folder)) {
        $respond(500, 'storage unavailable');
    }
    $temporary = $folder . '/incoming-' . bin2hex(random_bytes(8)) . '.apk';
    // exit skips finally blocks; this removes a rejected upload either way.
    register_shutdown_function(static function () use ($temporary): void {
        if (is_file($temporary)) {
            @unlink($temporary);
        }
    });
    $in = fopen('php://input', 'rb');
    $out = fopen($temporary, 'xb');
    if ($in === false || $out === false) {
        $respond(500, 'cannot read upload');
    }
    $size = stream_copy_to_stream($in, $out, MAX_APK_BYTES + 1);
    fclose($in);
    fclose($out);
    chmod($temporary, 0600);
    if ($size === false || $size < 1024 || $size > MAX_APK_BYTES || !verifiedApkFile($temporary, $size)) {
        $respond(422, 'not a signed APK');
    }
    if (!apkMatchesChannelSigner($temporary, $channel)) {
        $respond(422, 'signed with a different key than the dev channel');
    }
    $sha = hash_file('sha256', $temporary);
    $target = releaseFile($channel, $code);
    $published = locked($db, function () use ($db, $channel, $code, $name, $size, $sha, $notes, $temporary, $target): ?int {
        $current = currentRelease($db, $channel);
        if ($current !== null && (int) $current['code'] >= $code) {
            return (int) $current['code'];
        }
        if (!rename($temporary, $target)) {
            throw new RuntimeException('Cannot store APK');
        }
        $db->prepare('INSERT OR REPLACE INTO app_releases
            (channel, code, name, bytes, sha256, notes, published, notify) VALUES (?, ?, ?, ?, ?, ?, 1, 1)')
            ->execute([$channel, $code, $name, $size, $sha, encode($notes)]);
        return null;
    });
    if ($published !== null) {
        $respond(409, "build $published is already published");
    }
    $respond(201, "published $name");
}
