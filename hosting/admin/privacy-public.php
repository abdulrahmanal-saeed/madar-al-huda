<?php
if (!defined('MADAR_ADMIN')) {
    http_response_code(404);
    exit;
}
if (!in_array($_SERVER['REQUEST_METHOD'] ?? '', ['GET', 'HEAD'], true)) {
    header('Allow: GET, HEAD');
    http_response_code(405);
    exit;
}
header('Content-Type: text/html; charset=utf-8');
header('Cache-Control: no-cache');
header("Content-Security-Policy: default-src 'none'; style-src 'self'; script-src 'self'; font-src 'self'; connect-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'");
header('Strict-Transport-Security: max-age=31536000');
if ($_SERVER['REQUEST_METHOD'] === 'HEAD') {
    exit;
}
?><!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>سياسة الخصوصية | Madar Al-Huda Privacy Policy</title>
  <meta name="theme-color" content="#161123">
  <link rel="stylesheet" href="/madar-web/brand.css?v=<?= (int) @filemtime(__DIR__ . '/../madar-web/brand.css') ?>">
  <link rel="stylesheet" href="/admin/privacy.css?v=<?= (int) filemtime(__DIR__ . '/privacy.css') ?>">
  <script src="/admin/privacy.js" defer></script>
</head>
<body>
<header class="mast"><div><strong>مدار الهدى · Madar Al-Huda</strong><nav><a href="#ar">العربية</a> <a href="#en" lang="en">English</a> <a href="#request">التواصل / Contact</a></nav></div></header>
<main>
<section id="ar" lang="ar" dir="rtl">
  <p class="eyebrow">مدار الهدى</p>
  <h1>سياسة الخصوصية</h1>
  <p class="date">آخر تحديث: 25 نوفمبر 2026</p>
  <p>توضح هذه السياسة كيفية التعامل مع البيانات عند استخدام تطبيق مدار الهدى (Madar Al-Huda)، ومعرّف نسخة المتجر <bdi>com.abdulrahmanalsaeed.madaralhuda</bdi>، وموقعه وخدماته المرتبطة. يدير التطبيق مطوّر مدار الهدى. التطبيق مجاني ولا يحتوي على إعلانات تجارية أو أدوات تتبع إعلاني مدمجة، ولا نبيع بياناتك الشخصية.</p>
  <h2>١. البيانات التي نستخدمها ولماذا</h2>
  <ul>
    <li><strong>الحساب الاختياري:</strong> تستطيع استخدام التطبيق دون حساب. إذا اخترت تسجيل الدخول عبر Google، تعالج Google وSupabase بيانات الهوية اللازمة للمصادقة، مثل معرّف الحساب والبريد الإلكتروني وبيانات الملف الشخصي التي يتيحها مزود تسجيل الدخول ورموز الجلسة. لا نطلب كلمة مرور Google. تُستخدم هذه البيانات لإدارة حسابك وجلسة الدخول.</li>
    <li><strong>الموقع:</strong> عند السماح بموقع الجهاز، يُستخدم لحساب مواقيت الصلاة واتجاه القبلة محليًا. يحتفظ التطبيق بآخر موقع مقرب على الجهاز للعمل دون اتصال؛ لا يرسل إحداثيات هذا الموقع إلى خادم مدار الهدى لهذه الحسابات. يمكنك اختيار مدينة يدويًا أو إلغاء إذن الموقع من إعدادات النظام.</li>
    <li><strong>البيانات المحلية:</strong> تُحفظ إعدادات اللغة والمظهر، وموضع القراءة، والمفضلة، وتفضيلات العبادة والتنبيهات والتقدم والملفات المنزلة على جهازك بحسب الميزة. تُحفظ سجلات الأخطاء محليًا، ويمكنك اختيار مشاركتها بنفسك؛ لا تُرسل تلقائيًا إلى خدمة تحليلات.</li>
    <li><strong>البلاغات والاقتراحات:</strong> عند الإرسال، نستقبل نوع البلاغ ونصه ووسيلة التواصل التي تدخلها اختيارًا، ورقم بناء التطبيق، والصورة التي تختار إرفاقها (إن وجدت). تُحفظ البلاغات في لوحة الإدارة الخاصة، وقد يُرسل نصها إلى البريد المخصص للدعم. نستخدم بصمة مجزأة ومملحة لعنوان الاتصال للحد من إساءة الاستخدام. لا نصل إلى معرض الصور كاملًا؛ اختر فقط لقطة خالية من البيانات الحساسة. تُستخدم البلاغات للتواصل وحل المشكلات وتحسين التطبيق.</li>
    <li><strong>طلبات الشبكة:</strong> عند تحميل المكتبة أو التفسير أو التلاوات أو الأحاديث أو القصص أو الإذاعة أو بيانات التحديث، تتلقى الخوادم ومزودو المحتوى معلومات الاتصال المعتادة مثل عنوان IP وتوقيت الطلب والمورد المطلوب، وقد يحتفظون بسجلات تشغيل وأمان وفق سياساتهم.</li>
  </ul>
  <h2>٢. مشاركة البيانات ومزودو الخدمة</h2>
  <p>نستخدم Hostinger لاستضافة الموقع والبلاغات والمحتوى، وSupabase للمصادقة وخدمات الخادم، وGoogle لتسجيل الدخول الاختياري. قد يتصل التطبيق بمزودي المحتوى مثل Quran Foundation وQuranEnc وHadeethEnc ومصادر البث والتسجيلات عند استخدام الميزة. تُستخدم المعلومات اللازمة لتقديم الخدمة وتأمينها، أو للامتثال لالتزام قانوني واجب. لا نشارك البيانات بغرض الإعلانات الموجهة. تخضع الروابط الخارجية أيضًا لسياسات الجهات التي تديرها.</p>
  <h2>٣. الأمان والاحتفاظ والحذف</h2>
  <p>تُنقل الطلبات عبر HTTPS، وتخزن بيانات البلاغات خارج المجلد العام للموقع، ويقتصر الاطلاع عليها على الحسابات المخولة. تبقى البيانات المحلية على الجهاز إلى أن تحذفها أو تمسح بيانات التطبيق. يُحتفظ ببيانات الحساب ما دام الحساب قائمًا، وبالبلاغات وطلبات الدعم ما دامت لازمة لمعالجتها ومتابعتها وحماية الخدمة. يمكن طلب حذفها؛ وقد تبقى نسخ احتياطية أو سجلات محدودة للمدة اللازمة للأمان أو الالتزامات القانونية إلى أن تُستبدل أو تُزال. لا يدّعي التطبيق وجود حذف تلقائي للبلاغات بعد مدة ثابتة.</p>
  <h2>٤. خياراتك وحقوقك</h2>
  <p>يمكنك استخدام وضع الضيف، وإلغاء أذونات الموقع والتنبيهات، وإزالة صورة قبل إرسال البلاغ، ومسح بيانات التطبيق من إعدادات Android. تسجيل الخروج لا يحذف الحساب من الخادم. لطلب الوصول إلى بياناتك أو تصحيحها أو حذف حساب مدار الهدى والبيانات المرتبطة به، استخدم <a href="#request">نموذج طلبات الخصوصية والحذف</a> أدناه. نحتاج إلى التحقق من ملكيتك للحساب قبل تنفيذ الحذف؛ لا ترسل كلمة مرور أو رمز تحقق. حذف حساب مدار الهدى لا يحذف حساب Google نفسه.</p>
  <h2>٥. الأطفال والتغييرات</h2>
  <p>إذا كنت ولي أمر وتعتقد أن طفلًا أرسل بيانات شخصية، تواصل معنا عبر النموذج أدناه لطلب مراجعتها وحذفها عند الاقتضاء. سنحدّث هذه السياسة عند تغيير طريقة معالجة البيانات، مع تعديل تاريخ آخر تحديث.</p>
</section>
<section id="en" lang="en" dir="ltr">
  <p class="eyebrow">Madar Al-Huda</p>
  <h1>Privacy Policy</h1>
  <p class="date">Last updated: November 25, 2026</p>
  <p>This policy explains how Madar Al-Huda (مدار الهدى), store package <strong>com.abdulrahmanalsaeed.madaralhuda</strong>, its website and related services handle data. The service is operated by the developer of Madar Al-Huda. The app is free, contains no commercial ads or integrated advertising trackers, and we do not sell personal data.</p>
  <h2>1. Information we use and why</h2>
  <ul>
    <li><strong>Optional account:</strong> You can use the app without an account. If you choose Google sign-in, Google and Supabase process authentication information such as your account identifier, email, profile information provided by the sign-in provider and session tokens. We do not ask for your Google password. This information is used to manage your account and sign-in session.</li>
    <li><strong>Location:</strong> If you permit device location, it is used to calculate prayer times and Qibla direction locally. The app keeps the last rounded location on your device for offline use; it does not send those coordinates to Madar Al-Huda's server for these calculations. You can select a city manually or revoke location permission in system settings.</li>
    <li><strong>Local data:</strong> Depending on the feature, language, appearance, reading position, favorites, worship and reminder preferences, progress and downloaded files are kept on your device. Error logs are local and may be shared by your choice; they are not automatically submitted to an analytics service.</li>
    <li><strong>Feedback and suggestions:</strong> When you submit feedback, we receive its type, message, any optional contact information you enter, app build number and any image you explicitly attach. Reports are stored in the private admin dashboard and their text may be emailed to the designated support mailbox. A salted hash of the connection address helps prevent abuse. We do not access your entire photo library. Choose screenshots without sensitive information. We use feedback to respond, troubleshoot and improve the app.</li>
    <li><strong>Network requests:</strong> When you fetch the library, tafsir, recitations, hadith, stories, radio streams or update information, servers and content providers receive ordinary connection information such as IP address, request time and requested resource, and may retain operational and security logs under their policies.</li>
  </ul>
  <h2>2. Sharing and service providers</h2>
  <p>We use Hostinger for hosting, reports and content, Supabase for authentication and server services, and Google for optional sign-in. Depending on the feature, the app may contact content providers such as Quran Foundation, QuranEnc, HadeethEnc and streaming or recording sources. Information is used as necessary to provide and secure services, or to meet a binding legal obligation. We do not share data for targeted advertising. External links are also subject to the policies of their operators.</p>
  <h2>3. Security, retention and deletion</h2>
  <p>Requests use HTTPS. Report data is stored outside the public web directory and access is restricted to authorized accounts. Local data stays on your device until you delete it or clear app data. Account data is retained while the account exists; feedback and support requests are retained while needed for handling, follow-up and service protection. You may request deletion. Limited backups or records may remain as necessary for security or legal obligations until rotated or removed. There is no fixed automatic report deletion schedule.</p>
  <h2>4. Your choices and rights</h2>
  <p>You can use guest mode, revoke location and notification permissions, remove an image before submitting feedback, or clear app data in Android settings. Signing out does not delete your server account. To request access, correction, or deletion of your Madar Al-Huda account and associated data, use the <a href="#request">privacy and deletion request form</a> below. We need to verify account ownership before deleting it; never send a password or verification code. Deleting a Madar Al-Huda account does not delete your Google account.</p>
  <h2>5. Children and changes</h2>
  <p>If you are a parent or guardian and believe a child submitted personal information, contact us using the form below to request review and deletion where appropriate. We update this policy when our data handling changes and revise the last-updated date.</p>
</section>
<section id="request" lang="ar" dir="rtl">
  <h2>طلبات الخصوصية وحذف الحساب / <bdi lang="en">Privacy &amp; account deletion</bdi></h2>
  <p>استخدم النموذج للتواصل مع إدارة مدار الهدى أو طلب حذف حسابك والبيانات المرتبطة به. أدخل بريدًا يمكننا التواصل معك عليه، واذكر بريد الحساب عند اختلافه. لا ترسل كلمات مرور أو رموز تحقق.</p>
  <p lang="en" dir="ltr">Use this form to contact the Madar Al-Huda developer or request deletion of your app account and associated data. Provide a contact email and identify the account email if different. Never include passwords or verification codes.</p>
  <form id="privacy-request">
    <label for="request-kind">نوع الطلب / Request type</label>
    <select id="request-kind" required>
      <option value="account deletion">حذف الحساب والبيانات / Delete account and data</option>
      <option value="data deletion">حذف بيانات محددة / Delete specific data</option>
      <option value="privacy inquiry">استفسار أو تصحيح بيانات / Privacy inquiry or correction</option>
    </select>
    <label for="request-email">بريد التواصل / Contact email</label>
    <input id="request-email" type="email" dir="ltr" required maxlength="200" autocomplete="email">
    <label for="request-message">التفاصيل / Details</label>
    <textarea id="request-message" rows="5" maxlength="2800" required></textarea>
    <button type="submit" disabled>إرسال الطلب / Submit request</button>
    <p id="request-status" role="status" aria-live="polite"></p>
    <noscript>فعّل JavaScript لإرسال الطلب أو استخدم «أبلغ عن مشكلة أو اقترح» داخل التطبيق. Enable JavaScript or use the in-app feedback form.</noscript>
  </form>
</section>
</main>
<footer>مدار الهدى · Madar Al-Huda</footer>
</body>
</html>
<?php exit;
