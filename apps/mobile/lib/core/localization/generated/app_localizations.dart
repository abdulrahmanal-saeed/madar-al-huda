import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// adhkar Hub Title.
  ///
  /// In en, this message translates to:
  /// **'Adhkar & Duas'**
  String get adhkarHubTitle;

  /// adhkar Today.
  ///
  /// In en, this message translates to:
  /// **'Today’s adhkar'**
  String get adhkarToday;

  /// adhkar Resume.
  ///
  /// In en, this message translates to:
  /// **'Continue where you left off'**
  String get adhkarResume;

  /// adhkar Find.
  ///
  /// In en, this message translates to:
  /// **'Search adhkar and duas'**
  String get adhkarFind;

  /// adhkar Position.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String adhkarPosition(String current, String total);

  /// adhkar Variant.
  ///
  /// In en, this message translates to:
  /// **'Narration · {counts}'**
  String adhkarVariant(String counts);

  /// adhkar Previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get adhkarPrevious;

  /// adhkar Next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get adhkarNext;

  /// adhkar Completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get adhkarCompleted;

  /// adhkar Mark Read.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get adhkarMarkRead;

  /// adhkar Reset.
  ///
  /// In en, this message translates to:
  /// **'Reset counter'**
  String get adhkarReset;

  /// adhkar Return To Today.
  ///
  /// In en, this message translates to:
  /// **'Back to adhkar'**
  String get adhkarReturnToToday;

  /// adhkar Count Once.
  ///
  /// In en, this message translates to:
  /// **'Count one repetition'**
  String get adhkarCountOnce;

  /// adhkar Three Surah Cycle.
  ///
  /// In en, this message translates to:
  /// **'Count one recitation of each surah'**
  String get adhkarThreeSurahCycle;

  /// adhkar Bedtime Cycle.
  ///
  /// In en, this message translates to:
  /// **'Count one recitation and wiping cycle'**
  String get adhkarBedtimeCycle;

  /// adhkar Tasbih.
  ///
  /// In en, this message translates to:
  /// **'Count one tasbih'**
  String get adhkarTasbih;

  /// adhkar Tahmid.
  ///
  /// In en, this message translates to:
  /// **'Count one tahmid'**
  String get adhkarTahmid;

  /// adhkar Takbir.
  ///
  /// In en, this message translates to:
  /// **'Count one takbir'**
  String get adhkarTakbir;

  /// adhkar Tahlil.
  ///
  /// In en, this message translates to:
  /// **'Count the closing tahlil'**
  String get adhkarTahlil;

  /// adhkar Istighfar.
  ///
  /// In en, this message translates to:
  /// **'Count one istighfar'**
  String get adhkarIstighfar;

  /// adhkar Saved Progress.
  ///
  /// In en, this message translates to:
  /// **'Your progress is saved on this device'**
  String get adhkarSavedProgress;

  /// adhkar Wird Today.
  ///
  /// In en, this message translates to:
  /// **'Today’s wird · {day}'**
  String adhkarWirdToday(String day);

  /// adhkar Wird Groups.
  ///
  /// In en, this message translates to:
  /// **'Choose your sets'**
  String get adhkarWirdGroups;

  /// adhkar Add To Wird.
  ///
  /// In en, this message translates to:
  /// **'Add to my wird'**
  String get adhkarAddToWird;

  /// adhkar Remove From Wird.
  ///
  /// In en, this message translates to:
  /// **'Remove from my wird'**
  String get adhkarRemoveFromWird;

  /// adhkar Hisn Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Adhkar and duas for everyday situations'**
  String get adhkarHisnSubtitle;

  /// adhkar Nothing Found.
  ///
  /// In en, this message translates to:
  /// **'No matching entries'**
  String get adhkarNothingFound;

  /// adhkar Add Favorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get adhkarAddFavorite;

  /// adhkar Remove Favorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get adhkarRemoveFavorite;

  /// adhkar Hadith Number.
  ///
  /// In en, this message translates to:
  /// **'Hadith {number}'**
  String adhkarHadithNumber(String number);

  /// adhkar Merit.
  ///
  /// In en, this message translates to:
  /// **'Reported virtue'**
  String get adhkarMerit;

  /// adhkar Draft Meaning.
  ///
  /// In en, this message translates to:
  /// **'Draft English meaning'**
  String get adhkarDraftMeaning;

  /// adhkar Hadith Source.
  ///
  /// In en, this message translates to:
  /// **'Read the source hadith'**
  String get adhkarHadithSource;

  /// adhkar Retry Source.
  ///
  /// In en, this message translates to:
  /// **'Try loading the source again'**
  String get adhkarRetrySource;

  /// adhkar Bukhari6324.
  ///
  /// In en, this message translates to:
  /// **'Sahih al-Bukhari 6324'**
  String get adhkarBukhari6324;

  /// adhkar Use Period Wording.
  ///
  /// In en, this message translates to:
  /// **'Read the wording for this time in the narration below.'**
  String get adhkarUsePeriodWording;

  /// Brand name, transliterated. Not a literal translation.
  ///
  /// In en, this message translates to:
  /// **'Madar Al-Huda'**
  String get appTitle;

  /// Product tagline from docs/BRAND.md.
  ///
  /// In en, this message translates to:
  /// **'Quran, Knowledge & Worship in One Place'**
  String get appTagline;

  /// Dedication shown on the startup screen.
  ///
  /// In en, this message translates to:
  /// **'An ongoing charity in memory of my father'**
  String get appDedication;

  /// Accessibility label for leaving the startup screen.
  ///
  /// In en, this message translates to:
  /// **'Enter the app'**
  String get splashContinue;

  /// Bottom navigation: home tab.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navHome;

  /// Bottom navigation: Quran tab.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get navQuran;

  /// Bottom navigation: worship tab (prayer, qibla, adhkar).
  ///
  /// In en, this message translates to:
  /// **'Worship'**
  String get navWorship;

  /// Bottom navigation: Islamic library tab.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// Bottom navigation: learning tab.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get navLearning;

  /// Tooltip for the settings button in the app bar.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSettings;

  /// Greeting at the top of the home screen.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum'**
  String get homeGreeting;

  /// Label preceding today's Gregorian date.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeTodayLabel;

  /// Home shortcuts header.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get homeQuickAccess;

  /// Title of the notice explaining that content is not yet published.
  ///
  /// In en, this message translates to:
  /// **'Early development preview'**
  String get homePreviewTitle;

  /// Body of the development-preview notice.
  ///
  /// In en, this message translates to:
  /// **'Religious content appears only after its source, license and any required scholarly review are verified. Sections still awaiting verification are clearly marked.'**
  String get homePreviewBody;

  /// Title of the product promise card.
  ///
  /// In en, this message translates to:
  /// **'Free, private, ad-free'**
  String get homePromiseTitle;

  /// Body of the product promise card.
  ///
  /// In en, this message translates to:
  /// **'No ads, no subscriptions and no account required. Your preferences stay on this device.'**
  String get homePromiseBody;

  /// Intro line on the Quran tab.
  ///
  /// In en, this message translates to:
  /// **'Read, listen and reflect.'**
  String get quranHubIntro;

  /// Intro line on the Worship tab.
  ///
  /// In en, this message translates to:
  /// **'Your companion for daily worship.'**
  String get worshipHubIntro;

  /// Intro line on the Library tab.
  ///
  /// In en, this message translates to:
  /// **'Islamic knowledge with clear sources.'**
  String get libraryHubIntro;

  /// Intro line on the Learning tab.
  ///
  /// In en, this message translates to:
  /// **'Learn step by step.'**
  String get learningHubIntro;

  /// Quran reader section title.
  ///
  /// In en, this message translates to:
  /// **'Read the Quran'**
  String get sectionMushafTitle;

  /// Quran reader section description.
  ///
  /// In en, this message translates to:
  /// **'Surah index, search, bookmarks and last read position'**
  String get sectionMushafSubtitle;

  /// Audio recitations section title.
  ///
  /// In en, this message translates to:
  /// **'Recitations'**
  String get sectionRecitationsTitle;

  /// Audio recitations section description.
  ///
  /// In en, this message translates to:
  /// **'Listen to recitations by selected reciters'**
  String get sectionRecitationsSubtitle;

  /// Quran exegesis section title.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get sectionTafsirTitle;

  /// Tafsir section description: names of the two candidate works.
  ///
  /// In en, this message translates to:
  /// **'Al-Tabari and Ibn Kathir'**
  String get sectionTafsirSubtitle;

  /// Prayer times section title.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get sectionPrayerTimesTitle;

  /// Prayer times section description.
  ///
  /// In en, this message translates to:
  /// **'Based on your location or a city you choose'**
  String get sectionPrayerTimesSubtitle;

  /// Qibla direction section title.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get sectionQiblaTitle;

  /// Qibla section description.
  ///
  /// In en, this message translates to:
  /// **'Direction of the Kaaba from where you are'**
  String get sectionQiblaSubtitle;

  /// Remembrance and supplication section title.
  ///
  /// In en, this message translates to:
  /// **'Adhkar & Dua'**
  String get sectionAdhkarTitle;

  /// Adhkar section description.
  ///
  /// In en, this message translates to:
  /// **'Morning, evening and daily remembrance'**
  String get sectionAdhkarSubtitle;

  /// Hadith library section title.
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get sectionHadithTitle;

  /// Hadith section description.
  ///
  /// In en, this message translates to:
  /// **'Narrations with their sources and gradings'**
  String get sectionHadithSubtitle;

  /// Comparative jurisprudence section title.
  ///
  /// In en, this message translates to:
  /// **'Comparative Fiqh'**
  String get sectionFiqhTitle;

  /// Fiqh section description: the four Sunni madhhabs.
  ///
  /// In en, this message translates to:
  /// **'Hanafi, Maliki, Shafi\'i and Hanbali views'**
  String get sectionFiqhSubtitle;

  /// Articles section title.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get sectionArticlesTitle;

  /// Articles section description.
  ///
  /// In en, this message translates to:
  /// **'Reviewed articles in Arabic and English'**
  String get sectionArticlesSubtitle;

  /// Lessons and quizzes section title.
  ///
  /// In en, this message translates to:
  /// **'Lessons & Quizzes'**
  String get sectionLessonsTitle;

  /// Lessons section description.
  ///
  /// In en, this message translates to:
  /// **'Structured paths in fiqh, aqidah and sirah'**
  String get sectionLessonsSubtitle;

  /// Prophet stories section title.
  ///
  /// In en, this message translates to:
  /// **'Stories of the Prophets'**
  String get sectionStoriesTitle;

  /// Prophet stories section description.
  ///
  /// In en, this message translates to:
  /// **'Told from the Quran and Sunnah, with sources'**
  String get sectionStoriesSubtitle;

  /// Number of episodes in a learning series.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 episode} other{{countText} episodes}}'**
  String learningEpisodeCount(String countText, int count);

  /// Title for a numbered episode.
  ///
  /// In en, this message translates to:
  /// **'Episode {number}'**
  String learningEpisodeNumber(String number);

  /// Empty state for a series that has no episodes yet.
  ///
  /// In en, this message translates to:
  /// **'Episodes will appear here when they’re added.'**
  String get learningNoEpisodes;

  /// Select the audio editions of the episodes.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get learningFormatAudio;

  /// Select the video editions of the episodes.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get learningFormatVideo;

  /// Play the numbered episodes in order.
  ///
  /// In en, this message translates to:
  /// **'Play playlist'**
  String get learningPlaySeries;

  /// Save the episode in the selected format for offline use.
  ///
  /// In en, this message translates to:
  /// **'Download episode'**
  String get learningDownload;

  /// Status of a saved episode in the selected format.
  ///
  /// In en, this message translates to:
  /// **'Available offline'**
  String get learningDownloaded;

  /// Delete the selected format from app storage.
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get learningRemoveDownload;

  /// The learning media source has not been configured.
  ///
  /// In en, this message translates to:
  /// **'Episode media is currently unavailable.'**
  String get learningMediaUnavailable;

  /// Shown when an episode cannot be played.
  ///
  /// In en, this message translates to:
  /// **'Unable to play this episode.'**
  String get learningPlaybackFailed;

  /// Shown when saving or removing a media download fails.
  ///
  /// In en, this message translates to:
  /// **'Unable to update the download.'**
  String get learningDownloadFailed;

  /// Retry loading the current episode.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get learningRetry;

  /// Play the preceding video in the list.
  ///
  /// In en, this message translates to:
  /// **'Previous episode'**
  String get learningPreviousEpisode;

  /// Play the next video in the list.
  ///
  /// In en, this message translates to:
  /// **'Next episode'**
  String get learningNextEpisode;

  /// Content status: source/license not yet verified.
  ///
  /// In en, this message translates to:
  /// **'Awaiting source verification'**
  String get statusAwaitingSourceTitle;

  /// Explanation for the awaiting-source status.
  ///
  /// In en, this message translates to:
  /// **'This section will show content only after its source edition and usage rights have been verified.'**
  String get statusAwaitingSourceBody;

  /// Content status: recitation streaming rights not yet confirmed.
  ///
  /// In en, this message translates to:
  /// **'Awaiting audio rights'**
  String get statusAwaitingAudioTitle;

  /// Explanation for the awaiting-audio-rights status.
  ///
  /// In en, this message translates to:
  /// **'Recitations will become available once streaming permission is confirmed for each reciter.'**
  String get statusAwaitingAudioBody;

  /// Content status: needs qualified scholarly review.
  ///
  /// In en, this message translates to:
  /// **'Awaiting scholarly review'**
  String get statusAwaitingScholarlyTitle;

  /// Explanation for the awaiting-scholarly-review status.
  ///
  /// In en, this message translates to:
  /// **'This content is published only after review and approval by a qualified scholar.'**
  String get statusAwaitingScholarlyBody;

  /// Content status: needs source and editorial review.
  ///
  /// In en, this message translates to:
  /// **'Awaiting editorial review'**
  String get statusAwaitingEditorialTitle;

  /// Explanation for the awaiting-editorial-review status.
  ///
  /// In en, this message translates to:
  /// **'Articles and lessons are published only after their sources and text have been reviewed.'**
  String get statusAwaitingEditorialBody;

  /// Content status: prayer time calculation not yet validated.
  ///
  /// In en, this message translates to:
  /// **'Calculation under validation'**
  String get statusAwaitingValidationTitle;

  /// Explanation for the calculation-validation status.
  ///
  /// In en, this message translates to:
  /// **'Prayer times will appear once the calculation has been validated against official references for the UAE and Egypt.'**
  String get statusAwaitingValidationBody;

  /// Content status: feature is being built.
  ///
  /// In en, this message translates to:
  /// **'In development'**
  String get statusInDevelopmentTitle;

  /// Explanation for the in-development status.
  ///
  /// In en, this message translates to:
  /// **'This feature is being built and will be available in an upcoming version.'**
  String get statusInDevelopmentBody;

  /// Settings screen title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings group: app language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Language option: follow the device language.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageSystem;

  /// Language option: Arabic. Always shown in Arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// Language option: English. Always shown in English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Settings group: theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Theme option: follow the system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Theme option: light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Theme option: dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Accessibility toggle title.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get settingsReduceMotion;

  /// Accessibility toggle description.
  ///
  /// In en, this message translates to:
  /// **'Minimize animations and screen transitions'**
  String get settingsReduceMotionSubtitle;

  /// Settings group: account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// Account status: guest (no account).
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get settingsGuestMode;

  /// Explanation of guest mode.
  ///
  /// In en, this message translates to:
  /// **'No account needed. Your preferences are stored only on this device.'**
  String get settingsGuestModeBody;

  /// Action that opens Google sign-in in the browser.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get settingsGoogleSignIn;

  /// Label for the signed-in Google account.
  ///
  /// In en, this message translates to:
  /// **'Google account'**
  String get settingsGoogleAccount;

  /// Action that signs out on this device.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsGoogleSignOut;

  /// Shown when Google sign-in fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t sign in with Google. Try again.'**
  String get settingsGoogleSignInError;

  /// Shown when sign-out fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t sign out. Try again.'**
  String get settingsGoogleSignOutError;

  /// Settings group: about the app.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// About text: product promise.
  ///
  /// In en, this message translates to:
  /// **'Free forever, with no ads and no subscriptions.'**
  String get settingsAboutBody;

  /// Opens the open-source licenses page.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get settingsLicenses;

  /// Shown when saving a setting fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your preference. Please try again.'**
  String get settingsSaveError;

  /// Title shown for an unknown route.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// Body shown for an unknown route.
  ///
  /// In en, this message translates to:
  /// **'The page you were looking for doesn\'t exist.'**
  String get notFoundBody;

  /// Button that returns to the home screen.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get notFoundAction;

  /// Dubai
  ///
  /// In en, this message translates to:
  /// **'Dubai'**
  String get cityDubai;

  /// Abu Dhabi
  ///
  /// In en, this message translates to:
  /// **'Abu Dhabi'**
  String get cityAbuDhabi;

  /// Cairo
  ///
  /// In en, this message translates to:
  /// **'Cairo'**
  String get cityCairo;

  /// Alexandria
  ///
  /// In en, this message translates to:
  /// **'Alexandria'**
  String get cityAlexandria;

  /// Choose a city
  ///
  /// In en, this message translates to:
  /// **'Choose a city'**
  String get chooseCity;

  /// Title of the initial setup dialog for the shared worship location.
  ///
  /// In en, this message translates to:
  /// **'Set up your location'**
  String get startupLocationTitle;

  /// Explains why the app asks for location access and where to set a manual city.
  ///
  /// In en, this message translates to:
  /// **'Use your location for prayer times and Qibla. You can also choose a city in Prayer Times or Qibla.'**
  String get startupLocationExplanation;

  /// Dismisses location setup while leaving the rest of the app available.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get startupLocationLater;

  /// Use my location
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useLocation;

  /// Device location
  ///
  /// In en, this message translates to:
  /// **'Device location'**
  String get deviceLocation;

  /// Location permission was declined. You can choose a city.
  ///
  /// In en, this message translates to:
  /// **'Location permission was declined. You can choose a city.'**
  String get locationDenied;

  /// Location is unavailable. Check location services or choose a city.
  ///
  /// In en, this message translates to:
  /// **'Location is unavailable. Check location services or choose a city.'**
  String get locationUnavailable;

  /// Finding your location…
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get locationLoading;

  /// Could not save on this device.
  ///
  /// In en, this message translates to:
  /// **'Could not save on this device.'**
  String get localSaveFailed;

  /// Calculated times for testing while local references are being verified.
  ///
  /// In en, this message translates to:
  /// **'Calculated times for testing while local references are being verified.'**
  String get prayerPreview;

  /// Calculation method · Egypt
  ///
  /// In en, this message translates to:
  /// **'Calculation method · Egypt'**
  String get prayerEgyptMethod;

  /// Calculation method · Dubai
  ///
  /// In en, this message translates to:
  /// **'Calculation method · Dubai'**
  String get prayerDubaiMethod;

  /// Asr calculation
  ///
  /// In en, this message translates to:
  /// **'Asr calculation'**
  String get hanafiAsr;

  /// Hanafi
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get asrHanafi;

  /// Standard
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get asrStandard;

  /// Next prayer
  ///
  /// In en, this message translates to:
  /// **'Next prayer'**
  String get nextPrayer;

  /// Fajr
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// Sunrise
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerSunrise;

  /// Dhuhr
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// Asr
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// Maghrib
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// Isha
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// {degrees}° from true north
  ///
  /// In en, this message translates to:
  /// **'{degrees}° from true north'**
  String trueBearing(String degrees);

  /// Approximate direction from the selected city centre.
  ///
  /// In en, this message translates to:
  /// **'Approximate direction from the selected city centre.'**
  String get cityBearingApproximate;

  /// Hold your phone flat and away from metal.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone flat and away from metal.'**
  String get compassHoldFlat;

  /// Compass signal is weak. Move your phone in a figure eight away from metal.
  ///
  /// In en, this message translates to:
  /// **'Compass signal is weak. Move your phone in a figure eight away from metal.'**
  String get compassCalibrate;

  /// Waiting for the compass…
  ///
  /// In en, this message translates to:
  /// **'Waiting for the compass…'**
  String get compassWaiting;

  /// A live compass reading is unavailable.
  ///
  /// In en, this message translates to:
  /// **'A live compass reading is unavailable.'**
  String get compassUnavailable;

  /// Surahs
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get readerSurahs;

  /// Go to verse
  ///
  /// In en, this message translates to:
  /// **'Go to verse'**
  String get readerGoToVerse;

  /// Verse number
  ///
  /// In en, this message translates to:
  /// **'Verse number'**
  String get readerVerseNumber;

  /// Enter a verse number from 1 to {count}.
  ///
  /// In en, this message translates to:
  /// **'Enter a verse number from 1 to {count}.'**
  String readerVerseInvalid(String count);

  /// Go
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get readerGo;

  /// Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get readerCancel;

  /// Tafsir
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get readerTafsir;

  /// Tafsir · verse {verse}
  ///
  /// In en, this message translates to:
  /// **'Tafsir · verse {verse}'**
  String readerTafsirFor(String verse);

  /// Reciter
  ///
  /// In en, this message translates to:
  /// **'Reciter'**
  String get readerReciter;

  /// Quran text by Tanzil Project
  ///
  /// In en, this message translates to:
  /// **'Quran text by Tanzil Project'**
  String get readerTanzil;

  /// Quran Foundation
  ///
  /// In en, this message translates to:
  /// **'Quran Foundation'**
  String get readerQuranFoundation;

  /// Retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get readerRetry;

  /// Could not load the Quran text.
  ///
  /// In en, this message translates to:
  /// **'Could not load the Quran text.'**
  String get readerLoadFailed;

  /// Tafsir and recitations are currently unavailable.
  ///
  /// In en, this message translates to:
  /// **'Tafsir and recitations are currently unavailable.'**
  String get readerResourcesUnavailable;

  /// Tafsir is unavailable for this verse.
  ///
  /// In en, this message translates to:
  /// **'Tafsir is unavailable for this verse.'**
  String get readerTafsirUnavailable;

  /// Could not load this recitation.
  ///
  /// In en, this message translates to:
  /// **'Could not load this recitation.'**
  String get readerAudioUnavailable;

  /// Play surah
  ///
  /// In en, this message translates to:
  /// **'Play surah'**
  String get readerPlay;

  /// Pause recitation
  ///
  /// In en, this message translates to:
  /// **'Pause recitation'**
  String get readerPause;

  /// Resume recitation
  ///
  /// In en, this message translates to:
  /// **'Resume recitation'**
  String get readerResume;

  /// Stop recitation
  ///
  /// In en, this message translates to:
  /// **'Stop recitation'**
  String get readerStop;

  /// Loading tafsir…
  ///
  /// In en, this message translates to:
  /// **'Loading tafsir…'**
  String get readerTafsirLoading;

  /// Explains the limited Quran Foundation test content on other chapters.
  ///
  /// In en, this message translates to:
  /// **'Tafsir and recitation are available for Al-Fatihah and Al-Baqarah in this preview.'**
  String get readerPreliveCoverage;

  /// Quran index
  ///
  /// In en, this message translates to:
  /// **'Quran index'**
  String get readerIndex;

  /// Parts
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get readerJuzs;

  /// Hizbs
  ///
  /// In en, this message translates to:
  /// **'Hizbs'**
  String get readerHizbs;

  /// Pages
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get readerPages;

  /// Bookmarks
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get readerBookmarks;

  /// Search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get readerSearch;

  /// Search Arabic text, a surah, or a verse like 2:255
  ///
  /// In en, this message translates to:
  /// **'Search Arabic text, a surah, or a verse like 2:255'**
  String get readerSearchHint;

  /// No verses found
  ///
  /// In en, this message translates to:
  /// **'No verses found'**
  String get readerNoResults;

  /// No bookmarks yet
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get readerNoBookmarks;

  /// Choose a verse for tafsir or bookmarking
  ///
  /// In en, this message translates to:
  /// **'Choose a verse for tafsir or bookmarking'**
  String get readerPageActions;

  /// Add bookmark
  ///
  /// In en, this message translates to:
  /// **'Add bookmark'**
  String get readerAddBookmark;

  /// Remove bookmark
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get readerRemoveBookmark;

  /// Mushaf part label.
  ///
  /// In en, this message translates to:
  /// **'Juz {number}'**
  String readerJuzLabel(String number);

  /// Mushaf hizb label.
  ///
  /// In en, this message translates to:
  /// **'Hizb {number}'**
  String readerHizbLabel(String number);

  /// Mushaf or list page label.
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String readerPageLabel(String number);

  /// Quranic supplications
  ///
  /// In en, this message translates to:
  /// **'Quranic supplications'**
  String get duaTitle;

  /// Open in the Quran
  ///
  /// In en, this message translates to:
  /// **'Open in the Quran'**
  String get duaOpenVerse;

  /// English meaning is temporarily unavailable.
  ///
  /// In en, this message translates to:
  /// **'English meaning is temporarily unavailable.'**
  String get duaTranslationUnavailable;

  /// All topics
  ///
  /// In en, this message translates to:
  /// **'All topics'**
  String get duaTopics;

  /// Forgiveness and mercy
  ///
  /// In en, this message translates to:
  /// **'Forgiveness and mercy'**
  String get duaTopicForgiveness;

  /// Guidance and knowledge
  ///
  /// In en, this message translates to:
  /// **'Guidance and knowledge'**
  String get duaTopicGuidance;

  /// Family and community
  ///
  /// In en, this message translates to:
  /// **'Family and community'**
  String get duaTopicFamily;

  /// Patience and relief
  ///
  /// In en, this message translates to:
  /// **'Patience and relief'**
  String get duaTopicHardship;

  /// Gratitude and provision
  ///
  /// In en, this message translates to:
  /// **'Gratitude and provision'**
  String get duaTopicGratitude;

  /// Worship and good deeds
  ///
  /// In en, this message translates to:
  /// **'Worship and good deeds'**
  String get duaTopicWorship;

  /// The Hereafter
  ///
  /// In en, this message translates to:
  /// **'The Hereafter'**
  String get duaTopicHereafter;

  /// Protection
  ///
  /// In en, this message translates to:
  /// **'Protection'**
  String get duaTopicProtection;

  /// English meaning · Rowwad Translation Center via QuranEnc
  ///
  /// In en, this message translates to:
  /// **'English meaning · Rowwad Translation Center via QuranEnc'**
  String get duaTranslationSource;

  /// Cairo Quran Radio
  ///
  /// In en, this message translates to:
  /// **'Cairo Quran Radio'**
  String get radioTitle;

  /// Listen on the official site
  ///
  /// In en, this message translates to:
  /// **'Open the official live player in the app'**
  String get radioOpen;

  /// Could not open the official broadcast site.
  ///
  /// In en, this message translates to:
  /// **'Could not open the official broadcast site.'**
  String get radioOpenFailed;

  /// Action to show the English meaning of an ayah.
  ///
  /// In en, this message translates to:
  /// **'English meaning'**
  String get readerEnglishMeaning;

  /// Search hadith topics
  ///
  /// In en, this message translates to:
  /// **'Search hadith topics'**
  String get hadithSearchTopics;

  /// No matching topics
  ///
  /// In en, this message translates to:
  /// **'No matching topics'**
  String get hadithNoTopics;

  /// Previous page
  ///
  /// In en, this message translates to:
  /// **'Previous hadith'**
  String get hadithPrevious;

  /// Next page
  ///
  /// In en, this message translates to:
  /// **'Next hadith'**
  String get hadithNext;

  /// Grade from HadeethEnc · {grade}
  ///
  /// In en, this message translates to:
  /// **'Grade from HadeethEnc · {grade}'**
  String hadithProviderGrade(String grade);

  /// Hadith content is temporarily unavailable.
  ///
  /// In en, this message translates to:
  /// **'Hadith content is temporarily unavailable.'**
  String get hadithUnavailable;

  /// Search by verse text, surah or reference
  ///
  /// In en, this message translates to:
  /// **'Search by verse text, surah or reference'**
  String get duaSearch;

  /// Show saved supplications
  ///
  /// In en, this message translates to:
  /// **'Show saved supplications'**
  String get duaShowSaved;

  /// Show all supplications
  ///
  /// In en, this message translates to:
  /// **'Show all supplications'**
  String get duaShowAll;

  /// No matching supplications
  ///
  /// In en, this message translates to:
  /// **'No matching supplications'**
  String get duaNoResults;

  /// More topics on Quran.com
  ///
  /// In en, this message translates to:
  /// **'More topics on Quran.com'**
  String get duaQuranCom;

  /// Open browser
  ///
  /// In en, this message translates to:
  /// **'Open browser'**
  String get radioOpenInBrowser;

  /// Daily Quran reading
  ///
  /// In en, this message translates to:
  /// **'Daily Quran reading'**
  String get dailyReadingTitle;

  /// Change daily goal
  ///
  /// In en, this message translates to:
  /// **'Change daily goal'**
  String get dailyReadingEdit;

  /// Pages per session
  ///
  /// In en, this message translates to:
  /// **'Pages per session'**
  String get dailyReadingPaceLabel;

  /// Enter a number between 1 and 604.
  ///
  /// In en, this message translates to:
  /// **'Enter a number between 1 and 604.'**
  String get dailyReadingPaceRange;

  /// Save goal
  ///
  /// In en, this message translates to:
  /// **'Save goal'**
  String get dailyReadingSave;

  /// Pages read: of
  ///
  /// In en, this message translates to:
  /// **'Pages read: {read} of {total}'**
  String dailyReadingProgress(String read, String total);

  /// Read pages–
  ///
  /// In en, this message translates to:
  /// **'Read pages {start}–{end}'**
  String dailyReadingRange(String start, String end);

  /// Sessions remaining:
  ///
  /// In en, this message translates to:
  /// **'Sessions remaining: {count}'**
  String dailyReadingRemaining(String count);

  /// You’ve finished this reading plan.
  ///
  /// In en, this message translates to:
  /// **'You’ve finished this reading plan.'**
  String get dailyReadingCompleted;

  /// Start a new plan
  ///
  /// In en, this message translates to:
  /// **'Start a new plan'**
  String get dailyReadingRestart;

  /// Open in Mushaf
  ///
  /// In en, this message translates to:
  /// **'Open in Mushaf'**
  String get dailyReadingOpen;

  /// Mark this session read
  ///
  /// In en, this message translates to:
  /// **'Mark this session read'**
  String get dailyReadingMarkRead;

  /// Adhkar
  ///
  /// In en, this message translates to:
  /// **'Adhkar'**
  String get navAdhkar;

  /// Prayer
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get navPrayer;

  /// Calculation method
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get prayerCalculationMethod;

  /// Asr calculation
  ///
  /// In en, this message translates to:
  /// **'Asr calculation'**
  String get prayerAsrCalculation;

  /// In minutes min
  ///
  /// In en, this message translates to:
  /// **'In {minutes} min'**
  String prayerMinutesLeft(String minutes);

  /// In hours h minutes min
  ///
  /// In en, this message translates to:
  /// **'In {hours} h {minutes} min'**
  String prayerHoursLeft(String hours, String minutes);

  /// Facing the Qibla
  ///
  /// In en, this message translates to:
  /// **'Facing the Qibla'**
  String get compassAligned;

  /// Turn right · angle°
  ///
  /// In en, this message translates to:
  /// **'Turn right · {angle}°'**
  String compassTurnRight(String angle);

  /// Turn left · angle°
  ///
  /// In en, this message translates to:
  /// **'Turn left · {angle}°'**
  String compassTurnLeft(String angle);

  /// Phone heading angle°
  ///
  /// In en, this message translates to:
  /// **'Phone heading {angle}°'**
  String compassPhoneHeading(String angle);

  /// Last reading position
  ///
  /// In en, this message translates to:
  /// **'Last reading position'**
  String get readerLastPosition;

  /// surah · verse verse · p. page
  ///
  /// In en, this message translates to:
  /// **'{surah} · verse {verse} · p. {page}'**
  String readerPosition(String surah, String verse, String page);

  /// juz · hizb · page of total
  ///
  /// In en, this message translates to:
  /// **'{juz} · {hizb} · {page} of {total}'**
  String readerPageMeta(String juz, String hizb, String page, String total);

  /// Page number (1–604)
  ///
  /// In en, this message translates to:
  /// **'Page number (1–604)'**
  String get readerPageInput;

  /// Enter a page from 1 to 604.
  ///
  /// In en, this message translates to:
  /// **'Enter a page from 1 to 604.'**
  String get readerPageInvalid;

  /// Scroll vertically between pages.
  ///
  /// In en, this message translates to:
  /// **'Scroll vertically between pages.'**
  String get readerIndexScroll;

  /// count verses
  ///
  /// In en, this message translates to:
  /// **'{count} verses'**
  String readerIndexVerseCount(String count);

  /// Copy verse
  ///
  /// In en, this message translates to:
  /// **'Copy verse'**
  String get readerCopy;

  /// Verse copied
  ///
  /// In en, this message translates to:
  /// **'Verse copied'**
  String get readerCopied;

  /// Share verse
  ///
  /// In en, this message translates to:
  /// **'Share verse'**
  String get readerShare;

  /// Could not share the verse.
  ///
  /// In en, this message translates to:
  /// **'Could not share the verse.'**
  String get readerShareFailed;

  /// Listen to the surah
  ///
  /// In en, this message translates to:
  /// **'Listen to the surah'**
  String get readerListenChapter;

  /// Listen from this verse
  ///
  /// In en, this message translates to:
  /// **'Listen from this verse'**
  String get readerListenFromVerse;

  /// This recording has no timing for the selected verse.
  ///
  /// In en, this message translates to:
  /// **'This recording has no timing for the selected verse.'**
  String get readerVerseAudioUnavailable;

  /// Mushaf overflow menu.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get readerSources;

  /// Continue reading
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get homeContinueReading;

  /// Open page number
  ///
  /// In en, this message translates to:
  /// **'Open page {number}'**
  String homeOpenPage(String number);

  /// Open the Mushaf
  ///
  /// In en, this message translates to:
  /// **'Open the Mushaf'**
  String get homeReadQuran;

  /// Dua of the day
  ///
  /// In en, this message translates to:
  /// **'Dua of the day'**
  String get homeDuaOfDay;

  /// Morning adhkar
  ///
  /// In en, this message translates to:
  /// **'Morning adhkar'**
  String get homeMorning;

  /// Reading plan
  ///
  /// In en, this message translates to:
  /// **'Reading plan'**
  String get homeWird;

  /// Set your prayer location
  ///
  /// In en, this message translates to:
  /// **'Set your prayer location'**
  String get homeOpenPrayer;

  /// Live
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get radioLive;

  /// Live from Cairo
  ///
  /// In en, this message translates to:
  /// **'Live from Cairo'**
  String get radioCairo;

  /// Grade
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get hadithGradeTitle;

  /// Source
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get hadithSourceTitle;

  /// Explanation
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get hadithExplanationTitle;

  /// Add to favorites
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get hadithAddFavorite;

  /// Remove from favorites
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get hadithRemoveFavorite;

  /// Favorite hadiths
  ///
  /// In en, this message translates to:
  /// **'Favorite hadiths'**
  String get hadithFavoritesTitle;

  /// You have no favorite hadiths yet.
  ///
  /// In en, this message translates to:
  /// **'You have no favorite hadiths yet.'**
  String get hadithNoFavorites;

  /// Academy
  ///
  /// In en, this message translates to:
  /// **'Academy'**
  String get libraryAcademy;

  /// Stories of the prophets
  ///
  /// In en, this message translates to:
  /// **'Stories of the prophets'**
  String get libraryStories;

  /// View all
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get libraryMore;

  /// Current reading plan
  ///
  /// In en, this message translates to:
  /// **'Current reading plan'**
  String get dailyReadingCurrentPlan;

  /// Open next page · page
  ///
  /// In en, this message translates to:
  /// **'Open next page · {page}'**
  String dailyReadingNextPage(String page);

  /// Today’s reading
  ///
  /// In en, this message translates to:
  /// **'Today’s reading'**
  String get dailyReadingTodaysWird;

  /// Fewer pages per session
  ///
  /// In en, this message translates to:
  /// **'Fewer pages per session'**
  String get decreaseReadingPace;

  /// More pages per session
  ///
  /// In en, this message translates to:
  /// **'More pages per session'**
  String get increaseReadingPace;

  /// Tooltip for the approximate civil Hijri date.
  ///
  /// In en, this message translates to:
  /// **'Approximate civil Hijri date'**
  String get homeApproximateHijriDate;

  /// Play live radio
  ///
  /// In en, this message translates to:
  /// **'Play live radio'**
  String get radioPlay;

  /// Stop live radio
  ///
  /// In en, this message translates to:
  /// **'Stop live radio'**
  String get radioStop;

  /// Connecting to the live broadcast…
  ///
  /// In en, this message translates to:
  /// **'Connecting to the live broadcast…'**
  String get radioConnecting;

  /// The broadcast is unavailable. Try again or open the official player.
  ///
  /// In en, this message translates to:
  /// **'The broadcast is unavailable. Try again or open the official player.'**
  String get radioStreamFailed;

  /// Approximate phone heading angle°
  ///
  /// In en, this message translates to:
  /// **'Approximate phone heading {angle}°'**
  String compassApproximateHeading(String angle);

  /// Download recitation
  ///
  /// In en, this message translates to:
  /// **'Download recitation'**
  String get recitationDownload;

  /// Opens the full-recitation download controls for a reader covering all 114 surahs.
  ///
  /// In en, this message translates to:
  /// **'Download full Mushaf'**
  String get recitationDownloadMushaf;

  /// Opens the recitation download controls when a reader covers part of the Mushaf.
  ///
  /// In en, this message translates to:
  /// **'Download all available surahs'**
  String get recitationDownloadAvailable;

  /// Download action with the total number of available recordings.
  ///
  /// In en, this message translates to:
  /// **'Download surahs ({count})'**
  String recitationDownloadSurahs(String count);

  /// Downloading recitation
  ///
  /// In en, this message translates to:
  /// **'Downloading recitation'**
  String get recitationDownloading;

  /// Downloaded recitations
  ///
  /// In en, this message translates to:
  /// **'Downloaded recitations'**
  String get recitationDownloads;

  /// Download a surah to listen offline.
  ///
  /// In en, this message translates to:
  /// **'Download a surah to listen offline.'**
  String get recitationNoDownloads;

  /// Play downloaded recitation
  ///
  /// In en, this message translates to:
  /// **'Play downloaded recitation'**
  String get recitationPlayOffline;

  /// Remove download
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get recitationRemoveDownload;

  /// Could not save or access this download.
  ///
  /// In en, this message translates to:
  /// **'Could not save or access this download.'**
  String get recitationDownloadFailed;

  /// Shown when hosted library content has no response and no saved copy.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for new content. Check your connection and try again.'**
  String get contentLoadFailed;

  /// Button that loads hosted library content again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get contentRetry;

  /// Badge on the home card that suggests the remembrance for the current time.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get homeNowLabel;

  /// Home now card, morning.
  ///
  /// In en, this message translates to:
  /// **'After Fajr · time for the morning remembrance'**
  String get homeNowMorning;

  /// Home now card, after a prayer.
  ///
  /// In en, this message translates to:
  /// **'Right after the prayer'**
  String get homeNowAfterPrayer;

  /// Home now card, evening.
  ///
  /// In en, this message translates to:
  /// **'After Asr · time for the evening remembrance'**
  String get homeNowEvening;

  /// Home now card, bedtime.
  ///
  /// In en, this message translates to:
  /// **'Before you sleep'**
  String get homeNowBedtime;

  /// Opens the suggested remembrance.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get homeNowStart;

  /// Continues the suggested remembrance.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeNowContinue;

  /// Reminder settings screen title.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// Settings entry for reminders.
  ///
  /// In en, this message translates to:
  /// **'Prayer, remembrance and supplications'**
  String get remindersSettingsSubtitle;

  /// Reminder settings intro.
  ///
  /// In en, this message translates to:
  /// **'Reminders are calculated on your device from your prayer times and keep working offline.'**
  String get remindersIntro;

  /// Reminder section.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get remindersPrayerSection;

  /// Reminder toggle.
  ///
  /// In en, this message translates to:
  /// **'At prayer time'**
  String get remindersAdhan;

  /// Reminder toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'The five daily prayers'**
  String get remindersAdhanSubtitle;

  /// Reminder toggle.
  ///
  /// In en, this message translates to:
  /// **'Before the prayer'**
  String get remindersBeforePrayer;

  /// Reminder toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes before'**
  String remindersBeforePrayerSubtitle(String minutes);

  /// Reminder section.
  ///
  /// In en, this message translates to:
  /// **'Remembrance'**
  String get remindersAdhkarSection;

  /// Reminder toggle and notification title.
  ///
  /// In en, this message translates to:
  /// **'Morning remembrance'**
  String get remindersMorning;

  /// Reminder toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'30 minutes after Fajr'**
  String get remindersMorningSubtitle;

  /// Reminder toggle and notification title.
  ///
  /// In en, this message translates to:
  /// **'Evening remembrance'**
  String get remindersEvening;

  /// Reminder toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'15 minutes after Asr'**
  String get remindersEveningSubtitle;

  /// Reminder toggle.
  ///
  /// In en, this message translates to:
  /// **'Remembrance after prayer'**
  String get remindersAfterPrayer;

  /// Reminder toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'10 minutes after each prayer'**
  String get remindersAfterPrayerSubtitle;

  /// Reminder toggle and notification title.
  ///
  /// In en, this message translates to:
  /// **'Bedtime remembrance'**
  String get remindersBedtime;

  /// Reminder toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'At {time}'**
  String remindersBedtimeSubtitle(String time);

  /// Button that opens the time picker.
  ///
  /// In en, this message translates to:
  /// **'Change bedtime'**
  String get remindersBedtimeChange;

  /// Reminder toggle.
  ///
  /// In en, this message translates to:
  /// **'Surat Al-Kahf'**
  String get remindersKahf;

  /// Reminder toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Fridays at {time}'**
  String remindersKahfSubtitle(String time);

  /// Reminder section.
  ///
  /// In en, this message translates to:
  /// **'Supplication'**
  String get remindersDuaSection;

  /// Reminder toggle.
  ///
  /// In en, this message translates to:
  /// **'Supplication of the day'**
  String get remindersDailyDua;

  /// Reminder toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String remindersDailyDuaSubtitle(String time);

  /// Label before the interval choices.
  ///
  /// In en, this message translates to:
  /// **'A supplication every'**
  String get remindersDuaEvery;

  /// Interval choice that turns it off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get remindersDuaOff;

  /// Interval choice.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String remindersDuaHours(String hours);

  /// Quiet hours note.
  ///
  /// In en, this message translates to:
  /// **'No supplication reminders from {start} to {end}.'**
  String remindersQuietHours(String start, String end);

  /// Shown when notification permission is refused.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for Madar Al-Huda. Allow them in Android settings.'**
  String get remindersPermissionDenied;

  /// Exact alarm permission note.
  ///
  /// In en, this message translates to:
  /// **'For reminders on time, allow “Alarms & reminders”.'**
  String get remindersExactAlarm;

  /// Button that requests exact alarms.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get remindersExactAlarmAllow;

  /// Shown when no location is set.
  ///
  /// In en, this message translates to:
  /// **'Choose your location first so prayer times can be calculated.'**
  String get remindersNeedsLocation;

  /// Notification title at prayer time.
  ///
  /// In en, this message translates to:
  /// **'It\'s time for {prayer}'**
  String reminderAdhanTitle(String prayer);

  /// Notification body for prayer reminders.
  ///
  /// In en, this message translates to:
  /// **'Tap to see today\'s prayer times.'**
  String get reminderPrayerBody;

  /// Notification title before a prayer.
  ///
  /// In en, this message translates to:
  /// **'{prayer} in {minutes} minutes'**
  String reminderBeforeTitle(String prayer, String minutes);

  /// Notification title after a prayer.
  ///
  /// In en, this message translates to:
  /// **'Remembrance after {prayer}'**
  String reminderAfterTitle(String prayer);

  /// Notification body after a prayer.
  ///
  /// In en, this message translates to:
  /// **'Take a minute for the remembrance after prayer.'**
  String get reminderAfterBody;

  /// Notification body for remembrance reminders.
  ///
  /// In en, this message translates to:
  /// **'Tap to open the remembrance.'**
  String get reminderAdhkarBody;

  /// Friday notification title.
  ///
  /// In en, this message translates to:
  /// **'Friday: Surat Al-Kahf'**
  String get reminderKahfTitle;

  /// Friday notification body.
  ///
  /// In en, this message translates to:
  /// **'A reminder to read Surat Al-Kahf today.'**
  String get reminderKahfBody;

  /// Supplication notification title.
  ///
  /// In en, this message translates to:
  /// **'A supplication'**
  String get reminderDuaTitle;

  /// Download center screen title.
  ///
  /// In en, this message translates to:
  /// **'Download center'**
  String get downloadsTitle;

  /// Settings and library entry subtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the app without internet'**
  String get downloadsSettingsSubtitle;

  /// Summary card title.
  ///
  /// In en, this message translates to:
  /// **'On your device'**
  String get downloadsOnDevice;

  /// Storage used.
  ///
  /// In en, this message translates to:
  /// **'{size} used by downloads'**
  String downloadsUsed(String size);

  /// Label above built-in content.
  ///
  /// In en, this message translates to:
  /// **'Always available offline'**
  String get downloadsAlwaysOffline;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Recitations'**
  String get downloadsRecitations;

  /// Empty state.
  ///
  /// In en, this message translates to:
  /// **'No recitation is available for download yet.'**
  String get downloadsNoReciters;

  /// Reciter row subtitle.
  ///
  /// In en, this message translates to:
  /// **'{saved} of {total} surahs saved'**
  String downloadsReciterProgress(String saved, String total);

  /// Button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Download all'**
  String get downloadsAll;

  /// Button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove downloads'**
  String get downloadsRemoveAll;

  /// Removal confirmation.
  ///
  /// In en, this message translates to:
  /// **'Remove the downloaded files of {name}? You can download them again later.'**
  String downloadsRemoveConfirm(String name);

  /// Dialog button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get downloadsCancel;

  /// Dialog button.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get downloadsConfirmRemove;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Stories and lessons'**
  String get downloadsStories;

  /// Series row subtitle.
  ///
  /// In en, this message translates to:
  /// **'{saved} of {total} audio episodes saved'**
  String downloadsEpisodeProgress(String saved, String total);

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Library texts'**
  String get downloadsLibrary;

  /// Library row title.
  ///
  /// In en, this message translates to:
  /// **'Remembrance, supplications, articles and lessons'**
  String get downloadsLibraryBody;

  /// Library status.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device'**
  String get downloadsLibrarySaved;

  /// Library status.
  ///
  /// In en, this message translates to:
  /// **'Not saved yet'**
  String get downloadsLibraryMissing;

  /// Button that refreshes the library texts.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get downloadsUpdate;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Online only'**
  String get downloadsOnlineOnly;

  /// Online-only explanation.
  ///
  /// In en, this message translates to:
  /// **'Offered for download once its publishing rights allow it.'**
  String get downloadsOnlineOnlyBody;

  /// Empty state of a section added on the dashboard.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been added here yet.'**
  String get librarySectionEmpty;

  /// Shown when a section link cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link.'**
  String get librarySectionOpenFailed;

  /// Ramadan page title.
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get ramadanTitle;

  /// Ramadan page greeting.
  ///
  /// In en, this message translates to:
  /// **'Ramadan Kareem'**
  String get ramadanGreeting;

  /// Current day of Ramadan.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of Ramadan'**
  String ramadanDay(String day);

  /// Countdown label.
  ///
  /// In en, this message translates to:
  /// **'Until iftar'**
  String get ramadanUntilIftar;

  /// Countdown label.
  ///
  /// In en, this message translates to:
  /// **'Until imsak'**
  String get ramadanUntilImsak;

  /// Time of iftar.
  ///
  /// In en, this message translates to:
  /// **'Maghrib at {time}'**
  String ramadanMaghrib(String time);

  /// Time of imsak.
  ///
  /// In en, this message translates to:
  /// **'Imsak at {time}'**
  String ramadanImsak(String time);

  /// Ramadan timetable title.
  ///
  /// In en, this message translates to:
  /// **'Imsakiya'**
  String get ramadanImsakiya;

  /// Imsakiya note.
  ///
  /// In en, this message translates to:
  /// **'Imsak is 10 minutes before Fajr. Days follow the civil Hijri calendar and may differ by a day from local moon sighting.'**
  String get ramadanImsakNote;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get ramadanColumnDay;

  /// Table column.
  ///
  /// In en, this message translates to:
  /// **'Imsak'**
  String get ramadanColumnImsak;

  /// A juz a day.
  ///
  /// In en, this message translates to:
  /// **'Ramadan khatma'**
  String get ramadanKhatma;

  /// Daily juz.
  ///
  /// In en, this message translates to:
  /// **'Today\'s portion: juz {juz}'**
  String ramadanKhatmaToday(String juz);

  /// Opens the juz.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get ramadanOpenJuz;

  /// Card title.
  ///
  /// In en, this message translates to:
  /// **'The last ten nights'**
  String get ramadanLastTen;

  /// Days until the last ten nights.
  ///
  /// In en, this message translates to:
  /// **'They begin in {days} days'**
  String ramadanLastTenIn(String days);

  /// During the last ten nights.
  ///
  /// In en, this message translates to:
  /// **'Seek Laylat al-Qadr in these nights'**
  String get ramadanLastTenNow;

  /// Outside Ramadan.
  ///
  /// In en, this message translates to:
  /// **'Ramadan is expected to begin around {date}.'**
  String ramadanNotNow(String date);

  /// Reminder section.
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get remindersRamadanSection;

  /// Reminder toggle.
  ///
  /// In en, this message translates to:
  /// **'Suhoor'**
  String get remindersSuhoor;

  /// Reminder toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'30 minutes before imsak, during Ramadan'**
  String get remindersSuhoorSubtitle;

  /// Reminder toggle.
  ///
  /// In en, this message translates to:
  /// **'Iftar'**
  String get remindersIftar;

  /// Reminder toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'At Maghrib, during Ramadan'**
  String get remindersIftarSubtitle;

  /// Notification title.
  ///
  /// In en, this message translates to:
  /// **'Time for suhoor'**
  String get reminderSuhoorTitle;

  /// Notification body.
  ///
  /// In en, this message translates to:
  /// **'Imsak is in 30 minutes.'**
  String get reminderSuhoorBody;

  /// Notification title.
  ///
  /// In en, this message translates to:
  /// **'Time to break your fast'**
  String get reminderIftarTitle;

  /// Notification body.
  ///
  /// In en, this message translates to:
  /// **'May Allah accept your fast.'**
  String get reminderIftarBody;

  /// Reader action and sheet title.
  ///
  /// In en, this message translates to:
  /// **'Reading settings'**
  String get readerAppearance;

  /// Reading setting.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get readerFontSize;

  /// Button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Smaller text'**
  String get readerSmaller;

  /// Button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Larger text'**
  String get readerLarger;

  /// Reading setting.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get readerPaper;

  /// Follows the app theme.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get readerPaperAuto;

  /// Page background.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get readerPaperLight;

  /// Page background.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get readerPaperWarm;

  /// Page background.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get readerPaperNight;

  /// Counter screen title and home shortcut.
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get tasbihTitle;

  /// Hint under the counter.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to count'**
  String get tasbihTap;

  /// Screen reader value of the counter.
  ///
  /// In en, this message translates to:
  /// **'{count} counted'**
  String tasbihCount(String count);

  /// Goal choice without a target.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get tasbihNoGoal;

  /// Resets the current round.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get tasbihReset;

  /// Today's total.
  ///
  /// In en, this message translates to:
  /// **'Today: {count}'**
  String tasbihToday(String count);

  /// Shown and announced at the goal.
  ///
  /// In en, this message translates to:
  /// **'Goal reached'**
  String get tasbihDone;

  /// Counting without a phrase.
  ///
  /// In en, this message translates to:
  /// **'Free count'**
  String get tasbihFree;

  /// Reminder section.
  ///
  /// In en, this message translates to:
  /// **'Voluntary fasting'**
  String get remindersFastingSection;

  /// Reminder toggle.
  ///
  /// In en, this message translates to:
  /// **'Mondays and Thursdays'**
  String get remindersFastMonThu;

  /// Reminder toggle.
  ///
  /// In en, this message translates to:
  /// **'The white days (13–15 of each month)'**
  String get remindersFastWhiteDays;

  /// Reminder toggle.
  ///
  /// In en, this message translates to:
  /// **'Arafah, Tasu’a and Ashura'**
  String get remindersFastOccasions;

  /// Reminder toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'The evening before, at {time}'**
  String remindersFastingSubtitle(String time);

  /// Fasting reminder title.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow is Monday'**
  String get reminderFastMonday;

  /// Fasting reminder title.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow is Thursday'**
  String get reminderFastThursday;

  /// Fasting reminder title.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow is one of the white days'**
  String get reminderFastWhiteDay;

  /// Fasting reminder title.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow is the Day of Arafah'**
  String get reminderFastArafah;

  /// Fasting reminder title.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow is Tasu’a'**
  String get reminderFastTasua;

  /// Fasting reminder title.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow is Ashura'**
  String get reminderFastAshura;

  /// Fasting reminder body.
  ///
  /// In en, this message translates to:
  /// **'A reminder for anyone who wishes to fast.'**
  String get reminderFastBody;

  /// Playback speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get playerSpeed;

  /// Stops playback after a while.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get playerSleep;

  /// Sleep timer off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get playerSleepOff;

  /// Sleep timer choice.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String playerSleepMinutes(String minutes);

  /// When the sleep timer ends.
  ///
  /// In en, this message translates to:
  /// **'Playback stops at {time}'**
  String playerSleepUntil(String time);

  /// Seek back.
  ///
  /// In en, this message translates to:
  /// **'Back 10 seconds'**
  String get playerBack;

  /// Seek forward.
  ///
  /// In en, this message translates to:
  /// **'Forward 10 seconds'**
  String get playerForward;

  /// Shares the verse as a picture.
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get readerShareImage;

  /// Opens the location picker.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get locationChange;

  /// Title when no location is set.
  ///
  /// In en, this message translates to:
  /// **'Choose your location'**
  String get locationChooseTitle;

  /// Explains why a location is needed.
  ///
  /// In en, this message translates to:
  /// **'Prayer times and the Qibla follow it, anywhere in the world.'**
  String get locationChooseHint;

  /// The place comes from GPS.
  ///
  /// In en, this message translates to:
  /// **'Your current location'**
  String get locationFromDevice;

  /// The place was picked from the list.
  ///
  /// In en, this message translates to:
  /// **'City you chose'**
  String get locationChosenCity;

  /// City search field.
  ///
  /// In en, this message translates to:
  /// **'Search for a city or country'**
  String get locationSearchHint;

  /// Empty search.
  ///
  /// In en, this message translates to:
  /// **'No city matches that name.'**
  String get locationNoResults;

  /// List header before searching.
  ///
  /// In en, this message translates to:
  /// **'Largest cities'**
  String get locationLargestWorld;

  /// City list loading.
  ///
  /// In en, this message translates to:
  /// **'Loading cities…'**
  String get locationCitiesLoading;

  /// Method follows the country.
  ///
  /// In en, this message translates to:
  /// **'Automatic for your country'**
  String get prayerMethodAuto;

  /// Method sheet title.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get prayerMethodPick;

  /// List header for the current country.
  ///
  /// In en, this message translates to:
  /// **'Cities in {country}'**
  String locationCountryCities(String country);

  /// A prayer calculation authority.
  ///
  /// In en, this message translates to:
  /// **'{method, select, egyptian{Egyptian General Authority of Survey}ummAlQura{Umm al-Qura, Makkah}dubai{Dubai}qatar{Qatar}kuwait{Kuwait}gulfRegion{Gulf region}jordan{Jordan\'s Ministry of Awqaf}morocco{Morocco\'s Ministry of Habous}algerian{Algeria\'s Ministry of Religious Affairs}tunisia{Tunisia\'s Ministry of Religious Affairs}turkiye{Diyanet, Türkiye}karachi{University of Islamic Sciences, Karachi}singapore{Singapore and Malaysia}indonesian{Indonesia\'s Ministry of Religious Affairs}northAmerica{Islamic Society of North America}moonsightingCommittee{Moonsighting Committee}france{France (12°)}russia{Spiritual Administration of Muslims of Russia}muslimWorldLeague{Muslim World League}other{Muslim World League}}'**
  String prayerMethodName(String method);

  /// Header above the main hadith topics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get hadithTopicsTitle;

  /// Header above a topic's subtopics.
  ///
  /// In en, this message translates to:
  /// **'Subtopics'**
  String get hadithSubtopics;

  /// Benefits section.
  ///
  /// In en, this message translates to:
  /// **'Lessons from the hadith'**
  String get hadithBenefits;

  /// Glossary section.
  ///
  /// In en, this message translates to:
  /// **'Word meanings'**
  String get hadithWords;

  /// Translated text heading.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get hadithTranslation;

  /// Copies the hadith.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get hadithCopy;

  /// After copying.
  ///
  /// In en, this message translates to:
  /// **'Hadith copied'**
  String get hadithCopied;

  /// Shares the hadith.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get hadithShare;

  /// Opens the publisher page.
  ///
  /// In en, this message translates to:
  /// **'View on HadeethEnc'**
  String get hadithOpenSource;

  /// Credits the publisher.
  ///
  /// In en, this message translates to:
  /// **'From the Encyclopedia of Translated Prophetic Hadiths (HadeethEnc)'**
  String get hadithSourceNote;

  /// Paging error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more hadiths.'**
  String get hadithLoadMoreFailed;

  /// Topic search field.
  ///
  /// In en, this message translates to:
  /// **'Search topics, e.g. prayer, fasting, manners'**
  String get hadithSearchHint;

  /// How many hadiths a topic has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hadith} other{{countText} hadiths}}'**
  String hadithCount(String countText, int count);

  /// Opens every hadith of a topic.
  ///
  /// In en, this message translates to:
  /// **'All hadiths in “{topic}”'**
  String hadithAllIn(String topic);

  /// Place of a hadith in its list.
  ///
  /// In en, this message translates to:
  /// **'{index} of {total}'**
  String hadithPosition(String index, String total);

  /// Stories page intro.
  ///
  /// In en, this message translates to:
  /// **'The prophets\' stories, peace be upon them, to listen to or watch, in order from Adam.'**
  String get learningStoriesIntro;

  /// Downloads every story.
  ///
  /// In en, this message translates to:
  /// **'Download all stories'**
  String get learningDownloadAllStories;

  /// Both formats.
  ///
  /// In en, this message translates to:
  /// **'Audio and video'**
  String get learningAudioAndVideo;

  /// Marks the playing episode.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get learningNowPlaying;

  /// Enters full-screen video.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get learningFullscreen;

  /// Leaves full-screen video.
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get learningExitFullscreen;

  /// Episode menu.
  ///
  /// In en, this message translates to:
  /// **'Episode options'**
  String get learningEpisodeOptions;

  /// Story without episodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes coming soon'**
  String get learningSoon;

  /// Download size.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String learningFileSize(String size);

  /// Reciter sheet title.
  ///
  /// In en, this message translates to:
  /// **'Reciter'**
  String get recitationReciter;

  /// Reciter search.
  ///
  /// In en, this message translates to:
  /// **'Search reciters'**
  String get recitationSearchReciter;

  /// Short radio shortcut label.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get homeRadio;

  /// Prayer settings header.
  ///
  /// In en, this message translates to:
  /// **'Calculation'**
  String get prayerSettingsTitle;

  /// Timetable navigation.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get prayerPreviousDay;

  /// Timetable navigation.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get prayerNextDay;

  /// Today's timetable.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get prayerToday;

  /// Marks the next prayer.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get prayerNextBadge;

  /// Bearing stat.
  ///
  /// In en, this message translates to:
  /// **'Qibla angle'**
  String get qiblaAngle;

  /// Distance stat.
  ///
  /// In en, this message translates to:
  /// **'To Makkah'**
  String get qiblaDistanceLabel;

  /// Heading stat.
  ///
  /// In en, this message translates to:
  /// **'Phone heading'**
  String get qiblaPhoneLabel;

  /// Distance.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String qiblaKilometres(String km);

  /// Library grid header.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get libraryBrowse;

  /// Live radio badge.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get libraryLive;

  /// Khatma card title.
  ///
  /// In en, this message translates to:
  /// **'Khatma goal'**
  String get khatmaGoalTitle;

  /// Khatma hint.
  ///
  /// In en, this message translates to:
  /// **'Choose how many days to finish the Quran in; the daily wird follows.'**
  String get khatmaGoalHint;

  /// Removes the goal.
  ///
  /// In en, this message translates to:
  /// **'Remove goal'**
  String get khatmaCancel;

  /// Done for today.
  ///
  /// In en, this message translates to:
  /// **'Today\'s share is done. May Allah bless you.'**
  String get khatmaTodayDone;

  /// No streak.
  ///
  /// In en, this message translates to:
  /// **'Read a page today to start a streak'**
  String get khatmaNoStreak;

  /// A number of days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{n} days}}'**
  String khatmaDays(String n, int count);

  /// Reading streak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day in a row} other{{n} days in a row}}'**
  String khatmaStreak(String n, int count);

  /// Goal end date.
  ///
  /// In en, this message translates to:
  /// **'You finish on {date}'**
  String khatmaEndsOn(String date);

  /// Today's share.
  ///
  /// In en, this message translates to:
  /// **'Today: {target} pages · read {read}'**
  String khatmaToday(String target, String read);

  /// Amber on brown page.
  ///
  /// In en, this message translates to:
  /// **'Warm night'**
  String get readerPaperAmber;

  /// Enters full-screen reading.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get readerFullscreen;

  /// Leaves full-screen reading.
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get readerExitFullscreen;

  /// Opens app search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// Search field.
  ///
  /// In en, this message translates to:
  /// **'Search the Quran, adhkar, hadith…'**
  String get searchHint;

  /// Search intro.
  ///
  /// In en, this message translates to:
  /// **'Search surahs and verses, adhkar, hadith topics and the app\'s sections, even without internet. Type 2:255 to open a verse.'**
  String get searchIntro;

  /// Suggestions header.
  ///
  /// In en, this message translates to:
  /// **'Try'**
  String get searchTry;

  /// No results.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches that. Try another word.'**
  String get searchNoResults;

  /// Sections header.
  ///
  /// In en, this message translates to:
  /// **'In the app'**
  String get searchSections;

  /// Surahs header.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get searchSurahs;

  /// Verses header.
  ///
  /// In en, this message translates to:
  /// **'Verses'**
  String get searchVerses;

  /// Hadith header.
  ///
  /// In en, this message translates to:
  /// **'Hadith topics'**
  String get searchHadithTopics;

  /// Count.
  ///
  /// In en, this message translates to:
  /// **'{count} verses'**
  String searchVerseCount(String count);

  /// Count.
  ///
  /// In en, this message translates to:
  /// **'Show all {count}'**
  String searchShowAll(String count);

  /// Memorization.
  ///
  /// In en, this message translates to:
  /// **'Memorize'**
  String get memorizeTitle;

  /// Memorize intro.
  ///
  /// In en, this message translates to:
  /// **'Choose a surah and a range, repeat each verse, then hide the text and recite it from memory.'**
  String get memorizeIntro;

  /// Surah search.
  ///
  /// In en, this message translates to:
  /// **'Find a surah'**
  String get memorizeFindSurah;

  /// Range start.
  ///
  /// In en, this message translates to:
  /// **'From verse'**
  String get memorizeFrom;

  /// Range end.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get memorizeTo;

  /// Full text.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get memorizeShow;

  /// Prompt only.
  ///
  /// In en, this message translates to:
  /// **'First word'**
  String get memorizeFirstWord;

  /// Hidden text.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get memorizeHide;

  /// Repeat target.
  ///
  /// In en, this message translates to:
  /// **'Repeat each verse'**
  String get memorizeRepeatEach;

  /// Reveal hint.
  ///
  /// In en, this message translates to:
  /// **'Recite it, then tap to check'**
  String get memorizeTapToReveal;

  /// Mark memorized.
  ///
  /// In en, this message translates to:
  /// **'Memorized'**
  String get memorizeDone;

  /// Bulk mark.
  ///
  /// In en, this message translates to:
  /// **'Mark the range memorized'**
  String get memorizeMarkRange;

  /// Bulk clear.
  ///
  /// In en, this message translates to:
  /// **'Clear the range'**
  String get memorizeClearRange;

  /// Progress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} verses memorized'**
  String memorizeOverall(String done, String total);

  /// Progress.
  ///
  /// In en, this message translates to:
  /// **'Repeated {count} of {target}'**
  String memorizeRepeated(String count, String target);

  /// Statistics screen.
  ///
  /// In en, this message translates to:
  /// **'My statistics'**
  String get statsTitle;

  /// Privacy note.
  ///
  /// In en, this message translates to:
  /// **'Worked out from what this phone keeps; nothing is sent anywhere.'**
  String get statsPrivate;

  /// Section.
  ///
  /// In en, this message translates to:
  /// **'Quran reading'**
  String get statsReading;

  /// Tile.
  ///
  /// In en, this message translates to:
  /// **'pages today'**
  String get statsToday;

  /// Tile.
  ///
  /// In en, this message translates to:
  /// **'pages this week'**
  String get statsWeek;

  /// Tile.
  ///
  /// In en, this message translates to:
  /// **'pages in 30 days'**
  String get statsMonth;

  /// Tile.
  ///
  /// In en, this message translates to:
  /// **'days in a row'**
  String get statsStreak;

  /// Tile.
  ///
  /// In en, this message translates to:
  /// **'best streak'**
  String get statsBestStreak;

  /// Tile.
  ///
  /// In en, this message translates to:
  /// **'of the khatma'**
  String get statsKhatma;

  /// Heat strip.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get statsLast30;

  /// Section.
  ///
  /// In en, this message translates to:
  /// **'Memorization'**
  String get statsMemorize;

  /// Tile.
  ///
  /// In en, this message translates to:
  /// **'verses memorized'**
  String get statsVerses;

  /// Tile.
  ///
  /// In en, this message translates to:
  /// **'surahs started'**
  String get statsSurahsStarted;

  /// Section.
  ///
  /// In en, this message translates to:
  /// **'Remembrance'**
  String get statsRemembrance;

  /// Tile.
  ///
  /// In en, this message translates to:
  /// **'days with adhkar (30)'**
  String get statsAdhkarDays;

  /// Tile.
  ///
  /// In en, this message translates to:
  /// **'tasbih today'**
  String get statsTasbihToday;

  /// Tile.
  ///
  /// In en, this message translates to:
  /// **'tasbih in all'**
  String get statsTasbihTotal;

  /// Zakat screen.
  ///
  /// In en, this message translates to:
  /// **'Zakat calculator'**
  String get zakatTitle;

  /// Library tile.
  ///
  /// In en, this message translates to:
  /// **'An estimate for money, gold and trade'**
  String get zakatSubtitle;

  /// Missing price.
  ///
  /// In en, this message translates to:
  /// **'Enter the price of a gram to work out the nisab'**
  String get zakatNeedPrice;

  /// Result label.
  ///
  /// In en, this message translates to:
  /// **'Zakat due (2.5%)'**
  String get zakatDue;

  /// Result label.
  ///
  /// In en, this message translates to:
  /// **'Below the nisab: no zakat due'**
  String get zakatBelowNisab;

  /// Group.
  ///
  /// In en, this message translates to:
  /// **'Today\'s prices and nisab'**
  String get zakatPrices;

  /// Basis.
  ///
  /// In en, this message translates to:
  /// **'Gold nisab (85 g)'**
  String get zakatBasisGold;

  /// Basis.
  ///
  /// In en, this message translates to:
  /// **'Silver nisab (595 g)'**
  String get zakatBasisSilver;

  /// Field.
  ///
  /// In en, this message translates to:
  /// **'Price of 1 g of 24k gold'**
  String get zakatGoldPrice;

  /// Field.
  ///
  /// In en, this message translates to:
  /// **'Price of 1 g of silver'**
  String get zakatSilverPrice;

  /// Group.
  ///
  /// In en, this message translates to:
  /// **'What you own'**
  String get zakatAssets;

  /// Field.
  ///
  /// In en, this message translates to:
  /// **'Cash and bank balances'**
  String get zakatCash;

  /// Hint.
  ///
  /// In en, this message translates to:
  /// **'Held for a full lunar year'**
  String get zakatCashHint;

  /// Field.
  ///
  /// In en, this message translates to:
  /// **'Silver (grams)'**
  String get zakatSilver;

  /// Field.
  ///
  /// In en, this message translates to:
  /// **'Trade goods'**
  String get zakatTrade;

  /// Hint.
  ///
  /// In en, this message translates to:
  /// **'At today\'s selling value'**
  String get zakatTradeHint;

  /// Field.
  ///
  /// In en, this message translates to:
  /// **'Money owed to you, expected back'**
  String get zakatOwed;

  /// Group.
  ///
  /// In en, this message translates to:
  /// **'What you owe'**
  String get zakatLiabilities;

  /// Field.
  ///
  /// In en, this message translates to:
  /// **'Debts due now'**
  String get zakatDebts;

  /// Hint.
  ///
  /// In en, this message translates to:
  /// **'Deducted from your wealth'**
  String get zakatDebtsHint;

  /// Disclaimer.
  ///
  /// In en, this message translates to:
  /// **'A simplified estimate, not a fatwa. Scholars differ on details such as worn jewellery and the nisab; ask a scholar you trust about your case. Nothing you type is saved.'**
  String get zakatDisclaimer;

  /// Zakat.
  ///
  /// In en, this message translates to:
  /// **'Zakatable wealth: {amount}'**
  String zakatWealth(String amount);

  /// Zakat.
  ///
  /// In en, this message translates to:
  /// **'Nisab: {amount}'**
  String zakatNisab(String amount);

  /// Zakat.
  ///
  /// In en, this message translates to:
  /// **'Gold {karat}k (grams)'**
  String zakatGold(String karat);

  /// Countdown label.
  ///
  /// In en, this message translates to:
  /// **'Time left'**
  String get prayerRemaining;

  /// Relative prayer time.
  ///
  /// In en, this message translates to:
  /// **'in {time}'**
  String prayerIn(String time);

  /// Relative prayer time.
  ///
  /// In en, this message translates to:
  /// **'{time} ago'**
  String prayerSince(String time);

  /// Offline banner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Saved content still works.'**
  String get offlineBanner;

  /// Settings row.
  ///
  /// In en, this message translates to:
  /// **'Error report'**
  String get errorReportTitle;

  /// No errors.
  ///
  /// In en, this message translates to:
  /// **'No errors recorded'**
  String get errorReportNone;

  /// Privacy note.
  ///
  /// In en, this message translates to:
  /// **'Kept on this phone only. Share it with the developer if you want; nothing is sent by itself.'**
  String get errorReportPrivacy;

  /// Share.
  ///
  /// In en, this message translates to:
  /// **'Share the report'**
  String get errorReportShare;

  /// Clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get errorReportClear;

  /// Error count.
  ///
  /// In en, this message translates to:
  /// **'{count} recorded on this phone'**
  String errorReportCount(String count);

  /// Downloads tab.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get downloadsStoriesTab;

  /// Downloads tab.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get downloadsLibraryTab;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
