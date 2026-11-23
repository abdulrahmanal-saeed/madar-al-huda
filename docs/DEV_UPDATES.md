# تحديث نسخ التطوير تلقائيًا | Automatic dev-build updates (P00-11)

بدل ما تنزّل APK جديد كل مرة: كل تغيير يتدمج في `main` ويعدّي الـ CI بيتبني منه APK موقّع بمفتاح تطوير ثابت، وبيتنشر كـ **pre-release** على GitHub Releases. تطبيق **Obtainium** على موبايلك بيلاقي النسخة الجديدة ويثبّتها لوحده.

> قناة التطوير مستقلة ومعرّفها `com.abdulrahmanalsaeed.madaralhuda.dev`، وتوقيع Google Play له المهمة P06-01. تفتح قناة Dev المصحف والورد والصلاة والقبلة والأذكار والمكتبة المنشورة. يختبر Mobile CI الشاشات بإعدادات Dev الموقّعة.

## 1. إعداد لمرة واحدة: secrets في GitHub (لصاحب الريبو)

GitHub ← الريبو ← **Settings ← Secrets and variables ← Actions ← New repository secret**، وضيف التلاتة دول (القيم في ملف المفتاح اللي اتسلّم لك بشكل خاص، **ممنوع يتحط في الريبو**):

| Secret | القيمة |
|---|---|
| `MADAR_DEV_KEY_ALIAS` | `madar-dev` |
| `MADAR_DEV_KEYSTORE_PASSWORD` | كلمة السر من ملف المفتاح |
| `MADAR_DEV_KEYSTORE_BASE64` | السطر الطويل (base64) من ملف المفتاح |

احتفظ بنسخة احتياطية خاصة من ملف المفتاح. لو ضاع، النسخ الجديدة مش هتعرف تتثبّت فوق القديمة، وهتضطر تمسح تطبيق التطوير وتعمل مفتاح جديد.

## 2. إعداد لمرة واحدة على الموبايل: Obtainium

1. نزّل **Obtainium** من الموقع الرسمي (https://obtainium.imranr.dev) أو من F-Droid / IzzyOnDroid.
2. **Add App** ← في خانة الرابط حط:
   `https://github.com/abdulrahmanal-saeed/madar-al-huda`
3. فعّل **Include prereleases**.
4. في **Filter release titles by regular expression** اكتب: `^Dev build`
5. **Add** ← **Install**. أندرويد هيطلب إذن "تثبيت تطبيقات غير معروفة" لـ Obtainium مرة واحدة.
6. اختياري: في إعدادات Obtainium فعّل التحقق من التحديثات في الخلفية. على أندرويد 12 وأحدث ممكن التحديث يتثبّت من غير ما تضغط حاجة، للتطبيقات اللي Obtainium هو اللي ثبّتها.

لو عندك نسخة debug قديمة نزّلتها من artifacts الـ CI، امسحها. نسخة التطوير تطبيق منفصل بمعرّف مختلف.

## 3. إمتى بتطلع نسخة جديدة؟

- تلقائيًا بعد كل push على `main` (يعني بعد دمج PR) **لو** workflow ‏`Mobile CI` نجح على نفس الـ commit.
- أو يدويًا: Actions ← **Dev release** ← **Run workflow**. ده بيشتغل بس بعد ما الملف `dev-release.yml` يكون على `main`.
- اسم الإصدار `v0.1.0-dev.N`، ونفس الرقم بيظهر كـ versionName جوه التطبيق.
- بنحتفظ بآخر 10 نسخ تطوير بس، والأقدم بيتمسح تلقائيًا. إصدارات المتجر (`vX.Y.Z`) عمرها ما بتتمسح.

---

## English summary

- **Workflow:** `.github/workflows/dev-release.yml`. It runs only after `Mobile CI` succeeds for a push to `main` (or on manual dispatch), builds `flutter build apk --release` with `MADAR_CHANNEL=dev`, verifies the package ID, version and signature, and publishes the APK as a GitHub prerelease tagged `v<version>-dev.<run>`. It keeps the newest 10 dev releases. It repeats no CI checks.
- **Gradle** (`android/app/build.gradle.kts`): channel, version suffix and signing all come from environment variables. A dev build without signing variables **fails** rather than shipping an unrecognisable signature. Local and CI debug builds are unchanged.
- **Secrets:** `MADAR_DEV_KEYSTORE_BASE64`, `MADAR_DEV_KEYSTORE_PASSWORD`, `MADAR_DEV_KEY_ALIAS`. The keystore is decoded to `$RUNNER_TEMP` and deleted at the end of the job.
- **Updates:** Obtainium checks GitHub Releases. Android users can also enable periodic update notices in the app or check for updates in Settings.
- **Testers:** install Obtainium, add the repository URL, enable *Include prereleases*, and filter titles with `^Dev build`.
