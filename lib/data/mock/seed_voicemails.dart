import 'package:voicemail/features/voicemail/domain/voicemail.dart';

/// 20 realistic, enterprise-grade mock voicemails covering diverse dates,
/// callers, languages, durations, handling modes, and transcription states.
class SeedVoicemails {
  const SeedVoicemails._();

  static List<Voicemail> get items {
    final now = DateTime.now();

    return [
      // 1. Alex Morgan (Today - 15m ago, Unread)
      Voicemail(
        id: 'vm_001',
        callerNumber: '+1 (555) 019-2834',
        callerName: 'Alex Morgan',
        audioLocalPath: 'audio/sample_001.m4a',
        durationSeconds: 24,
        createdAt: now.subtract(const Duration(minutes: 15)),
        isRead: false,
        isStarred: false,
        transcriptText:
            'Hello, this is Alex following up on the project proposal. Give me a call back when you get a chance.',
        detectedLanguage: 'English',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Automated Assistant',
      ),

      // 2. Taylor Reed (Today - 3h ago, Read, Starred)
      Voicemail(
        id: 'vm_002',
        callerNumber: '+1 (555) 012-7890',
        callerName: 'Taylor Reed',
        audioLocalPath: 'audio/sample_002.m4a',
        durationSeconds: 18,
        createdAt: now.subtract(const Duration(hours: 3)),
        isRead: true,
        isStarred: true,
        transcriptText:
            'Hi there, just wanted to check if you received the documentation sent earlier today.',
        detectedLanguage: 'English',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Auto-Declined',
      ),

      // 3. Sophie Martin (Today - 5h ago, Unread, French)
      Voicemail(
        id: 'vm_003',
        callerNumber: '+33 1 42 68 55 00',
        callerName: 'Sophie Martin',
        audioLocalPath: 'audio/sample_003.m4a',
        durationSeconds: 32,
        createdAt: now.subtract(const Duration(hours: 5)),
        isRead: false,
        isStarred: false,
        transcriptText:
            'Bonjour, je vous appelle concernant la réunion de demain matin. Merci de me confirmer votre présence.',
        detectedLanguage: 'French',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Server Assistant',
      ),

      // 4. Carlos Mendez (Yesterday - 20h ago, Read, Spanish)
      Voicemail(
        id: 'vm_004',
        callerNumber: '+34 91 123 4567',
        callerName: 'Carlos Mendez',
        audioLocalPath: 'audio/sample_004.m4a',
        durationSeconds: 45,
        createdAt: now.subtract(const Duration(hours: 20)),
        isRead: true,
        isStarred: false,
        transcriptText:
            'Hola, llamo para confirmar nuestra cita de este viernes. Por favor avísame si necesitas cambiar la hora.',
        detectedLanguage: 'Spanish',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Auto-Declined',
      ),

      // 5. Lukas Weber (Yesterday - 26h ago, Unread, Starred, German)
      Voicemail(
        id: 'vm_005',
        callerNumber: '+49 30 1234567',
        callerName: 'Lukas Weber',
        audioLocalPath: 'audio/sample_005.m4a',
        durationSeconds: 28,
        createdAt: now.subtract(const Duration(hours: 26)),
        isRead: false,
        isStarred: true,
        transcriptText:
            'Guten Tag, hier ist Lukas. Bitte rufen Sie mich bezüglich des Projektplans und der nächsten Schritte zurück.',
        detectedLanguage: 'German',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Automated Assistant',
      ),

      // 6. Priya Sharma (Yesterday - 30h ago, Read, Hindi)
      Voicemail(
        id: 'vm_006',
        callerNumber: '+91 98201 12345',
        callerName: 'Priya Sharma',
        audioLocalPath: 'audio/sample_006.m4a',
        durationSeconds: 35,
        createdAt: now.subtract(const Duration(hours: 30)),
        isRead: true,
        isStarred: false,
        transcriptText:
            'नमस्ते, मैं कल की मीटिंग के समय के बारे में बात करना चाहती थी। जब भी आप फ्री हों मुझे कॉल करें।',
        detectedLanguage: 'Hindi',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Server Assistant',
      ),

      // 7. Liam O\'Connor (Yesterday - 34h ago, Read, English)
      Voicemail(
        id: 'vm_007',
        callerNumber: '+44 20 7946 0912',
        callerName: "Liam O'Connor",
        audioLocalPath: 'audio/sample_007.m4a',
        durationSeconds: 40,
        createdAt: now.subtract(const Duration(hours: 34)),
        isRead: true,
        isStarred: false,
        transcriptText:
            'Hi, just checking in regarding the delivery schedule for next week. Everything is on track from our end.',
        detectedLanguage: 'English',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Direct Forward',
      ),

      // 8. Elena Rossi (2 days ago, Unread, Italian)
      Voicemail(
        id: 'vm_008',
        callerNumber: '+39 06 6987 1234',
        callerName: 'Elena Rossi',
        audioLocalPath: 'audio/sample_008.m4a',
        durationSeconds: 22,
        createdAt: now.subtract(const Duration(days: 2, hours: 2)),
        isRead: false,
        isStarred: false,
        transcriptText:
            'Ciao, ti ho inviato i documenti aggiornati via email. Fammi sapere cosa ne pensi appena hai tempo.',
        detectedLanguage: 'Italian',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Auto-Declined',
      ),

      // 9. Kenji Sato (3 days ago, Read, Japanese)
      Voicemail(
        id: 'vm_009',
        callerNumber: '+81 3 5555 0143',
        callerName: 'Kenji Sato',
        audioLocalPath: 'audio/sample_009.m4a',
        durationSeconds: 50,
        createdAt: now.subtract(const Duration(days: 3, hours: 4)),
        isRead: true,
        isStarred: false,
        transcriptText:
            'こんにちは、佐藤です。来週のスケジュールについて確認したいのですが、お時間のある際にご連絡いただけますでしょうか。',
        detectedLanguage: 'Japanese',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Automated Assistant',
      ),

      // 10. Marcus Johnson (3 days ago, Unread, English)
      Voicemail(
        id: 'vm_010',
        callerNumber: '+1 (555) 345-6789',
        callerName: 'Marcus Johnson',
        audioLocalPath: 'audio/sample_010.m4a',
        durationSeconds: 15,
        createdAt: now.subtract(const Duration(days: 3, hours: 9)),
        isRead: false,
        isStarred: false,
        transcriptText:
            'Hey, quick question about the invoice you sent over. Let me know when you are available.',
        detectedLanguage: 'English',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Server Assistant',
      ),

      // 11. Amara Okafor (4 days ago, Read, Starred, English)
      Voicemail(
        id: 'vm_011',
        callerNumber: '+234 1 234 5678',
        callerName: 'Amara Okafor',
        audioLocalPath: 'audio/sample_011.m4a',
        durationSeconds: 29,
        createdAt: now.subtract(const Duration(days: 4, hours: 3)),
        isRead: true,
        isStarred: true,
        transcriptText:
            'Good morning, just following up on our discussion yesterday regarding the contract review.',
        detectedLanguage: 'English',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Automated Assistant',
      ),

      // 12. Automated Service Alert (4 days ago, Unread, English, No caller name)
      Voicemail(
        id: 'vm_012',
        callerNumber: '+1 (800) 555-0199',
        callerName: null,
        audioLocalPath: 'audio/sample_012.m4a',
        durationSeconds: 12,
        createdAt: now.subtract(const Duration(days: 4, hours: 8)),
        isRead: false,
        isStarred: false,
        transcriptText:
            'Automated reminder: your scheduled system maintenance window is set for Tuesday at 10:00 PM.',
        detectedLanguage: 'English',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Silent DND',
      ),

      // 13. Chloe Dubois (5 days ago, Read, French)
      Voicemail(
        id: 'vm_013',
        callerNumber: '+33 4 72 00 11 22',
        callerName: 'Chloe Dubois',
        audioLocalPath: 'audio/sample_013.m4a',
        durationSeconds: 38,
        createdAt: now.subtract(const Duration(days: 5, hours: 1)),
        isRead: true,
        isStarred: false,
        transcriptText:
            'Bonjour, c est Chloe. Merci de me rappeler des que possible au sujet du contrat signe.',
        detectedLanguage: 'French',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Server Assistant',
      ),

      // 14. Hans Schmidt (5 days ago, Read, German)
      Voicemail(
        id: 'vm_014',
        callerNumber: '+49 89 987654',
        callerName: 'Hans Schmidt',
        audioLocalPath: 'audio/sample_014.m4a',
        durationSeconds: 19,
        createdAt: now.subtract(const Duration(days: 5, hours: 6)),
        isRead: true,
        isStarred: false,
        transcriptText:
            'Hallo, bitte um kurze Rueckmeldung zum Kostenvoranschlag fuer naechsten Monat. Danke!',
        detectedLanguage: 'German',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Auto-Declined',
      ),

      // 15. Fatima Al-Mansoor (6 days ago, Unread, English)
      Voicemail(
        id: 'vm_015',
        callerNumber: '+971 4 321 4567',
        callerName: 'Fatima Al-Mansoor',
        audioLocalPath: 'audio/sample_015.m4a',
        durationSeconds: 42,
        createdAt: now.subtract(const Duration(days: 6, hours: 3)),
        isRead: false,
        isStarred: false,
        transcriptText:
            'Hello, this is Fatima from the international logistics team confirming the revised shipping itinerary.',
        detectedLanguage: 'English',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Automated Assistant',
      ),

      // 16. David Kim (7 days ago, Read, English)
      Voicemail(
        id: 'vm_016',
        callerNumber: '+82 2 1234 5678',
        callerName: 'David Kim',
        audioLocalPath: 'audio/sample_016.m4a',
        durationSeconds: 27,
        createdAt: now.subtract(const Duration(days: 7, hours: 5)),
        isRead: true,
        isStarred: false,
        transcriptText:
            'Hi, following up on our software integration timeline. Let me know when you have time for a sync call.',
        detectedLanguage: 'English',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Server Assistant',
      ),

      // 17. Isabella Santos (8 days ago, Unread, Portuguese)
      Voicemail(
        id: 'vm_017',
        callerNumber: '+55 11 91234-5678',
        callerName: 'Isabella Santos',
        audioLocalPath: 'audio/sample_017.m4a',
        durationSeconds: 33,
        createdAt: now.subtract(const Duration(days: 8, hours: 2)),
        isRead: false,
        isStarred: false,
        transcriptText:
            'Ola, tudo bem? Queria alinhar os detalhes finais da nossa apresentacao na proxima semana.',
        detectedLanguage: 'Portuguese',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Auto-Declined',
      ),

      // 18. Michael Chen (9 days ago, Read, Starred, English)
      Voicemail(
        id: 'vm_018',
        callerNumber: '+1 (555) 789-0123',
        callerName: 'Michael Chen',
        audioLocalPath: 'audio/sample_018.m4a',
        durationSeconds: 21,
        createdAt: now.subtract(const Duration(days: 9, hours: 7)),
        isRead: true,
        isStarred: true,
        transcriptText:
            'Hey, great catching up earlier. Sending the slide deck your way right now.',
        detectedLanguage: 'English',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Automated Assistant',
      ),

      // 19. Noah Williams (11 days ago, Read, English)
      Voicemail(
        id: 'vm_019',
        callerNumber: '+61 2 9876 5432',
        callerName: 'Noah Williams',
        audioLocalPath: 'audio/sample_019.m4a',
        durationSeconds: 48,
        createdAt: now.subtract(const Duration(days: 11, hours: 4)),
        isRead: true,
        isStarred: false,
        transcriptText:
            "G'day! Giving you a quick update on the regional network configuration and tests.",
        detectedLanguage: 'English',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Direct Forward',
      ),

      // 20. Service Dispatch (13 days ago, Read, English)
      Voicemail(
        id: 'vm_020',
        callerNumber: '+1 (888) 555-0147',
        callerName: 'Service Dispatch',
        audioLocalPath: 'audio/sample_020.m4a',
        durationSeconds: 16,
        createdAt: now.subtract(const Duration(days: 13, hours: 6)),
        isRead: true,
        isStarred: false,
        transcriptText:
            'This is an automated dispatch notification confirming your service inquiry #48291 has been resolved.',
        detectedLanguage: 'English',
        transcriptionStatus: 'completed',
        callHandlingMode: 'Automated Assistant',
      ),
    ];
  }
}
