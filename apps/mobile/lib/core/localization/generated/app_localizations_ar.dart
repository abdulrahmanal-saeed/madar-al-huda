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

  @override
  String get homeNowLabel => 'الآن';

  @override
  String get homeNowMorning => 'بعد الفجر · وقت أذكار الصباح';

  @override
  String get homeNowAfterPrayer => 'بعد الصلاة مباشرة';

  @override
  String get homeNowEvening => 'بعد العصر · وقت أذكار المساء';

  @override
  String get homeNowBedtime => 'قبل النوم';

  @override
  String get homeNowStart => 'ابدأ';

  @override
  String get homeNowContinue => 'أكمل';

  @override
  String get remindersTitle => 'التذكيرات';

  @override
  String get remindersSettingsSubtitle => 'الصلاة والأذكار والأدعية';

  @override
  String get remindersIntro =>
      'تُحسب التذكيرات على جهازك من مواقيت صلاتك، وتعمل دون اتصال بالإنترنت.';

  @override
  String get remindersPrayerSection => 'الصلاة';

  @override
  String get remindersAdhan => 'عند دخول وقت الصلاة';

  @override
  String get remindersAdhanSubtitle => 'الصلوات الخمس';

  @override
  String get remindersBeforePrayer => 'قبل الصلاة';

  @override
  String remindersBeforePrayerSubtitle(String minutes) {
    return 'قبلها بـ $minutes دقيقة';
  }

  @override
  String get remindersAdhkarSection => 'الأذكار';

  @override
  String get remindersMorning => 'أذكار الصباح';

  @override
  String get remindersMorningSubtitle => 'بعد الفجر بـ ٣٠ دقيقة';

  @override
  String get remindersEvening => 'أذكار المساء';

  @override
  String get remindersEveningSubtitle => 'بعد العصر بـ ١٥ دقيقة';

  @override
  String get remindersAfterPrayer => 'أذكار بعد الصلاة';

  @override
  String get remindersAfterPrayerSubtitle => 'بعد كل صلاة بـ ١٠ دقائق';

  @override
  String get remindersBedtime => 'أذكار النوم';

  @override
  String remindersBedtimeSubtitle(String time) {
    return 'الساعة $time';
  }

  @override
  String get remindersBedtimeChange => 'غيّر موعد النوم';

  @override
  String get remindersKahf => 'سورة الكهف';

  @override
  String remindersKahfSubtitle(String time) {
    return 'يوم الجمعة الساعة $time';
  }

  @override
  String get remindersDuaSection => 'الدعاء';

  @override
  String get remindersDailyDua => 'دعاء اليوم';

  @override
  String remindersDailyDuaSubtitle(String time) {
    return 'كل يوم الساعة $time';
  }

  @override
  String get remindersDuaEvery => 'دعاء كل';

  @override
  String get remindersDuaOff => 'إيقاف';

  @override
  String remindersDuaHours(String hours) {
    return '$hours ساعات';
  }

  @override
  String remindersQuietHours(String start, String end) {
    return 'لا تذكير بالدعاء من $start إلى $end.';
  }

  @override
  String get remindersPermissionDenied =>
      'الإشعارات متوقفة لتطبيق مدار الهدى. فعّلها من إعدادات Android.';

  @override
  String get remindersExactAlarm =>
      'لتصل التذكيرات في موعدها، اسمح بـ «المنبّهات والتذكيرات».';

  @override
  String get remindersExactAlarmAllow => 'السماح';

  @override
  String get remindersNeedsLocation =>
      'اختر موقعك أولًا حتى تُحسب مواقيت الصلاة.';

  @override
  String reminderAdhanTitle(String prayer) {
    return 'حان الآن وقت صلاة $prayer';
  }

  @override
  String get reminderPrayerBody => 'اضغط لعرض مواقيت اليوم.';

  @override
  String reminderBeforeTitle(String prayer, String minutes) {
    return 'باقي $minutes دقيقة على صلاة $prayer';
  }

  @override
  String reminderAfterTitle(String prayer) {
    return 'أذكار بعد صلاة $prayer';
  }

  @override
  String get reminderAfterBody => 'خذ دقيقة لأذكار ما بعد الصلاة.';

  @override
  String get reminderAdhkarBody => 'اضغط لفتح الأذكار.';

  @override
  String get reminderKahfTitle => 'الجمعة: سورة الكهف';

  @override
  String get reminderKahfBody => 'تذكير بقراءة سورة الكهف اليوم.';

  @override
  String get reminderDuaTitle => 'دعاء';

  @override
  String get downloadsTitle => 'مركز التحميل';

  @override
  String get downloadsSettingsSubtitle => 'استخدم التطبيق دون اتصال بالإنترنت';

  @override
  String get downloadsOnDevice => 'على جهازك';

  @override
  String downloadsUsed(String size) {
    return 'المساحة المستخدمة للتحميلات: $size';
  }

  @override
  String get downloadsAlwaysOffline => 'متاح دائمًا دون اتصال';

  @override
  String get downloadsRecitations => 'التلاوات';

  @override
  String get downloadsNoReciters => 'لا توجد تلاوة متاحة للتحميل بعد.';

  @override
  String downloadsReciterProgress(String saved, String total) {
    return '$saved من $total سورة محفوظة';
  }

  @override
  String get downloadsAll => 'تحميل الكل';

  @override
  String get downloadsRemoveAll => 'حذف التحميلات';

  @override
  String downloadsRemoveConfirm(String name) {
    return 'هل تريد حذف الملفات المحمّلة لـ $name؟ يمكنك تحميلها مرة أخرى لاحقًا.';
  }

  @override
  String get downloadsCancel => 'إلغاء';

  @override
  String get downloadsConfirmRemove => 'حذف';

  @override
  String get downloadsStories => 'القصص والدروس';

  @override
  String downloadsEpisodeProgress(String saved, String total) {
    return '$saved من $total حلقة صوتية محفوظة';
  }

  @override
  String get downloadsLibrary => 'نصوص المكتبة';

  @override
  String get downloadsLibraryBody => 'الأذكار والأدعية والمقالات والدروس';

  @override
  String get downloadsLibrarySaved => 'محفوظة على هذا الجهاز';

  @override
  String get downloadsLibraryMissing => 'لم تُحفظ بعد';

  @override
  String get downloadsUpdate => 'تحديث';

  @override
  String get downloadsOnlineOnly => 'عبر الإنترنت فقط';

  @override
  String get downloadsOnlineOnlyBody =>
      'سيُتاح للتحميل عندما تسمح حقوق نشره بذلك.';

  @override
  String get librarySectionEmpty => 'لم يُضف محتوى هنا بعد.';

  @override
  String get librarySectionOpenFailed => 'تعذّر فتح الرابط.';

  @override
  String get ramadanTitle => 'رمضان';

  @override
  String get ramadanGreeting => 'رمضان كريم';

  @override
  String ramadanDay(String day) {
    return 'اليوم $day من رمضان';
  }

  @override
  String get ramadanUntilIftar => 'باقي على الإفطار';

  @override
  String get ramadanUntilImsak => 'باقي على الإمساك';

  @override
  String ramadanMaghrib(String time) {
    return 'المغرب الساعة $time';
  }

  @override
  String ramadanImsak(String time) {
    return 'الإمساك الساعة $time';
  }

  @override
  String get ramadanImsakiya => 'الإمساكية';

  @override
  String get ramadanImsakNote =>
      'الإمساك قبل الفجر بعشر دقائق. الأيام حسب التقويم الهجري المدني، وقد تختلف يومًا عن رؤية الهلال المحلية.';

  @override
  String get ramadanColumnDay => 'اليوم';

  @override
  String get ramadanColumnImsak => 'الإمساك';

  @override
  String get ramadanKhatma => 'ختمة رمضان';

  @override
  String ramadanKhatmaToday(String juz) {
    return 'ورد اليوم: الجزء $juz';
  }

  @override
  String get ramadanOpenJuz => 'افتح';

  @override
  String get ramadanLastTen => 'العشر الأواخر';

  @override
  String ramadanLastTenIn(String days) {
    return 'تبدأ بعد $days أيام';
  }

  @override
  String get ramadanLastTenNow => 'تحرَّ ليلة القدر في هذه الليالي';

  @override
  String ramadanNotNow(String date) {
    return 'يُتوقع أن يبدأ رمضان في حدود $date.';
  }

  @override
  String get remindersRamadanSection => 'رمضان';

  @override
  String get remindersSuhoor => 'السحور';

  @override
  String get remindersSuhoorSubtitle => 'قبل الإمساك بـ ٣٠ دقيقة، في رمضان';

  @override
  String get remindersIftar => 'الإفطار';

  @override
  String get remindersIftarSubtitle => 'عند المغرب، في رمضان';

  @override
  String get reminderSuhoorTitle => 'حان وقت السحور';

  @override
  String get reminderSuhoorBody => 'الإمساك بعد ٣٠ دقيقة.';

  @override
  String get reminderIftarTitle => 'حان وقت الإفطار';

  @override
  String get reminderIftarBody => 'تقبّل الله صيامك.';

  @override
  String get readerAppearance => 'إعدادات القراءة';

  @override
  String get readerFontSize => 'حجم الخط';

  @override
  String get readerSmaller => 'تصغير الخط';

  @override
  String get readerLarger => 'تكبير الخط';

  @override
  String get readerPaper => 'الصفحة';

  @override
  String get readerPaperAuto => 'تلقائي';

  @override
  String get readerPaperLight => 'فاتح';

  @override
  String get readerPaperWarm => 'دافئ';

  @override
  String get readerPaperNight => 'ليلي';

  @override
  String get tasbihTitle => 'السبحة';

  @override
  String get tasbihTap => 'اضغط في أي مكان للعدّ';

  @override
  String tasbihCount(String count) {
    return 'العدد $count';
  }

  @override
  String get tasbihNoGoal => 'مفتوح';

  @override
  String get tasbihReset => 'ابدأ من جديد';

  @override
  String tasbihToday(String count) {
    return 'اليوم: $count';
  }

  @override
  String get tasbihDone => 'اكتمل العدد';

  @override
  String get tasbihFree => 'عدّ حر';

  @override
  String get remindersFastingSection => 'صيام التطوع';

  @override
  String get remindersFastMonThu => 'الإثنين والخميس';

  @override
  String get remindersFastWhiteDays => 'الأيام البيض (١٣–١٥ من كل شهر)';

  @override
  String get remindersFastOccasions => 'يوم عرفة وتاسوعاء وعاشوراء';

  @override
  String remindersFastingSubtitle(String time) {
    return 'في الليلة السابقة الساعة $time';
  }

  @override
  String get reminderFastMonday => 'غدًا الإثنين';

  @override
  String get reminderFastThursday => 'غدًا الخميس';

  @override
  String get reminderFastWhiteDay => 'غدًا من الأيام البيض';

  @override
  String get reminderFastArafah => 'غدًا يوم عرفة';

  @override
  String get reminderFastTasua => 'غدًا تاسوعاء';

  @override
  String get reminderFastAshura => 'غدًا عاشوراء';

  @override
  String get reminderFastBody => 'تذكير لمن أراد الصيام.';

  @override
  String get playerSpeed => 'السرعة';

  @override
  String get playerSleep => 'مؤقت النوم';

  @override
  String get playerSleepOff => 'إيقاف';

  @override
  String playerSleepMinutes(String minutes) {
    return '$minutes د';
  }

  @override
  String playerSleepUntil(String time) {
    return 'يتوقف التشغيل الساعة $time';
  }

  @override
  String get playerBack => 'رجوع ١٠ ثوانٍ';

  @override
  String get playerForward => 'تقديم ١٠ ثوانٍ';
}
