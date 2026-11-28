<?php
declare(strict_types=1);

/** Preserve exact existing legacy fiqh subtree during unrelated publications.
 * No old draft, review marker, deletion, or historical restore may replace it.
 * This grandfathering is not a new scholarly approval.
 */
function fiqhPreserveLegacy(array $target, ?array $baseline): array
{
    if (is_array($baseline['library'] ?? null) && array_key_exists('fiqh',$baseline['library'])) {
        if (!is_array($target['library'] ?? null)) $target['library'] = [];
        $target['library']['fiqh'] = $baseline['library']['fiqh'];
    } elseif (is_array($target['library'] ?? null)) {
        unset($target['library']['fiqh']);
    }
    return $target;
}
function fiqhGeneralPublication(array $draft, ?array $published): array
{
    return fiqhPreserveLegacy($draft,$published);
}
function fiqhGeneralChanged(array $draft, ?array $published): bool
{
    return $published === null || fiqhCanonicalLegacy(fiqhGeneralPublication($draft,$published)) !== fiqhCanonicalLegacy($published);
}
function fiqhCanonicalLegacy(mixed $value): mixed
{
    if (!is_array($value)) return $value;
    if (!array_is_list($value)) ksort($value,SORT_STRING);
    return array_map('fiqhCanonicalLegacy',$value);
}
function fiqhLegacyAssertAction(string $section, string $action): void
{
    if ($action === 'review_approve' || ($section === 'fiqh' && in_array($action,['save','delete'],true))) {
        throw new InvalidArgumentException('قسم الفقه القديم للقراءة فقط إلى حين الترحيل. استخدم محرر الفقه الجديد.');
    }
}
