class Voicemail {
  final String id;
  final String callerNumber;
  final String? callerName;
  final String audioLocalPath;
  final int durationSeconds;
  final DateTime createdAt;
  final bool isRead;
  final bool isStarred;
  final String? transcriptText;
  final String? detectedLanguage;
  final String transcriptionStatus; // 'pending', 'processing', 'completed', 'failed'
  final String callHandlingMode; // 'Server Assistant', 'Auto-Declined', 'Direct Forward'

  const Voicemail({
    required this.id,
    required this.callerNumber,
    this.callerName,
    required this.audioLocalPath,
    required this.durationSeconds,
    required this.createdAt,
    this.isRead = false,
    this.isStarred = false,
    this.transcriptText,
    this.detectedLanguage,
    this.transcriptionStatus = 'completed',
    this.callHandlingMode = 'Server Assistant',
  });

  String get displayName =>
      (callerName != null && callerName!.isNotEmpty) ? callerName! : callerNumber;

  String get initials {
    if (callerName != null && callerName!.isNotEmpty) {
      final parts = callerName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return callerName![0].toUpperCase();
    }
    return '#';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caller_number': callerNumber,
      'caller_name': callerName,
      'audio_local_path': audioLocalPath,
      'duration_seconds': durationSeconds,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_read': isRead ? 1 : 0,
      'is_starred': isStarred ? 1 : 0,
      'transcript_text': transcriptText,
      'detected_language': detectedLanguage,
      'transcription_status': transcriptionStatus,
      'call_handling_mode': callHandlingMode,
    };
  }

  factory Voicemail.fromMap(Map<String, dynamic> map) {
    return Voicemail(
      id: map['id'] as String,
      callerNumber: map['caller_number'] as String,
      callerName: map['caller_name'] as String?,
      audioLocalPath: (map['audio_local_path'] as String?) ?? '',
      durationSeconds: (map['duration_seconds'] as int?) ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isRead: (map['is_read'] as int) == 1,
      isStarred: (map['is_starred'] as int) == 1,
      transcriptText: map['transcript_text'] as String?,
      detectedLanguage: map['detected_language'] as String?,
      transcriptionStatus: (map['transcription_status'] as String?) ?? 'completed',
      callHandlingMode: (map['call_handling_mode'] as String?) ?? 'Server Assistant',
    );
  }

  Voicemail copyWith({
    String? callerName,
    bool? isRead,
    bool? isStarred,
    String? transcriptText,
    String? detectedLanguage,
    String? transcriptionStatus,
    String? callHandlingMode,
  }) {
    return Voicemail(
      id: id,
      callerNumber: callerNumber,
      callerName: callerName ?? this.callerName,
      audioLocalPath: audioLocalPath,
      durationSeconds: durationSeconds,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      transcriptText: transcriptText ?? this.transcriptText,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      transcriptionStatus: transcriptionStatus ?? this.transcriptionStatus,
      callHandlingMode: callHandlingMode ?? this.callHandlingMode,
    );
  }
}
