<?php
declare(strict_types=1);

/*
 * Who may do what, the scholarly review that fiqh needs before it is
 * published, and a log of every change.
 */

/** Sections only the owner manages. */
const OWNER_SECTIONS = ['appearance', 'app_settings', 'library_sections', 'reciters', 'releases', 'users', 'audit', 'reports', 'chatgpt'];

/** Actions and the roles allowed to take them. */
const ACTION_ROLES = [
    'fiqh_draft_save' => ['owner', 'reviewer', 'editor'],
    'fiqh_autosave' => ['owner', 'reviewer', 'editor'],
    'fiqh_metadata_save' => ['owner', 'reviewer', 'editor'],
    'fiqh_import_preview' => ['owner','reviewer','editor'],
    'fiqh_import_commit' => ['owner','reviewer','editor'],
    'fiqh_publish' => ['owner', 'reviewer'],
    'fiqh_archive' => ['owner', 'reviewer'],
    'save' => ['owner', 'reviewer', 'editor'],
    'delete' => ['owner', 'reviewer', 'editor'],
    'upload_story' => ['owner', 'reviewer', 'editor'],
    'drive_import' => ['owner', 'reviewer', 'editor'],
    'archive_story' => ['owner', 'reviewer'],
    'restore_story' => ['owner', 'reviewer'],
    'publish' => ['owner', 'reviewer'],
    'restore' => ['owner', 'reviewer'],
    'review_approve' => ['owner', 'reviewer'],
    'release_upload' => ['owner'],
    'release_publish' => ['owner'],
    'release_notify' => ['owner'],
    'release_withdraw' => ['owner'],
    'user_add' => ['owner'],
    'user_role' => ['owner'],
    'user_disable' => ['owner'],
    'user_enable' => ['owner'],
    'user_reset' => ['owner'],
    'password_change' => ['owner', 'reviewer', 'editor'],
    'totp_enable' => ['owner', 'reviewer', 'editor'],
    'totp_disable' => ['owner', 'reviewer', 'editor'],
    'logout' => ['owner', 'reviewer', 'editor'],
    'report_settings' => ['owner'],
    'report_done' => ['owner'],
    'report_open' => ['owner'],
    'report_delete' => ['owner'],
    'agent_key_create' => ['owner'],
    'agent_key_revoke' => ['owner'],
    'agent_publish_approve' => ['owner'],
    'agent_publish_reject' => ['owner'],
    'agent_publish_mode' => ['owner'],
];

function canSee(array $user, string $section): bool
{
    if ($user['role'] === 'owner') {
        return true;
    }
    if ($section === 'audit') {
        return $user['role'] === 'reviewer';
    }
    return !in_array($section, OWNER_SECTIONS, true);
}

function allowedAction(array $user, string $action, string $section): bool
{
    $roles = ACTION_ROLES[$action] ?? ['owner'];
    // Account actions work from any page; the rest need the page too.
    $anywhere = in_array($action, ['logout', 'password_change', 'totp_enable', 'totp_disable'], true);
    return in_array($user['role'], $roles, true) && ($anywhere || canSee($user, $section));
}

function auditTable(PDO $db): void
{
    $db->exec('CREATE TABLE IF NOT EXISTS audit (
        id INTEGER PRIMARY KEY, at INTEGER NOT NULL, user TEXT NOT NULL,
        action TEXT NOT NULL, section TEXT NOT NULL, detail TEXT NOT NULL
    )');
}

function audit(PDO $db, string $user, string $action, string $section, string $detail = ''): void
{
    try {
        $db->prepare('INSERT INTO audit (at, user, action, section, detail) VALUES (?, ?, ?, ?, ?)')
            ->execute([time(), $user, $action, $section, mb_substr($detail, 0, 300)]);
    } catch (Throwable $failure) {
        error_log('Madar audit: ' . $failure->getMessage());
    }
}

const AUDIT_ACTIONS = [
    'login' => 'دخول', 'logout' => 'خروج', 'save' => 'حفظ في المسودة', 'delete' => 'حذف من المسودة',
    'publish' => 'نشر', 'restore' => 'استعادة إصدار', 'review_approve' => 'اعتماد شرعي',
    'upload_story' => 'رفع تسجيل', 'drive_import' => 'نقل من Drive', 'archive_story' => 'أرشفة تسجيل',
    'restore_story' => 'استعادة تسجيل', 'release_upload' => 'رفع APK', 'release_publish' => 'نشر إصدار',
    'release_notify' => 'إشعار تحديث', 'release_withdraw' => 'سحب إصدار', 'user_add' => 'إضافة مستخدم',
    'user_role' => 'تغيير دور', 'user_disable' => 'إيقاف مستخدم', 'user_enable' => 'تفعيل مستخدم',
    'user_reset' => 'إعادة تعيين كلمة مرور', 'password_change' => 'تغيير كلمة المرور',
    'totp_enable' => 'تفعيل التحقق بخطوتين', 'totp_disable' => 'إيقاف التحقق بخطوتين',
    'report_settings' => 'بريد البلاغات', 'report_done' => 'إنهاء بلاغ', 'report_open' => 'إعادة فتح بلاغ',
    'report_delete' => 'حذف بلاغ',
    'agent_key_create' => 'إنشاء رابط ChatGPT', 'agent_key_revoke' => 'إلغاء رابط ChatGPT',
    'agent_publish_approve' => 'موافقة على نشر من ChatGPT', 'agent_publish_reject' => 'رفض نشر من ChatGPT',
    'agent_publish_mode' => 'طريقة النشر من ChatGPT',
];

/** What the audit line says about a request, without secrets. */
function auditDetail(string $action): string
{
    $parts = [];
    foreach (['original', 'story', 'group', 'reader', 'file', 'name', 'link', 'item', 'channel', 'code', 'username', 'role'] as $key) {
        $value = $_POST[$key] ?? null;
        if (is_string($value) && $value !== '' && !in_array($action, ['login', 'password_change', 'totp_enable', 'totp_disable'], true)) {
            $parts[] = "$key=" . mb_substr($value, 0, 80);
        }
    }
    if ($action === 'upload_story' && is_string($_FILES['recording']['name'] ?? null)) {
        $parts[] = 'file=' . $_FILES['recording']['name'];
    }
    return implode(' · ', $parts);
}

/** The hash a scholarly approval is bound to: the item without its review. */
function reviewHash(array $item): string
{
    unset($item['review']);
    return hash('sha256', encode($item));
}

function reviewCurrent(array $item): bool
{
    return is_array($item['review'] ?? null) && ($item['review']['hash'] ?? '') === reviewHash($item);
}

/** Fiqh items that changed after their approval, or were never approved. */
function unreviewedFiqh(array $content): array
{
    return array_values(array_filter(
        $content['library']['fiqh'] ?? [],
        fn ($item) => is_array($item) && !reviewCurrent($item),
    ));
}

function approveFiqh(array $content, array $user): array
{
    $id = field('item');
    foreach ($content['library']['fiqh'] ?? [] as $index => $item) {
        if (($item['id'] ?? null) === $id) {
            $content['library']['fiqh'][$index]['review'] = [
                'by' => $user['username'], 'at' => time(), 'hash' => reviewHash($item),
            ];
            return $content;
        }
    }
    throw new InvalidArgumentException('المسألة غير موجودة في المسودة.');
}

/** Owner actions on accounts; returns the notice. */
function changeUsers(PDO $db, array $owner, string $action): string
{
    if ($action === 'user_add') {
        $username = strtolower(field('username'));
        if (!preg_match('/\A[a-z][a-z0-9._-]{2,31}\z/', $username)) {
            throw new InvalidArgumentException('اسم المستخدم: حروف إنجليزية صغيرة وأرقام (٣ إلى ٣٢ حرفًا) يبدأ بحرف.');
        }
        $role = field('role');
        if (!isset(ROLES[$role])) {
            throw new InvalidArgumentException('اختر دورًا صالحًا.');
        }
        $password = $_POST['password'] ?? '';
        if (!is_string($password) || strlen($password) < 12 || strlen($password) > 72) {
            throw new InvalidArgumentException('كلمة المرور المؤقتة ١٢ حرفًا على الأقل.');
        }
        try {
            $db->prepare('INSERT INTO users (username, password, role, created) VALUES (?, ?, ?, ?)')
                ->execute([$username, password_hash($password, PASSWORD_DEFAULT), $role, time()]);
        } catch (PDOException) {
            throw new InvalidArgumentException('اسم المستخدم مستخدم بالفعل.');
        }
        return "أُضيف $username بدور " . ROLES[$role] . '. أعطه كلمة المرور المؤقتة ليغيّرها من «حسابي».';
    }
    $id = integer(field('user'), 1, PHP_INT_MAX);
    if ($id === (int) $owner['id']) {
        throw new InvalidArgumentException('لا يمكنك تغيير دور حسابك أو إيقافه من هنا.');
    }
    $target = $db->prepare('SELECT * FROM users WHERE id = ?');
    $target->execute([$id]);
    $row = $target->fetch();
    if ($row === false) {
        throw new InvalidArgumentException('المستخدم غير موجود.');
    }
    switch ($action) {
        case 'user_role':
            $role = field('role');
            if (!isset(ROLES[$role])) {
                throw new InvalidArgumentException('اختر دورًا صالحًا.');
            }
            $db->prepare('UPDATE users SET role = ? WHERE id = ?')->execute([$role, $id]);
            return 'تغيّر دور ' . $row['username'] . ' إلى ' . ROLES[$role] . '.';
        case 'user_disable':
            $db->prepare('UPDATE users SET disabled = 1 WHERE id = ?')->execute([$id]);
            return 'أُوقف حساب ' . $row['username'] . '.';
        case 'user_enable':
            $db->prepare('UPDATE users SET disabled = 0 WHERE id = ?')->execute([$id]);
            return 'فُعّل حساب ' . $row['username'] . '.';
        case 'user_reset':
            $password = $_POST['password'] ?? '';
            if (!is_string($password) || strlen($password) < 12 || strlen($password) > 72) {
                throw new InvalidArgumentException('كلمة المرور المؤقتة ١٢ حرفًا على الأقل.');
            }
            // A reset also removes the lost phone's two-step setup.
            $db->prepare('UPDATE users SET password = ?, totp_secret = NULL, totp_last = 0 WHERE id = ?')
                ->execute([password_hash($password, PASSWORD_DEFAULT), $id]);
            return 'أُعيد تعيين كلمة مرور ' . $row['username'] . ' وأُوقف تحققه بخطوتين.';
    }
    throw new InvalidArgumentException('الإجراء غير متاح.');
}
