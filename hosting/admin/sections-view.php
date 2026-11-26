<?php
if (!defined('MADAR_ADMIN')) {
    http_response_code(404);
    exit;
}
$librarySections = currentSections($draft);
$editing = null;
foreach ($librarySections as $candidate) {
    if ($candidate['kind'] === 'links' && $candidate['id'] === $edit) {
        $editing = $candidate;
    }
}
?><?php if ($editing === null): ?>
<div class="editor-grid">
  <section class="panel">
    <h2>أقسام المكتبة في التطبيق</h2>
    <p>رتّب الأقسام بالأسهم، وأخفِ ما لا تريد ظهوره. الأقسام الأساسية تُخفى ولا تُحذف.</p>
    <?php $last = count($librarySections) - 1; ?>
    <?php foreach ($librarySections as $index => $item): ?>
      <div class="row section-row<?= ($item['visible'] ?? true) ? '' : ' hidden-section' ?>">
        <span class="section-name">
          <strong><?= e(sectionLabel($item)) ?></strong>
          <span class="badge"><?= $item['kind'] === 'builtin' ? 'أساسي' : 'روابط · ' . e(count($item['items'] ?? [])) . ' / مواسم · ' . e(count($item['seasons'] ?? [])) ?></span>
          <?php if (!($item['visible'] ?? true)): ?><span class="badge muted">مخفي</span><?php endif; ?>
        </span>
        <span class="section-actions">
          <form method="post"><?php controls('save', $revision); ?><input type="hidden" name="op" value="up"><input type="hidden" name="id" value="<?= e($item['id']) ?>"><button class="quiet" aria-label="تحريك لأعلى" <?= $index === 0 ? 'disabled' : '' ?>>↑</button></form>
          <form method="post"><?php controls('save', $revision); ?><input type="hidden" name="op" value="down"><input type="hidden" name="id" value="<?= e($item['id']) ?>"><button class="quiet" aria-label="تحريك لأسفل" <?= $index === $last ? 'disabled' : '' ?>>↓</button></form>
          <form method="post"><?php controls('save', $revision); ?><input type="hidden" name="op" value="toggle"><input type="hidden" name="id" value="<?= e($item['id']) ?>"><button class="quiet"><?= ($item['visible'] ?? true) ? 'إخفاء' : 'إظهار' ?></button></form>
          <?php if ($item['kind'] !== 'builtin'): ?>
            <a class="button quiet" href="<?= e(route($section, '', $item['id'])) ?>">تعديل</a>
            <form method="post"><?php controls('delete', $revision); ?><input type="hidden" name="id" value="<?= e($item['id']) ?>"><button class="quiet danger">حذف</button></form>
          <?php endif; ?>
        </span>
      </div>
    <?php endforeach; ?>
  </section>
  <section class="panel">
    <h2>إضافة قسم جديد</h2>
    <p>مثلًا «السيرة النبوية». بعد الإضافة افتح «تعديل» وأضف المواسم والحلقات والتسجيلات أو الروابط.</p>
    <form method="post">
      <?php controls('save', $revision); ?>
      <input type="hidden" name="op" value="add">
      <label>اسم القسم بالعربية<input name="title_ar" required maxlength="120"></label>
      <label>اسم القسم بالإنجليزية<input name="title_en" dir="ltr" required maxlength="120"></label>
      <label>وصف قصير بالعربية (اختياري)<input name="subtitle_ar" maxlength="200"></label>
      <label>وصف قصير بالإنجليزية (اختياري)<input name="subtitle_en" dir="ltr" maxlength="200"></label>
      <button class="primary">إضافة القسم</button>
    </form>
  </section>
</div>
<?php else: ?>
<p><a class="button quiet" href="<?= e(route($section)) ?>">→ كل الأقسام</a></p>
<?php require __DIR__ . '/library-seasons-view.php'; ?>
<div class="editor-grid">
  <section class="panel">
    <h2>روابط «<?= e($editing['title']['ar']) ?>»</h2>
    <?php if (($editing['items'] ?? []) === []): ?><p>لا توجد روابط بعد.</p><?php endif; ?>
    <?php foreach ($editing['items'] ?? [] as $position => $link): ?>
      <div class="row">
        <span class="section-name"><strong><?= e($link['title']['ar']) ?></strong><bdi dir="ltr" class="url"><?= e($link['url']) ?></bdi></span>
        <form method="post"><?php controls('save', $revision); ?><input type="hidden" name="op" value="remove_item"><input type="hidden" name="id" value="<?= e($editing['id']) ?>"><input type="hidden" name="item" value="<?= e($position) ?>"><button class="quiet danger">إزالة</button></form>
      </div>
    <?php endforeach; ?>
    <h2 class="spaced">إضافة رابط</h2>
    <form method="post">
      <?php controls('save', $revision); ?>
      <input type="hidden" name="op" value="add_item">
      <input type="hidden" name="id" value="<?= e($editing['id']) ?>">
      <label>العنوان بالعربية<input name="item_ar" required maxlength="200"></label>
      <label>العنوان بالإنجليزية<input name="item_en" dir="ltr" required maxlength="200"></label>
      <label>الرابط (فيديو MP4 أو صفحة)<input name="url" type="url" dir="ltr" required placeholder="https://"></label>
      <button class="primary">إضافة الرابط</button>
    </form>
  </section>
  <section class="panel">
    <h2>اسم القسم</h2>
    <form method="post">
      <?php controls('save', $revision); ?>
      <input type="hidden" name="op" value="rename">
      <input type="hidden" name="id" value="<?= e($editing['id']) ?>">
      <label>بالعربية<input name="title_ar" required maxlength="120" value="<?= e($editing['title']['ar']) ?>"></label>
      <label>بالإنجليزية<input name="title_en" dir="ltr" required maxlength="120" value="<?= e($editing['title']['en']) ?>"></label>
      <label>وصف قصير بالعربية<input name="subtitle_ar" maxlength="200" value="<?= e($editing['subtitle']['ar'] ?? '') ?>"></label>
      <label>وصف قصير بالإنجليزية<input name="subtitle_en" dir="ltr" maxlength="200" value="<?= e($editing['subtitle']['en'] ?? '') ?>"></label>
      <button class="primary">حفظ الاسم</button>
    </form>
  </section>
</div>
<?php endif; ?>
