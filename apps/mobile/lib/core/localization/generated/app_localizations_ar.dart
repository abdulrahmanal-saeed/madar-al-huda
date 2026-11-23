// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get adhkarHubTitle => 'الأذكار والأدعية';

  @override
  String get adhkarToday => 'أذكار اليوم';

  @override
  String get adhkarResume => 'استكمل من مكانك';

  @override
  String get adhkarFind => 'بحث في الأذكار والأدعية';

  @override
  String adhkarPosition(String current, String total) {
    return '$current من $total';
  }

  @override
  String adhkarVariant(String counts) {
    return 'الرواية · $counts';
  }

  @override
  String get adhkarPrevious => 'السابق';

  @override
  String get adhkarNext => 'التالي';

  @override
  String get adhkarCompleted => 'تمّت';

  @override
  String get adhkarMarkRead => 'سجّل القراءة';

  @override
  String get adhkarReset => 'إعادة العدّاد';

  @override
  String get adhkarReturnToToday => 'العودة إلى الأذكار';

  @override
  String get adhkarCountOnce => 'سجّل تكرارًا';

  @override
  String get adhkarThreeSurahCycle => 'سجّل قراءة السور الثلاث';

  @override
  String get adhkarBedtimeCycle => 'سجّل دورة القراءة والمسح';

  @override
  String get adhkarTasbih => 'سجّل تسبيحة';

  @override
  String get adhkarTahmid => 'سجّل تحميدة';

  @override
  String get adhkarTakbir => 'سجّل تكبيرة';

  @override
  String get adhkarTahlil => 'سجّل التهليل الختامي';

  @override
  String get adhkarIstighfar => 'سجّل استغفارة';

  @override
  String get adhkarSavedProgress => 'تقدّمك محفوظ على الجهاز';

  @override
  String adhkarWirdToday(String day) {
    return 'ورد اليوم · $day';
  }

  @override
  String get adhkarWirdGroups => 'اختَر مجموعات وردك';

  @override
  String get adhkarAddToWird => 'أضف إلى وردي';

  @override
  String get adhkarRemoveFromWird => 'أزل من وردي';

  @override
  String get adhkarHisnSubtitle => 'أذكار وأدعية حسب الموقف';

  @override
  String get adhkarNothingFound => 'لا توجد نتائج مطابقة';

  @override
  String get adhkarAddFavorite => 'أضف إلى المفضلة';

  @override
  String get adhkarRemoveFavorite => 'أزل من المفضلة';

  @override
  String adhkarHadithNumber(String number) {
    return 'حديث $number';
  }

  @override
  String get adhkarMerit => 'الفضل الوارد';

  @override
  String get adhkarDraftMeaning => 'معنى إنجليزي أولي';

  @override
  String get adhkarHadithSource => 'اقرأ الحديث ومصدره';

  @override
  String get adhkarRetrySource => 'أعد تحميل المصدر';

  @override
  String get adhkarBukhari6324 => 'صحيح البخاري ٦٣٢٤';

  @override
  String get adhkarUsePeriodWording => 'اقرأ صيغة هذا الوقت من الحديث أدناه.';

  @override
  String get appTitle => 'مدار الهدى';

  @override
  String get appTagline => 'القرآن والعلم والعبادة في مكان واحد';

  @override
  String get appDedication => 'صدقة جارية على روح أبي';

  @override
  String get splashContinue => 'الدخول إلى التطبيق';

  @override
  String get navHome => 'اليوم';

  @override
  String get navQuran => 'المصحف';

  @override
  String get navWorship => 'العبادات';

  @override
  String get navLibrary => 'المكتبة';

  @override
  String get navLearning => 'التعلّم';

  @override
  String get openSettings => 'الإعدادات';

  @override
  String get homeGreeting => 'السلام عليكم';

  @override
  String get homeTodayLabel => 'اليوم';

  @override
  String get homeQuickAccess => 'وصول سريع';

  @override
  String get homePreviewTitle => 'نسخة تطويرية أولية';

  @override
  String get homePreviewBody =>
      'لا يظهر المحتوى الديني إلا بعد التحقق من مصدره وترخيصه واستكمال المراجعة الشرعية اللازمة. الأقسام التي لم يُعتمد محتواها بعدُ موضّحة بعلامة واضحة.';

  @override
  String get homePromiseTitle => 'مجاني، خاص، بلا إعلانات';

  @override
  String get homePromiseBody =>
      'لا إعلانات ولا اشتراكات ولا حاجة إلى حساب. تبقى تفضيلاتك على هذا الجهاز.';

  @override
  String get quranHubIntro => 'اقرأ واستمع وتدبّر.';

  @override
  String get worshipHubIntro => 'رفيقك في عباداتك اليومية.';

  @override
  String get libraryHubIntro => 'علم شرعي واضح المصادر.';

  @override
  String get learningHubIntro => 'تعلّم خطوة بخطوة.';

  @override
  String get sectionMushafTitle => 'قراءة القرآن';

  @override
  String get sectionMushafSubtitle =>
      'فهرس السور والبحث والعلامات وآخر موضع قراءة';

  @override
  String get sectionRecitationsTitle => 'التلاوات';

  @override
  String get sectionRecitationsSubtitle => 'استمع إلى تلاوات قرّاء مختارين';

  @override
  String get sectionTafsirTitle => 'التفسير';

  @override
  String get sectionTafsirSubtitle => 'الطبري وابن كثير';

  @override
  String get sectionPrayerTimesTitle => 'مواقيت الصلاة';

  @override
  String get sectionPrayerTimesSubtitle => 'حسب موقعك أو مدينة تختارها';

  @override
  String get sectionQiblaTitle => 'القبلة';

  @override
  String get sectionQiblaSubtitle => 'اتجاه الكعبة المشرّفة من مكانك';

  @override
  String get sectionAdhkarTitle => 'الأذكار والأدعية';

  @override
  String get sectionAdhkarSubtitle => 'أذكار الصباح والمساء واليوم والليلة';

  @override
  String get sectionHadithTitle => 'الحديث';

  @override
  String get sectionHadithSubtitle => 'أحاديث بمصادرها ودرجاتها';

  @override
  String get sectionFiqhTitle => 'الفقه المقارن';

  @override
  String get sectionFiqhSubtitle =>
      'أقوال الحنفية والمالكية والشافعية والحنابلة';

  @override
  String get sectionArticlesTitle => 'المقالات';

  @override
  String get sectionArticlesSubtitle => 'مقالات مراجَعة بالعربية والإنجليزية';

  @override
  String get sectionLessonsTitle => 'الدروس والاختبارات';

  @override
  String get sectionLessonsSubtitle =>
      'مسارات متدرجة في الفقه والعقيدة والسيرة';

  @override
  String get sectionStoriesTitle => 'قصص الأنبياء';

  @override
  String get sectionStoriesSubtitle => 'من القرآن والسنة مع ذكر المصادر';

  @override
  String learningEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حلقة',
      few: '$count حلقات',
      two: 'حلقتان',
      one: 'حلقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String learningEpisodeNumber(int number) {
    return 'الحلقة $number';
  }

  @override
  String get learningNoEpisodes => 'هتظهر الحلقات هنا عند إضافتها.';

  @override
  String get learningFormatAudio => 'صوت';

  @override
  String get learningFormatVideo => 'فيديو';

  @override
  String get learningPlaySeries => 'تشغيل القائمة';

  @override
  String get learningDownload => 'تنزيل الحلقة';

  @override
  String get learningDownloaded => 'متاحة دون إنترنت';

  @override
  String get learningRemoveDownload => 'حذف التنزيل';

  @override
  String get learningMediaUnavailable => 'وسائط الحلقات غير متاحة حاليًا.';

  @override
  String get learningPlaybackFailed => 'تعذّر تشغيل الحلقة.';

  @override
  String get learningDownloadFailed => 'تعذّر حفظ التنزيل أو حذفه.';

  @override
  String get learningRetry => 'أعد المحاولة';

  @override
  String get learningPreviousEpisode => 'الحلقة السابقة';

  @override
  String get learningNextEpisode => 'الحلقة التالية';

  @override
  String get statusAwaitingSourceTitle => 'بانتظار التحقق من المصدر';

  @override
  String get statusAwaitingSourceBody =>
      'لن يعرض هذا القسم أي محتوى إلا بعد التحقق من طبعة المصدر وحقوق استخدامه.';

  @override
  String get statusAwaitingAudioTitle => 'بانتظار حقوق التلاوات';

  @override
  String get statusAwaitingAudioBody =>
      'ستتاح التلاوات بعد تأكيد إذن البث لكل قارئ.';

  @override
  String get statusAwaitingScholarlyTitle => 'بانتظار المراجعة الشرعية';

  @override
  String get statusAwaitingScholarlyBody =>
      'لا يُنشر هذا المحتوى إلا بعد مراجعته واعتماده من مختص شرعي مؤهل.';

  @override
  String get statusAwaitingEditorialTitle => 'بانتظار المراجعة التحريرية';

  @override
  String get statusAwaitingEditorialBody =>
      'لا تُنشر المقالات والدروس إلا بعد مراجعة مصادرها ونصوصها.';

  @override
  String get statusAwaitingValidationTitle => 'الحساب قيد التحقق';

  @override
  String get statusAwaitingValidationBody =>
      'ستظهر المواقيت بعد التحقق من دقة الحساب مقارنةً بالمراجع الرسمية في الإمارات ومصر.';

  @override
  String get statusInDevelopmentTitle => 'قيد التطوير';

  @override
  String get statusInDevelopmentBody =>
      'هذه الميزة قيد البناء وستتاح في إصدار قادم.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get languageSystem => 'لغة الجهاز';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get settingsReduceMotion => 'تقليل الحركة';

  @override
  String get settingsReduceMotionSubtitle =>
      'تقليل الرسوم المتحركة وانتقالات الشاشات';

  @override
  String get settingsAccount => 'الحساب';

  @override
  String get settingsGuestMode => 'وضع الضيف';

  @override
  String get settingsGuestModeBody =>
      'لا حاجة إلى حساب. تُحفظ تفضيلاتك على هذا الجهاز فقط.';

  @override
  String get settingsGoogleSignIn => 'تسجيل الدخول باستخدام Google';

  @override
  String get settingsGoogleAccount => 'حساب Google';

  @override
  String get settingsGoogleSignOut => 'تسجيل الخروج';

  @override
  String get settingsGoogleSignInError =>
      'تعذّر تسجيل الدخول باستخدام Google. حاول مرة أخرى.';

  @override
  String get settingsGoogleSignOutError => 'تعذّر تسجيل الخروج. حاول مرة أخرى.';

  @override
  String get settingsAbout => 'عن التطبيق';

  @override
  String get settingsAboutBody => 'مجاني دائمًا، بلا إعلانات ولا اشتراكات.';

  @override
  String get settingsLicenses => 'تراخيص البرمجيات مفتوحة المصدر';

  @override
  String get settingsSaveError => 'تعذّر حفظ التفضيل. حاول مرة أخرى.';

  @override
  String get notFoundTitle => 'الصفحة غير موجودة';

  @override
  String get notFoundBody => 'الصفحة التي تبحث عنها غير موجودة.';

  @override
  String get notFoundAction => 'العودة إلى الرئيسية';

  @override
  String get cityDubai => 'دبي';

  @override
  String get cityAbuDhabi => 'أبوظبي';

  @override
  String get cityCairo => 'القاهرة';

  @override
  String get cityAlexandria => 'الإسكندرية';

  @override
  String get chooseCity => 'اختر مدينة';

  @override
  String get startupLocationTitle => 'إعداد الموقع';

  @override
  String get startupLocationExplanation =>
      'استخدم موقعك لحساب مواقيت الصلاة وتحديد القبلة. يمكنك أيضًا اختيار مدينة من شاشة الصلاة أو القبلة.';

  @override
  String get startupLocationLater => 'لاحقًا';

  @override
  String get useLocation => 'استخدم موقعي';

  @override
  String get deviceLocation => 'موقع الجهاز';

  @override
  String get locationDenied => 'تم رفض إذن الموقع. يمكنك اختيار مدينة.';

  @override
  String get locationUnavailable =>
      'تعذّر تحديد الموقع. تحقق من خدمة الموقع أو اختر مدينة.';

  @override
  String get locationOutside =>
      'موقع الجهاز مدعوم داخل مصر والإمارات. اختر مدينة للمتابعة.';

  @override
  String get locationLoading => 'جارٍ تحديد موقعك…';

  @override
  String get localSaveFailed => 'تعذّر الحفظ على هذا الجهاز.';

  @override
  String get prayerPreview =>
      'مواقيت محسوبة للاختبار خلال التحقق من المراجع المحلية.';

  @override
  String get prayerEgyptMethod => 'طريقة الحساب · مصر';

  @override
  String get prayerDubaiMethod => 'طريقة الحساب · دبي';

  @override
  String get hanafiAsr => 'حساب العصر';

  @override
  String get asrHanafi => 'حنفي';

  @override
  String get asrStandard => 'قياسي';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String trueBearing(String degrees) {
    return '$degrees° من الشمال الجغرافي';
  }

  @override
  String get cityBearingApproximate => 'اتجاه تقريبي من مركز المدينة المختارة.';

  @override
  String get compassHoldFlat => 'أمسك الهاتف أفقيًا وأبعده عن المعادن.';

  @override
  String get compassCalibrate =>
      'قراءة البوصلة ضعيفة. حرّك الهاتف على شكل رقم ثمانية بعيدًا عن المعادن.';

  @override
  String get compassWaiting => 'في انتظار قراءة البوصلة…';

  @override
  String get compassUnavailable => 'قراءة البوصلة المباشرة غير متاحة.';

  @override
  String get readerSurahs => 'السور';

  @override
  String get readerGoToVerse => 'انتقل إلى آية';

  @override
  String get readerVerseNumber => 'رقم الآية';

  @override
  String readerVerseInvalid(int count) {
    return 'أدخل رقم آية من ١ إلى $count.';
  }

  @override
  String get readerGo => 'انتقل';

  @override
  String get readerCancel => 'إلغاء';

  @override
  String get readerTafsir => 'التفسير';

  @override
  String readerTafsirFor(int verse) {
    return 'التفسير · الآية $verse';
  }

  @override
  String get readerReciter => 'القارئ';

  @override
  String get readerTanzil => 'نص القرآن من مشروع تنزيل';

  @override
  String get readerQuranFoundation => 'مؤسسة القرآن';

  @override
  String get readerRetry => 'إعادة المحاولة';

  @override
  String get readerLoadFailed => 'تعذّر تحميل نص القرآن.';

  @override
  String get readerResourcesUnavailable =>
      'التفسير والتلاوات غير متاحين حاليًا.';

  @override
  String get readerTafsirUnavailable => 'التفسير غير متاح لهذه الآية.';

  @override
  String get readerAudioUnavailable => 'تعذّر تحميل هذه التلاوة.';

  @override
  String get readerPlay => 'تشغيل السورة';

  @override
  String get readerPause => 'إيقاف التلاوة مؤقتًا';

  @override
  String get readerResume => 'استئناف التلاوة';

  @override
  String get readerStop => 'إيقاف التلاوة';

  @override
  String get readerTafsirLoading => 'جارٍ تحميل التفسير…';

  @override
  String get readerPreliveCoverage =>
      'التفسير والتلاوة متاحان حاليًا للفاتحة والبقرة في نسخة الاختبار.';

  @override
  String get readerIndex => 'فهرس المصحف';

  @override
  String get readerJuzs => 'الأجزاء';

  @override
  String get readerHizbs => 'الأحزاب';

  @override
  String get readerPages => 'الصفحات';

  @override
  String get readerBookmarks => 'العلامات المرجعية';

  @override
  String get readerSearch => 'بحث';

  @override
  String get readerSearchHint =>
      'ابحث في النص أو باسم السورة أو برقم مثل ٢:٢٥٥';

  @override
  String get readerNoResults => 'مفيش آيات مطابقة';

  @override
  String get readerNoBookmarks => 'لا توجد علامات مرجعية';

  @override
  String get readerPageActions => 'اختر آية للتفسير أو لحفظ علامة';

  @override
  String get readerAddBookmark => 'أضف علامة مرجعية';

  @override
  String get readerRemoveBookmark => 'احذف العلامة المرجعية';

  @override
  String readerJuzLabel(String number) {
    return 'الجزء $number';
  }

  @override
  String readerHizbLabel(String number) {
    return 'الحزب $number';
  }

  @override
  String readerPageLabel(String number) {
    return 'صفحة $number';
  }

  @override
  String get duaTitle => 'أدعية من القرآن';

  @override
  String get duaOpenVerse => 'افتح في المصحف';

  @override
  String get duaTranslationUnavailable => 'المعنى الإنجليزي غير متاح مؤقتًا.';

  @override
  String get duaTopics => 'كل الموضوعات';

  @override
  String get duaTopicForgiveness => 'المغفرة والرحمة';

  @override
  String get duaTopicGuidance => 'الهداية والعلم';

  @override
  String get duaTopicFamily => 'الأهل والمجتمع';

  @override
  String get duaTopicHardship => 'الصبر والفرج';

  @override
  String get duaTopicGratitude => 'الشكر والرزق';

  @override
  String get duaTopicWorship => 'العبادة والعمل الصالح';

  @override
  String get duaTopicHereafter => 'الآخرة';

  @override
  String get duaTopicProtection => 'الاستعاذة والحفظ';

  @override
  String get duaTranslationSource =>
      'المعنى بالإنجليزية · مركز روّاد الترجمة عبر QuranEnc';

  @override
  String get radioTitle => 'إذاعة القرآن الكريم من القاهرة';

  @override
  String get radioOpen => 'افتح مشغّل البث الرسمي داخل التطبيق';

  @override
  String get radioOpenFailed => 'تعذّر فتح موقع الإذاعة الرسمي.';

  @override
  String get readerEnglishMeaning => 'المعنى بالإنجليزية';

  @override
  String get hadithSearchTopics => 'ابحث في موضوعات الحديث';

  @override
  String get hadithNoTopics => 'لا توجد موضوعات مطابقة';

  @override
  String get hadithPrevious => 'الصفحة السابقة';

  @override
  String get hadithNext => 'الصفحة التالية';

  @override
  String hadithProviderGrade(String grade) {
    return 'الدرجة من موسوعة الحديث · $grade';
  }

  @override
  String get hadithUnavailable => 'محتوى الحديث غير متاح مؤقتًا.';

  @override
  String get duaSearch => 'ابحث بنص الآية أو اسم السورة أو رقمها';

  @override
  String get duaShowSaved => 'عرض الأدعية المحفوظة';

  @override
  String get duaShowAll => 'عرض كل الأدعية';

  @override
  String get duaNoResults => 'لا توجد أدعية مطابقة';

  @override
  String get duaQuranCom => 'المزيد من الموضوعات على Quran.com';

  @override
  String get radioOpenInBrowser => 'افتح المتصفح';

  @override
  String get dailyReadingTitle => 'الورد اليومي';

  @override
  String get dailyReadingEdit => 'تعديل الورد';

  @override
  String get dailyReadingPaceLabel => 'عدد الصفحات في الورد';

  @override
  String get dailyReadingPaceRange => 'أدخل عددًا من ١ إلى ٦٠٤.';

  @override
  String get dailyReadingSave => 'حفظ الورد';

  @override
  String dailyReadingProgress(String read, String total) {
    return 'الصفحات المقروءة: $read من $total';
  }

  @override
  String dailyReadingRange(String start, String end) {
    return 'اقرأ من الصفحة $start إلى $end';
  }

  @override
  String dailyReadingRemaining(String count) {
    return 'الأوراد المتبقية: $count';
  }

  @override
  String get dailyReadingCompleted => 'أكملت هذه الختمة.';

  @override
  String get dailyReadingRestart => 'ابدأ ختمة جديدة';

  @override
  String get dailyReadingOpen => 'افتح في المصحف';

  @override
  String get dailyReadingMarkRead => 'سجّل قراءة الورد';

  @override
  String get navAdhkar => 'الأذكار';

  @override
  String get navPrayer => 'الصلاة';

  @override
  String get prayerCalculationMethod => 'طريقة الحساب';

  @override
  String get prayerAsrCalculation => 'حساب العصر';

  @override
  String prayerMinutesLeft(String minutes) {
    return 'بعد $minutes د';
  }

  @override
  String prayerHoursLeft(String hours, String minutes) {
    return 'بعد $hours س $minutes د';
  }

  @override
  String get compassAligned => 'أنت باتجاه القبلة';

  @override
  String compassTurnRight(String angle) {
    return 'لِف لليمين · $angle°';
  }

  @override
  String compassTurnLeft(String angle) {
    return 'لِف لليسار · $angle°';
  }

  @override
  String compassPhoneHeading(String angle) {
    return 'اتجاه الهاتف $angle°';
  }

  @override
  String get readerLastPosition => 'آخر موضع قراءة';

  @override
  String readerPosition(String surah, String verse, String page) {
    return '$surah · الآية $verse · ص $page';
  }

  @override
  String readerPageMeta(String juz, String hizb, String page, String total) {
    return '$juz · $hizb · $page من $total';
  }

  @override
  String get readerPageInput => 'رقم الصفحة (١–٦٠٤)';

  @override
  String get readerPageInvalid => 'أدخل رقم صفحة من ١ إلى ٦٠٤.';

  @override
  String get readerIndexScroll => 'صفحات المصحف متصلة رأسيًا.';

  @override
  String readerIndexVerseCount(String count) {
    return '$count آية';
  }

  @override
  String get readerCopy => 'نسخ الآية';

  @override
  String get readerCopied => 'تم نسخ الآية';

  @override
  String get readerShare => 'مشاركة الآية';

  @override
  String get readerShareFailed => 'تعذّرت مشاركة الآية.';

  @override
  String get readerListenChapter => 'استمع للسورة';

  @override
  String get readerListenFromVerse => 'استمع من هنا';

  @override
  String get readerVerseAudioUnavailable =>
      'التوقيت غير متاح لهذه الآية في هذه التلاوة.';

  @override
  String get readerSources => 'مصادر القراءة';

  @override
  String get homeContinueReading => 'استكمل القراءة';

  @override
  String homeOpenPage(String number) {
    return 'افتح الصفحة $number';
  }

  @override
  String get homeReadQuran => 'افتح المصحف';

  @override
  String get homeDuaOfDay => 'دعاء اليوم';

  @override
  String get homeMorning => 'أذكار الصباح';

  @override
  String get homeWird => 'الورد';

  @override
  String get homeOpenPrayer => 'حدّد موقعك للصلاة';

  @override
  String get radioLive => 'مباشر';

  @override
  String get radioCairo => 'من القاهرة · بث مباشر';

  @override
  String get hadithGradeTitle => 'الدرجة';

  @override
  String get hadithSourceTitle => 'المصدر';

  @override
  String get hadithExplanationTitle => 'الشرح';

  @override
  String get hadithAddFavorite => 'أضف إلى المفضلة';

  @override
  String get hadithRemoveFavorite => 'إزالة من المفضلة';

  @override
  String get hadithFavoritesTitle => 'الأحاديث المفضلة';

  @override
  String get hadithNoFavorites => 'مفيش أحاديث في المفضلة لسه.';

  @override
  String get libraryAcademy => 'الأكاديمية';

  @override
  String get libraryStories => 'قصص الأنبياء';

  @override
  String get libraryMore => 'الكل';

  @override
  String get dailyReadingCurrentPlan => 'الختمة الحالية';

  @override
  String dailyReadingNextPage(String page) {
    return 'افتح الصفحة التالية · $page';
  }

  @override
  String get dailyReadingTodaysWird => 'ورد اليوم';

  @override
  String get decreaseReadingPace => 'تقليل عدد الصفحات';

  @override
  String get increaseReadingPace => 'زيادة عدد الصفحات';

  @override
  String get homeApproximateHijriDate => 'التاريخ الهجري الحسابي التقريبي';

  @override
  String get radioPlay => 'شغّل البث المباشر';

  @override
  String get radioStop => 'أوقف البث المباشر';

  @override
  String get radioConnecting => 'جاري الاتصال بالبث المباشر…';

  @override
  String get radioStreamFailed =>
      'تعذّر تشغيل البث. جرّب تاني أو افتح المشغّل الرسمي.';

  @override
  String compassApproximateHeading(String angle) {
    return 'اتجاه الهاتف التقريبي $angle°';
  }

  @override
  String get recitationDownload => 'نزّل التلاوة';

  @override
  String get recitationDownloadMushaf => 'تنزيل المصحف كاملًا';

  @override
  String get recitationDownloadAvailable => 'تنزيل كل السور المتاحة';

  @override
  String recitationDownloadSurahs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'تنزيل السور ($countString)';
  }

  @override
  String get recitationDownloading => 'جاري تنزيل التلاوة';

  @override
  String get recitationDownloads => 'التلاوات المحمّلة';

  @override
  String get recitationNoDownloads => 'نزّل تلاوة سورة عشان تسمعها من غير نت.';

  @override
  String get recitationPlayOffline => 'شغّل التلاوة المحمّلة';

  @override
  String get recitationRemoveDownload => 'احذف التلاوة المحمّلة';

  @override
  String get recitationDownloadFailed =>
      'تعذّر حفظ التلاوة أو الوصول للملف المحمّل.';

  @override
  String get contentLoadFailed =>
      'تعذّر التحقق من وجود محتوى جديد. تحقّق من اتصالك بالإنترنت ثم أعد المحاولة.';

  @override
  String get contentRetry => 'إعادة المحاولة';
}
