import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';

class DndPreset {
  final String id;
  final String title;
  final Map<String, String> defaultMessages;

  const DndPreset({
    required this.id,
    required this.title,
    required this.defaultMessages,
  });
}

class TtsService {
  static final TtsService instance = TtsService._internal();
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en-IN', 'name': 'English (India)'},
    {'code': 'hi-IN', 'name': 'Hindi (हिन्दी)'},
    {'code': 'ta-IN', 'name': 'Tamil (தமிழ்)'},
    {'code': 'te-IN', 'name': 'Telugu (తెలుగు)'},
    {'code': 'ml-IN', 'name': 'Malayalam (മലയാളം)'},
    {'code': 'kn-IN', 'name': 'Kannada (ಕನ್ನಡ)'},
  ];

  static const List<DndPreset> presets = [
    DndPreset(
      id: 'meeting',
      title: 'Meeting',
      defaultMessages: {
        'en-IN': "Hi, I am currently in a meeting and cannot take your call. Please leave a message after the beep. This call is recorded.",
        'hi-IN': "नमस्ते, मैं अभी एक मीटिंग में हूँ और कॉल नहीं उठा सकता। कृपया बीप के बाद संदेश छोड़ें। यह कॉल रिकॉर्ड की जाती है।",
        'ta-IN': "வணக்கம், நான் இப்போது ஒரு சந்திப்பில் இருக்கிறேன். பீப் ஒலிக்குப் பிறகு செய்தி விடவும். இந்த அழைப்பு பதிவு செய்யப்படுகிறது.",
        'te-IN': "నమస్కారం, నేను ప్రస్తుతం సమావేశంలో ఉన్నాను. దయచేసి బీప్ తర్వాత సందేశం ఇవ్వండి. ఈ కాల్ రికార్డ్ చేయబడుతుంది.",
        'ml-IN': "നമസ്കാരം, ഞാൻ ഇപ്പോൾ ഒരു മീറ്റിംഗിലാണ്. ബീപ്പ് ശബ്ദത്തിന് ശേഷം സന്ദേശം നൽകുക. ഈ കോൾ റെക്കോർഡ് ചെയ്യപ്പെടുന്നുണ്ട്.",
        'kn-IN': "ನಮಸ್ಕಾರ, ನಾನು ಪ್ರಸ್ತುತ ಸಭೆಯಲ್ಲಿದ್ದೇನೆ. ದಯವಿಟ್ಟು ಬೀಪ್ ನಂತರ ಸಂದೇಶ ತಿಳಿಸಿ. ಈ ಕರೆ ರೆಕಾರ್ಡ್ ಆಗುತ್ತಿದೆ.",
      },
    ),
    DndPreset(
      id: 'driving',
      title: 'Driving',
      defaultMessages: {
        'en-IN': "I am driving right now and cannot answer your call safely. Please leave a message after the beep. This call is recorded.",
        'hi-IN': "मैं अभी गाड़ी चला रहा हूँ। कृपया बीप के बाद संदेश छोड़ें। यह कॉल रिकॉर्ड की जाती है।",
        'ta-IN': "நான் இப்போது வாகனம் ஓட்டுகிறேன். பீப் ஒலிக்குப் பிறகு செய்தி விடவும்.",
        'te-IN': "నేను ప్రస్తుతం డ్రైవింగ్ చేస్తున్నాను. దయచేసి బీప్ తర్వాత సందేశం ఇవ్వండి.",
        'ml-IN': "ഞാൻ ഇപ്പോൾ ഡ്രൈവിംഗിലാണ്. ബീപ്പ് ശബ്ദത്തിന് ശേഷം സന്ദേശം നൽകുക.",
        'kn-IN': "ನಾನು ಪ್ರಸ್ತುತ ವಾಹನ ಚಾಲನೆ ಮಾಡುತ್ತಿದ್ದೇನೆ. ದಯವಿಟ್ಟು ಬೀಪ್ ನಂತರ ಸಂದೇಶ ತಿಳಿಸಿ.",
      },
    ),
    DndPreset(
      id: 'sleeping',
      title: 'Sleeping',
      defaultMessages: {
        'en-IN': "I am asleep right now. If this is an emergency, please call back within 3 minutes; otherwise leave a message after the beep.",
        'hi-IN': "मैं अभी सो रहा हूँ। यदि यह आपातकालीन है, तो कृपया 3 मिनट के भीतर दोबारा कॉल करें, अन्यथा बीप के बाद संदेश छोड़ें।",
        'ta-IN': "நான் இப்போது தூங்குகிறேன். அவசரமென்றால் 3 நிமிடங்களுக்குள் மீண்டும் அழைக்கவும்.",
        'te-IN': "నేను ప్రస్తుతం నిద్రపోతున్నాను. అత్యవసరమైతే 3 నిమిషాల్లో మళ్ళీ కాల్ చేయండి.",
        'ml-IN': "ഞാൻ ഇപ്പോൾ ഉറങ്ങുകയാണ്. അത്യാവശ്യമാണെങ്കിൽ 3 മിനിറ്റിനുള്ളിൽ വീണ്ടും വിളിക്കുക.",
        'kn-IN': "ನಾನು ಪ್ರಸ್ತುತ ನಿದ್ರಿಸುತ್ತಿದ್ದೇನೆ. ತುರ್ತು ಸಂದರ್ಭದಲ್ಲಿ 3 ನಿಮಿಷಗಳಲ್ಲಿ ಮರು ಕರೆ ಮಾಡಿ.",
      },
    ),
    DndPreset(
      id: 'travelling',
      title: 'Travelling',
      defaultMessages: {
        'en-IN': "I am currently travelling with limited connectivity. Please leave a message after the beep. This call is recorded.",
        'hi-IN': "मैं अभी यात्रा कर रहा हूँ। कृपया बीप के बाद संदेश छोड़ें। यह कॉल रिकॉर्ड की जाती है।",
        'ta-IN': "நான் பயணத்தில் இருக்கிறேன். பீப் ஒலிக்குப் பிறகு செய்தி விடவும்.",
        'te-IN': "నేను ప్రయాణంలో ఉన్నాను. దಯచేసి బీప్ తర్వాత సందేశం ఇవ్వండి.",
        'ml-IN': "ഞാൻ ഇപ്പോൾ യാത്രയിലാണ്. ബീപ്പ് ശബ്ദത്തിന് ശേഷം സന്ദേശം നൽകുക.",
        'kn-IN': "ನಾನು ಪ್ರಯಾಣದಲ್ಲಿದ್ದೇನೆ. ದಯವಿಟ್ಟು ಬೀಪ್ ನಂತರ ಸಂದೇಶ ತಿಳಿಸಿ.",
      },
    ),
    DndPreset(
      id: 'custom',
      title: 'Custom',
      defaultMessages: {
        'en-IN': "I am unavailable at the moment. Please leave your message after the tone. This call is recorded.",
        'hi-IN': "मैं अभी उपलब्ध नहीं हूँ। कृपया बीप के बाद अपना संदेश छोड़ें। यह कॉल रिकॉर्ड की जाती है।",
        'ta-IN': "நான் இப்போது வர இயலவில்லை. பீப் ஒலிக்குப் பிறகு செய்தி விடவும்.",
        'te-IN': "నేను ప్రస్తుతం అందుబాటులో లేను. దయచేసి బీప్ తర్వాత సందేశం ఇవ్వండి.",
        'ml-IN': "ഞാൻ ഇപ്പോൾ ലഭ്യമല്ല. ബീപ്പ് ശബ്ദത്തിന് ശേഷം സന്ദേശം നൽകുക.",
        'kn-IN': "ನಾನು ಪ್ರಸ್ತುತ ಲಭ್ಯವಿಲ್ಲ. ದಯವಿಟ್ಟು ಬೀಪ್ ನಂತರ ಸಂದೇಶ ತಿಳಿಸಿ.",
      },
    ),
  ];

  Future<File> synthesizeGreetingToFile(String text, String langCode) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'dnd_greeting_${DateTime.now().millisecondsSinceEpoch}.wav';
    final filePath = '${tempDir.path}/$fileName';

    await _flutterTts.setLanguage(langCode);
    await _flutterTts.setSpeechRate(0.48); // Natural, clear telephony pace
    await _flutterTts.setPitch(1.0);

    // Ensure mandatory recording consent is present in text
    String finalSpeechText = text.trim();
    if (!finalSpeechText.toLowerCase().contains("record") && 
        !finalSpeechText.contains("रिकॉर्ड") && 
        !finalSpeechText.contains("பதிவு") && 
        !finalSpeechText.contains("రికార్డ్")) {
      finalSpeechText += " This call is recorded for voicemail delivery.";
    }

    final dynamic res = await _flutterTts.synthesizeToFile(finalSpeechText, fileName);
    print("[TTS Service] synthesizeToFile result: $res, path: $filePath");

    final file = File(filePath);
    if (!await file.exists()) {
      // In case synthesizer saved directly to app documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      final altFile = File('${docsDir.path}/$fileName');
      if (await altFile.exists()) {
        return altFile;
      }
    }
    return file;
  }

  Future<void> previewGreetingAudio(String text, String langCode) async {
    await _flutterTts.stop();
    await _audioPlayer.stop();

    await _flutterTts.setLanguage(langCode);
    await _flutterTts.setSpeechRate(0.48);
    await _flutterTts.speak(text);

    // Sound short beep tone after speech finishes
    _flutterTts.setCompletionHandler(() async {
      await _playBeepTone();
    });
  }

  Future<void> _playBeepTone() async {
    try {
      await _audioPlayer.setAsset('assets/audio/beep.wav');
      await _audioPlayer.play();
    } catch (_) {
      // Audio asset optional in debug preview
    }
  }

  Future<void> stopPlayback() async {
    await _flutterTts.stop();
    await _audioPlayer.stop();
  }
}
