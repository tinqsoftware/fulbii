import 'package:intl/intl.dart';

class SpanishDateFormatter {
  const SpanishDateFormatter._();

  static DateTime? parse(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }

  static String birthDate(String? value) {
    final date = parse(value);
    return date == null
        ? 'Fecha de nacimiento: —'
        : DateFormat('d MMM y', 'es').format(date);
  }

  static String pichangaDate(String? value, {DateTime? now}) {
    final date = parse(value);
    if (date == null) return 'Fecha por confirmar';
    final current = (now ?? DateTime.now()).toLocal();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(current.year, current.month, current.day);
    final prefix = day == today
        ? 'Hoy'
        : day == today.add(const Duration(days: 1))
        ? 'Mañana'
        : DateFormat(
            date.year == current.year ? 'EEE, d MMM' : 'EEE, d MMM y',
            'es',
          ).format(date);
    return '$prefix · ${DateFormat('h:mm a', 'es').format(date).replaceAll('AM', 'a. m.').replaceAll('PM', 'p. m.')}';
  }

  static String status(String? value) => switch (value?.trim().toLowerCase()) {
    'confirmed' => 'Confirmada',
    'pending' => 'Pendiente',
    'published' => 'Abierta',
    'completed' => 'Finalizada',
    'cancelled' => 'Cancelada',
    _ => 'Por confirmar',
  };
}
