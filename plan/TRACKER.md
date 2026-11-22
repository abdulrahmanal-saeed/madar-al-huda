# Tracker — مصدر الحقيقة لحالة العمل

**Snapshot بتاريخ 2026-11-19:** Phase 00 IN_PROGRESS. عدد المهام 59، منها 5 DONE (P00-01 وP00-02 وP00-03 وP00-05 وP00-09)، و3 REVIEW (`P00-04`، `P00-06`، `P00-11`)، و13 BLOCKED بسبب متطلبات لم تتحقق بعد. الحالة تتغير عبر PRs وليست متابعة تلقائية.

**Status:** `TODO` · `IN_PROGRESS` · `BLOCKED` · `REVIEW` · `DONE` · `DEFERRED` · `CANCELLED`.

**قاعدة:** `DONE` فقط بعد كود/محتوى صحيح، اختبارات مثبتة، مراجعة لازمة، Merge ورابط Evidence. لا يعتبر دمج docs تشغيلًا للتطبيق.

## Summary
- [Phase 00 — Foundation](PHASE_00_FOUNDATION.md): **IN_PROGRESS**, 11 tasks
- [Phase 01 — Quran & Prayer MVP](PHASE_01_QURAN_MVP.md): **TODO**, 9 tasks
- [Phase 02 — Worship & Daily Journey](PHASE_02_WORSHIP.md): **TODO**, 8 tasks
- [Phase 03 — Hadith & Fiqh](PHASE_03_HADITH_FIQH.md): **TODO**, 8 tasks
- [Phase 04 — Academy & CMS](PHASE_04_ACADEMY.md): **TODO**, 8 tasks
- [Phase 05 — Beta & QA](PHASE_05_BETA.md): **TODO**, 8 tasks
- [Phase 06 — Android Release & iOS](PHASE_06_RELEASE.md): **TODO**, 7 tasks

## Phase 00 — Foundation — التأسيس وتجهيز المنتج

| ID | المهمة | Status | Dependencies | Evidence / Issue |
|---|---|---|---|---|
| `P00-01` | تثبيت قرارات المنتج والاسم | `DONE` | — | PR #1 |
| `P00-02` | دمج مستندات التأسيس على main | `DONE` | P00-01 | PR #1 |
| `P00-03` | اعتماد الهوية واسم المنتج بصريًا | `DONE` | P00-01 | [Issue #15](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/15) · [PR #16 merged](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/16): original editable SVG icon/wordmarks, Android adaptive + monochrome vectors, five legacy PNG densities, tokens and CI check. **Owner approved existing name and logo on 2026-11-22; no redesign.** Legal trademark/store/package verification is separate [R-10 / Issue #19](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/19) before Play publication; NOT claimed cleared. |
| `P00-04` | Wireframes عربية وإنجليزية | `REVIEW` | P00-03 | [Issue #18](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/18) · [14 AR/EN SVG wireframes](../docs/ux/README.md), mapped to existing routes, no duplicate logo or Home; pending CI/review/merge. |
| `P00-05` | اعتماد ERD والمعمارية وRLS | `DONE` | P00-01 | [Issue #13](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/13) · architecture ADR, ERD, RLS matrix, SQL reference blueprint, threat model in `docs/architecture/`; [PR #14](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/14) **merged** with three green CI jobs. Engineering architecture baseline delegated for completion by owner; database design only, not deployed; later SQL migrations and role tests remain separate implementation gates |
| `P00-06` | Flutter skeleton + Android CI | `REVIEW` | P00-03,P00-05 | Issue #2 / MHD-001 · branch `claude/serene-galileo-f2ia01` · [PR #4](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/4) **merged**. الاختبارات الآلية ناجحة؛ اختبار Android على جهاز/محاكي بالعربية والإنجليزية، ومراجعة TalkBack والنص العربي لا تزال مطلوبة قبل إغلاق المهمة. بُني على Tokens وهوية **مؤقتة** ومعمارية **مقترحة** بقرار المالك حتى لا تتعطل الهندسة؛ لا يثبّت شيئًا من P00-03/P00-05 (D-16). |
| `P00-07` | تحقيق حقوق مصادر المصحف والتفسير والصوت | `BLOCKED` | P00-01 | — |
| `P00-08` | تعيين مراجع شرعي مؤهل للفقه | `BLOCKED` | P00-01 | — |
| `P00-09` | قواعد QA وDefinition of Done | `DONE` | P00-05 | branch `phase-00/p00-09-qa-dod` · [PR #5](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/5) **merged**; وثائق DoD وQA وقالب PR دُمجت بعد مراجعة الكود ونجاح CI — [DEFINITION_OF_DONE.md](DEFINITION_OF_DONE.md)، [QA_CHECKLIST](../docs/QA_CHECKLIST.md)، PR template. بُني مؤقتًا قبل اعتماد P00-05 بموافقة المالك. |
| `P00-10` | Prayer fixtures للإمارات ومصر | `TODO` | P00-05 | — |
| `P00-11` | قناة تحديث نسخ التطوير (APK موقّع + Obtainium) | `REVIEW` | P00-06 | طلب المالك 2026-11-19 · branch `phase-00/p00-11-dev-updates` · [PR #6](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/6) **merged** · [DEV_UPDATES.md](../docs/DEV_UPDATES.md) · D-17. تم بنجاح نشر أول APK تطوير موقّع في [v0.1.0-dev.2](https://github.com/abdulrahmanal-saeed/madar-al-huda/releases/tag/v0.1.0-dev.2)، وأكد المالك تثبيته واستلامه عبر Obtainium بتاريخ 2026-11-19 ([دليل](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/6#issuecomment-7012989410)). **المتبقي:** إثبات تحديث تلقائي على الجهاز فوق النسخة الحالية؛ الحالة REVIEW وليست DONE. |

## Phase 01 — Quran & Prayer MVP — المصحف والصلاة والقبلة

| ID | المهمة | Status | Dependencies | Evidence / Issue |
|---|---|---|---|---|
| `P01-01` | نص المصحف والآيات immutable | `BLOCKED` | P00-07,P00-06 | — |
| `P01-02` | القارئ والفهرسة والتنقل | `TODO` | P01-01 | — |
| `P01-03` | بحث وعلامات وآخر موضع | `TODO` | P01-01 | — |
| `P01-04` | ترجمة معاني القرآن للإنجليزية | `BLOCKED` | P00-07,P01-01 | — |
| `P01-05` | تفسير الطبري وابن كثير | `BLOCKED` | P00-07,P01-01 | — |
| `P01-06` | مشغل صوت وتلاوة أولى | `BLOCKED` | P00-07,P00-06 | — |
| `P01-07` | صلاة حسب المدينة والموقع | `TODO` | P00-10,P00-06 | — |
| `P01-08` | القبلة ومعايرة المستشعر | `TODO` | P00-06 | — |
| `P01-09` | قبول MVP End-to-End | `TODO` | P01-02,P01-03,P01-04,P01-05,P01-06,P01-07,P01-08 | — |

## Phase 02 — Worship & Daily Journey — الأذكار والدعاء والورد والتلاوات

| ID | المهمة | Status | Dependencies | Evidence / Issue |
|---|---|---|---|---|
| `P02-01` | الحقوق والتوافر للقراء الثلاثة | `BLOCKED` | P00-07,P01-06 | — |
| `P02-02` | خيارات الصوت المتقدمة | `TODO` | P02-01 | — |
| `P02-03` | مصادر ومراجعة الأذكار والأدعية | `BLOCKED` | P00-07 | — |
| `P02-04` | العداد والمفضلة | `TODO` | P02-03 | — |
| `P02-05` | خطة الختم والورد | `TODO` | P01-03 | — |
| `P02-06` | التنبيهات الاختيارية | `TODO` | P01-07,P02-03 | — |
| `P02-07` | Download/cache policy للصوت | `BLOCKED` | P02-01 | — |
| `P02-08` | QA العبادة اليومية | `TODO` | P02-04,P02-05,P02-06 | — |

## Phase 03 — Hadith & Fiqh — الحديث والفقه للمذاهب الأربعة

| ID | المهمة | Status | Dependencies | Evidence / Issue |
|---|---|---|---|---|
| `P03-01` | اختيار مصدر الحديث وترخيصه | `BLOCKED` | P00-07 | — |
| `P03-02` | Data model للأحاديث والدرجات | `TODO` | P03-01,P00-05 | — |
| `P03-03` | بحث وتصنيف الحديث | `TODO` | P03-02 | — |
| `P03-04` | بناء مسائل الفقه وتغطية المذاهب | `TODO` | P00-05 | — |
| `P03-05` | إدخال أقوال فقهية مراجعة | `BLOCKED` | P00-08,P03-04 | — |
| `P03-06` | مقارنة المذاهب بدون إجماع وهمي | `TODO` | P03-05 | — |
| `P03-07` | Workflow نشر/تصحيح شرعي | `BLOCKED` | P00-08,P03-02,P03-04 | — |
| `P03-08` | QA الحديث والفقه والأذونات | `TODO` | P03-03,P03-06,P03-07 | — |

## Phase 04 — Academy & CMS — الدروس والقصص والمقالات ولوحة المحتوى

| ID | المهمة | Status | Dependencies | Evidence / Issue |
|---|---|---|---|---|
| `P04-01` | CMS وأدوار التحرير والمراجعة | `TODO` | P03-07 | — |
| `P04-02` | مسارات ودروس الفقه والعقيدة والشريعة | `TODO` | P04-01 | — |
| `P04-03` | اختبارات وتقدم المتعلم | `TODO` | P04-02 | — |
| `P04-04` | قصص الأنبياء الموثقة | `BLOCKED` | P00-08,P04-01 | — |
| `P04-05` | مقالات موثقة ثنائية اللغة | `TODO` | P04-01 | — |
| `P04-06` | مقتبسات مجدولة بعد الاعتماد | `TODO` | P02-06,P04-05 | — |
| `P04-07` | مزامنة وتراجع المحتوى | `TODO` | P04-01 | — |
| `P04-08` | QA رحلة التعلم والنشر | `TODO` | P04-02,P04-03,P04-04,P04-05,P04-07 | — |

## Phase 05 — Beta & QA — الأمان والاختبارات والتجربة المغلقة

| ID | المهمة | Status | Dependencies | Evidence / Issue |
|---|---|---|---|---|
| `P05-01` | تدقيق القرآن والمصادر والتراخيص | `TODO` | P01-09,P02-08,P03-08,P04-08 | — |
| `P05-02` | تدقيق Security وRLS | `TODO` | P04-07 | — |
| `P05-03` | Android Device Matrix | `TODO` | P02-08 | — |
| `P05-04` | Accessibility وRTL/LTR QA | `TODO` | P04-08 | — |
| `P05-05` | أداء وOffline والاتصال | `TODO` | P01-09 | — |
| `P05-06` | Privacy وStore Data Safety | `TODO` | P05-02 | — |
| `P05-07` | Beta على أجهزة ومستخدمين حقيقيين | `TODO` | P05-01,P05-03,P05-04,P05-05,P05-06 | — |
| `P05-08` | قرار Go/No-Go للإطلاق | `TODO` | P05-07 | — |

## Phase 06 — Android Release & iOS — النشر والتشغيل والاستعداد لـ iOS

| ID | المهمة | Status | Dependencies | Evidence / Issue |
|---|---|---|---|---|
| `P06-01` | Build AAB وتوقيع التطبيق والمتجر | `TODO` | P05-08 | — |
| `P06-02` | إطلاق تدريجي ورصد الأعطال | `TODO` | P06-01 | — |
| `P06-03` | بلاغات وتصحيح وسحب محتوى | `TODO` | P06-02 | — |
| `P06-04` | متابعة ميزانية وحقوق الاستخدام | `TODO` | P06-02 | — |
| `P06-05` | iOS architecture readiness | `TODO` | P06-02 | — |
| `P06-06` | اختبار وبناء iOS (لاحقًا) | `DEFERRED` | P06-05 | — |
| `P06-07` | Roadmap التحسينات المستقبلية | `TODO` | P06-03,P06-04 | — |


## طريقة تحديث صف
غير حالة مهمة في هذا الملف وأضف Issue/PR/commit في العمود الأخير. عند `BLOCKED` اربطه برقم Risk من [RISKS_AND_BLOCKERS.md](RISKS_AND_BLOCKERS.md). لا تنشئ ID جديدًا لو يوجد بالفعل ID لنفس العمل.

**ربط مهام سابق:** `P00-06` تقابل [MHD-001 / GitHub Issue #2](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/2)، و`P00-02` مبنية على [PR #1 المدموج](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/1). ملفات `AI_BRIDGE` لتسليم العمل وليست نسخة ثانية من هذا Tracker.
