# القرارات النهائية والمعلّقة

| ID | Decision | Status |
|---|---|---|
| D-01 | مدار الهدى — Madar Al-Huda (اسم المنتج مُعتمد، والفحص القانوني الرسمي منفصل R-10) | CONFIRMED |
| D-02 | Android أولًا Flutter مع معمارية iOS-ready | CONFIRMED |
| D-03 | العربية والإنجليزية مع RTL/LTR | CONFIRMED |
| D-04 | مجاني تمامًا، بدون إعلانات أو اشتراكات | CONFIRMED |
| D-05 | قرآن قراءة واستماع، مع بحث وتفسير وترجمة | CONFIRMED |
| D-06 | مرشحو التفسير: الطبري وابن كثير | CONFIRMED CANDIDATES |
| D-07 | مرشحو القراء: ماهر المعيقلي، محمود علي البنا، إسلام صبحي | CONFIRMED CANDIDATES |
| D-08 | فقه المذاهب الأربعة بعرض الأدلة والاختلاف وتوثيق المراجع | CONFIRMED |
| D-09 | أول دولتين لاختبار الصلاة: الإمارات ومصر | CONFIRMED |
| D-10 | مكتبة ودروس من مصادر موثقة ومحتوى أصلي | CONFIRMED |
| D-11 | الحساب اختياري، البيانات الأساسية Local-first | CONFIRMED DESIGN |
| D-12 | Mobile stack: Flutter 3.50.0 stable (Dart 3.14), `material_ui` 1.11.1، Riverpod 3.5.0، go_router 18.1.4، shared_preferences 2.5.6، intl 0.20.3. إصدارات **مثبتة بالضبط** مع `pubspec.lock`، والترقية بـ PR مستقل (Dependabot) | PROPOSED (P00-06 PR) |
| D-13 | لغة الواجهة الافتراضية تتبع الجهاز: العربية لأجهزة العربية، وغيرها يرجع إلى الإنجليزية؛ ويمكن التغيير من الإعدادات ويُحفظ محليًا | PROPOSED (P00-06 PR) |
| D-14 | خط الواجهة المؤقت: IBM Plex Sans Arabic (SIL OFL 1.1، الترخيص مرفق) للعربية واللاتينية معًا؛ تأجيل Inter لتجنب ملف variable ~0.9MB. ليس خط مصحف | PROPOSED (P00-03 يعتمد) |
| D-15 | معرف التطبيق للتطوير `com.abdulrahmanalsaeed.madaralhuda` (Android وiOS) كمرشح من BRAND.md؛ يبقى O-08 مفتوحًا قبل أول نشر | PROPOSED |
| D-17 | نسخ التطوير تُوزَّع كـ GitHub **prerelease** عامة (الريبو public) بمعرف `…madaralhuda.dev` ومفتاح تطوير ثابت (ليس مفتاح المتجر)، وتتحدث على أجهزة المختبرين عبر Obtainium. لا كود تحديث ولا صلاحيات داخل التطبيق | CONFIRMED (owner choice 2026-11-19) |
| D-16 | تنفيذ P00-06 قبل اعتماد P00-03/P00-05 بقرار المالك: الألوان والأيقونة والمعمارية مؤقتة وقابلة للاستبدال دون كسر الهيكل | CONFIRMED (owner instruction) |

| D-18 | P00-05 engineering baseline: Flutter offline-first + versioned immutable Quran source + private editorial schema + published-only API projection + RLS owner isolation for optional cloud sync; no production Supabase deployment in Phase 0 | CONFIRMED engineering baseline — PR #14 merged; no Supabase deployment |

| D-19 | P00-03 design: open-book orbit mark, source SVG and Android vector+PNG launcher, green/gold/ivory colors, bilingual IBM Plex Sans Arabic UI with OFL-1.1. Not trademark-cleared; production signoff pending. | CREATIVE ASSETS APPROVED — owner 2026-11-22; existing PR #16 unchanged; legal review remains R-10 |

| D-20 | المالك وافق صراحة بتاريخ 2026-11-22 على الشعار الحالي والاسم الحالي دون إعادة تصميم؛ P00-03 تم اعتماده بصريًا، وR-10/O-01/O-08 للعلامة/المتجر تبقى بوابات قانونية مستقلة قبل النشر | CONFIRMED |

| D-21 | مراجعة شرعية شاملة عند اكتمال التطبيق. التنفيذ والفحص الفني والنسخ الخاصة التجريبية تسبق المراجعة. النشر العام يحافظ على إتاحة الأقسام المعتمدة فقط. | CONFIRMED (owner, 2026-11-23) |

## Needs decision / verification
- `O-01` فحص العلامة التجارية واسم المتجر رسميًا فقط؛ الشعار والاسم معتمدان بصريًا (D-20، Issue #19).
- `O-02` حقوق إصدار المصحف وملف hash.
- `O-03` ترخيص كل تسجيل والحدود المسموحة للـ cache/download.
- `O-04` طبعة وحقوق نسخ تفسير الطبري وابن كثير.
- `O-05` اسم مؤهل المراجعة الشرعية ومسار الاعتماد.
- `O-06` مترجم إنجليزي معتمد وحقوق عرض معاني الآيات.
- `O-07` ميزانية تشغيل بعد معرفة استخدام الصوت والسحابة.
- `O-08` Package ID Android قبل النشر.
- `O-09` إصدارات Flutter/Next.js/Supabase تثبّت بعد التحقق من الوثائق التقنية. (Flutter مقترح في D-12؛ Next.js/Supabase لم تُحدد.)

**مرجع ملزم للمصادر:** [../docs/CONTENT_SOURCES.md](../docs/CONTENT_SOURCES.md). كل اختيار تقني مقترح وليس تصريحًا بأن الخدمة جهّزت بالفعل.
