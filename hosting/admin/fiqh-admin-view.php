<?php
declare(strict_types=1);
if (!defined('MADAR_ADMIN') || !$active || $user === null) exit;
?>
<section class="panel">
  <h2>إدارة الفقه المقارن — النسخة التجريبية</h2>
  <p>إعداد المسودات فقط. لا تتصل هذه الواجهة بالنشر أو الاعتماد الشرعي. قسم الفقه السابق ما زال منفصلًا إلى حين ترحيله.</p>
  <?php if (!fiqhAdminReady($db)): ?>
    <p role="status">قاعدة الفقه الجديدة غير مفعّلة. يلزم تنفيذ الترحيل على نسخة اختبارية أولًا.</p>
  <?php endif; ?>
</section>
<?php if (fiqhAdminReady($db)): ?>
<?php
$stats = fiqhAdminStats($db);
$categories = fiqhListMetadata($db, 'category');
$sources = fiqhListMetadata($db, 'source');
$fiqhPage = filter_var($_GET['page'] ?? 1, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1, 'max_range' => 100000]]) ?: 1;
$filter = is_string($_GET['category'] ?? null) && fiqhStableId($_GET['category']) ? $_GET['category'] : null;
$issues = fiqhListDrafts($db, $filter, 50, ($fiqhPage - 1) * 50);
$selected = is_string($_GET['issue'] ?? null) && fiqhStableId($_GET['issue']) ? fiqhLatestRevision($db, $_GET['issue']) : null;
$issue = $selected === null ? [] : json_decode($selected['body'], true, 64, JSON_THROW_ON_ERROR);
$pretty = static fn (array $value): string => json_encode($value, JSON_THROW_ON_ERROR | JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
$fiqhLink = static fn (array $query): string => './?' . http_build_query(['section' => 'fiqh_editor'] + $query);
?>
<section class="panel">
  <h2>نظرة عامة</h2>
  <?php foreach (['planned' => 'المخطط', 'created' => 'المسائل المنشأة', 'draft' => 'المسودات', 'published' => 'المنشور من النظام الجديد'] as $key => $label): ?>
    <div class="row"><span><?= e($label) ?></span><strong><?= e($stats[$key]) ?></strong></div>
  <?php endforeach; ?>
  <p>حالات المراجعة الشرعية ومؤشرات النشر التفصيلية غير مفعّلة بعد.</p>
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
  <form method="post" action="<?= e($fiqhLink($selected === null ? [] : ['issue'=>$issue['id']])) ?>">
    <?php controls('fiqh_draft_save'); ?><input type="hidden" name="fiqh_revision" value="<?= e($selected['revision'] ?? 0) ?>">
    <details open><summary>1. المعلومات العامة / General</summary>
      <?php foreach (['id','number','slug'] as $key): ?>
        <label><?= e($key) ?><input name="<?= e($key) ?>" dir="ltr" value="<?= e($issue[$key] ?? '') ?>" required <?= $selected !== null ? 'readonly' : '' ?>></label>
      <?php endforeach; ?>
      <?php foreach (['categoryId'=>'القسم الرئيسي','subcategoryId'=>'القسم الفرعي'] as $key=>$label): ?>
        <label><?= e($label) ?><select name="<?= e($key) ?>" <?= $key === 'categoryId' ? 'required' : '' ?>><option value="">اختر</option>
        <?php foreach ($categories as $entry): $cat=$entry['record']; ?>
          <option value="<?= e($cat['id']) ?>" <?= ($issue[$key] ?? null) === $cat['id'] ? 'selected' : '' ?>><?= e($cat['title']['ar']) ?></option>
        <?php endforeach; ?></select></label>
      <?php endforeach; ?>
      <?php foreach (['title'=>'العنوان','summary'=>'الملخص','introduction'=>'المقدمة','scope'=>'نطاق المسألة','scholarlySummary'=>'الخلاصة العلمية'] as $key=>$label): ?>
        <?php foreach (['ar'=>'rtl','en'=>'ltr'] as $lang=>$dir): ?>
          <label><?= e($label . ' (' . $lang . ')') ?><textarea name="<?= e($key . '_' . $lang) ?>" dir="<?= e($dir) ?>" rows="3" <?= $key==='title' ? 'required' : '' ?>><?= e($issue[$key][$lang] ?? '') ?></textarea></label>
        <?php endforeach; ?>
      <?php endforeach; ?>
      <?php foreach (['relatedCategoryIds','relatedIssueIds','keywords'] as $key): ?>
        <label><?= e($key) ?> (JSON)<textarea name="<?= e($key) ?>" dir="ltr" rows="2"><?= e($pretty($issue[$key] ?? [])) ?></textarea></label>
      <?php endforeach; ?>
      <label>الترتيب<input type="number" min="0" name="displayOrder" value="<?= e($issue['displayOrder'] ?? 0) ?>"></label>
      <label>المستوى<select name="difficulty"><?php foreach (['','beginner','intermediate','advanced'] as $level): ?>
        <option value="<?= e($level) ?>" <?= ($issue['difficulty'] ?? '') === $level ? 'selected' : '' ?>><?= e($level ?: 'غير محدد') ?></option>
      <?php endforeach; ?></select></label>
    </details>
    <?php foreach (['hanafi'=>'الحنفي','maliki'=>'المالكي','shafii'=>'الشافعي','hanbali'=>'الحنبلي'] as $school=>$label): $position=$issue['positions'][$school] ?? []; ?>
      <details><summary><?= e($label) ?></summary>
        <?php foreach (['ruling'=>'القول','explanation'=>'الشرح','reasoning'=>'التعليل'] as $key=>$heading): ?>
          <?php foreach (['ar'=>'rtl','en'=>'ltr'] as $lang=>$dir): ?>
            <label><?= e($heading . ' (' . $lang . ')') ?><textarea name="<?= e($school.'_'.$key.'_'.$lang) ?>" dir="<?= e($dir) ?>" rows="4"><?= e($position[$key][$lang] ?? '') ?></textarea></label>
          <?php endforeach; ?>
        <?php endforeach; ?>
        <label>الشروط والاستثناءات والأقوال الأخرى والمصادر والأدلة (JSON)<textarea name="<?= e($school.'_details') ?>" dir="ltr" rows="8"><?= e($pretty(array_diff_key($position, array_flip(['ruling','explanation','reasoning'])))) ?></textarea></label>
      </details>
    <?php endforeach; ?>
    <?php foreach (fiqhAdminSections() as $key=>$label): ?>
      <details><summary><?= e($label) ?></summary><label>JSON<textarea name="<?= e($key) ?>" dir="ltr" rows="8"><?= e($pretty($issue[$key] ?? [])) ?></textarea></label></details>
    <?php endforeach; ?>
    <details><summary>المصادر المتاحة / Sources</summary><p>استخدم معرّفات المصادر في sourceReferences وsourceIds. بيانات الطبعة والصفحات تحتاج توثيقًا.</p>
      <?php foreach ($sources as $entry): ?><p><bdi><?= e($entry['record']['id']) ?></bdi> · <?= e($entry['record']['title']['ar']) ?></p><?php endforeach; ?>
    </details>
    <details><summary>المراجعة الشرعية / Review</summary><p>غير متاحة في هذه المرحلة.</p>
      <?php if ($selected !== null): foreach (fiqhCompletenessErrors($issue) as $missing): ?><p><bdi><?= e($missing) ?></bdi></p><?php endforeach; endif; ?>
    </details>
    <details><summary>معاينة المسودة / Preview</summary><p>معاينة بيانات الإصدار المحفوظ، وليست محاكاة Flutter.</p><pre dir="ltr"><?= e($pretty($issue)) ?></pre></details>
    <details><summary>سجل الإصدارات / History</summary>
      <?php if ($selected !== null):
        $history=$db->prepare('SELECT revision, created_at, actor FROM fiqh_revisions WHERE issue_id = ? ORDER BY revision DESC LIMIT 100');
        $history->execute([$issue['id']]);
        foreach ($history->fetchAll(PDO::FETCH_ASSOC) as $version): ?>
          <p><bdi>v<?= e($version['revision']) ?> · <?= e($version['actor']) ?></bdi> · <?= e(publishedLabel((int)$version['created_at'])) ?></p>
        <?php endforeach; endif; ?>
    </details>
    <button class="primary">حفظ مسودة المسألة</button>
  </form>
</section>
<?php endif; ?>
