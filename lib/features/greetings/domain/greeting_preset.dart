class GreetingPreset {
  final String id;
  final String title;
  final String text;
  final String language;
  final String assignedGroup; // 'All Callers', 'Family', 'Work', 'College'

  const GreetingPreset({
    required this.id,
    required this.title,
    required this.text,
    this.language = 'English (India)',
    this.assignedGroup = 'All Callers',
  });

  static List<GreetingPreset> defaultPresets = const [
    GreetingPreset(
      id: 'preset_general',
      title: 'General (Danish K)',
      text:
          'Hi, Danish here. I can\'t take your call right now. Please WhatsApp or SMS me. Thanks!',
      language: 'English (India)',
      assignedGroup: 'All Callers',
    ),
    GreetingPreset(
      id: 'preset_meeting',
      title: 'In a Meeting',
      text:
          'Hi, you have reached Danish K. I am currently in a meeting. Please leave a message or send a WhatsApp. Thank you.',
      language: 'English (India)',
      assignedGroup: 'Work',
    ),
    GreetingPreset(
      id: 'preset_driving',
      title: 'Driving / Commuting',
      text:
          'Hey, Danish here. Currently driving and cannot take your call. Please text me on WhatsApp.',
      language: 'English (India)',
      assignedGroup: 'All Callers',
    ),
    GreetingPreset(
      id: 'preset_sleeping',
      title: 'Sleeping / Quiet Hours',
      text:
          'Hi, Danish is resting right now. For emergencies, please call back within 3 minutes.',
      language: 'English (India)',
      assignedGroup: 'All Callers',
    ),
    GreetingPreset(
      id: 'preset_hindi',
      title: 'नमस्ते (Hindi Greeting)',
      text:
          'नमस्ते, आप दानिश के फोन पर कॉल कर रहे हैं। अभी बात नहीं हो पाएगी, कृपया व्हाट्सएप पर मैसेज भेजें। धन्यवाद।',
      language: 'Hindi',
      assignedGroup: 'All Callers',
    ),
    GreetingPreset(
      id: 'preset_malayalam',
      title: 'നമസ്കാരം (Malayalam Greeting)',
      text:
          'നമസ്കാരം, ഡാനിഷിന്റെ ഫോണിലേക്കാണ് നിങ്ങൾ വിളിക്കുന്നത്. ഇപ്പോൾ സംസാരിക്കാൻ സാധിക്കില്ല, ദയവായി വാട്ട്സാപ്പിൽ സന്ദേശം അയക്കൂ.',
      language: 'Malayalam',
      assignedGroup: 'All Callers',
    ),
  ];
}

