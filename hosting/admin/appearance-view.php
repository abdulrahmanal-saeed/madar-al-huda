<?php
if (!defined('MADAR_ADMIN')) {
    http_response_code(404);
    exit;
}
$theme = currentTheme($draft);
$checks = themeChecks($theme);
?><link rel="stylesheet" href="./?preview_css=<?= e($revision) ?>">
<div class="appearance-grid">
  <div>
    <section class="panel">
      <h2>قوالب جاهزة</h2>
      <p>اختيار قالب يملأ الألوان في المسودة، وتقدر تعدّلها بعدها.</p>
      <form method="post" class="presets">
        <?php controls('save', $revision); ?>
        <input type="hidden" name="radius" value="<?= e($theme['radius']) ?>">
        <input type="hidden" name="textScale" value="<?= e($theme['textScale']) ?>">
        <input type="hidden" name="ramadanAuto" value="<?= $theme['ramadanAuto'] ? '1' : '0' ?>">
        <?php foreach (THEME_PRESETS as $id => $preset): ?>
          <button class="preset<?= $theme['preset'] === $id ? ' current' : '' ?>" name="apply_preset" value="<?= e($id) ?>" aria-pressed="<?= $theme['preset'] === $id ? 'true' : 'false' ?>">
            <span class="swatches" aria-hidden="true"><span class="swatch preset-<?= e($id) ?>-primary"></span><span class="swatch preset-<?= e($id) ?>-gold"></span><span class="swatch preset-<?= e($id) ?>-background"></span></span>
            <strong><?= e($preset['name']) ?></strong>
            <span><?= e($preset['note']) ?></span>
          </button>
        <?php endforeach; ?>
      </form>
    </section>

    <section class="panel">
      <h2>الألوان والشكل</h2>
      <form method="post">
        <?php controls('save', $revision); ?>
        <input type="hidden" name="preset" value="<?= e($theme['preset']) ?>">
        <div class="fields">
          <?php foreach (THEME_COLORS as $key => $label): ?>
            <label class="color-field"><?= e($label) ?>
              <span class="color-row">
                <input type="color" name="<?= e($key) ?>" value="<?= e(strtolower($theme[$key])) ?>">
                <bdi dir="ltr"><?= e($theme[$key]) ?></bdi>
              </span>
            </label>
          <?php endforeach; ?>
        </div>
        <div class="fields">
          <label>استدارة الزوايا (بكسل)<input type="number" name="radius" min="4" max="32" step="2" value="<?= e($theme['radius']) ?>"></label>
          <label>حجم الخط الأساسي (٪)<input type="number" name="textScale" min="90" max="125" step="5" value="<?= e($theme['textScale']) ?>"></label>
        </div>
        <label class="check"><input type="checkbox" name="ramadanAuto" value="1" <?= $theme['ramadanAuto'] ? 'checked' : '' ?>>فعّل قالب رمضان تلقائيًا في شهر رمضان</label>
        <button class="primary">حفظ في المسودة</button>
      </form>
      <form method="post" class="delete-form">
        <?php controls('delete', $revision); ?>
        <button class="quiet">رجوع للهوية الأصلية</button>
      </form>
    </section>

    <section class="panel">
      <h2>وضوح الألوان</h2>
      <?php foreach ($checks as $check): ?>
        <p class="alert<?= $check['ok'] ? '' : ' error' ?>"><?= $check['ok'] ? 'يجتاز' : 'ضعيف' ?> · <?= e($check['label']) ?> · <bdi dir="ltr"><?= e(number_format($check['ratio'], 1)) ?>:1</bdi></p>
      <?php endforeach; ?>
      <p>النشر يُرفض لو أي فحص أقل من ٤٫٥:١، عشان النص يفضل مقروء لكل المستخدمين.</p>
    </section>
  </div>

  <aside aria-label="معاينة" class="preview-wrap">
    <p>معاينة المسودة</p>
    <div class="phone">
      <div class="phone-screen">
        <div class="phone-head"><span class="phone-brand">مدار الهدى</span></div>
        <div class="phone-hero">
          <span class="phone-chip">الآن</span>
          <strong>أذكار الصباح</strong>
          <span>٧ أذكار · نحو ٦ دقائق</span>
          <span class="phone-track"><span></span></span>
          <span class="phone-button">أكمل أذكار الصباح</span>
        </div>
        <div class="phone-card"><span class="muted">الصلاة القادمة</span><strong>العصر ٣:١٨ م</strong></div>
        <div class="phone-card"><span class="gold">دعاء اليوم</span><strong>البقرة · ٢٠١</strong></div>
        <div class="phone-nav"><span class="on">الرئيسية</span><span>القرآن</span><span>الأذكار</span><span>الصلاة</span><span>المكتبة</span></div>
      </div>
    </div>
    <p>المعاينة بتتحدث بعد «حفظ في المسودة»، والتغيير يوصل للتطبيق بعد النشر.</p>
  </aside>
</div>
