import 'package:flutter/material.dart';

// All UI string translations. Access via AppStrings.of(context).key
// Translations sourced from the design file (language-screens.jsx / STR.ur).
class AppStrings {
  final bool isUrdu;
  const AppStrings._(this.isUrdu);

  factory AppStrings.of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return AppStrings._(code == 'ur');
  }

  String _t(String en, String ur) => isUrdu ? ur : en;

  // ── Tab bar ──────────────────────────────────────────────────
  String get tabHome => _t('Home', 'ابتدا');
  String get tabRead => _t('Read', 'مطالعہ');
  String get tabSelf => _t('Self', 'ترتیبات');

  // ── Settings screen ──────────────────────────────────────────
  String get settings => _t('Settings', 'ترتیبات');
  String get sectionAccount => _t('ACCOUNT', 'اکاؤنٹ');
  String get sectionPractice => _t('PRACTICE', 'مشق');
  String get sectionTradition => _t('TRADITION', 'مذہب');
  String get sectionTexts => _t('TEXTS', 'متون');
  String get sectionAppearance => _t('APPEARANCE', 'ظاہری شکل');
  String get sectionGeneral => _t('GENERAL', 'عمومی');
  String get sectionDeveloper => _t('DEVELOPER', 'ڈویلپر');
  String get sectionAbout => _t('ABOUT', 'تعارف');
  String get editProfile => _t('Edit profile', 'پروفائل ترمیم کریں');
  String get signOut => _t('Sign out', 'سائن آؤٹ');
  String get readingPlan => _t('Reading plan', 'مطالعہ کا منصوبہ');
  String get chooseTexts => _t('Choose texts', 'متون منتخب کریں');
  String get darkMode => _t('Dark mode', 'ڈارک موڈ');
  String get language => _t('Language', 'زبان');
  String get languageCurrentValue => _t('English', 'اردو');
  String get meetTheTeam => _t('Meet the team', 'بنانے والے');
  String get reportAnIssue => _t('Report an issue', 'مسئلہ بتائیں');
  String get version => _t('Version', 'ورژن');
  String religions(int count) => _t('$count religions', '$count مذاہب');
  String get noTraditionSelected => _t('No tradition selected', 'کوئی مذہب منتخب نہیں');
  String get guest => _t('Guest', 'مہمان');

  // ── Language sheet ────────────────────────────────────────────
  String get chooseLanguage => _t('Choose language', 'زبان منتخب کریں');
  String get languageSheetNote => _t(
    'You can change this any time in Settings.',
    'آپ کسی بھی وقت ترتیبات سے یہ بدل سکتے ہیں۔',
  );
  String get cancel => _t('Cancel', 'منسوخ');
  String get done => _t('Done', 'مکمل');

  // ── Onboarding language screen (always English — user hasn't picked yet) ──
  static const onboardStep1 = 'STEP 1 OF 3';
  static const onboardLangTitle = 'Choose your\nlanguage';
  static const onboardLangSub = 'You can change this later from Settings.';
  static const onboardContinue = 'Continue';

  // ── Onboarding religion screen ────────────────────────────────
  String get onboardStep2 => _t('STEP · 02 OF 03', '۲ از ۳');
  String get onboardTradTitle => _t('Which path\nguides you?', 'آپ کس مذہب سے\nتعلق رکھتے ہیں؟');
  String get onboardTradSub => _t(
    'Pick a tradition — or open the dialogue across all of them.',
    'ہم اسی مطابق آپ کی شخصیت، آیت اور مطالعے کا منصوبہ ترتیب دیں گے۔',
  );
  String get continueBtn => _t('Continue', 'جاری رکھیں');

  // Religion names and scripture subtitles (for tradition cards)
  String religionName(String id, String fallback) {
    if (!isUrdu) return fallback;
    switch (id) {
      case 'islam': return 'اسلام';
      case 'hinduism': return 'ہندو مت';
      case 'sikhism': return 'سکھ مت';
      case 'christianity': return 'مسیحیت';
      default: return fallback;
    }
  }

  String religionScripture(String id) {
    if (!isUrdu) return '';
    switch (id) {
      case 'islam': return 'القرآن الکریم';
      case 'hinduism': return 'بھگوت گیتا';
      case 'sikhism': return 'گرو گرنتھ صاحب';
      case 'christianity': return 'انجیل مقدس';
      default: return '';
    }
  }

  // ── Home screen ───────────────────────────────────────────────
  String get verseToday => _t('VERSE FOR TODAY', 'آج کی آیت');
  String get askAnything => _t('Ask anything…', 'کچھ بھی پوچھیں…');
  String get continueReading => _t("Continue today's reading", 'آج کا مطالعہ جاری رکھیں');
  String get today => _t('TODAY', 'آج');
  String get streakDays => _t('DAY STREAK', 'دن مسلسل');
  String greetingName(String name) => _t('Welcome, $name', 'خوش آمدید، $name');

  // ── Library screen ────────────────────────────────────────────
  String get library => _t('LIBRARY', 'لائبریری');
  String get primaryText => _t('PRIMARY TEXT', 'بنیادی متن');
  String get otherTexts => _t('OTHER TEXTS', 'دیگر متون');

  // ── Chat screen ───────────────────────────────────────────────
  String get typeMessage => _t('Ask anything…', 'کچھ بھی پوچھیں…');
  String get thinking => _t('Thinking…', 'سوچ رہا ہوں…');
  String get newChat => _t('New conversation', 'نئی گفتگو');

  // ── History screen ────────────────────────────────────────────
  String get history => _t('History', 'تاریخ');
  String get noHistory => _t('No conversations yet', 'ابھی تک کوئی گفتگو نہیں');

  // ── Sign-in screen ────────────────────────────────────────────
  String get signIn => _t('Sign in', 'سائن ان');
  String get continueWithGoogle => _t('Continue with Google', 'گوگل سے جاری رکھیں');
  String get continueWithApple => _t('Continue with Apple', 'ایپل سے جاری رکھیں');
  String get continueAsGuest => _t('Continue as guest', 'مہمان کے طور پر جاری رکھیں');

  // ── Profile setup ─────────────────────────────────────────────
  String get tellUsAboutYou => _t('Tell us about yourself', 'اپنے بارے میں بتائیں');
  String get firstName => _t('First name', 'پہلا نام');
  String get lastName => _t('Last name', 'آخری نام');
  String get age => _t('Age', 'عمر');
  String get save => _t('Save', 'محفوظ کریں');
  String get skip => _t('Skip', 'چھوڑیں');

  // ── Report issue ──────────────────────────────────────────────
  String get reportIssue => _t('Report an issue', 'مسئلہ بتائیں');
  String get submit => _t('Submit', 'جمع کریں');

  // ── Developers screen ─────────────────────────────────────────
  String get developers => _t('Developers', 'بنانے والے');
  String get meetTheTeamTitle => _t('Meet the team', 'ٹیم سے ملیں');

  // ── Reading plans ─────────────────────────────────────────────
  String get readingPlans => _t('Reading Plans', 'مطالعے کے منصوبے');
}
