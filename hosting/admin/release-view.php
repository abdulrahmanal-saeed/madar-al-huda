<?php
if (!defined('MADAR_ADMIN')) {
    http_response_code(404);
    exit;
}
?><section class="panel">
  <h2>رفع APK</h2>
  <p>ارفع الإصدار الموقّع بنفس مفتاح القناة. يظهر للمستخدمين بعد النشر من هذه الصفحة.</p>
  <form method="post" enctype="multipart/form-data" class="editor">
    <?php controls('release_upload'); ?>
    <label>القناة <select name="channel"><option value="dev">Obtainium · Dev</option><option value="preview">Preview</option></select></label>
    <label>رقم البناء <input name="code" type="number" min="1" max="2100000000" required></label>
    <label>اسم الإصدار <input name="name" dir="ltr" required placeholder="0.1.0-dev.15"></label>
    <label>ملاحظات الإصدار بالعربي <textarea name="notes_ar"></textarea></label>
    <label>ملاحظات الإصدار بالإنجليزي <textarea name="notes_en" dir="ltr"></textarea></label>
    <label>ملف APK <input type="file" name="apk" accept=".apk" required></label>
    <button class="primary">رفع إلى المسودة</button>
  </form>
</section>
<?php foreach (RELEASE_CHANNELS as $channel): ?>
  <section class="panel">
    <div class="row head"><h2><?= e($channel) ?></h2><a href="./?updates=<?= e($channel) ?>">صفحة تنزيل الإصدار</a></div>
    <?php $activeRelease = currentRelease($db, $channel); ?>
    <?php $list = $db->prepare('SELECT * FROM app_releases WHERE channel = ? ORDER BY code DESC LIMIT 20'); $list->execute([$channel]); ?>
    <?php foreach ($list as $item): ?>
      <div class="row">
        <div><bdi><?= e($item['name']) ?></bdi> · <?= e($item['published'] ? 'منشور' : 'مسودة') ?><br>
          <small>الحجم <?= e(feedSizeLabel((int) $item['bytes'])) ?> · <span dir="ltr" title="<?= e($item['sha256']) ?>">SHA-256 <?= e(substr($item['sha256'], 0, 12)) ?>…</span></small>
        </div>
        <?php $isActive = $activeRelease !== null && $item['code'] === $activeRelease['code']; ?>
        <?php if (!$item['published'] && ($activeRelease === null || $item['code'] > $activeRelease['code'])): ?>
          <form method="post"><?php controls('release_publish'); ?>
            <input type="hidden" name="channel" value="<?= e($channel) ?>">
            <input type="hidden" name="code" value="<?= e($item['code']) ?>">
            <button class="primary">نشر الإصدار</button>
          </form>
        <?php elseif ($isActive && !$item['notify']): ?>
          <form method="post"><?php controls('release_notify'); ?>
            <input type="hidden" name="channel" value="<?= e($channel) ?>">
            <input type="hidden" name="code" value="<?= e($item['code']) ?>">
            <button class="quiet">إشعار المستخدمين</button>
          </form>
        <?php elseif ($isActive): ?><span>الإشعار مفعّل</span><?php endif; ?>
        <?php if ($isActive): ?>
          <form method="post"><?php controls('release_withdraw'); ?>
            <input type="hidden" name="channel" value="<?= e($channel) ?>">
            <input type="hidden" name="code" value="<?= e($item['code']) ?>">
            <button class="quiet danger">سحب الإصدار</button>
          </form>
        <?php endif; ?>
      </div>
    <?php endforeach; ?>
  </section>
<?php endforeach; ?>
