<?php
if (!defined('MADAR_ADMIN')) {
    http_response_code(404);
    exit;
}
reportsTable($db);
$showDone = ($_GET['show'] ?? '') === 'all';
$reports = $db->query('SELECT reports.*, EXISTS(SELECT 1 FROM report_images WHERE report = reports.id) AS has_image FROM reports' . ($showDone ? '' : ' WHERE done = 0') . ' ORDER BY id DESC LIMIT 300')->fetchAll();
$openCount = (int) $db->query('SELECT COUNT(*) FROM reports WHERE done = 0')->fetchColumn();
?>
<section class="panel">
  <h2>إرسال البلاغات بالبريد</h2>
  <p>كل بلاغ أو اقتراح يُرسل من التطبيق يُحفظ هنا، ويصل أيضًا إلى هذا البريد. اتركه فارغًا لإيقاف الإرسال بالبريد.</p>
  <form method="post" class="inline">
    <?php controls('report_settings'); ?>
    <label>البريد الإلكتروني<input type="email" name="report_email" dir="ltr" value="<?= e(adminSetting($db, 'report_email')) ?>" autocomplete="email"></label>
    <button class="primary">حفظ</button>
  </form>
</section>
<section class="panel">
  <div class="row head">
    <h2><?= $showDone ? 'كل البلاغات' : 'بلاغات جديدة (' . e(arabicDigits((string) $openCount)) . ')' ?></h2>
    <a class="button quiet" href="./?section=reports<?= $showDone ? '' : '&amp;show=all' ?>"><?= $showDone ? 'الجديدة فقط' : 'عرض المنتهية أيضًا' ?></a>
  </div>
  <label>ابحث<input type="search" data-filter-list=".report-row" placeholder="نص أو وسيلة تواصل"></label>
  <?php if ($reports === []): ?><p>لا توجد بلاغات<?= $showDone ? '' : ' جديدة' ?>.</p><?php endif; ?>
  <?php foreach ($reports as $report): ?>
    <article class="report-row panel<?= $report['done'] ? ' muted' : '' ?>">
      <div class="row">
        <span>
          <span class="badge<?= $report['kind'] === 'problem' ? ' warn' : '' ?>"><?= e(REPORT_KINDS[$report['kind']] ?? $report['kind']) ?></span>
          · <small><?= e(publishedLabel((int) $report['at'])) ?></small>
          <?php if ($report['app'] !== ''): ?> · <small dir="ltr"><?= e($report['app']) ?></small><?php endif; ?>
        </span>
        <span class="section-actions">
          <form method="post"><?php controls($report['done'] ? 'report_open' : 'report_done'); ?>
            <input type="hidden" name="report" value="<?= e($report['id']) ?>">
            <button class="quiet"><?= $report['done'] ? 'إعادة فتح' : 'تمّ' ?></button>
          </form>
          <form method="post"><?php controls('report_delete'); ?>
            <input type="hidden" name="report" value="<?= e($report['id']) ?>">
            <button class="quiet danger">حذف</button>
          </form>
        </span>
      </div>
      <p class="report-text"><?= nl2br(e($report['message'])) ?></p>
      <?php if ($report['has_image']): ?>
        <p><a href="./?report_image=<?= e($report['id']) ?>" target="_blank" rel="noopener">
          <img src="./?report_image=<?= e($report['id']) ?>" alt="الصورة المرفقة" width="180" loading="lazy">
          عرض الصورة المرفقة بالحجم الكامل
        </a></p>
      <?php endif; ?>
      <?php if ($report['contact'] !== ''): ?><p><small>للتواصل: <bdi><?= e($report['contact']) ?></bdi></small></p><?php endif; ?>
    </article>
  <?php endforeach; ?>
</section>
