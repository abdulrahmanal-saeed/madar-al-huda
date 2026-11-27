<?php
declare(strict_types=1);

if (!defined('MADAR_ADMIN')) {
    http_response_code(404);
    exit;
}

function repeatEditor(string $slot, array $steps, string $label): void
{
    $units = [
        'recitation' => 'قراءة الذكر', 'tasbih' => 'سبحان الله',
        'tahmid' => 'الحمد لله', 'takbir' => 'الله أكبر',
        'seeking_forgiveness' => 'أستغفر الله', 'closing_tahlil' => 'لا إله إلا الله',
        'each_surah' => 'كل سورة', 'full_recitation_and_wiping_cycle' => 'القراءة والمسح',
    ];
    $row = static function (array $step = []) use ($slot): void {
        ?>
        <div class="repeat-step">
          <label>نوع التكرار
            <input name="repetition[<?= e($slot) ?>][unit][]" maxlength="120" dir="ltr"
              list="units-<?= e($slot) ?>" value="<?= e($step['unit'] ?? '') ?>" placeholder="recitation">
          </label>
          <label>العدد
            <input name="repetition[<?= e($slot) ?>][count][]" type="number" min="1" max="1000" step="1"
              value="<?= e($step['count'] ?? '') ?>">
          </label>
          <button type="button" class="quiet" data-repeat-remove hidden aria-label="حذف خطوة التكرار">حذف</button>
        </div>
        <?php
    };
    ?>
    <fieldset class="repeat-steps" data-repeat-editor>
      <legend><?= e($label) ?></legend>
      <input type="hidden" name="repetition[<?= e($slot) ?>][editor]" value="1">
      <p class="hint">اكتب العدد لكل خطوة. اترك النوع والعدد فارغين للقراءة بدون عداد.</p>
      <datalist id="units-<?= e($slot) ?>">
        <?php foreach ($units as $key => $name): ?>
          <option value="<?= e($key) ?>" label="<?= e($name) ?>"></option>
        <?php endforeach; ?>
      </datalist>
      <div data-repeat-rows>
        <?php foreach ($steps ?: [[]] as $step) $row($step); ?>
      </div>
      <template><?php $row(); ?></template>
      <button type="button" class="quiet repeat-add" data-repeat-add hidden>إضافة خطوة</button>
    </fieldset>
    <?php
}
