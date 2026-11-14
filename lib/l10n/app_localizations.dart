import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('ml'), // Malayalam
    Locale('ta'), // Tamil
    Locale('te'), // Telugu
    Locale('kn'), // Kannada
  ];

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Vani Voicemail',
      'tab_voicemail': 'Voicemail',
      'tab_modes': 'Modes',
      'tab_greetings': 'Greetings',
      'tab_settings': 'Settings',
      'inbox_zero': 'Inbox Zero',
      'call_back': 'Call Back',
      'copy_text': 'Copy Text',
      'share': 'Share',
      'delete': 'Delete',
      'star': 'Star',
      'active': 'Active',
      'paused': 'Paused',
      'save': 'Save',
    },
    'hi': {
      'app_name': 'वाणी वॉयसमेल',
      'tab_voicemail': 'वॉयसमेल',
      'tab_modes': 'मोड्स',
      'tab_greetings': 'अभिवादन',
      'tab_settings': 'सेटिंग्स',
      'inbox_zero': 'कोई नया संदेश नहीं',
      'call_back': 'कॉल बैक',
      'copy_text': 'कॉपी करें',
      'share': 'शेयर',
      'delete': 'हटाएं',
      'star': 'स्टार',
      'active': 'सक्रिय',
      'paused': 'रोका गया',
      'save': 'सहेजें',
    },
    'ml': {
      'app_name': 'വാണി വോയ്സ്മെയിൽ',
      'tab_voicemail': 'വോയ്സ്മെയിൽ',
      'tab_modes': 'മോഡുകൾ',
      'tab_greetings': 'ഗ്രീറ്റിങ്സ്',
      'tab_settings': 'ക്രമീകരണങ്ങൾ',
      'inbox_zero': 'പുതിയ സന്ദേശങ്ങളൊന്നുമില്ല',
      'call_back': 'തിരികെ വിളിക്കുക',
      'copy_text': 'പകർത്തുക',
      'share': 'പങ്കുവെക്കുക',
      'delete': 'ഡിലീറ്റ്',
      'star': 'സ്റ്റാർ',
      'active': 'സജീവം',
      'paused': 'താൽക്കാലികമായി നിർത്തി',
      'save': 'സേവ് ചെയ്യുക',
    },
    'ta': {
      'app_name': 'வாணி குரலஞ்சல்',
      'tab_voicemail': 'குரலஞ்சல்',
      'tab_modes': 'முறைகள்',
      'tab_greetings': 'வாழ்த்துகள்',
      'tab_settings': 'அமைப்புகள்',
      'inbox_zero': 'புதிய செய்திகள் இல்லை',
      'call_back': 'மீண்டும் அழைக்கவும்',
      'copy_text': 'நகலெடு',
      'share': 'பகிர்',
      'delete': 'நீக்கு',
      'star': 'நட்சத்திரம்',
      'active': 'செயலில் உள்ளது',
      'paused': 'இடைநிறுத்தப்பட்டது',
      'save': 'சேமி',
    },
    'te': {
      'app_name': 'వాణి వాయిస్మెయిల్',
      'tab_voicemail': 'వాయిస్మెయిల్',
      'tab_modes': 'మోడ్లు',
      'tab_greetings': 'గ్రీటింగ్స్',
      'tab_settings': 'సెట్టింగ్‌లు',
      'inbox_zero': 'కొత్త సందేశాలు లేవు',
      'call_back': 'తిరిగి కాల్ చేయండి',
      'copy_text': 'కాపీ చేయండి',
      'share': 'షేర్',
      'delete': 'తొలగించు',
      'star': 'స్టార్',
      'active': 'యాక్టివ్',
      'paused': 'పాజ్ చేయబడింది',
      'save': 'సేవ్ చేయండి',
    },
    'kn': {
      'app_name': 'ವಾಣಿ ಧ್ವನಿಮೇಲ್',
      'tab_voicemail': 'ಧ್ವನಿಮೇಲ್',
      'tab_modes': 'ಮೋಡ್‌ಗಳು',
      'tab_greetings': 'ಶುಭಾಶಯಗಳು',
      'tab_settings': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
      'inbox_zero': 'ಯಾವುದೇ ಸಂದೇಶಗಳಿಲ್ಲ',
      'call_back': 'ಮರಳಿ ಕರೆ ಮಾಡಿ',
      'copy_text': 'ನಕಲಿಸಿ',
      'share': 'ಹಂಚಿಕೊಳ್ಳಿ',
      'delete': 'ಅಳಿಸಿ',
      'star': 'ಸ್ಟಾರ್',
      'active': 'ಸಕ್ರಿಯ',
      'paused': 'ವಿರಾಮಗೊಳಿಸಲಾಗಿದೆ',
      'save': 'ಉಳಿಸಿ',
    },
  };

  String translate(String key) {
    final lang = locale.languageCode;
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }

  String get appName => translate('app_name');
  String get tabVoicemail => translate('tab_voicemail');
  String get tabModes => translate('tab_modes');
  String get tabGreetings => translate('tab_greetings');
  String get tabSettings => translate('tab_settings');
  String get inboxZero => translate('inbox_zero');
  String get callBack => translate('call_back');
  String get copyText => translate('copy_text');
  String get share => translate('share');
  String get delete => translate('delete');
  String get star => translate('star');
  String get active => translate('active');
  String get paused => translate('paused');
  String get save => translate('save');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'ml', 'ta', 'te', 'kn'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

