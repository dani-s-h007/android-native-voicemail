import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Groups voicemails into Today, Yesterday, or Earlier
  String get dateGroupHeader {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    return DateFormat('MMMM d, y').format(this);
  }

  /// Short time string e.g. "10:45 AM"
  String get formattedTime {
    return DateFormat.jm().format(this);
  }

  /// Date and time e.g. "Nov 7, 10:45 AM"
  String get formattedDateTime {
    return DateFormat('MMM d, h:mm a').format(this);
  }

  /// Relative human-readable time e.g. "2m ago", "1h ago"
  String get timeAgo {
    final difference = DateTime.now().difference(this);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d').format(this);
  }
}

extension DurationExtensions on Duration {
  /// Formats duration as "0:42" or "1:15"
  String get formattedMinutesSeconds {
    final minutes = inMinutes;
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

