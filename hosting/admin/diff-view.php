<?php
if (!defined('MADAR_ADMIN')) {
    http_response_code(404);
    exit;
}
// Expects $changes from libraryDiff().
?><?php if ($changes === []): ?>
  <p>لا توجد تغييرات عن المنشور.</p>
<?php else: ?>
  <ul class="diff">
    <?php foreach ($changes as $change): ?>
      <li class="diff-<?= e($change['kind']) ?>">
        <strong><?= e(['added' => 'إضافة', 'removed' => 'حذف', 'changed' => 'تعديل'][$change['kind']]) ?></strong>
        <span><?= e($change['path'] !== '' ? $change['path'] : 'المكتبة') ?></span>
        <bdi><?= e($change['detail']) ?></bdi>
      </li>
    <?php endforeach; ?>
  </ul>
  <?php if (count($changes) >= 200): ?><p>تُعرض أول ٢٠٠ تغيير فقط.</p><?php endif; ?>
<?php endif; ?>
