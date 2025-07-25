import 'package:intl/intl.dart';

/// Format an ISO 8601 timestamp as `dd/MM/yy`.
String formatTimestamp(String iso) {
  try {
    final date = DateTime.parse(iso).toLocal();
    return DateFormat('dd/MM/yy').format(date);
  } catch (_) {
    return iso;
  }
}

/// Format an ISO 8601 timestamp as `MMM d, h:mm a`.
String formatTimestampWithTime(String iso) {
  try {
    final date = DateTime.parse(iso).toLocal();
    return DateFormat('MMM d, h:mm a').format(date);
  } catch (_) {
    return iso;
  }
}
