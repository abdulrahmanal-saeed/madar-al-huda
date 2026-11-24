<?php
if (!defined('MADAR_ADMIN')) {
    http_response_code(404);
    exit;
}
?><?php if ($section === 'reciters'): ?>
  <section class="panel">
    <h2>اختيار قارئ من المصادر</h2>
    <form method="post" class="inline">
      <?php controls('save', $revision); ?>
      <label>ابحث عن قارئ
        <input type="search" data-filter-select="reader-select" placeholder="اكتب جزءًا من الاسم">
      </label>
      <label class="check"><input type="checkbox" data-complete-only="reader-select"> المصحف كاملًا فقط (١١٤ سورة)</label>
      <label>القارئ
        <select name="reader" id="reader-select" required size="8">
          <?php
            // A reciter is either chosen (below) or offered here, never both:
            // the same name from another source counts as already chosen.
            $chosenReaders = array_filter($draft['reciters'] ?? defaultReaders(), static fn (array $r): bool => !empty($r['enabled']));
            $chosenIds = array_column($chosenReaders, 'id');
            $chosenNames = array_map(static fn (array $r): string => trim((string) $r['ar']), $chosenReaders);
            $offered = array_filter(availableReaders(), static fn (array $c): bool => !in_array($c['id'], $chosenIds, true) && !in_array(trim((string) $c['ar']), $chosenNames, true));
          ?>
          <?php if ($offered === []): ?><option disabled>كل القراء المتاحين مختارون بالفعل</option><?php endif; ?>
          <?php foreach ($offered as $choice): ?>
            <option value="<?= e($choice['id']) ?>" data-complete="<?= !isset($choice['chapters']) || count($choice['chapters']) >= 114 ? '1' : '0' ?>"><?= e($choice['ar']) ?> · <?= e($choice['source']) ?><?= isset($choice['chapters']) ? ' · ' . count($choice['chapters']) . ' سورة' : '' ?></option>
          <?php endforeach; ?>
        </select>
      </label>
      <button class="primary">إضافة للقائمة</button>
    </form>
  </section>
  <section class="panel">
    <h2>القراء المختارون</h2>
    <?php foreach (($draft['reciters'] ?? defaultReaders()) as $reader): ?>
      <?php if ($reader['enabled']): ?>
        <div class="row">
          <span><?= e($reader['ar']) ?></span>
          <form method="post">
            <?php controls('delete', $revision); ?>
            <input type="hidden" name="reader" value="<?= e($reader['id']) ?>">
            <button class="quiet danger">إزالة من القائمة</button>
          </form>
        </div>
      <?php endif; ?>
    <?php endforeach; ?>
  </section>
<?php else: ?>
<div class="editor-grid">
  <section class="panel">
    <div class="row head"><h2>العناصر</h2><a class="button quiet" href="<?= e(route($section, '', 'new')) ?>">إضافة</a></div>
    <?php if ($rows === []): ?><p>لا توجد عناصر في هذا القسم.</p><?php endif; ?>
    <?php foreach ($rows as $row): ?>
      <a class="entry" href="<?= e(route($section, '', $row['id'])) ?>">
        <strong><?= e($row['title']['ar']) ?></strong>
        <?php if ($section === 'fiqh'): ?><span class="badge<?= reviewCurrent($row) ? '' : ' warn' ?>"><?= reviewCurrent($row) ? 'معتمد شرعيًا' : 'بانتظار المراجعة' ?></span><?php endif; ?>
        <span dir="ltr"><?= e($row['title']['en']) ?></span>
      </a>
    <?php endforeach; ?>
  </section>
  <?php if ($section === 'names' && $current === null && $edit !== 'new'): ?>
  <section class="panel">
    <h2>إضافة أسماء دفعة واحدة</h2>
    <p>الصق اسمًا في كل سطر بهذا الشكل، ثم «حفظ في المسودة». السطر الذي اسمه موجود يحدّث معناه:</p>
    <p dir="rtl"><code>الرحمن | Ar-Rahman | ذو الرحمة الواسعة التي وسعت كل شيء | The Most Merciful</code></p>
    <form method="post">
      <?php controls('save', $revision); ?>
      <input type="hidden" name="original" value="">
      <textarea name="bulk" rows="10" required></textarea>
      <button class="primary">حفظ في المسودة</button>
    </form>
    <p class="hint">بعد الحفظ افتح أي اسم لإضافة الدليل ورابط المصدر أو تعديل الرقم. ولا يظهر القسم في التطبيق حتى تنشر المسودة.</p>
  </section>
  <?php endif; ?>
  <?php if ($current !== null || $edit === 'new'): ?>
  <section class="panel">
    <h2><?= $current !== null ? 'تعديل العنصر' : 'إضافة عنصر' ?></h2>
    <?php if ($section === 'fiqh' && $current !== null): ?>
      <?php if (reviewCurrent($current)): ?>
        <p class="alert">اعتمدها <bdi dir="ltr"><?= e($current['review']['by']) ?></bdi> في <?= e(publishedLabel((int) $current['review']['at'])) ?>. أي تعديل يلغي الاعتماد.</p>
      <?php else: ?>
        <p class="alert error">لم تُعتمد شرعيًا بعد، ولن تُنشر حتى يعتمدها مراجع.</p>
        <?php if (allowedAction($user, 'review_approve', $section)): ?>
          <form method="post"><?php controls('review_approve', $revision); ?><input type="hidden" name="item" value="<?= e($current['id']) ?>"><button class="primary">اعتماد شرعي</button></form>
        <?php endif; ?>
      <?php endif; ?>
    <?php endif; ?>
    <form method="post">
      <?php controls('save', $revision); ?>
      <input type="hidden" name="original" value="<?= e($current['id'] ?? '') ?>">
      <?php if ($section === 'names'): ?>
        <div class="fields">
          <label>الرقم<input name="number" type="number" min="1" max="999" value="<?= e($current['number'] ?? count($rows) + 1) ?>" required></label>
          <label>الاسم<input name="ar" value="<?= e($current['title']['ar'] ?? '') ?>" required placeholder="الرحمن"></label>
          <label>النطق بالإنجليزية<input name="en" dir="ltr" value="<?= e($current['title']['en'] ?? '') ?>" required placeholder="Ar-Rahman"></label>
        </div>
        <label>المعنى والشرح بالعربية<textarea name="body_ar" rows="6" required><?= e($current['body']['ar'] ?? '') ?></textarea></label>
        <label>المعنى بالإنجليزية (اختياري)<textarea name="body_en" dir="ltr" rows="4"><?= e($current['body']['en'] ?? '') ?></textarea></label>
        <label>الدليل من القرآن أو السنة (اختياري)<textarea name="evidence" rows="3"><?= e($current['evidence']['ar'] ?? '') ?></textarea></label>
        <label>رابط المصدر (اختياري)<input name="source" type="url" dir="ltr" value="<?= e($current['source'] ?? '') ?>"></label>
      <?php else: ?>
      <label>العنوان بالعربية<input name="ar" value="<?= e($current['title']['ar'] ?? '') ?>" required></label>
      <label>العنوان بالإنجليزية<input name="en" dir="ltr" value="<?= e($current['title']['en'] ?? '') ?>" required></label>
      <?php endif; ?>
      <?php if ($section === 'names'): ?>
      <?php elseif ($section === 'fiqh'): ?>
        <?php $positions = array_column($current['positions'] ?? [], null, 'school'); ?>
        <?php foreach (SCHOOLS as $key => $name): ?>
          <?php $position = $positions[$key] ?? []; ?>
          <details <?= $position !== [] ? 'open' : '' ?>>
            <summary>المذهب <?= e($name) ?></summary>
            <label>القول بالعربية<textarea name="ar_<?= e($key) ?>"><?= e($position['body']['ar'] ?? '') ?></textarea></label>
            <label>القول بالإنجليزية<textarea dir="ltr" name="en_<?= e($key) ?>"><?= e($position['body']['en'] ?? '') ?></textarea></label>
            <label>رابط المصدر<input dir="ltr" type="url" name="source_<?= e($key) ?>" value="<?= e($position['source'] ?? '') ?>"></label>
          </details>
        <?php endforeach; ?>
      <?php else: ?>
        <label>النص بالعربية<textarea name="body_ar" required><?= e($current['body']['ar'] ?? '') ?></textarea></label>
        <label>النص بالإنجليزية<textarea name="body_en" dir="ltr" required><?= e($current['body']['en'] ?? '') ?></textarea></label>
        <label>رابط المصدر<input name="source" type="url" dir="ltr" value="<?= e($current['source'] ?? '') ?>" required></label>
        <?php if ($section === 'lessons'): ?>
          <?php $questions = $current['questions'] ?? []; $questions[] = []; ?>
          <input type="hidden" name="questions_count" value="<?= count($questions) ?>">
          <?php foreach ($questions as $i => $question): ?>
            <details <?= $question !== [] ? 'open' : '' ?>>
              <summary><?= $question === [] ? 'إضافة سؤال اختياري' : 'سؤال ' . ($i + 1) ?></summary>
              <label>السؤال بالعربية<input name="question_ar_<?= $i ?>" value="<?= e($question['prompt']['ar'] ?? '') ?>"></label>
              <label>السؤال بالإنجليزية<input dir="ltr" name="question_en_<?= $i ?>" value="<?= e($question['prompt']['en'] ?? '') ?>"></label>
              <?php for ($choice = 0; $choice < 4; $choice++): ?>
                <label>الاختيار <?= $choice + 1 ?> بالعربية<input name="choice_ar_<?= $i ?>_<?= $choice ?>" value="<?= e($question['choices'][$choice]['ar'] ?? '') ?>"></label>
                <label>الاختيار <?= $choice + 1 ?> بالإنجليزية<input dir="ltr" name="choice_en_<?= $i ?>_<?= $choice ?>" value="<?= e($question['choices'][$choice]['en'] ?? '') ?>"></label>
              <?php endfor; ?>
              <label>الإجابة الصحيحة
                <select name="answer_<?= $i ?>"><?php for ($choice = 0; $choice < 4; $choice++): ?><option value="<?= $choice ?>" <?= ($question['answer'] ?? 0) === $choice ? 'selected' : '' ?>><?= $choice + 1 ?></option><?php endfor; ?></select>
              </label>
              <?php if ($question !== []): ?><label class="check"><input name="skip_question_<?= $i ?>" type="checkbox" value="1">حذف السؤال</label><?php endif; ?>
            </details>
          <?php endforeach; ?>
        <?php endif; ?>
      <?php endif; ?>
      <button class="primary">حفظ في المسودة</button>
    </form>
    <?php if ($current !== null): ?>
      <form method="post" class="delete-form">
        <?php controls('delete', $revision); ?><input type="hidden" name="original" value="<?= e($current['id']) ?>">
        <button class="quiet danger">حذف من المسودة</button>
      </form>
      <?php require __DIR__ . '/preview-view.php'; ?>
    <?php endif; ?>
  </section>
  <?php endif; ?>
</div>
<?php endif; ?>
