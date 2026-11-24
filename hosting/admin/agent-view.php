<?php
if (!defined('MADAR_ADMIN')) {
    http_response_code(404);
    exit;
}
agentTables($db);
$newUrl = $_SESSION['agent_url'] ?? null;
unset($_SESSION['agent_url']);
$pending = $db->query("SELECT * FROM publish_requests WHERE status = 'pending' ORDER BY id DESC LIMIT 1")->fetch();
$keys = $db->query('SELECT * FROM agent_keys ORDER BY id DESC')->fetchAll();
$activity = $db->query('SELECT l.*, k.label FROM agent_log l LEFT JOIN agent_keys k ON k.id = l.key_id ORDER BY l.id DESC LIMIT 40')->fetchAll();
?>
<?php if ($pending): ?>
  <section class="panel">
    <h2>طلب نشر من ChatGPT</h2>
    <p><bdi><?= e($pending['label']) ?></bdi> · <?= e(publishedLabel((int) $pending['at'])) ?></p>
    <?php if ($pending['note'] !== ''): ?><p class="alert"><?= nl2br(e($pending['note'])) ?></p><?php endif; ?>
    <?php if ((int) $pending['revision'] !== $revision): ?>
      <p class="alert warn">تغيّرت المسودة بعد إرسال الطلب. راجع التغييرات أدناه، فهي ما سيُنشر.</p>
    <?php endif; ?>
    <?php $changes = libraryDiff(json_decode($state['published'] ?? 'null', true), $draft); ?>
    <h3>ما سيتغيّر في التطبيق (<?= e(arabicDigits((string) count($changes))) ?>)</h3>
    <?php require __DIR__ . '/diff-view.php'; ?>
    <div class="row">
      <form method="post"><?php controls('agent_publish_approve'); ?>
        <input type="hidden" name="request" value="<?= e($pending['id']) ?>">
        <button class="primary">موافقة ونشر للتطبيق</button>
      </form>
      <form method="post"><?php controls('agent_publish_reject'); ?>
        <input type="hidden" name="request" value="<?= e($pending['id']) ?>">
        <button class="quiet danger">رفض</button>
      </form>
    </div>
  </section>
<?php endif; ?>
<section class="panel">
  <h2>ربط ChatGPT بلوحة الإدارة</h2>
  <p>يستطيع ChatGPT من خلال هذا الرابط قراءة المحتوى وإضافته وتعديله وحذفه في المسودة، ثم النشر بالطريقة المختارة أدناه. ولا يصل إلى المستخدمين أو كلمات المرور أو الإصدارات.</p>
  <form method="post" class="editor">
    <?php controls('agent_publish_mode'); ?>
    <fieldset>
      <legend>النشر من ChatGPT</legend>
      <label class="check"><input type="radio" name="mode" value="chat" <?= agentPublishMode($db) === 'chat' ? 'checked' : '' ?>> ينشر بعد أن يسألك في المحادثة كل مرة (اترك أداة <bdi>publish</bdi> على <bdi>Always ask</bdi> في ChatGPT)</label>
      <label class="check"><input type="radio" name="mode" value="dashboard" <?= agentPublishMode($db) === 'dashboard' ? 'checked' : '' ?>> يرسل طلب نشر فقط، وتوافق أنت من هذه الصفحة</label>
    </fieldset>
    <button class="quiet">حفظ</button>
  </form>
  <?php if (is_string($newUrl)): ?>
    <div class="alert">
      <p><strong>انسخ هذا الرابط الآن، فلن يظهر مرة أخرى:</strong></p>
      <p dir="ltr"><code class="secret-url"><?= e($newUrl) ?></code></p>
    </div>
  <?php endif; ?>
  <form method="post" class="inline">
    <?php controls('agent_key_create'); ?>
    <label>اسم الرابط<input name="label" maxlength="60" placeholder="ChatGPT" value="ChatGPT"></label>
    <button class="primary">إنشاء رابط جديد</button>
  </form>
  <details>
    <summary>طريقة الإضافة في ChatGPT</summary>
    <ol class="help-steps">
      <li>في ChatGPT: <strong>Settings → Apps &amp; Connectors → Advanced settings</strong> وفعّل <strong>Developer mode</strong>.</li>
      <li>اضغط <strong>Create</strong> (أو Add custom connector)، واكتب الاسم «مدار الهدى»، والصق الرابط في <strong>MCP Server URL</strong>.</li>
      <li>في <strong>Authentication</strong> اختر <strong>No authentication</strong>، ثم وافق وأنشئ.</li>
      <li>في أي محادثة: اضغط <strong>+</strong> واختر «مدار الهدى» لتفعيله فيها، ثم اطلب مثلًا: «ضيف ذكر جديد لأذكار الصباح».</li>
      <li>أول مرة يطلب النشر، يسألك ChatGPT عن الإذن: اختر <strong>Always ask</strong> (اسأل دائمًا) وليس «Always allow»، فيسألك قبل كل نشر.</li>
    </ol>
    <p class="hint">الرابط هو كلمة السر: لا تشاركه. إن شككت أنه تسرّب، ألغِه من القائمة أدناه وأنشئ غيره.</p>
  </details>
</section>
<section class="panel">
  <h2>الروابط</h2>
  <?php if ($keys === []): ?><p>لا توجد روابط بعد.</p><?php endif; ?>
  <?php foreach ($keys as $key): ?>
    <div class="row">
      <span>
        <strong><?= e($key['label']) ?></strong>
        <?= $key['revoked_at'] ? ' · <span class="badge muted">ملغي</span>' : '' ?>
        <br><small>أُنشئ <?= e(publishedLabel((int) $key['created_at'])) ?> · استُخدم <?= e(arabicDigits((string) $key['use_count'])) ?> مرة<?= $key['last_used_at'] ? ' · آخر مرة ' . e(publishedLabel((int) $key['last_used_at'])) : '' ?></small>
      </span>
      <?php if (!$key['revoked_at']): ?>
        <form method="post"><?php controls('agent_key_revoke'); ?>
          <input type="hidden" name="key" value="<?= e($key['id']) ?>">
          <button class="quiet danger">إلغاء</button>
        </form>
      <?php endif; ?>
    </div>
  <?php endforeach; ?>
</section>
<section class="panel">
  <h2>آخر ما فعله ChatGPT</h2>
  <?php if ($activity === []): ?><p>لا يوجد نشاط بعد.</p><?php endif; ?>
  <?php foreach ($activity as $line): ?>
    <div class="row">
      <span><?= $line['ok'] ? '' : '<span class="badge warn">خطأ</span> ' ?><bdi dir="ltr"><?= e($line['tool']) ?></bdi> <small dir="ltr"><?= e($line['detail']) ?></small></span>
      <small><?= e(publishedLabel((int) $line['at'])) ?></small>
    </div>
  <?php endforeach; ?>
</section>
