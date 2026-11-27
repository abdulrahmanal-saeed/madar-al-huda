<fieldset class="content-news-fields">
  <legend>إشعار للمستخدمين</legend>
  <?php if ($optionalNews): ?>
    <label class="check"><input type="checkbox" name="send_content_news" value="1">إرسال إشعار عند النشر</label>
  <?php endif; ?>
  <label>عنوان الإشعار<input name="news_title" maxlength="80" <?= $optionalNews ? '' : 'required' ?>></label>
  <label>نص الإشعار<textarea name="news_body" rows="2" maxlength="220" <?= $optionalNews ? '' : 'required' ?>></textarea></label>
  <label>يفتح الزر
    <select name="news_route">
      <?php foreach (contentNewsTargets($newsContent) as $path => $label): ?>
        <option value="<?= e($path) ?>"><?= e($label) ?></option>
      <?php endforeach; ?>
    </select>
  </label>
  <label>الجمهور
    <select name="news_channel">
      <option value="dev">أجهزة الاختبار</option>
      <?php if (getenv('MADAR_NEWS_LIVE') === '1'): ?>
        <option value="live">المستخدمون الذين سمحوا بالإشعارات</option>
      <?php endif; ?>
    </select>
  </label>
  <div class="panel" aria-label="معاينة الإشعار">
    <strong data-news-preview-title>عنوان الإشعار</strong>
    <p data-news-preview-body>نص الإشعار</p>
    <span class="button quiet" data-news-preview-action>افتح</span>
  </div>
</fieldset>
