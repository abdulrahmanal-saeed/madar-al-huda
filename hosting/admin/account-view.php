<?php
if (!defined('MADAR_ADMIN')) {
    http_response_code(404);
    exit;
}
?><section class="panel">
  <h2>تغيير كلمة المرور</h2>
  <form method="post" class="editor">
    <?php controls('password_change'); ?>
    <label>كلمة المرور الحالية<input type="password" name="current_password" required autocomplete="current-password"></label>
    <label>كلمة المرور الجديدة (١٢ حرفًا على الأقل)<input type="password" name="new_password" required minlength="12" maxlength="72" autocomplete="new-password"></label>
    <label>تأكيد كلمة المرور الجديدة<input type="password" name="confirm_password" required minlength="12" maxlength="72" autocomplete="new-password"></label>
    <button class="primary">تغيير كلمة المرور</button>
  </form>
</section>
<section class="panel">
  <h2>التحقق بخطوتين</h2>
  <?php if ($user['totp_secret']): ?>
    <p>مفعّل: يُطلب رمز من تطبيق المصادقة عند كل دخول.</p>
    <form method="post" class="editor">
      <?php controls('totp_disable'); ?>
      <label>كلمة المرور الحالية<input type="password" name="current_password" required autocomplete="current-password"></label>
      <label>رمز التطبيق الحالي<input name="code" required inputmode="numeric" autocomplete="one-time-code" dir="ltr"></label>
      <button class="quiet danger">إيقاف التحقق بخطوتين</button>
    </form>
  <?php else: ?>
    <?php $_SESSION['totp_pending'] ??= newTotpSecret(); $pending = $_SESSION['totp_pending']; ?>
    <ol>
      <li>افتح تطبيق مصادقة على هاتفك (Google Authenticator أو Microsoft Authenticator أو غيرهما).</li>
      <li>أضف حسابًا بالمفتاح التالي، أو افتح الرابط من هاتفك:
        <p><code dir="ltr" class="secret"><?= e(implode(' ', str_split($pending, 4))) ?></code></p>
        <p><a href="<?= e(totpUri($pending, $user['username'])) ?>">فتح في تطبيق المصادقة</a></p>
      </li>
      <li>اكتب الرمز المكوّن من ٦ أرقام الذي يظهر في التطبيق للتأكيد.</li>
    </ol>
    <form method="post" class="inline">
      <?php controls('totp_enable'); ?>
      <input name="code" required inputmode="numeric" autocomplete="one-time-code" dir="ltr" placeholder="123456" aria-label="رمز التطبيق">
      <button class="primary">تفعيل التحقق بخطوتين</button>
    </form>
  <?php endif; ?>
</section>
