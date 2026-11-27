<?php
if (!defined('MADAR_ADMIN')) {
    http_response_code(404);
    exit;
}
$theme = currentTheme($draft);
$profile = paletteProfile($_GET['profile'] ?? null);
$colors = currentPalettes($draft)[$profile];
$checks = paletteChecks($colors);
$failedChecks = array_filter($checks, fn ($check) => !$check['ok']);
?><link rel="stylesheet" href="./?preview_css=<?= e($revision) ?>&amp;profile=<?= e($profile) ?>">
<div class="appearance-grid">
  <div>
    <section class="panel">
      <h2>لوحات ألوان التطبيق</h2>
      <div class="appearance-profiles" role="group" aria-label="اختر الموسم ووضع العرض">
        <?php foreach (PALETTE_PROFILES as $id => $label): ?>
          <a class="button<?= $id === $profile ? ' primary' : '' ?>" href="./?section=appearance&amp;profile=<?= e($id) ?>" <?= $id === $profile ? 'aria-current="page"' : '' ?>><?= e($label) ?></a>
        <?php endforeach; ?>
      </div>
      <p>التطبيق يختار رمضان والعيد حسب التاريخ الهجري، ويستخدم الوضع الفاتح أو الداكن حسب إعدادات العرض.</p>
    </section>

    <section class="panel">
      <h2><?= e(PALETTE_PROFILES[$profile]) ?></h2>
      <form method="post">
        <?php controls('save', $revision); ?>
        <?php foreach (PALETTE_ROLE_GROUPS as $group => $roles): ?>
          <details <?= $group === array_key_first(PALETTE_ROLE_GROUPS) ? 'open' : '' ?>>
            <summary><?= e($group) ?></summary>
            <div class="fields appearance-colors">
              <?php foreach ($roles as $key => $label): ?>
                <label><?= e($label) ?>
                  <?php if (paletteAlpha($key)): ?>
                    <input type="text" dir="ltr" name="palette[<?= e($key) ?>]" value="<?= e($colors[$key]) ?>"
                      pattern="#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})" aria-label="<?= e($label . '، HEX أو AARRGGBB') ?>" required>
                  <?php else: ?>
                    <span class="color-row">
                      <input type="color" name="palette[<?= e($key) ?>]" value="<?= e(strtolower($colors[$key])) ?>">
                      <bdi dir="ltr"><?= e($colors[$key]) ?></bdi>
                    </span>
                  <?php endif; ?>
                </label>
              <?php endforeach; ?>
            </div>
          </details>
        <?php endforeach; ?>
        <div class="fields">
          <label>استدارة الزوايا (بكسل)<input type="number" name="radius" min="4" max="32" value="<?= e($theme['radius']) ?>"></label>
          <label>حجم الخط الأساسي (٪)<input type="number" name="textScale" min="90" max="125" value="<?= e($theme['textScale']) ?>"></label>
        </div>
        <button class="primary">حفظ في المسودة</button>
      </form>
      <form method="post" class="delete-form">
        <?php controls('delete', $revision); ?>
        <button class="quiet">استعادة الألوان الأصلية لهذه اللوحة</button>
      </form>
    </section>

    <section class="panel">
      <h2>وضوح الألوان</h2>
      <?php if ($failedChecks === []): ?><p class="alert">ألوان هذه اللوحة تجتاز فحوص التباين.</p><?php endif; ?>
      <?php foreach ($failedChecks as $check): ?>
        <p class="alert error"><?= e($check['label']) ?> · <bdi dir="ltr"><?= e(number_format($check['ratio'], 2)) ?>:1</bdi></p>
      <?php endforeach; ?>
      <p>يلزم تباين ٤٫٥:١ على الأقل لكل زوج معروض قبل النشر.</p>
    </section>
  </div>

  <aside aria-label="معاينة" class="preview-wrap">
    <p>معاينة المسودة · <?= e(PALETTE_PROFILES[$profile]) ?></p>
    <div class="phone appearance-phone">
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
