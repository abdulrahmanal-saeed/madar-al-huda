<?php
declare(strict_types=1);
if (!defined('MADAR_ADMIN') || !$active || $user === null) exit;
?>
<section class="panel">
  <h2>إدارة الفقه المقارن — النسخة التجريبية</h2>
  <p>واجهة تجريبية للمسودات والمراجعة. مؤشر النشر الداخلي لا يتصل بالتطبيق أو الموقع العام. قسم الفقه السابق منفصل إلى حين ترحيله.</p>
  <?php if (!fiqhAdminReady($db)): ?>
    <p role="status">قاعدة الفقه الجديدة غير مفعّلة. يلزم تنفيذ الترحيل على نسخة اختبارية أولًا.</p>
  <?php endif; ?>
</section>
<?php if (fiqhAdminReady($db)): ?>
<?php
$stats = fiqhAdminStats($db);
$reviewReady = fiqhReviewReady($db);
$categories = fiqhListMetadata($db, 'category');
$sources = fiqhListMetadata($db, 'source');
$fiqhPage = filter_var($_GET['page'] ?? 1, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1, 'max_range' => 100000]]) ?: 1;
$filter = is_string($_GET['category'] ?? null) && fiqhStableId($_GET['category']) ? $_GET['category'] : null;
$issues = fiqhListDrafts($db, $filter, 50, ($fiqhPage - 1) * 50);
$selected = is_string($_GET['issue'] ?? null) && fiqhStableId($_GET['issue']) ? fiqhLatestRevision($db, $_GET['issue']) : null;
$issue = $selected === null ? [] : json_decode($selected['body'], true, 64, JSON_THROW_ON_ERROR);
$pretty = static fn (mixed $value): string => json_encode($value, JSON_THROW_ON_ERROR | JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
$fiqhLink = static fn (array $query): string => './?' . http_build_query(['section' => 'fiqh_editor'] + $query);
$failedSave = $error !== null && ($_SERVER['REQUEST_METHOD'] ?? '') === 'POST'
    && ($_POST['action'] ?? '') === 'fiqh_draft_save';
$posted = $failedSave ? $_POST : [];
$fv = static fn (string $key, string|int $fallback = ''): string => fiqhEditorValue($posted, $key, $fallback);
$comparison = filter_var($_GET['compare'] ?? '', FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
$previous = $selected !== null && $comparison !== false ? fiqhGetRevision($db, $issue['id'], $comparison) : null;
?>
<section class="panel">
  <h2>نظرة عامة</h2>
  <?php foreach (['planned' => 'المخطط', 'created' => 'المسائل المنشأة', 'draft' => 'المسودات', 'published' => 'مؤشر النشر التجريبي','ready_for_review'=>'جاهزة للمراجعة','under_review'=>'قيد المراجعة',
    'changes_requested'=>'طلب تصحيحات','approved'=>'معتمدة','archived'=>'مؤرشفة'] as $key => $label): if (!array_key_exists($key,$stats)) continue; ?>
    <div class="row"><span><?= e($label) ?></span><strong><?= e($stats[$key]) ?></strong></div>
  <?php endforeach; ?>
  <?php if (!$reviewReady): ?><p>يلزم ترحيل المراجعة (3 و4) على نسخة اختبارية أولًا.</p><?php endif; ?>
</section>
<section class="panel" id="fiqh-import">
  <h2>الاستيراد والتصدير</h2>
  <p>دفعة من 1 إلى 50 مسألة. JSON يدعم الإنشاء والتحديث بالإصدار المحدد؛ CSV ينشئ بيانات أساسية فقط ولا يستبدل مسألة موجودة. لا اعتماد أو نشر.</p>
  <p><a href="<?= e($fiqhLink(['fiqh_export'=>'json','offset'=>($fiqhPage-1)*50])) ?>">تنزيل JSON (صفحة <?= e($fiqhPage) ?> من جميع المسودات)</a>
   · <a href="<?= e($fiqhLink(['fiqh_export'=>'csv','offset'=>($fiqhPage-1)*50])) ?>">تنزيل CSV للبيانات الأساسية</a></p>
  <form method="post" action="<?= e($fiqhLink([])) ?>#fiqh-import">
    <?php controls('fiqh_import_preview'); ?>
    <label>الصيغة<select name="import_format"><option value="json">JSON</option><option value="csv">CSV</option></select></label>
    <label>المحتوى<textarea name="import_payload" dir="ltr" rows="10" required><?= e(is_string($_POST['import_payload'] ?? null) ? $_POST['import_payload'] : '') ?></textarea></label>
    <p dir="ltr"><code>id,number,slug,categoryId,title_ar,title_en</code></p>
    <button class="primary">معاينة دون حفظ</button>
  </form>
  <?php if ($fiqhImportPreview !== null): ?>
    <h3>نتيجة المعاينة — لم تُحفظ الدفعة</h3>
    <?php foreach ($fiqhImportPreview['result']['results'] as $result): ?>
      <p><bdi><?= e($result['id']) ?> · v<?= e($result['revision']) ?></bdi> · <?= $result['changed'] ? 'تغيير' : 'دون تغيير' ?> · <?= count($result['completenessErrors']) ?> حقل ناقص</p>
    <?php endforeach; ?>
    <details><summary>عرض المحتوى الذي سيُحفظ</summary><pre dir="auto"><?= e($pretty($fiqhImportPreview['payload'])) ?></pre></details>
    <form method="post" action="<?= e($fiqhLink([])) ?>#fiqh-import">
      <?php controls('fiqh_import_commit'); ?>
      <input type="hidden" name="import_confirmation" value="<?= e($fiqhImportPreview['result']['confirmation']) ?>">
      <textarea name="import_payload" hidden><?= e(fiqhJson($fiqhImportPreview['payload'])) ?></textarea>
      <label><input type="checkbox" name="fiqh_confirm" value="yes" required> أؤكد حفظ هذه الدفعة في المسودات فقط.</label>
      <button class="primary">حفظ الدفعة</button>
    </form>
  <?php endif; ?>
</section>
<section class="panel">
  <h2>الأقسام والمراجع</h2>
  <?php foreach (['category' => $categories, 'source' => $sources] as $kind => $records): ?>
    <details><summary><?= $kind === 'category' ? 'إدارة الأقسام' : 'إدارة المراجع' ?> (<?= count($records) ?>)</summary>
    <?php foreach ($records as $record): ?>
      <details><summary><?= e($record['record']['title']['ar']) ?> · <bdi><?= e($record['record']['id']) ?></bdi></summary>
        <form method="post" action="<?= e($fiqhLink([])) ?>">
          <?php controls('fiqh_metadata_save'); ?>
          <input type="hidden" name="kind" value="<?= e($kind) ?>">
          <input type="hidden" name="edit_token" value="<?= e($record['editToken']) ?>">
          <label>بيانات JSON<textarea name="record" rows="12" dir="ltr" required><?= e($pretty($record['record'])) ?></textarea></label>
          <button class="primary">حفظ المسودة</button>
        </form>
      </details>
    <?php endforeach; ?>
    <details><summary>إضافة سجل</summary>
      <form method="post" action="<?= e($fiqhLink([])) ?>">
        <?php controls('fiqh_metadata_save'); ?><input type="hidden" name="kind" value="<?= e($kind) ?>">
        <label>سجل JSON جديد<textarea name="record" dir="ltr" rows="12" required><?= e($pretty($kind === 'category'
          ? ['id'=>'', 'title'=>['ar'=>'','en'=>''], 'description'=>['ar'=>'','en'=>''], 'icon'=>'book', 'order'=>0, 'parentId'=>null, 'plannedIssueCount'=>0, 'visible'=>true, 'status'=>'draft']
          : ['id'=>'', 'title'=>['ar'=>'','en'=>''], 'author'=>['ar'=>'','en'=>''], 'madhhab'=>null, 'sourceType'=>'book', 'status'=>'placeholder'])) ?></textarea></label>
        <button class="primary">إضافة مسودة</button>
      </form>
    </details></details>
  <?php endforeach; ?>
</section>
<section class="panel">
  <h2>المسائل</h2>
  <form method="get">
    <input type="hidden" name="section" value="fiqh_editor">
    <label>القسم<select name="category"><option value="">الكل</option>
    <?php foreach ($categories as $entry): $cat = $entry['record']; ?>
      <option value="<?= e($cat['id']) ?>" <?= $filter === $cat['id'] ? 'selected' : '' ?>><?= e($cat['title']['ar']) ?></option>
    <?php endforeach; ?></select></label><button>تصفية</button>
  </form>
  <p><a href="<?= e($fiqhLink([])) ?>#fiqh-issue">مسألة جديدة</a></p>
  <?php foreach ($issues as $entry): ?>
    <div class="row"><a href="<?= e($fiqhLink(['issue'=>$entry['issue']['id']])) ?>#fiqh-issue"><?= e($entry['issue']['title']['ar']) ?></a>
    <span><bdi><?= e($entry['issue']['number']) ?> · v<?= e($entry['revision']) ?></bdi> · <?= count($entry['completenessErrors']) ?> حقول ناقصة</span></div>
  <?php endforeach; ?>
  <?php if (!$issues): ?><p>لا توجد مسائل في هذه الصفحة.</p><?php endif; ?>
  <?php if ($fiqhPage > 1): ?><a href="<?= e($fiqhLink(['page'=>$fiqhPage-1,'category'=>$filter ?? ''])) ?>">السابق</a><?php endif; ?>
  <?php if (count($issues) === 50): ?><a href="<?= e($fiqhLink(['page'=>$fiqhPage+1,'category'=>$filter ?? ''])) ?>">التالي</a><?php endif; ?>
</section>
<section class="panel" id="fiqh-issue">
  <h2><?= $selected === null ? 'مسألة جديدة' : 'تعديل مسودة المسألة' ?></h2>
  <?php if ($selected !== null): ?><p>الإصدار <?= e($selected['revision']) ?>. الحفظ ينشئ إصدارًا جديدًا عند تغير المحتوى.</p><?php endif; ?>
  <?php if ($failedSave): ?><p class="alert warn">لم يُحفظ التعديل. بقيت المدخلات ورقم الإصدار الأصلي في النموذج. إذا تغيّر الإصدار في نافذة أخرى، انسخ تعديلاتك ثم أعد فتح أحدث إصدار وقارنها قبل الحفظ.</p><?php endif; ?>
  <form method="post" data-fiqh-editor action="<?= e($fiqhLink($selected === null ? [] : ['issue'=>$issue['id']])) ?>">
    <?php controls('fiqh_draft_save'); ?><input type="hidden" name="fiqh_revision" value="<?= e($fv('fiqh_revision', $selected['revision'] ?? 0)) ?>">
    <details open><summary>1. المعلومات العامة / General</summary>
      <?php foreach (['id','number','slug'] as $key): ?>
        <label><?= e($key) ?><input name="<?= e($key) ?>" dir="ltr" value="<?= e($fv($key, $issue[$key] ?? '')) ?>" required <?= $selected !== null ? 'readonly' : '' ?>></label>
      <?php endforeach; ?>
      <?php foreach (['categoryId'=>'القسم الرئيسي','subcategoryId'=>'القسم الفرعي'] as $key=>$label): ?>
        <label><?= e($label) ?><select name="<?= e($key) ?>" <?= $key === 'categoryId' ? 'required' : '' ?>><option value="">اختر</option>
        <?php foreach ($categories as $entry): $cat=$entry['record']; ?>
          <option value="<?= e($cat['id']) ?>" <?= $fv($key, $issue[$key] ?? '') === $cat['id'] ? 'selected' : '' ?>><?= e($cat['title']['ar']) ?></option>
        <?php endforeach; ?></select></label>
      <?php endforeach; ?>
      <?php foreach (['title'=>'العنوان','summary'=>'الملخص','introduction'=>'المقدمة','scope'=>'نطاق المسألة','scholarlySummary'=>'الخلاصة العلمية'] as $key=>$label): ?>
        <?php foreach (['ar'=>'rtl','en'=>'ltr'] as $lang=>$dir): ?>
          <label><?= e($label . ' (' . $lang . ')') ?><textarea name="<?= e($key . '_' . $lang) ?>" dir="<?= e($dir) ?>" rows="3" <?= $key==='title' ? 'required' : '' ?>><?= e($fv($key . '_' . $lang, $issue[$key][$lang] ?? '')) ?></textarea></label>
        <?php endforeach; ?>
      <?php endforeach; ?>
      <?php foreach (['relatedCategoryIds','relatedIssueIds','keywords'] as $key): ?>
        <label><?= e($key) ?> (JSON)<textarea name="<?= e($key) ?>" dir="ltr" rows="2"><?= e($fv($key, $pretty($issue[$key] ?? []))) ?></textarea></label>
      <?php endforeach; ?>
      <label>الترتيب<input type="number" min="0" name="displayOrder" value="<?= e($fv('displayOrder', $issue['displayOrder'] ?? 0)) ?>"></label>
      <label>المستوى<select name="difficulty"><?php foreach (['','beginner','intermediate','advanced'] as $level): ?>
        <option value="<?= e($level) ?>" <?= $fv('difficulty', $issue['difficulty'] ?? '') === $level ? 'selected' : '' ?>><?= e($level ?: 'غير محدد') ?></option>
      <?php endforeach; ?></select></label>
    </details>
    <?php foreach (['hanafi'=>'الحنفي','maliki'=>'المالكي','shafii'=>'الشافعي','hanbali'=>'الحنبلي'] as $school=>$label): $position=$issue['positions'][$school] ?? []; ?>
      <details><summary><?= e($label) ?></summary>
        <?php foreach (['ruling'=>'القول','explanation'=>'الشرح','reasoning'=>'التعليل'] as $key=>$heading): ?>
          <?php foreach (['ar'=>'rtl','en'=>'ltr'] as $lang=>$dir): ?>
            <label><?= e($heading . ' (' . $lang . ')') ?><textarea name="<?= e($school.'_'.$key.'_'.$lang) ?>" dir="<?= e($dir) ?>" rows="4"><?= e($fv($school.'_'.$key.'_'.$lang, $position[$key][$lang] ?? '')) ?></textarea></label>
          <?php endforeach; ?>
        <?php endforeach; ?>
        <label>الشروط والاستثناءات والأقوال الأخرى والمصادر والأدلة (JSON)<textarea name="<?= e($school.'_details') ?>" dir="ltr" rows="8"><?= e($fv($school.'_details', $pretty(array_diff_key($position, array_flip(['ruling','explanation','reasoning']))))) ?></textarea></label>
      </details>
    <?php endforeach; ?>
    <?php foreach (fiqhAdminSections() as $key=>$label): ?>
      <details><summary><?= e($label) ?></summary>
        <?php if ($key==='evidence'): ?>
          <div data-fiqh-evidence-builder hidden>
            <p>أضف دليلًا موثقًا إلى النموذج دون إنشاء نص أو مرجع تلقائي.</p>
            <label>معرّف الدليل<input data-evidence-id dir="ltr"></label>
            <label>النوع<select data-evidence-type><?php foreach (FIQH_EVIDENCE_TYPES as $type): ?><option value="<?= e($type) ?>"><?= e($type) ?></option><?php endforeach; ?></select></label>
            <?php foreach (['text'=>'النص','reference'=>'المرجع','explanation'=>'وجه الاستدلال'] as $field=>$heading):
              foreach (['ar'=>'rtl','en'=>'ltr'] as $lang=>$dir): ?>
                <label><?= e($heading.' '.$lang) ?><textarea data-evidence-field="<?= e($field.'_'.$lang) ?>" dir="<?= e($dir) ?>" rows="2"></textarea></label>
            <?php endforeach; endforeach; ?>
            <label>المصدر<select data-evidence-source><option value="">اختر</option>
              <?php foreach ($sources as $entry): $s=$entry['record']; ?><option value="<?= e($s['id']) ?>"><?= e($s['title']['ar'].' · '.$s['id']) ?></option><?php endforeach; ?>
            </select></label>
            <div data-evidence-quran hidden>
              <label>رقم السورة<input data-evidence-surah type="number" min="1" max="114"></label>
              <label>أول آية<input data-evidence-first type="number" min="1"></label>
              <label>آخر آية<input data-evidence-last type="number" min="1"></label>
            </div>
            <div data-evidence-hadith hidden>
              <?php foreach (['number'=>'رقم الحديث','book'=>'الكتاب','chapter'=>'الباب','editionLocator'=>'الطبعة والموضع','grading'=>'درجة الحديث','gradingAttribution'=>'صاحب الحكم'] as $field=>$heading):
                foreach (['ar'=>'rtl','en'=>'ltr'] as $lang=>$dir): ?>
                <label><?= e($heading.' '.$lang) ?><input data-evidence-field="<?= e($field.'_'.$lang) ?>" dir="<?= e($dir) ?>"></label>
              <?php endforeach; endforeach; ?>
            </div>
            <button type="button" data-evidence-add>إضافة الدليل إلى النموذج</button><p data-evidence-status role="status"></p>
          </div>
        <?php endif; ?>
        <label>JSON<textarea name="<?= e($key) ?>" dir="ltr" rows="8"><?= e($fv($key, $pretty($issue[$key] ?? []))) ?></textarea></label>
      </details>
    <?php endforeach; ?>
    <details><summary>المصادر المتاحة / Sources</summary>
      <p>اختر المرجع والمذهب واكتب موضع الاستشهاد الموثق باللغتين. لا تُضاف أرقام أو بيانات طبعات تلقائيًا.</p>
      <div data-fiqh-source-picker hidden>
        <label>البحث عن مصدر<input type="search" data-fiqh-source-search></label>
        <label>المصدر<select data-fiqh-source><option value="">اختر</option>
        <?php foreach ($sources as $entry): $source = $entry['record']; ?>
          <option value="<?= e($source['id']) ?>"><?= e($source['title']['ar'] . ' | ' . $source['title']['en'] . ' | ' . $source['id']) ?></option>
        <?php endforeach; ?></select></label>
        <label>المذهب<select data-fiqh-school><?php foreach (FIQH_SCHOOLS as $school): ?><option value="<?= e($school) ?>"><?= e($school) ?></option><?php endforeach; ?></select></label>
        <label>موضع الاستشهاد بالعربية<input data-fiqh-locator-ar dir="rtl"></label>
        <label>Reference locator in English<input data-fiqh-locator-en dir="ltr"></label>
        <button type="button" data-fiqh-add-source>إضافة المرجع إلى المسودة</button>
        <p role="status" data-fiqh-source-status></p>
      </div>
      <?php foreach ($sources as $entry): ?><p><bdi><?= e($entry['record']['id']) ?></bdi> · <?= e($entry['record']['title']['ar']) ?></p><?php endforeach; ?>
    </details>
    <details><summary>التحقق من اكتمال المسودة / Validation</summary><p>يُستخدم التحقق لتحديد الحقول الناقصة؛ لا يُعد اعتمادًا شرعيًا.</p>
      <?php if ($selected !== null): foreach (fiqhCompletenessErrors($issue) as $missing): ?><p><bdi><?= e($missing) ?></bdi></p><?php endforeach; endif; ?>
    </details>
    <details><summary>معاينة المسودة / Preview</summary><p>معاينة بيانات الإصدار المحفوظ، وليست محاكاة Flutter.</p><pre dir="ltr"><?= e($pretty($issue)) ?></pre></details>
    <details <?= $previous !== null ? 'open' : '' ?>><summary>سجل الإصدارات / History</summary>
      <?php if ($selected !== null):
        $history=$db->prepare('SELECT revision, created_at, actor FROM fiqh_revisions WHERE issue_id = ? ORDER BY revision DESC LIMIT 100');
        $history->execute([$issue['id']]);
        foreach ($history->fetchAll(PDO::FETCH_ASSOC) as $version): ?>
          <p><bdi>v<?= e($version['revision']) ?> · <?= e($version['actor']) ?></bdi> · <?= e(publishedLabel((int)$version['created_at'])) ?>
          <a href="<?= e($fiqhLink(['issue'=>$issue['id'], 'compare'=>$version['revision']])) ?>#fiqh-issue">مقارنة بأحدث إصدار</a></p>
        <?php endforeach; endif; ?>
      <?php if ($previous !== null):
        $changes = fiqhRevisionDiff(
            ['body'=>json_decode($previous['body'], true, 64, JSON_THROW_ON_ERROR), 'sources'=>json_decode($previous['source_snapshot'], true, 64, JSON_THROW_ON_ERROR)],
            ['body'=>$issue, 'sources'=>json_decode($selected['source_snapshot'], true, 64, JSON_THROW_ON_ERROR)]
        ); ?>
        <h3>مقارنة v<?= e($previous['revision']) ?> مع v<?= e($selected['revision']) ?></h3>
        <?php if (!$changes): ?><p>لا توجد تغييرات في البيانات.</p><?php endif; ?>
        <?php foreach ($changes as $change): ?>
          <details><summary><bdi><?= e($change['path'] . ' · ' . $change['kind']) ?></bdi></summary>
            <h4>قبل</h4><pre dir="auto"><?= e($pretty($change['before'])) ?></pre>
            <h4>بعد</h4><pre dir="auto"><?= e($pretty($change['after'])) ?></pre>
          </details>
        <?php endforeach; ?>
      <?php endif; ?>
    </details>
    <?php if ($selected !== null): ?>
      <label data-fiqh-autosave-option hidden><input type="checkbox" data-fiqh-autosave> تفعيل الحفظ التلقائي للمسودة في هذه الصفحة فقط</label>
      <p data-fiqh-autosave-status role="status"></p>
      <p>بعد الحفظ التلقائي، أعد فتح الصفحة لتحديث معاينة الإصدار وسجل المراجعة. لا يُعتمد المحتوى تلقائيًا.</p>
    <?php endif; ?>
    <p data-fiqh-dirty role="status" hidden>توجد تعديلات لم تُحفظ.</p>
    <button class="primary">حفظ مسودة المسألة</button>
  </form>
</section>

<?php if ($reviewReady && $selected !== null):
    $reviewState = fiqhReviewCurrent($db,$issue['id'],(int)$selected['revision']);
    $reviewActions = fiqhAvailableReviewActions($db,(int)$user['id'],$selected);
    $published = fiqhPublishedRevision($db,$issue['id']);
    $reviewErrors = fiqhReviewErrors($selected);
    $labels = ['submit'=>'إرسال للمراجعة','start'=>'بدء المراجعة','request_changes'=>'طلب تصحيحات','approve'=>'اعتماد شرعي','publish'=>'نشر داخلي تجريبي'];
?>
<section class="panel" id="fiqh-review">
  <h2>المراجعة الشرعية للإصدار <?= e($selected['revision']) ?></h2>
  <p>الحالة: <bdi><?= e($reviewState['state'] ?? 'draft') ?></bdi> · الاعتماد يخص النسخة المحفوظة فقط.</p>
  <?php if ($published !== null): ?><p>مؤشر النشر الداخلي: v<?= e($published['revision']) ?></p><?php endif; ?>
  <?php foreach ($reviewErrors as $missing): ?><p><bdi><?= e($missing) ?></bdi></p><?php endforeach; ?>
  <?php foreach ($reviewActions as $op): ?>
    <details><summary><?= e($labels[$op]) ?></summary>
      <form method="post" action="<?= e($fiqhLink(['issue'=>$issue['id']])) ?>">
        <?php controls('fiqh_review_action'); ?>
        <input type="hidden" name="id" value="<?= e($issue['id']) ?>">
        <input type="hidden" name="fiqh_revision" value="<?= e($selected['revision']) ?>">
        <input type="hidden" name="fiqh_review_event" value="<?= e((int)($reviewState['id'] ?? 0)) ?>">
        <input type="hidden" name="review_action" value="<?= e($op) ?>">
        <label>ملاحظات<textarea name="notes" rows="3" <?= in_array($op,['approve','request_changes'],true) ? 'required' : '' ?>></textarea></label>
        <?php if ($op === 'request_changes'): ?><label>التصحيحات المطلوبة<textarea name="corrections" required rows="4"></textarea></label><?php endif; ?>
        <label><input type="checkbox" name="fiqh_confirm" value="yes" required> أؤكد الإجراء على هذا الإصدار المحفوظ.</label>
        <button class="primary"><?= e($labels[$op]) ?></button>
      </form>
    </details>
  <?php endforeach; ?>
  <?php if ($published !== null):
    $canArchive = true;
    try { fiqhAssertPublisher($db,fiqhHumanUser($db,(int)$user['id'])); } catch (InvalidArgumentException) { $canArchive=false; }
    if ($canArchive): ?>
      <details><summary>سحب الإصدار المنشور داخليًا</summary>
        <form method="post" action="<?= e($fiqhLink(['issue'=>$issue['id']])) ?>">
          <?php controls('fiqh_archive'); ?>
          <input type="hidden" name="id" value="<?= e($issue['id']) ?>"><input type="hidden" name="fiqh_revision" value="<?= e($published['revision']) ?>">
          <label>سبب السحب<textarea name="notes" required></textarea></label>
          <label><input type="checkbox" name="fiqh_confirm" value="yes" required> أؤكد سحب v<?= e($published['revision']) ?> دون حذف السجل.</label>
          <button>سحب الإصدار</button>
        </form>
      </details>
    <?php endif; endif; ?>
  <details><summary>سجل القرارات</summary>
    <?php $events=$db->prepare('SELECT revision,state,actor_name,qualifications,notes,corrections,at FROM fiqh_review_events WHERE issue_id=? ORDER BY id DESC LIMIT 100');
    $events->execute([$issue['id']]); foreach ($events->fetchAll(PDO::FETCH_ASSOC) as $event): ?>
      <div class="row"><div><strong><bdi>v<?= e($event['revision']) ?> · <?= e($event['state']) ?></bdi></strong>
        <p><?= e($event['actor_name']) ?> · <?= e(publishedLabel((int)$event['at'])) ?></p>
        <?php if ($event['qualifications'] !== null): ?><p><?= e($event['qualifications']) ?></p><?php endif; ?>
        <p><?= e($event['notes']) ?></p><p><?= e($event['corrections']) ?></p>
      </div></div>
    <?php endforeach; ?>
  </details>
</section>
<?php endif; ?>
<?php if ($reviewReady && $user['role'] === 'owner'):
    $accounts=$db->query('SELECT id,username,role FROM users WHERE disabled=0 ORDER BY username')->fetchAll(PDO::FETCH_ASSOC);
    $profiles=$db->query('SELECT user_id,reviewer_name,qualifications,active FROM fiqh_review_profiles ORDER BY user_id')->fetchAll(PDO::FETCH_ASSOC);
    $grants=$db->query('SELECT user_id FROM fiqh_publish_grants ORDER BY user_id')->fetchAll(PDO::FETCH_COLUMN);
?>
<section class="panel">
  <h2>إدارة المراجعين والناشرين</h2>
  <p>لا تسجل مؤهلات غير متحقق منها. هذا القسم للمالك فقط، ولا يمنح المالك صلاحية الاعتماد الشرعي.</p>
  <?php foreach ($profiles as $profile): ?><p><?= e($profile['reviewer_name']) ?> · <?= e($profile['qualifications']) ?> · <?= $profile['active'] ? 'نشط' : 'موقوف' ?></p><?php endforeach; ?>
  <form method="post" action="<?= e($fiqhLink([])) ?>">
    <?php controls('fiqh_reviewer_profile'); ?>
    <label>حساب المراجع<select name="subject_id" required><option value="">اختر</option><?php foreach ($accounts as $account): if ($account['role'] !== 'reviewer') continue; ?>
      <option value="<?= e($account['id']) ?>"><?= e($account['username']) ?></option><?php endforeach; ?></select></label>
    <label>الاسم الحقيقي<input name="reviewer_name" required></label>
    <label>المؤهلات الشرعية التي تحققت منها<textarea name="qualifications" required></textarea></label>
    <label>الصلاحية<select name="enabled"><option value="yes">تفعيل</option><option value="no">إيقاف</option></select></label>
    <label><input type="checkbox" name="fiqh_confirm" value="yes" required> أؤكد التحقق من هوية المراجع ومؤهلاته.</label>
    <button>حفظ الملف</button>
  </form>
  <form method="post" action="<?= e($fiqhLink([])) ?>">
    <?php controls('fiqh_publisher_grant'); ?>
    <label>حساب الناشر<select name="subject_id" required><option value="">اختر</option><?php foreach ($accounts as $account): ?>
      <option value="<?= e($account['id']) ?>"><?= e($account['username']) ?><?= in_array((int)$account['id'],array_map('intval',$grants),true) ? ' — لديه صلاحية نشر' : '' ?></option><?php endforeach; ?></select></label>
    <label>الصلاحية<select name="enabled"><option value="yes">منح</option><option value="no">سحب</option></select></label>
    <label><input type="checkbox" name="fiqh_confirm" value="yes" required> أؤكد تغيير صلاحية النشر.</label>
    <button>حفظ الصلاحية</button>
  </form>
</section>
<?php endif; ?>
<?php endif; ?>
