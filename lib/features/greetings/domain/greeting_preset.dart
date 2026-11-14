class GreetingPreset {
  final String id;
  final String title;
  final String text;
  final String language;
  final String assignedGroup; // 'All Callers', 'Work & Clients', 'Family & VIP', 'Unknown / Spam'

  const GreetingPreset({
    required this.id,
    required this.title,
    required this.text,
    this.language = 'English',
    this.assignedGroup = 'All Callers',
  });

  static List<GreetingPreset> defaultPresets = const [
    GreetingPreset(
      id: 'preset_general',
      title: 'General (Default)',
      text:
          'Hello. I am unavailable to take your call right now. Please leave a voicemail after the tone or send a text message. Thank you.',
      language: 'English',
      assignedGroup: 'All Callers',
    ),
    GreetingPreset(
      id: 'preset_meeting',
      title: 'In a Meeting',
      text:
          'Hello, I am currently in a meeting and cannot take your call. Please leave a message or send a text and I will respond as soon as possible.',
      language: 'English',
      assignedGroup: 'Work & Clients',
    ),
    GreetingPreset(
      id: 'preset_driving',
      title: 'Driving / Commuting',
      text:
          'I am currently driving and cannot safely answer the phone. Please leave a voicemail or text me. Thank you.',
      language: 'English',
      assignedGroup: 'All Callers',
    ),
    GreetingPreset(
      id: 'preset_sleeping',
      title: 'Sleeping / Rest',
      text:
          'I am currently resting and unavailable. If this is an emergency, please repeat your call or leave a voicemail.',
      language: 'English',
      assignedGroup: 'All Callers',
    ),
    GreetingPreset(
      id: 'preset_traveling',
      title: 'Traveling / Away',
      text:
          'I am currently traveling with limited connectivity. Please leave a voicemail or email, and I will get back to you shortly.',
      language: 'English',
      assignedGroup: 'All Callers',
    ),
    GreetingPreset(
      id: 'preset_custom',
      title: 'Custom Template',
      text:
          'Hello, this is {name}. I cannot take your call right now. Please leave a message after the tone and I will get back to you by {time_back}.',
      language: 'English',
      assignedGroup: 'All Callers',
    ),
    GreetingPreset(
      id: 'preset_hindi',
      title: 'Hindi',
      text:
          'नमस्ते। मैं अभी आपकी कॉल का उत्तर देने में असमर्थ हूँ। कृपया बीप के बाद अपना संदेश छोड़ें या संदेश भेजें। धन्यवाद।',
      language: 'Hindi',
      assignedGroup: 'All Callers',
    ),
    GreetingPreset(
      id: 'preset_malayalam',
      title: 'Malayalam',
      text:
          'നമസ്കാരം. എനിക്ക് ഇപ്പോൾ നിങ്ങളുടെ കോളിന് മറുപടി നൽകാൻ സാധിക്കില്ല. ദയവായി സന്ദേശം നൽകുക. നന്ദി.',
      language: 'Malayalam',
      assignedGroup: 'All Callers',
    ),
    GreetingPreset(
      id: 'preset_spanish',
      title: 'Spanish',
      text:
          'Hola. No puedo responder su llamada en este momento. Por favor deje un mensaje después del tono o envíe un mensaje de texto. Gracias.',
      language: 'Spanish',
      assignedGroup: 'All Callers',
    ),
  ];
}
