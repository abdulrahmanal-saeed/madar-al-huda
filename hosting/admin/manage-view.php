<?php
if (!defined('MADAR_ADMIN')) {
    http_response_code(404);
    exit;
}
?><?php if ($section === 'app_settings'): ?>
  <?php $settings = appSettings($draft); ?>
  <section class="panel">
    <h2>أقسام التطبيق وإعلان الرئيسية</h2>
    <p>أوقف أي ميزة لتختفي من التطبيق (الرئيسية والبحث والمكتبة) بعد النشر.</p>
    <form method="post" class="editor">
      <?php controls('save', $revision); ?>
      <fieldset>
        <legend>الميزات الظاهرة</legend>
        <?php foreach (APP_FEATURES as $key => $label): ?>
          <label class="check"><input type="checkbox" name="feature[<?= e($key) ?>]" <?= $settings['features'][$key] ? 'checked' : '' ?>> <?= e($label) ?></label>
        <?php endforeach; ?>
      </fieldset>
      <fieldset>
        <legend>إعلان في أعلى الرئيسية (اتركه فارغًا لإخفائه)</legend>
        <label>النص بالعربية<textarea name="announcement_ar" maxlength="300"><?= e($settings['announcement']['ar']) ?></textarea></label>
        <label>النص بالإنجليزية<textarea name="announcement_en" dir="ltr" maxlength="300"><?= e($settings['announcement']['en']) ?></textarea></label>
        <label>رابط (اختياري)<input name="link" dir="ltr" value="<?= e($settings['announcement']['link']) ?>" placeholder="https://"></label>
        <label>يظهر حتى تاريخ (اختياري)<input name="until" type="date" value="<?= e($settings['announcement']['until']) ?>"></label>
      </fieldset>
      <button class="primary">حفظ في المسودة</button>
    </form>
  </section>
<?php elseif ($section === 'story_titles'): ?>
  <?php $stories = is_array($draft['stories'] ?? null) ? $draft['stories'] : []; ?>
  <section class="panel">
    <h2>عناوين القصص والحلقات</h2>
    <p>عدّل عنوان القصة ووصفها وعناوين حلقاتها كما تظهر في التطبيق، أو أخفِ قصة. الملفات نفسها تُدار من صفحة «قصص الأنبياء».</p>
    <label>ابحث<input type="search" data-filter-list=".story-card" placeholder="اسم النبي"></label>
  </section>
  <?php foreach (storyProphets() as $id => [$ar, $en]): ?>
    <?php $story = $stories[$id] ?? []; ?>
    <section class="panel story-card">
      <details>
        <summary><strong><?= e($story['ar'] ?? '' ?: 'سيدنا ' . $ar . ' عليه السلام') ?></strong><?= !empty($story['hidden']) ? ' · <span class="badge">مخفية</span>' : '' ?></summary>
        <form method="post" class="editor">
          <?php controls('save', $revision); ?>
          <input type="hidden" name="story" value="<?= e($id) ?>">
          <label>العنوان بالعربية<input name="title_ar" maxlength="80" value="<?= e($story['ar'] ?? '') ?>" placeholder="<?= e('سيدنا ' . $ar . ' عليه السلام') ?>"></label>
          <label>العنوان بالإنجليزية<input name="title_en" dir="ltr" maxlength="80" value="<?= e($story['en'] ?? '') ?>" placeholder="<?= e($en . ', peace be upon him') ?>"></label>
          <label>وصف بالعربية<textarea name="description_ar" maxlength="600"><?= e($story['descriptionAr'] ?? '') ?></textarea></label>
          <label>وصف بالإنجليزية<textarea name="description_en" dir="ltr" maxlength="600"><?= e($story['descriptionEn'] ?? '') ?></textarea></label>
          <label>عناوين الحلقات، كل حلقة في سطر: <bdi>١: العنوان | English title</bdi>
            <textarea name="episodes" rows="5"><?php foreach (($story['episodes'] ?? []) as $number => $title): ?><?= e($number . ': ' . $title['ar'] . ($title['en'] !== '' ? ' | ' . $title['en'] : '')) . "\n" ?><?php endforeach; ?></textarea>
          </label>
          <label class="check"><input type="checkbox" name="hidden" <?= !empty($story['hidden']) ? 'checked' : '' ?>> إخفاء القصة من التطبيق</label>
          <button class="primary">حفظ في المسودة</button>
        </form>
      </details>
    </section>
  <?php endforeach; ?>
<?php elseif ($section === 'adhkar_groups'): ?>
  <?php $entryTitles = array_column(array_map(fn ($entry) => ['id' => $entry['id'], 'title' => $entry['title']['ar'] ?? $entry['id']], $draft['adhkar']['daily']['entries'] ?? []), 'title', 'id'); ?>
  <section class="panel">
    <h2>مجموعات أذكار اليوم</h2>
    <p>عدّل عنوان كل مجموعة وترتيب أذكارها: اكتب معرّف كل ذكر في سطر بالترتيب الذي يظهر به. المعرّفات المتاحة:</p>
    <ul class="ids"><?php foreach ($entryTitles as $id => $title): ?><li><bdi dir="ltr"><?= e($id) ?></bdi> · <?= e($title) ?></li><?php endforeach; ?></ul>
  </section>
  <?php foreach (($draft['adhkar']['daily']['groups'] ?? []) as $group): ?>
    <section class="panel">
      <h2><?= e($group['title']['ar'] ?? $group['id']) ?></h2>
      <form method="post" class="editor">
        <?php controls('save', $revision); ?>
        <input type="hidden" name="group" value="<?= e($group['id']) ?>">
        <label>العنوان بالعربية<input name="title_ar" maxlength="60" required value="<?= e($group['title']['ar'] ?? '') ?>"></label>
        <label>العنوان بالإنجليزية<input name="title_en" dir="ltr" maxlength="60" required value="<?= e($group['title']['en'] ?? '') ?>"></label>
        <label>الأذكار بالترتيب<textarea name="entries" dir="ltr" rows="<?= e(max(4, count($group['entries'] ?? []))) ?>" required><?= e(implode("\n", $group['entries'] ?? [])) ?></textarea></label>
        <button class="primary">حفظ في المسودة</button>
      </form>
    </section>
  <?php endforeach; ?>
<?php endif; ?>
