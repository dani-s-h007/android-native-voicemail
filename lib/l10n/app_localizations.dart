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
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('de'), // German
    Locale('hi'), // Hindi
    Locale('ml'), // Malayalam
  ];

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Voicemail Assistant',
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
    'es': {
      'app_name': 'Asistente de Buzón de Voz',
      'tab_voicemail': 'Buzón de Voz',
      'tab_modes': 'Modos',
      'tab_greetings': 'Saludos',
      'tab_settings': 'Ajustes',
      'inbox_zero': 'Bandeja Vacía',
      'call_back': 'Devolver llamada',
      'copy_text': 'Copiar texto',
      'share': 'Compartir',
      'delete': 'Eliminar',
      'star': 'Destacar',
      'active': 'Activo',
      'paused': 'Pausado',
      'save': 'Guardar',
    },
    'fr': {
      'app_name': 'Assistant Messagerie Vocale',
      'tab_voicemail': 'Messagerie',
      'tab_modes': 'Modes',
      'tab_greetings': 'Annonces',
      'tab_settings': 'Paramètres',
      'inbox_zero': 'Boîte de réception vide',
      'call_back': 'Rappeler',
      'copy_text': 'Copier le texte',
      'share': 'Partager',
      'delete': 'Supprimer',
      'star': 'Favori',
      'active': 'Actif',
      'paused': 'En pause',
      'save': 'Enregistrer',
    },
    'de': {
      'app_name': 'Mailbox-Assistent',
      'tab_voicemail': 'Mailbox',
      'tab_modes': 'Modi',
      'tab_greetings': 'Ansagen',
      'tab_settings': 'Einstellungen',
      'inbox_zero': 'Keine Nachrichten',
      'call_back': 'Zurückrufen',
      'copy_text': 'Text kopieren',
      'share': 'Teilen',
      'delete': 'Löschen',
      'star': 'Markieren',
      'active': 'Aktiv',
      'paused': 'Pausiert',
      'save': 'Speichern',
    },
    'hi': {
      'app_name': 'वॉयसमेल सहायक',
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
      'app_name': 'വോയ്സ്മെയിൽ അസിസ്റ്റന്റ്',
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
  };

  String get appName => _localizedValues[locale.languageCode]?['app_name'] ?? 'Voicemail Assistant';
  String get tabVoicemail => _localizedValues[locale.languageCode]?['tab_voicemail'] ?? 'Voicemail';
  String get tabModes => _localizedValues[locale.languageCode]?['tab_modes'] ?? 'Modes';
  String get tabGreetings => _localizedValues[locale.languageCode]?['tab_greetings'] ?? 'Greetings';
  String get tabSettings => _localizedValues[locale.languageCode]?['tab_settings'] ?? 'Settings';
  String get inboxZero => _localizedValues[locale.languageCode]?['inbox_zero'] ?? 'Inbox Zero';
  String get callBack => _localizedValues[locale.languageCode]?['call_back'] ?? 'Call Back';
  String get copyText => _localizedValues[locale.languageCode]?['copy_text'] ?? 'Copy Text';
  String get share => _localizedValues[locale.languageCode]?['share'] ?? 'Share';
  String get delete => _localizedValues[locale.languageCode]?['delete'] ?? 'Delete';
  String get star => _localizedValues[locale.languageCode]?['star'] ?? 'Star';
  String get active => _localizedValues[locale.languageCode]?['active'] ?? 'Active';
  String get paused => _localizedValues[locale.languageCode]?['paused'] ?? 'Paused';
  String get save => _localizedValues[locale.languageCode]?['save'] ?? 'Save';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((e) => e.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
