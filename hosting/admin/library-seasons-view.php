<?php
if (!defined('MADAR_ADMIN')) { http_response_code(404); exit; }
/** Form controls use the existing CSRF, permissions and revision lock. */
function seasonControls(string $op, int $revision, string $id, string $season = '', string $episode = ''): void
{
    controls('save', $revision);
    foreach (['op' => $op, 'id' => $id, 'season' => $season, 'episode' => $episode] as $key => $value) {
        echo '<input type="hidden" name="' . e($key) . '" value="' . e($value) . '">';
    }
}
?>
<section class="panel">
  <h2>المواسم والحلقات · <?= e($editing['title']['ar']) ?></h2>
  <p>أضف موسمًا، ثم الحلقات بترتيبها، وارفع MP3 وMP4 لكل حلقة. تبقى التسجيلات خاصة حتى نشر المسودة. الروابط القديمة تبقى كما هي.</p>
  <form method="post">
    <?php seasonControls('add_season', $revision, $editing['id']); ?>
    <label>اسم الموسم بالعربية<input name="season_ar" required maxlength="120" placeholder="الموسم الأول"></label>
    <label>اسم الموسم بالإنجليزية<input name="season_en" required maxlength="120" dir="ltr" placeholder="Season 1"></label>
    <button class="primary">إضافة موسم / مجلد</button>
  </form>
</section>
<?php foreach ($editing['seasons'] ?? [] as $season): ?>
<section class="panel">
  <h2><?= e($season['title']['ar']) ?> · <?= e(count($season['episodes'])) ?> حلقة</h2>
  <form method="post">
    <?php seasonControls('rename_season', $revision, $editing['id'], $season['id']); ?>
    <label>اسم الموسم بالعربية<input name="season_ar" required value="<?= e($season['title']['ar']) ?>"></label>
    <label>اسم الموسم بالإنجليزية<input name="season_en" required dir="ltr" value="<?= e($season['title']['en']) ?>"></label>
    <button class="quiet">حفظ الاسم</button>
  </form>
  <div class="section-actions">
    <?php foreach (['season_up' => '↑', 'season_down' => '↓'] as $op => $label): ?>
      <form method="post"><?php seasonControls($op, $revision, $editing['id'], $season['id']); ?><button class="quiet"><?= e($label) ?></button></form>
    <?php endforeach; ?>
    <?php if ($season['episodes'] === []): ?>
      <form method="post"><?php seasonControls('remove_season', $revision, $editing['id'], $season['id']); ?><button class="quiet danger">حذف الموسم الفارغ</button></form>
    <?php endif; ?>
  </div>
  <h3>رفع جماعي للتسجيلات</h3>
  <p>اختر عدة ملفات مثل <bdi>Madar-Seerah-001.mp3</bdi> و<bdi>Madar-Seerah-001.mp4</bdi>. تُنشأ الحلقات تلقائيًا بحسب الرقم الأخير في اسم الملف، ويُجمع الصوت والفيديو تحت نفس الرقم دون استبدال تسجيل موجود.</p>
  <form method="post" enctype="multipart/form-data" data-season-batch="upload">
    <?php seasonControls('bulk_upload', $revision, $editing['id'], $season['id']); ?>
    <label>ملفات MP3 وMP4<input name="recording" type="file" accept=".mp3,.mp4" multiple required></label>
    <button class="primary">رفع جماعي</button>
    <div class="uploads" data-batch-progress hidden></div>
  </form>
  <h3>استيراد مباشر من Google Drive</h3>
  <p>الصق رابط كل ملف في سطر (حتى ٥٠ رابطًا)، مع اسم اختياري بعد مسافة. اجعل مشاركة الملف «أي شخص لديه الرابط». تُحفظ الملفات في المسودة فقط.</p>
  <form method="post" data-season-batch="drive">
    <?php seasonControls('bulk_drive', $revision, $editing['id'], $season['id']); ?>
    <textarea name="links" required rows="4" dir="ltr" placeholder="https://drive.google.com/file/d/… Madar-Seerah-001.mp4"></textarea>
    <button class="primary">نقل من Drive</button>
    <div class="uploads" data-batch-progress hidden></div>
  </form>
  <h3>إضافة حلقة</h3>
  <form method="post">
    <?php seasonControls('add_episode', $revision, $editing['id'], $season['id']); ?>
    <label>رقم الحلقة<input name="number" type="number" min="1" max="999999" required></label>
    <label>عنوان الحلقة بالعربية<input name="episode_ar" required maxlength="120"></label>
    <label>عنوان الحلقة بالإنجليزية<input name="episode_en" required maxlength="120" dir="ltr"></label>
    <button class="primary">إضافة الحلقة</button>
  </form>
  <?php $episodes = $season['episodes']; usort($episodes, fn ($a, $b) => $a['number'] <=> $b['number']); ?>
  <?php foreach ($episodes as $episode): ?>
    <details class="panel">
      <summary><?= e($episode['number']) ?> · <?= e($episode['title']['ar']) ?> — <?= isset($episode['media']['audio']) ? 'MP3 ✓' : 'MP3 —' ?> / <?= isset($episode['media']['video']) ? 'MP4 ✓' : 'MP4 —' ?></summary>
      <form method="post">
        <?php seasonControls('rename_episode', $revision, $editing['id'], $season['id'], $episode['id']); ?>
        <label>رقم الحلقة<input name="number" type="number" min="1" max="999999" required value="<?= e($episode['number']) ?>"></label>
        <label>العنوان بالعربية<input name="episode_ar" required value="<?= e($episode['title']['ar']) ?>"></label>
        <label>العنوان بالإنجليزية<input name="episode_en" dir="ltr" required value="<?= e($episode['title']['en']) ?>"></label>
        <button class="quiet">حفظ بيانات الحلقة</button>
      </form>
      <?php foreach (['audio' => 'mp3', 'video' => 'mp4'] as $format => $extension): ?>
        <form method="post" enctype="multipart/form-data">
          <?php seasonControls('upload_episode', $revision, $editing['id'], $season['id'], $episode['id']); ?>
          <input type="hidden" name="format" value="<?= e($format) ?>">
          <label><?= isset($episode['media'][$format]) ? 'استبدال' : 'رفع' ?> <?= e(strtoupper($extension)) ?><input name="recording" type="file" accept=".<?= e($extension) ?>" required></label>
          <button class="primary">Upload <?= e(strtoupper($extension)) ?></button>
        </form>
        <?php if (isset($episode['media'][$format])): ?>
          <p><?= e(feedSizeLabel($episode['media'][$format]['bytes'])) ?></p>
          <form method="post">
            <?php seasonControls('remove_media', $revision, $editing['id'], $season['id'], $episode['id']); ?>
            <input type="hidden" name="format" value="<?= e($format) ?>">
            <button class="quiet danger">إزالة <?= e(strtoupper($extension)) ?> من المسودة</button>
          </form>
        <?php endif; ?>
      <?php endforeach; ?>
      <?php if ($episode['media'] === []): ?>
        <form method="post"><?php seasonControls('remove_episode', $revision, $editing['id'], $season['id'], $episode['id']); ?><button class="quiet danger">حذف الحلقة الفارغة</button></form>
      <?php endif; ?>
    </details>
  <?php endforeach; ?>
</section>
<?php endforeach; ?>
