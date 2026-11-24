<?php
declare(strict_types=1);

/*
 * Problem reports and suggestions sent from the app's «أبلغ عن مشكلة أو
 * اقترح» form. Kept here for the owner and emailed to the address set on
 * the reports page; nothing about the sender is stored but what they typed
 * and a salted hash of their address for rate limiting.
 */

const REPORT_KINDS = ['problem' => 'مشكلة', 'suggestion' => 'اقتراح'];
const REPORT_HOURLY_PER_SENDER = 5;
const REPORT_DAILY_TOTAL = 300;

function reportsTable(PDO $db): void
{
    $db->exec('CREATE TABLE IF NOT EXISTS reports (
        id INTEGER PRIMARY KEY,
        at INTEGER NOT NULL,
        kind TEXT NOT NULL,
        message TEXT NOT NULL,
        contact TEXT NOT NULL DEFAULT \'\',
        app TEXT NOT NULL DEFAULT \'\',
        sender TEXT NOT NULL DEFAULT \'\',
        done INTEGER NOT NULL DEFAULT 0
    )');
    $db->exec('CREATE TABLE IF NOT EXISTS admin_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
}

function adminSetting(PDO $db, string $key): string
{
    $query = $db->prepare('SELECT value FROM admin_settings WHERE key = ?');
    $query->execute([$key]);
    return (string) ($query->fetchColumn() ?: '');
}

function setAdminSetting(PDO $db, string $key, string $value): void
{
    $db->prepare('INSERT INTO admin_settings (key, value) VALUES (?, ?)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value')->execute([$key, $value]);
}

/** A salted hash of the sender's address: enough to rate-limit, not to trace. */
function reportSender(): string
{
    $saltFile = storage() . '/report-salt';
    if (!is_file($saltFile)) {
        @file_put_contents($saltFile, bin2hex(random_bytes(16)), LOCK_EX);
        @chmod($saltFile, 0600);
    }
    $salt = (string) @file_get_contents($saltFile);
    return substr(hash('sha256', $salt . '|' . ($_SERVER['REMOTE_ADDR'] ?? '')), 0, 32);
}

/** POST ?report=1 with JSON {kind, message, contact?, app?}. */
function receiveReport(PDO $db): never
{
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    $respond = static function (int $status, string $message): never {
        http_response_code($status);
        echo encode(['ok' => $status < 300, 'message' => $message]);
        exit;
    };
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
        header('Allow: POST');
        $respond(405, 'POST only');
    }
    $raw = file_get_contents('php://input', false, null, 0, 16384);
    $data = json_decode(is_string($raw) ? $raw : '', true);
    if (!is_array($data)) {
        $respond(400, 'bad request');
    }
    $kind = is_string($data['kind'] ?? null) ? $data['kind'] : '';
    $message = is_string($data['message'] ?? null) ? trim($data['message']) : '';
    $contact = is_string($data['contact'] ?? null) ? trim($data['contact']) : '';
    $app = is_string($data['app'] ?? null) ? trim($data['app']) : '';
    // Control characters other than new lines never reach the page or mail.
    $clean = static fn (string $text): string => (string) preg_replace('/[^\P{C}\n]/u', '', $text);
    $message = $clean($message);
    $contact = $clean(str_replace("\n", ' ', $contact));
    $app = $clean(str_replace("\n", ' ', $app));
    if (!isset(REPORT_KINDS[$kind]) || mb_strlen($message) < 5 || mb_strlen($message) > 3000 ||
        mb_strlen($contact) > 200 || mb_strlen($app) > 100) {
        $respond(422, 'invalid report');
    }
    $sender = reportSender();
    $now = time();
    $saved = locked($db, static function () use ($db, $kind, $message, $contact, $app, $sender, $now): bool {
        $recent = $db->prepare('SELECT COUNT(*) FROM reports WHERE sender = ? AND at > ?');
        $recent->execute([$sender, $now - 3600]);
        $today = $db->prepare('SELECT COUNT(*) FROM reports WHERE at > ?');
        $today->execute([$now - 86400]);
        if ((int) $recent->fetchColumn() >= REPORT_HOURLY_PER_SENDER ||
            (int) $today->fetchColumn() >= REPORT_DAILY_TOTAL) {
            return false;
        }
        $db->prepare('INSERT INTO reports (at, kind, message, contact, app, sender) VALUES (?, ?, ?, ?, ?, ?)')
            ->execute([$now, $kind, $message, $contact, $app, $sender]);
        return true;
    });
    if (!$saved) {
        $respond(429, 'too many reports');
    }
    mailReport($db, $kind, $message, $contact, $app);
    $respond(201, 'received');
}

function mailReport(PDO $db, string $kind, string $message, string $contact, string $app): void
{
    $to = adminSetting($db, 'report_email');
    if ($to === '' || !filter_var($to, FILTER_VALIDATE_EMAIL) || !function_exists('mail')) {
        return;
    }
    $host = preg_replace('/[^a-z0-9.-]/i', '', (string) ($_SERVER['HTTP_HOST'] ?? 'localhost')) ?: 'localhost';
    $subject = '=?UTF-8?B?' . base64_encode('مدار الهدى · ' . REPORT_KINDS[$kind] . ' جديد') . '?=';
    $details = array_filter([
        'النوع: ' . REPORT_KINDS[$kind],
        $app !== '' ? 'نسخة التطبيق: ' . $app : '',
        $contact !== '' ? 'للتواصل: ' . $contact : '',
    ], static fn (string $line): bool => $line !== '');
    $body = implode("\n", $details) . "\n\n" . $message .
        "\n\nتجده في لوحة الإدارة: https://" . $host . '/admin/?section=reports';
    $headers = implode("\r\n", [
        'From: =?UTF-8?B?' . base64_encode('مدار الهدى') . '?= <no-reply@' . $host . '>',
        'MIME-Version: 1.0',
        'Content-Type: text/plain; charset=UTF-8',
        'Content-Transfer-Encoding: base64',
    ]);
    try {
        @mail($to, $subject, chunk_split(base64_encode($body)), $headers);
    } catch (Throwable $failure) {
        error_log('Madar report mail: ' . $failure->getMessage());
    }
}

function changeReports(PDO $db, string $action): string
{
    reportsTable($db);
    if ($action === 'report_settings') {
        $email = field('report_email');
        if ($email !== '' && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('اكتب بريدًا إلكترونيًا صحيحًا أو اتركه فارغًا.');
        }
        setAdminSetting($db, 'report_email', $email);
        return $email === '' ? 'أُوقف إرسال البلاغات بالبريد.' : 'ستصل البلاغات الجديدة إلى هذا البريد.';
    }
    $id = (int) field('report');
    if ($action === 'report_done' || $action === 'report_open') {
        $db->prepare('UPDATE reports SET done = ? WHERE id = ?')->execute([$action === 'report_done' ? 1 : 0, $id]);
        return $action === 'report_done' ? 'عُلّم البلاغ كمنتهٍ.' : 'أُعيد البلاغ إلى الجديد.';
    }
    if ($action === 'report_delete') {
        $db->prepare('DELETE FROM reports WHERE id = ?')->execute([$id]);
        return 'حُذف البلاغ.';
    }
    throw new InvalidArgumentException('الإجراء غير متاح.');
}
