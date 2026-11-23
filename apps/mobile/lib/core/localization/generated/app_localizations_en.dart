// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get adhkarHubTitle => 'Adhkar & Duas';

  @override
  String get adhkarToday => 'Today’s adhkar';

  @override
  String get adhkarResume => 'Continue where you left off';

  @override
  String get adhkarFind => 'Search adhkar and duas';

  @override
  String adhkarPosition(String current, String total) {
    return '$current of $total';
  }

  @override
  String adhkarVariant(String counts) {
    return 'Narration · $counts';
  }

  @override
  String get adhkarPrevious => 'Previous';

  @override
  String get adhkarNext => 'Next';

  @override
  String get adhkarCompleted => 'Completed';

  @override
  String get adhkarMarkRead => 'Mark as read';

  @override
  String get adhkarReset => 'Reset counter';

  @override
  String get adhkarReturnToToday => 'Back to adhkar';

  @override
  String get adhkarCountOnce => 'Count one repetition';

  @override
  String get adhkarThreeSurahCycle => 'Count one recitation of each surah';

  @override
  String get adhkarBedtimeCycle => 'Count one recitation and wiping cycle';

  @override
  String get adhkarTasbih => 'Count one tasbih';

  @override
  String get adhkarTahmid => 'Count one tahmid';

  @override
  String get adhkarTakbir => 'Count one takbir';

  @override
  String get adhkarTahlil => 'Count the closing tahlil';

  @override
  String get adhkarIstighfar => 'Count one istighfar';

  @override
  String get adhkarSavedProgress => 'Your progress is saved on this device';

  @override
  String adhkarWirdToday(String day) {
    return 'Today’s wird · $day';
  }

  @override
  String get adhkarWirdGroups => 'Choose your sets';

  @override
  String get adhkarAddToWird => 'Add to my wird';

  @override
  String get adhkarRemoveFromWird => 'Remove from my wird';

  @override
  String get adhkarHisnSubtitle => 'Adhkar and duas for everyday situations';

  @override
  String get adhkarNothingFound => 'No matching entries';

  @override
  String get adhkarAddFavorite => 'Add to favorites';

  @override
  String get adhkarRemoveFavorite => 'Remove from favorites';

  @override
  String adhkarHadithNumber(String number) {
    return 'Hadith $number';
  }

  @override
  String get adhkarMerit => 'Reported virtue';

  @override
  String get adhkarDraftMeaning => 'Draft English meaning';

  @override
  String get adhkarHadithSource => 'Read the source hadith';

  @override
  String get adhkarRetrySource => 'Try loading the source again';

  @override
  String get adhkarBukhari6324 => 'Sahih al-Bukhari 6324';

  @override
  String get adhkarUsePeriodWording =>
      'Read the wording for this time in the narration below.';

  @override
  String get appTitle => 'Madar Al-Huda';

  @override
  String get appTagline => 'Quran, Knowledge & Worship in One Place';

  @override
  String get appDedication => 'An ongoing charity in memory of my father';

  @override
  String get splashContinue => 'Enter the app';

  @override
  String get navHome => 'Today';

  @override
  String get navQuran => 'Quran';

  @override
  String get navWorship => 'Worship';

  @override
  String get navLibrary => 'Library';

  @override
  String get navLearning => 'Learning';

  @override
  String get openSettings => 'Settings';

  @override
  String get homeGreeting => 'Assalamu alaikum';

  @override
  String get homeTodayLabel => 'Today';

  @override
  String get homeQuickAccess => 'Quick access';

  @override
  String get homePreviewTitle => 'Early development preview';

  @override
  String get homePreviewBody =>
      'Religious content appears only after its source, license and any required scholarly review are verified. Sections still awaiting verification are clearly marked.';

  @override
  String get homePromiseTitle => 'Free, private, ad-free';

  @override
  String get homePromiseBody =>
      'No ads, no subscriptions and no account required. Your preferences stay on this device.';

  @override
  String get quranHubIntro => 'Read, listen and reflect.';

  @override
  String get worshipHubIntro => 'Your companion for daily worship.';

  @override
  String get libraryHubIntro => 'Islamic knowledge with clear sources.';

  @override
  String get learningHubIntro => 'Learn step by step.';

  @override
  String get sectionMushafTitle => 'Read the Quran';

  @override
  String get sectionMushafSubtitle =>
      'Surah index, search, bookmarks and last read position';

  @override
  String get sectionRecitationsTitle => 'Recitations';

  @override
  String get sectionRecitationsSubtitle =>
      'Listen to recitations by selected reciters';

  @override
  String get sectionTafsirTitle => 'Tafsir';

  @override
  String get sectionTafsirSubtitle => 'Al-Tabari and Ibn Kathir';

  @override
  String get sectionPrayerTimesTitle => 'Prayer Times';

  @override
  String get sectionPrayerTimesSubtitle =>
      'Based on your location or a city you choose';

  @override
  String get sectionQiblaTitle => 'Qibla';

  @override
  String get sectionQiblaSubtitle =>
      'Direction of the Kaaba from where you are';

  @override
  String get sectionAdhkarTitle => 'Adhkar & Dua';

  @override
  String get sectionAdhkarSubtitle => 'Morning, evening and daily remembrance';

  @override
  String get sectionHadithTitle => 'Hadith';

  @override
  String get sectionHadithSubtitle =>
      'Narrations with their sources and gradings';

  @override
  String get sectionFiqhTitle => 'Comparative Fiqh';

  @override
  String get sectionFiqhSubtitle =>
      'Hanafi, Maliki, Shafi\'i and Hanbali views';

  @override
  String get sectionArticlesTitle => 'Articles';

  @override
  String get sectionArticlesSubtitle =>
      'Reviewed articles in Arabic and English';

  @override
  String get sectionLessonsTitle => 'Lessons & Quizzes';

  @override
  String get sectionLessonsSubtitle =>
      'Structured paths in fiqh, aqidah and sirah';

  @override
  String get sectionStoriesTitle => 'Stories of the Prophets';

  @override
  String get sectionStoriesSubtitle =>
      'Told from the Quran and Sunnah, with sources';

  @override
  String learningEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes',
      one: '1 episode',
    );
    return '$_temp0';
  }

  @override
  String learningEpisodeNumber(int number) {
    return 'Episode $number';
  }

  @override
  String get learningNoEpisodes =>
      'Episodes will appear here when they’re added.';

  @override
  String get learningFormatAudio => 'Audio';

  @override
  String get learningFormatVideo => 'Video';

  @override
  String get learningPlaySeries => 'Play playlist';

  @override
  String get learningDownload => 'Download episode';

  @override
  String get learningDownloaded => 'Available offline';

  @override
  String get learningRemoveDownload => 'Remove download';

  @override
  String get learningMediaUnavailable =>
      'Episode media is currently unavailable.';

  @override
  String get learningPlaybackFailed => 'Unable to play this episode.';

  @override
  String get learningDownloadFailed => 'Unable to update the download.';

  @override
  String get learningRetry => 'Retry';

  @override
  String get learningPreviousEpisode => 'Previous episode';

  @override
  String get learningNextEpisode => 'Next episode';

  @override
  String get statusAwaitingSourceTitle => 'Awaiting source verification';

  @override
  String get statusAwaitingSourceBody =>
      'This section will show content only after its source edition and usage rights have been verified.';

  @override
  String get statusAwaitingAudioTitle => 'Awaiting audio rights';

  @override
  String get statusAwaitingAudioBody =>
      'Recitations will become available once streaming permission is confirmed for each reciter.';

  @override
  String get statusAwaitingScholarlyTitle => 'Awaiting scholarly review';

  @override
  String get statusAwaitingScholarlyBody =>
      'This content is published only after review and approval by a qualified scholar.';

  @override
  String get statusAwaitingEditorialTitle => 'Awaiting editorial review';

  @override
  String get statusAwaitingEditorialBody =>
      'Articles and lessons are published only after their sources and text have been reviewed.';

  @override
  String get statusAwaitingValidationTitle => 'Calculation under validation';

  @override
  String get statusAwaitingValidationBody =>
      'Prayer times will appear once the calculation has been validated against official references for the UAE and Egypt.';

  @override
  String get statusInDevelopmentTitle => 'In development';

  @override
  String get statusInDevelopmentBody =>
      'This feature is being built and will be available in an upcoming version.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'Device language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsReduceMotion => 'Reduce motion';

  @override
  String get settingsReduceMotionSubtitle =>
      'Minimize animations and screen transitions';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsGuestMode => 'Guest mode';

  @override
  String get settingsGuestModeBody =>
      'No account needed. Your preferences are stored only on this device.';

  @override
  String get settingsGoogleSignIn => 'Sign in with Google';

  @override
  String get settingsGoogleAccount => 'Google account';

  @override
  String get settingsGoogleSignOut => 'Sign out';

  @override
  String get settingsGoogleSignInError =>
      'Couldn’t sign in with Google. Try again.';

  @override
  String get settingsGoogleSignOutError => 'Couldn’t sign out. Try again.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutBody =>
      'Free forever, with no ads and no subscriptions.';

  @override
  String get settingsLicenses => 'Open-source licenses';

  @override
  String get settingsSaveError =>
      'Couldn\'t save your preference. Please try again.';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundBody => 'The page you were looking for doesn\'t exist.';

  @override
  String get notFoundAction => 'Back to home';

  @override
  String get cityDubai => 'Dubai';

  @override
  String get cityAbuDhabi => 'Abu Dhabi';

  @override
  String get cityCairo => 'Cairo';

  @override
  String get cityAlexandria => 'Alexandria';

  @override
  String get chooseCity => 'Choose a city';

  @override
  String get startupLocationTitle => 'Set up your location';

  @override
  String get startupLocationExplanation =>
      'Use your location for prayer times and Qibla. You can also choose a city in Prayer Times or Qibla.';

  @override
  String get startupLocationLater => 'Later';

  @override
  String get useLocation => 'Use my location';

  @override
  String get deviceLocation => 'Device location';

  @override
  String get locationDenied =>
      'Location permission was declined. You can choose a city.';

  @override
  String get locationUnavailable =>
      'Location is unavailable. Check location services or choose a city.';

  @override
  String get locationOutside =>
      'Device location is supported in Egypt and the UAE. Choose a city to continue.';

  @override
  String get locationLoading => 'Finding your location…';

  @override
  String get localSaveFailed => 'Could not save on this device.';

  @override
  String get prayerPreview =>
      'Calculated times for testing while local references are being verified.';

  @override
  String get prayerEgyptMethod => 'Calculation method · Egypt';

  @override
  String get prayerDubaiMethod => 'Calculation method · Dubai';

  @override
  String get hanafiAsr => 'Asr calculation';

  @override
  String get asrHanafi => 'Hanafi';

  @override
  String get asrStandard => 'Standard';

  @override
  String get nextPrayer => 'Next prayer';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String trueBearing(String degrees) {
    return '$degrees° from true north';
  }

  @override
  String get cityBearingApproximate =>
      'Approximate direction from the selected city centre.';

  @override
  String get compassHoldFlat => 'Hold your phone flat and away from metal.';

  @override
  String get compassCalibrate =>
      'Compass signal is weak. Move your phone in a figure eight away from metal.';

  @override
  String get compassWaiting => 'Waiting for the compass…';

  @override
  String get compassUnavailable => 'A live compass reading is unavailable.';

  @override
  String get readerSurahs => 'Surahs';

  @override
  String get readerGoToVerse => 'Go to verse';

  @override
  String get readerVerseNumber => 'Verse number';

  @override
  String readerVerseInvalid(int count) {
    return 'Enter a verse number from 1 to $count.';
  }

  @override
  String get readerGo => 'Go';

  @override
  String get readerCancel => 'Cancel';

  @override
  String get readerTafsir => 'Tafsir';

  @override
  String readerTafsirFor(int verse) {
    return 'Tafsir · verse $verse';
  }

  @override
  String get readerReciter => 'Reciter';

  @override
  String get readerTanzil => 'Quran text by Tanzil Project';

  @override
  String get readerQuranFoundation => 'Quran Foundation';

  @override
  String get readerRetry => 'Retry';

  @override
  String get readerLoadFailed => 'Could not load the Quran text.';

  @override
  String get readerResourcesUnavailable =>
      'Tafsir and recitations are currently unavailable.';

  @override
  String get readerTafsirUnavailable => 'Tafsir is unavailable for this verse.';

  @override
  String get readerAudioUnavailable => 'Could not load this recitation.';

  @override
  String get readerPlay => 'Play surah';

  @override
  String get readerPause => 'Pause recitation';

  @override
  String get readerResume => 'Resume recitation';

  @override
  String get readerStop => 'Stop recitation';

  @override
  String get readerTafsirLoading => 'Loading tafsir…';

  @override
  String get readerPreliveCoverage =>
      'Tafsir and recitation are available for Al-Fatihah and Al-Baqarah in this preview.';

  @override
  String get readerIndex => 'Quran index';

  @override
  String get readerJuzs => 'Parts';

  @override
  String get readerHizbs => 'Hizbs';

  @override
  String get readerPages => 'Pages';

  @override
  String get readerBookmarks => 'Bookmarks';

  @override
  String get readerSearch => 'Search';

  @override
  String get readerSearchHint =>
      'Search Arabic text, a surah, or a verse like 2:255';

  @override
  String get readerNoResults => 'No verses found';

  @override
  String get readerNoBookmarks => 'No bookmarks yet';

  @override
  String get readerPageActions => 'Choose a verse for tafsir or bookmarking';

  @override
  String get readerAddBookmark => 'Add bookmark';

  @override
  String get readerRemoveBookmark => 'Remove bookmark';

  @override
  String readerJuzLabel(String number) {
    return 'Juz $number';
  }

  @override
  String readerHizbLabel(String number) {
    return 'Hizb $number';
  }

  @override
  String readerPageLabel(String number) {
    return 'Page $number';
  }

  @override
  String get duaTitle => 'Quranic supplications';

  @override
  String get duaOpenVerse => 'Open in the Quran';

  @override
  String get duaTranslationUnavailable =>
      'English meaning is temporarily unavailable.';

  @override
  String get duaTopics => 'All topics';

  @override
  String get duaTopicForgiveness => 'Forgiveness and mercy';

  @override
  String get duaTopicGuidance => 'Guidance and knowledge';

  @override
  String get duaTopicFamily => 'Family and community';

  @override
  String get duaTopicHardship => 'Patience and relief';

  @override
  String get duaTopicGratitude => 'Gratitude and provision';

  @override
  String get duaTopicWorship => 'Worship and good deeds';

  @override
  String get duaTopicHereafter => 'The Hereafter';

  @override
  String get duaTopicProtection => 'Protection';

  @override
  String get duaTranslationSource =>
      'English meaning · Rowwad Translation Center via QuranEnc';

  @override
  String get radioTitle => 'Cairo Quran Radio';

  @override
  String get radioOpen => 'Open the official live player in the app';

  @override
  String get radioOpenFailed => 'Could not open the official broadcast site.';

  @override
  String get readerEnglishMeaning => 'English meaning';

  @override
  String get hadithSearchTopics => 'Search hadith topics';

  @override
  String get hadithNoTopics => 'No matching topics';

  @override
  String get hadithPrevious => 'Previous page';

  @override
  String get hadithNext => 'Next page';

  @override
  String hadithProviderGrade(String grade) {
    return 'Grade from HadeethEnc · $grade';
  }

  @override
  String get hadithUnavailable => 'Hadith content is temporarily unavailable.';

  @override
  String get duaSearch => 'Search by verse text, surah or reference';

  @override
  String get duaShowSaved => 'Show saved supplications';

  @override
  String get duaShowAll => 'Show all supplications';

  @override
  String get duaNoResults => 'No matching supplications';

  @override
  String get duaQuranCom => 'More topics on Quran.com';

  @override
  String get radioOpenInBrowser => 'Open browser';

  @override
  String get dailyReadingTitle => 'Daily Quran reading';

  @override
  String get dailyReadingEdit => 'Change daily goal';

  @override
  String get dailyReadingPaceLabel => 'Pages per session';

  @override
  String get dailyReadingPaceRange => 'Enter a number between 1 and 604.';

  @override
  String get dailyReadingSave => 'Save goal';

  @override
  String dailyReadingProgress(String read, String total) {
    return 'Pages read: $read of $total';
  }

  @override
  String dailyReadingRange(String start, String end) {
    return 'Read pages $start–$end';
  }

  @override
  String dailyReadingRemaining(String count) {
    return 'Sessions remaining: $count';
  }

  @override
  String get dailyReadingCompleted => 'You’ve finished this reading plan.';

  @override
  String get dailyReadingRestart => 'Start a new plan';

  @override
  String get dailyReadingOpen => 'Open in Mushaf';

  @override
  String get dailyReadingMarkRead => 'Mark this session read';

  @override
  String get navAdhkar => 'Adhkar';

  @override
  String get navPrayer => 'Prayer';

  @override
  String get prayerCalculationMethod => 'Calculation method';

  @override
  String get prayerAsrCalculation => 'Asr calculation';

  @override
  String prayerMinutesLeft(String minutes) {
    return 'In $minutes min';
  }

  @override
  String prayerHoursLeft(String hours, String minutes) {
    return 'In $hours h $minutes min';
  }

  @override
  String get compassAligned => 'Facing the Qibla';

  @override
  String compassTurnRight(String angle) {
    return 'Turn right · $angle°';
  }

  @override
  String compassTurnLeft(String angle) {
    return 'Turn left · $angle°';
  }

  @override
  String compassPhoneHeading(String angle) {
    return 'Phone heading $angle°';
  }

  @override
  String get readerLastPosition => 'Last reading position';

  @override
  String readerPosition(String surah, String verse, String page) {
    return '$surah · verse $verse · p. $page';
  }

  @override
  String readerPageMeta(String juz, String hizb, String page, String total) {
    return '$juz · $hizb · $page of $total';
  }

  @override
  String get readerPageInput => 'Page number (1–604)';

  @override
  String get readerPageInvalid => 'Enter a page from 1 to 604.';

  @override
  String get readerIndexScroll => 'Scroll vertically between pages.';

  @override
  String readerIndexVerseCount(String count) {
    return '$count verses';
  }

  @override
  String get readerCopy => 'Copy verse';

  @override
  String get readerCopied => 'Verse copied';

  @override
  String get readerShare => 'Share verse';

  @override
  String get readerShareFailed => 'Could not share the verse.';

  @override
  String get readerListenChapter => 'Listen to the surah';

  @override
  String get readerListenFromVerse => 'Listen from this verse';

  @override
  String get readerVerseAudioUnavailable =>
      'This recording has no timing for the selected verse.';

  @override
  String get readerSources => 'Reading sources';

  @override
  String get homeContinueReading => 'Continue reading';

  @override
  String homeOpenPage(String number) {
    return 'Open page $number';
  }

  @override
  String get homeReadQuran => 'Open the Mushaf';

  @override
  String get homeDuaOfDay => 'Dua of the day';

  @override
  String get homeMorning => 'Morning adhkar';

  @override
  String get homeWird => 'Reading plan';

  @override
  String get homeOpenPrayer => 'Set your prayer location';

  @override
  String get radioLive => 'Live';

  @override
  String get radioCairo => 'Live from Cairo';

  @override
  String get hadithGradeTitle => 'Grade';

  @override
  String get hadithSourceTitle => 'Source';

  @override
  String get hadithExplanationTitle => 'Explanation';

  @override
  String get hadithAddFavorite => 'Add to favorites';

  @override
  String get hadithRemoveFavorite => 'Remove from favorites';

  @override
  String get hadithFavoritesTitle => 'Favorite hadiths';

  @override
  String get hadithNoFavorites => 'You have no favorite hadiths yet.';

  @override
  String get libraryAcademy => 'Academy';

  @override
  String get libraryStories => 'Stories of the prophets';

  @override
  String get libraryMore => 'View all';

  @override
  String get dailyReadingCurrentPlan => 'Current reading plan';

  @override
  String dailyReadingNextPage(String page) {
    return 'Open next page · $page';
  }

  @override
  String get dailyReadingTodaysWird => 'Today’s reading';

  @override
  String get decreaseReadingPace => 'Fewer pages per session';

  @override
  String get increaseReadingPace => 'More pages per session';

  @override
  String get homeApproximateHijriDate => 'Approximate civil Hijri date';

  @override
  String get radioPlay => 'Play live radio';

  @override
  String get radioStop => 'Stop live radio';

  @override
  String get radioConnecting => 'Connecting to the live broadcast…';

  @override
  String get radioStreamFailed =>
      'The broadcast is unavailable. Try again or open the official player.';

  @override
  String compassApproximateHeading(String angle) {
    return 'Approximate phone heading $angle°';
  }

  @override
  String get recitationDownload => 'Download recitation';

  @override
  String get recitationDownloadMushaf => 'Download full Mushaf';

  @override
  String get recitationDownloadAvailable => 'Download all available surahs';

  @override
  String recitationDownloadSurahs(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Download surahs ($countString)';
  }

  @override
  String get recitationDownloading => 'Downloading recitation';

  @override
  String get recitationDownloads => 'Downloaded recitations';

  @override
  String get recitationNoDownloads => 'Download a surah to listen offline.';

  @override
  String get recitationPlayOffline => 'Play downloaded recitation';

  @override
  String get recitationRemoveDownload => 'Remove download';

  @override
  String get recitationDownloadFailed =>
      'Could not save or access this download.';

  @override
  String get contentLoadFailed =>
      'Couldn\'t check for new content. Check your connection and try again.';

  @override
  String get contentRetry => 'Retry';

  @override
  String get homeNowLabel => 'Now';

  @override
  String get homeNowMorning => 'After Fajr · time for the morning remembrance';

  @override
  String get homeNowAfterPrayer => 'Right after the prayer';

  @override
  String get homeNowEvening => 'After Asr · time for the evening remembrance';

  @override
  String get homeNowBedtime => 'Before you sleep';

  @override
  String get homeNowStart => 'Start';

  @override
  String get homeNowContinue => 'Continue';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get remindersSettingsSubtitle =>
      'Prayer, remembrance and supplications';

  @override
  String get remindersIntro =>
      'Reminders are calculated on your device from your prayer times and keep working offline.';

  @override
  String get remindersPrayerSection => 'Prayer';

  @override
  String get remindersAdhan => 'At prayer time';

  @override
  String get remindersAdhanSubtitle => 'The five daily prayers';

  @override
  String get remindersBeforePrayer => 'Before the prayer';

  @override
  String remindersBeforePrayerSubtitle(String minutes) {
    return '$minutes minutes before';
  }

  @override
  String get remindersAdhkarSection => 'Remembrance';

  @override
  String get remindersMorning => 'Morning remembrance';

  @override
  String get remindersMorningSubtitle => '30 minutes after Fajr';

  @override
  String get remindersEvening => 'Evening remembrance';

  @override
  String get remindersEveningSubtitle => '15 minutes after Asr';

  @override
  String get remindersAfterPrayer => 'Remembrance after prayer';

  @override
  String get remindersAfterPrayerSubtitle => '10 minutes after each prayer';

  @override
  String get remindersBedtime => 'Bedtime remembrance';

  @override
  String remindersBedtimeSubtitle(String time) {
    return 'At $time';
  }

  @override
  String get remindersBedtimeChange => 'Change bedtime';

  @override
  String get remindersKahf => 'Surat Al-Kahf';

  @override
  String remindersKahfSubtitle(String time) {
    return 'Fridays at $time';
  }

  @override
  String get remindersDuaSection => 'Supplication';

  @override
  String get remindersDailyDua => 'Supplication of the day';

  @override
  String remindersDailyDuaSubtitle(String time) {
    return 'Every day at $time';
  }

  @override
  String get remindersDuaEvery => 'A supplication every';

  @override
  String get remindersDuaOff => 'Off';

  @override
  String remindersDuaHours(String hours) {
    return '$hours hours';
  }

  @override
  String remindersQuietHours(String start, String end) {
    return 'No supplication reminders from $start to $end.';
  }

  @override
  String get remindersPermissionDenied =>
      'Notifications are off for Madar Al-Huda. Allow them in Android settings.';

  @override
  String get remindersExactAlarm =>
      'For reminders on time, allow “Alarms & reminders”.';

  @override
  String get remindersExactAlarmAllow => 'Allow';

  @override
  String get remindersNeedsLocation =>
      'Choose your location first so prayer times can be calculated.';

  @override
  String reminderAdhanTitle(String prayer) {
    return 'It\'s time for $prayer';
  }

  @override
  String get reminderPrayerBody => 'Tap to see today\'s prayer times.';

  @override
  String reminderBeforeTitle(String prayer, String minutes) {
    return '$prayer in $minutes minutes';
  }

  @override
  String reminderAfterTitle(String prayer) {
    return 'Remembrance after $prayer';
  }

  @override
  String get reminderAfterBody =>
      'Take a minute for the remembrance after prayer.';

  @override
  String get reminderAdhkarBody => 'Tap to open the remembrance.';

  @override
  String get reminderKahfTitle => 'Friday: Surat Al-Kahf';

  @override
  String get reminderKahfBody => 'A reminder to read Surat Al-Kahf today.';

  @override
  String get reminderDuaTitle => 'A supplication';

  @override
  String get downloadsTitle => 'Download center';

  @override
  String get downloadsSettingsSubtitle => 'Use the app without internet';

  @override
  String get downloadsOnDevice => 'On your device';

  @override
  String downloadsUsed(String size) {
    return '$size used by downloads';
  }

  @override
  String get downloadsAlwaysOffline => 'Always available offline';

  @override
  String get downloadsRecitations => 'Recitations';

  @override
  String get downloadsNoReciters =>
      'No recitation is available for download yet.';

  @override
  String downloadsReciterProgress(String saved, String total) {
    return '$saved of $total surahs saved';
  }

  @override
  String get downloadsAll => 'Download all';

  @override
  String get downloadsRemoveAll => 'Remove downloads';

  @override
  String downloadsRemoveConfirm(String name) {
    return 'Remove the downloaded files of $name? You can download them again later.';
  }

  @override
  String get downloadsCancel => 'Cancel';

  @override
  String get downloadsConfirmRemove => 'Remove';

  @override
  String get downloadsStories => 'Stories and lessons';

  @override
  String downloadsEpisodeProgress(String saved, String total) {
    return '$saved of $total audio episodes saved';
  }

  @override
  String get downloadsLibrary => 'Library texts';

  @override
  String get downloadsLibraryBody =>
      'Remembrance, supplications, articles and lessons';

  @override
  String get downloadsLibrarySaved => 'Saved on this device';

  @override
  String get downloadsLibraryMissing => 'Not saved yet';

  @override
  String get downloadsUpdate => 'Update';

  @override
  String get downloadsOnlineOnly => 'Online only';

  @override
  String get downloadsOnlineOnlyBody =>
      'Offered for download once its publishing rights allow it.';

  @override
  String get librarySectionEmpty => 'Nothing has been added here yet.';

  @override
  String get librarySectionOpenFailed => 'Couldn\'t open the link.';

  @override
  String get ramadanTitle => 'Ramadan';

  @override
  String get ramadanGreeting => 'Ramadan Kareem';

  @override
  String ramadanDay(String day) {
    return 'Day $day of Ramadan';
  }

  @override
  String get ramadanUntilIftar => 'Until iftar';

  @override
  String get ramadanUntilImsak => 'Until imsak';

  @override
  String ramadanMaghrib(String time) {
    return 'Maghrib at $time';
  }

  @override
  String ramadanImsak(String time) {
    return 'Imsak at $time';
  }

  @override
  String get ramadanImsakiya => 'Imsakiya';

  @override
  String get ramadanImsakNote =>
      'Imsak is 10 minutes before Fajr. Days follow the civil Hijri calendar and may differ by a day from local moon sighting.';

  @override
  String get ramadanColumnDay => 'Day';

  @override
  String get ramadanColumnImsak => 'Imsak';

  @override
  String get ramadanKhatma => 'Ramadan khatma';

  @override
  String ramadanKhatmaToday(String juz) {
    return 'Today\'s portion: juz $juz';
  }

  @override
  String get ramadanOpenJuz => 'Open';

  @override
  String get ramadanLastTen => 'The last ten nights';

  @override
  String ramadanLastTenIn(String days) {
    return 'They begin in $days days';
  }

  @override
  String get ramadanLastTenNow => 'Seek Laylat al-Qadr in these nights';

  @override
  String ramadanNotNow(String date) {
    return 'Ramadan is expected to begin around $date.';
  }

  @override
  String get remindersRamadanSection => 'Ramadan';

  @override
  String get remindersSuhoor => 'Suhoor';

  @override
  String get remindersSuhoorSubtitle =>
      '30 minutes before imsak, during Ramadan';

  @override
  String get remindersIftar => 'Iftar';

  @override
  String get remindersIftarSubtitle => 'At Maghrib, during Ramadan';

  @override
  String get reminderSuhoorTitle => 'Time for suhoor';

  @override
  String get reminderSuhoorBody => 'Imsak is in 30 minutes.';

  @override
  String get reminderIftarTitle => 'Time to break your fast';

  @override
  String get reminderIftarBody => 'May Allah accept your fast.';

  @override
  String get readerAppearance => 'Reading settings';

  @override
  String get readerFontSize => 'Text size';

  @override
  String get readerSmaller => 'Smaller text';

  @override
  String get readerLarger => 'Larger text';

  @override
  String get readerPaper => 'Page';

  @override
  String get readerPaperAuto => 'Auto';

  @override
  String get readerPaperLight => 'Light';

  @override
  String get readerPaperWarm => 'Warm';

  @override
  String get readerPaperNight => 'Night';
}
