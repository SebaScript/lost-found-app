import 'package:timeago/timeago.dart' as timeago;

class TimeUtils {
  static String getTimeAgo(DateTime dateTime) {
    timeago.setLocaleMessages('es', timeago.EsMessages());
    return timeago.format(dateTime, locale: 'es');
  }

  static String formatTime(DateTime dateTime) {
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static String formatDate(DateTime dateTime) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    DateTime dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return 'Hoy';
    } else if (dateToCheck == yesterday) {
      return 'Ayer';
    } else if (now.difference(dateTime).inDays < 7) {
      List<String> weekdays = [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo'
      ];
      return weekdays[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

