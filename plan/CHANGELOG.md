# Plan Changelog

## 2026-11-22 — P00-04 bilingual wireframes merged
- PR #20 merged with all 3 CI jobs successful. P00-04 DONE for **design handoff only**, not a claim of implemented reader/player/prayer UI. Existing brand and Home remain unchanged.


## 2026-11-22 — P00-10 official reference groundwork
- Added two date-stamped Egypt Survey Authority prayer-time reference rows (Cairo/Alexandria, 2026-11-22); Dubai/Abu Dhabi official expected values explicitly pending, not invented.
- Added zoneinfo 2026 DST/UTC offset validation in a zero-dependency Python checker; P00-10 stays IN_PROGRESS until all four authorities/calculation comparisons are verified.


## 2026-11-22 — Existing identity approved; nonduplicative P00-04 design handoff
- Owner approved the current name/logo without changes. P00-03 creative identity DONE; official trademark/store clearance tracked separately in R-10 / Issue #19.
- P00-04: 14 source-controlled SVG wireframes (seven screens × Arabic RTL/English LTR), mapped to existing routes and content gates. No alterations to existing brand assets or Home screen. Static checker added to existing CI.


## 2026-11-19 — Phase 0 design reconciliation after PR #14 and #16
- P00-05 architectural design DONE after docs/ERD/RLS blueprint merged; does **not** mean live database or RLS role tests were run.
- P00-03 creative/Android icon assets merged, remains REVIEW for visual owner signoff and official naming/trademark clearance.
- RLS blueprint hardened with expiry-aware content gate; static design contract checker added to policy CI.

## 2026-11-19 — P00-03 brand assets
- Original SVG mark + AR/EN wordmark, native Android vector/mono, 5 PNG sizes, token JSON and CI verification. Creative identity ready for review; trademark and owner signoff not claimed.

## 2026-11-19 — P00-05 architecture baseline proposed
- وثائق ADR/ERD/RLS/Threat model + SQL blueprint مرجعي، دون تشغيل قاعدة بيانات أو إضافة أسرار. الحالة REVIEW لحين المراجعة والدمج.

## 2026-11-19 — Merge reconciliation
- [PR #4](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/4), [PR #5](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/5) و[PR #6](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/6) دُمجت في main بناءً على طلب المالك، بعد مراجعة الفروقات ونتائج CI على رؤوس PRs.
- `P00-09` DONE (التوثيق وقواعد الجودة دُمجت). `P00-06` REVIEW لحين فحص جهاز/محاكي باللغتين وAccessibility/copy. `P00-11` REVIEW لحين تفعيل أسرار توقيع التطوير وتجربة prerelease وتحديث Obtainium.
- لا يُفهم دمج كود التطوير على أنه اكتمال بوابات Phase 00 أو ترخيص نصوص دينية.

## 2026-11-19 — P00-11 dev update channel
- مهمة جديدة `P00-11` بطلب المالك: workflow `dev-release.yml` ينشر APK تطوير موقّع بعد نجاح CI على `main`، والتحديث عبر Obtainium. Phase 00 أصبحت 11 مهمة (المجموع 59). قرار D-17.

## 2026-11-19 — P00-09 QA rules & Definition of Done
- `P00-09` → `REVIEW`: [DEFINITION_OF_DONE.md](DEFINITION_OF_DONE.md) (انتقالات الحالة، قوائم الإنجاز حسب نوع المهمة، بوابات CI الحالية، المراجعات والأدلة، الخطورة)، و`docs/QA_CHECKLIST.md`، و`.github/pull_request_template.md`. لا يضيف CI جديدًا.

## 2026-11-19 — P00-06 implementation
- `P00-06` → `REVIEW`: Flutter skeleton في `apps/mobile` مع AR/EN وRTL/LTR وخمس وجهات تنقل وشاشات أقسام محجوبة المحتوى، وثيمات فاتح/داكن، وتفضيلات محلية، و81 اختبارًا، وGitHub Actions CI.
- قرارات مقترحة جديدة D-12 إلى D-16 في [DECISIONS.md](DECISIONS.md).

## 2026-11-19 — v1.0
- إنشاء خطة شاملة لـ Phase 00 إلى Phase 06، تشمل جميع أقسام التطبيق.
- تتبع 58 مهمة بحالة وتبعيات وشروط قبول وروابط تنفيذ.
- ربط خطة التأسيس المدمجة في PR #1 بأول مهمة Flutter الموجودة في Issue #2.
- الحقوق العلمية والشرعية وحقوق الوسائط موانع فعلية للنشر وليست مفترضة.
- الوضع الأولي: Phase 00 IN_PROGRESS، ولم يُنفَّذ Flutter app بعد.
