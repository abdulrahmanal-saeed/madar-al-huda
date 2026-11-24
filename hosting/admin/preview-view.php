<?php
if (!defined('MADAR_ADMIN')) {
    http_response_code(404);
    exit;
}
/*
 * How the saved item looks in the app, drawn in a phone frame with the
 * draft's colours. Expects $section, $current (the saved item) and $draft.
 */
$item = is_array($current ?? null) ? $current : null;
if ($item === null) {
    return;
}
$ar = static fn (mixed $value): string => is_array($value) && is_string($value['ar'] ?? null) ? $value['ar'] : '';
$excerpt = static fn (string $text, int $limit): string => mb_strlen($text) > $limit ? mb_substr($text, 0, $limit) . '…' : $text;
?>
<link rel="stylesheet" href="./?preview_css=<?= e($revision) ?>">
<details class="app-preview" open>
  <summary>معاينة كما ستظهر في التطبيق</summary>
  <p class="hint">تعرض المعاينة آخر نسخة محفوظة في المسودة؛ احفظ لترى تعديلاتك.</p>
  <div class="phone" aria-hidden="true">
    <div class="phone-screen">
      <?php if (in_array($section, ['daily', 'merits'], true)): ?>
        <span class="phone-brand"><?= e($ar($item['title'])) ?></span>
        <div class="phone-card phone-reading">
          <?php if ($ar($item['wording'] ?? null) !== ''): ?>
            <p><?= nl2br(e($excerpt($ar($item['wording']), 420))) ?></p>
          <?php else: ?>
            <p class="muted">يظهر هنا نص الحديث رقم <bdi><?= e((string) ($item['hadith'] ?? $item['variants'][0]['hadith'] ?? '')) ?></bdi> من المصدر.</p>
          <?php endif; ?>
          <?php if ($ar($item['source'] ?? null) !== ''): ?><span class="muted"><?= e($ar($item['source'])) ?></span><?php endif; ?>
        </div>
        <?php $goal = array_sum(array_column($item['repeat'] ?? [], 'count')) ?: 1; ?>
        <div class="phone-button">٠ / <?= e(arabicDigits((string) $goal)) ?></div>
      <?php elseif ($section === 'hisn'): ?>
        <span class="phone-brand"><?= e($ar($item['title'])) ?></span>
        <?php foreach (array_slice($item['entries'] ?? [], 0, 6) as $entry): ?>
          <div class="phone-card"><strong><?= e($ar($entry['title'])) ?></strong><span class="muted"><?= e($excerpt($ar($entry['wording'] ?? null), 70)) ?></span></div>
        <?php endforeach; ?>
        <?php foreach (array_slice($item['chapterIds'] ?? [], 0, 4) as $chapter): ?>
          <div class="phone-card"><span><?= e($ar($draft['adhkar']['hisn']['chapterTitles'][$chapter] ?? null)) ?></span></div>
        <?php endforeach; ?>
      <?php elseif ($section === 'names'): ?>
        <div class="phone-hero phone-center">
          <span class="phone-chip"><?= e(arabicDigits((string) ($item['number'] ?? ''))) ?></span>
          <strong class="phone-name"><?= e(($item['vocalized'] ?? '') ?: $ar($item['title'])) ?></strong>
          <span dir="ltr"><?= e($item['title']['en'] ?? '') ?></span>
        </div>
        <div class="phone-card"><span class="gold">المعنى</span><span><?= e($excerpt($ar($item['body'] ?? null), 260)) ?></span></div>
        <?php foreach (NAME_TEXTS as $key => $label): ?>
          <?php if ($ar($item[$key] ?? null) !== ''): ?>
            <div class="phone-card"><span class="gold"><?= e($label) ?></span><span><?= e($excerpt($ar($item[$key]), 160)) ?></span></div>
          <?php endif; ?>
        <?php endforeach; ?>
      <?php elseif ($section === 'duas'): ?>
        <span class="phone-brand">الأدعية القرآنية</span>
        <div class="phone-card"><span class="gold"><?= e(verseRangeLabel($item)) ?></span><span class="muted">يظهر هنا نص الآيات من المصحف المضمّن.</span></div>
      <?php else: ?>
        <span class="phone-brand"><?= e($ar($item['title'])) ?></span>
        <div class="phone-card"><span><?= e($excerpt($ar($item['body'] ?? null) ?: $ar($item['positions'][0]['body'] ?? null), 420)) ?></span></div>
      <?php endif; ?>
    </div>
  </div>
</details>
