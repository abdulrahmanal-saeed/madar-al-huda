<?php
declare(strict_types=1);

/**
 * Accounts: several people sign in, each with a role, a password and an
 * optional authenticator-app code (TOTP, RFC 6238).
 */
const ROLES = ['owner' => 'المالك', 'reviewer' => 'مراجع شرعي', 'editor' => 'محرر'];

function usersTable(PDO $db): void
{
    $db->exec('CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY, username TEXT NOT NULL UNIQUE, password TEXT NOT NULL,
        role TEXT NOT NULL, totp_secret TEXT, totp_last INTEGER NOT NULL DEFAULT 0,
        disabled INTEGER NOT NULL DEFAULT 0, created INTEGER NOT NULL
    )');
    // The single account from before becomes the owner.
    if ((int) $db->query('SELECT COUNT(*) FROM users')->fetchColumn() === 0) {
        $hash = accountPassword($db);
        if ($hash !== false) {
            $db->prepare('INSERT INTO users (id, username, password, role, created) VALUES (1, ?, ?, ?, ?)')
                ->execute(['owner', $hash, 'owner', time()]);
        }
    }
}

function userById(PDO $db, int $id): ?array
{
    $query = $db->prepare('SELECT * FROM users WHERE id = ? AND disabled = 0');
    $query->execute([$id]);
    return $query->fetch() ?: null;
}

function base32Encode(string $bytes): string
{
    $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    $bits = '';
    foreach (str_split($bytes) as $byte) {
        $bits .= str_pad(decbin(ord($byte)), 8, '0', STR_PAD_LEFT);
    }
    $out = '';
    foreach (str_split($bits, 5) as $chunk) {
        $out .= $alphabet[bindec(str_pad($chunk, 5, '0'))];
    }
    return $out;
}

function base32Decode(string $text): string
{
    $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    $bits = '';
    foreach (str_split(strtoupper(preg_replace('/[^A-Za-z2-7]/', '', $text))) as $char) {
        $bits .= str_pad(decbin(strpos($alphabet, $char)), 5, '0', STR_PAD_LEFT);
    }
    $out = '';
    foreach (str_split($bits, 8) as $chunk) {
        if (strlen($chunk) === 8) {
            $out .= chr(bindec($chunk));
        }
    }
    return $out;
}

/** The six-digit code for a 30-second [$step]. */
function totpCode(string $secret, int $step): string
{
    $hash = hash_hmac('sha1', pack('J', $step), base32Decode($secret), true);
    $offset = ord($hash[19]) & 0x0f;
    $value = ((ord($hash[$offset]) & 0x7f) << 24) | (ord($hash[$offset + 1]) << 16)
        | (ord($hash[$offset + 2]) << 8) | ord($hash[$offset + 3]);
    return str_pad((string) ($value % 1000000), 6, '0', STR_PAD_LEFT);
}

/**
 * The step a code matches, allowing one step of clock drift, or null. A
 * step already used ([$last]) is refused so a code works once.
 */
function totpStep(string $secret, string $code, int $last = 0, ?int $now = null): ?int
{
    $code = preg_replace('/\D/', '', strtr($code, ['٠' => '0', '١' => '1', '٢' => '2', '٣' => '3', '٤' => '4', '٥' => '5', '٦' => '6', '٧' => '7', '٨' => '8', '٩' => '9']));
    if (strlen($code) !== 6) {
        return null;
    }
    $current = intdiv($now ?? time(), 30);
    foreach ([$current, $current - 1, $current + 1] as $step) {
        if ($step > $last && hash_equals(totpCode($secret, $step), $code)) {
            return $step;
        }
    }
    return null;
}

function newTotpSecret(): string
{
    return base32Encode(random_bytes(20));
}

function totpUri(string $secret, string $username): string
{
    return 'otpauth://totp/' . rawurlencode('مدار الهدى:' . $username)
        . '?secret=' . $secret . '&issuer=' . rawurlencode('مدار الهدى');
}

/**
 * Signs a user in. Failures are counted per address and per account, so
 * guessing one account from many addresses is slowed too.
 */
function signIn(PDO $db): ?array
{
    $username = strtolower(field('username')) ?: 'owner';
    $password = $_POST['password'] ?? '';
    if (!is_string($password) || strlen($password) > 72) {
        return null;
    }
    $buckets = [
        hash('sha256', 'login|' . ($_SERVER['REMOTE_ADDR'] ?? 'local')),
        hash('sha256', 'account|' . $username),
    ];
    $now = time();
    return locked($db, function () use ($db, $username, $password, $buckets, $now): ?array {
        $limits = [8, 20];
        foreach ($buckets as $index => $bucket) {
            $query = $db->prepare('SELECT started, count FROM auth_attempts WHERE bucket = ?');
            $query->execute([$bucket]);
            $row = $query->fetch();
            if ($row !== false && $now - (int) $row['started'] < 600 && (int) $row['count'] >= $limits[$index]) {
                return null;
            }
        }
        $query = $db->prepare('SELECT * FROM users WHERE username = ? AND disabled = 0');
        $query->execute([$username]);
        $user = $query->fetch() ?: null;
        $ok = $user !== null && password_verify($password, $user['password']);
        if ($ok && $user['totp_secret']) {
            $step = totpStep($user['totp_secret'], field('code'), (int) $user['totp_last'], $now);
            $ok = $step !== null;
            if ($ok) {
                $db->prepare('UPDATE users SET totp_last = ? WHERE id = ?')->execute([$step, $user['id']]);
            }
        }
        foreach ($buckets as $bucket) {
            if ($ok) {
                $db->prepare('DELETE FROM auth_attempts WHERE bucket = ?')->execute([$bucket]);
                continue;
            }
            $query = $db->prepare('SELECT started, count FROM auth_attempts WHERE bucket = ?');
            $query->execute([$bucket]);
            $row = $query->fetch();
            $recent = $row !== false && $now - (int) $row['started'] < 600;
            $db->prepare('INSERT INTO auth_attempts (bucket, started, count) VALUES (?, ?, ?) '
                . 'ON CONFLICT(bucket) DO UPDATE SET started = excluded.started, count = excluded.count')
                ->execute([$bucket, $recent ? (int) $row['started'] : $now, $recent ? (int) $row['count'] + 1 : 1]);
        }
        return $ok ? $user : null;
    });
}

/** Account changes by the signed-in user; returns the notice. */
function changeAccount(PDO $db, array $user, string $action): string
{
    $verifyPassword = function () use ($user): void {
        $current = $_POST['current_password'] ?? '';
        if (!is_string($current) || !password_verify($current, $user['password'])) {
            throw new InvalidArgumentException('كلمة المرور الحالية غير صحيحة.');
        }
    };
    if ($action === 'password_change') {
        $verifyPassword();
        $next = $_POST['new_password'] ?? '';
        if (!is_string($next) || strlen($next) < 12 || strlen($next) > 72) {
            throw new InvalidArgumentException('اختر كلمة مرور من ١٢ حرفًا على الأقل.');
        }
        if ($next !== ($_POST['confirm_password'] ?? '')) {
            throw new InvalidArgumentException('تأكيد كلمة المرور لا يطابقها.');
        }
        if (password_verify($next, $user['password'])) {
            throw new InvalidArgumentException('اختر كلمة مرور مختلفة عن الحالية.');
        }
        $hash = password_hash($next, PASSWORD_DEFAULT);
        $db->prepare('UPDATE users SET password = ? WHERE id = ?')->execute([$hash, $user['id']]);
        if ((int) $user['id'] === 1) {
            // Kept in step with the original single account.
            $db->prepare('UPDATE admin SET password = ? WHERE id = 1')->execute([$hash]);
        }
        return 'تم تغيير كلمة المرور.';
    }
    if ($action === 'totp_enable') {
        $secret = $_SESSION['totp_pending'] ?? '';
        if (!is_string($secret) || $secret === '') {
            throw new InvalidArgumentException('ابدأ إعداد التحقق بخطوتين من جديد.');
        }
        $step = totpStep($secret, field('code'));
        if ($step === null) {
            throw new InvalidArgumentException('الرمز غير صحيح. تأكّد من ضبط الوقت على هاتفك ثم أعد المحاولة.');
        }
        $db->prepare('UPDATE users SET totp_secret = ?, totp_last = ? WHERE id = ?')->execute([$secret, $step, $user['id']]);
        unset($_SESSION['totp_pending']);
        return 'فُعّل التحقق بخطوتين. ستحتاج رمز التطبيق عند كل دخول.';
    }
    if ($action === 'totp_disable') {
        $verifyPassword();
        if (!$user['totp_secret'] || totpStep($user['totp_secret'], field('code'), (int) $user['totp_last']) === null) {
            throw new InvalidArgumentException('رمز التطبيق غير صحيح.');
        }
        $db->prepare('UPDATE users SET totp_secret = NULL, totp_last = 0 WHERE id = ?')->execute([$user['id']]);
        return 'أُوقف التحقق بخطوتين.';
    }
    throw new InvalidArgumentException('الإجراء غير متاح.');
}
