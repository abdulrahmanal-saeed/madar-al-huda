<?php
if (!defined('MADAR_ADMIN')) {
    http_response_code(404);
    exit;
}
?><?php if ($section === 'users'): ?>
  <section class="panel">
    <h2>إضافة مستخدم</h2>
    <p><strong>المحرر</strong> يعدّل المحتوى في المسودة فقط. <strong>المراجع الشرعي</strong> يراجع ويعتمد مسائل الفقه وينشر. <strong>المالك</strong> يدير كل شيء.</p>
    <form method="post" class="editor">
      <?php controls('user_add'); ?>
      <label>اسم المستخدم<input name="username" dir="ltr" required pattern="[a-z][a-z0-9._-]{2,31}" autocomplete="off"></label>
      <label>الدور<select name="role"><?php foreach (ROLES as $key => $name): ?><option value="<?= e($key) ?>" <?= $key === 'editor' ? 'selected' : '' ?>><?= e($name) ?></option><?php endforeach; ?></select></label>
      <label>كلمة مرور مؤقتة (١٢ حرفًا على الأقل)<input type="password" name="password" required minlength="12" maxlength="72" autocomplete="new-password"></label>
      <button class="primary">إضافة</button>
    </form>
  </section>
  <section class="panel">
    <h2>المستخدمون</h2>
    <?php foreach ($db->query('SELECT * FROM users ORDER BY id') as $account): ?>
      <div class="row">
        <span>
          <strong dir="ltr"><?= e($account['username']) ?></strong> · <?= e(ROLES[$account['role']] ?? $account['role']) ?>
          <?= $account['totp_secret'] ? ' · <span class="badge">تحقق بخطوتين</span>' : '' ?>
          <?= $account['disabled'] ? ' · <span class="badge">موقوف</span>' : '' ?>
        </span>
        <?php if ((int) $account['id'] !== (int) $user['id']): ?>
          <span class="section-actions">
            <form method="post" class="inline"><?php controls('user_role'); ?>
              <input type="hidden" name="user" value="<?= e($account['id']) ?>">
              <select name="role" aria-label="الدور"><?php foreach (ROLES as $key => $name): ?><option value="<?= e($key) ?>" <?= $key === $account['role'] ? 'selected' : '' ?>><?= e($name) ?></option><?php endforeach; ?></select>
              <button class="quiet">تغيير الدور</button>
            </form>
            <form method="post" class="inline"><?php controls('user_reset'); ?>
              <input type="hidden" name="user" value="<?= e($account['id']) ?>">
              <input type="password" name="password" minlength="12" maxlength="72" required placeholder="كلمة مرور مؤقتة" autocomplete="new-password" aria-label="كلمة مرور مؤقتة">
              <button class="quiet">إعادة تعيين</button>
            </form>
            <form method="post"><?php controls($account['disabled'] ? 'user_enable' : 'user_disable'); ?>
              <input type="hidden" name="user" value="<?= e($account['id']) ?>">
              <button class="quiet<?= $account['disabled'] ? '' : ' danger' ?>"><?= $account['disabled'] ? 'تفعيل' : 'إيقاف' ?></button>
            </form>
          </span>
        <?php endif; ?>
      </div>
    <?php endforeach; ?>
  </section>
<?php elseif ($section === 'audit'): ?>
  <section class="panel">
    <h2>سجل التعديلات</h2>
    <label>ابحث<input type="search" data-filter-list=".audit-row" placeholder="مستخدم أو إجراء أو قسم"></label>
    <?php $lines = $db->query('SELECT * FROM audit ORDER BY id DESC LIMIT 300')->fetchAll(); ?>
    <?php if ($lines === []): ?><p>لا توجد تعديلات مسجلة بعد.</p><?php endif; ?>
    <?php foreach ($lines as $line): ?>
      <div class="row audit-row">
        <span>
          <strong><?= e(AUDIT_ACTIONS[$line['action']] ?? $line['action']) ?></strong>
          · <?= e($sections[$line['section']] ?? $line['section']) ?>
          · <bdi dir="ltr"><?= e($line['user']) ?></bdi>
          <?php if ($line['detail'] !== ''): ?><br><small dir="ltr"><?= e($line['detail']) ?></small><?php endif; ?>
        </span>
        <small><?= e(publishedLabel((int) $line['at'])) ?></small>
      </div>
    <?php endforeach; ?>
  </section>
<?php endif; ?>
