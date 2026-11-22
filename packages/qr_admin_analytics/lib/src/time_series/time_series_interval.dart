/// Bucket intervals for aggregating scan and generation time-series telemetry.
enum TimeSeriesBucketInterval {
  hourly,
  daily,
  weekly,
  monthly;

  /// Truncates a timestamp to the beginning of the bucket interval in UTC.
  DateTime truncate(DateTime dt) {
    final utc = dt.toUtc();
    switch (this) {
      case TimeSeriesBucketInterval.hourly:
        return DateTime.utc(utc.year, utc.month, utc.day, utc.hour);
      case TimeSeriesBucketInterval.daily:
        return DateTime.utc(utc.year, utc.month, utc.day);
      case TimeSeriesBucketInterval.weekly:
        // Beginning of week: Monday
        final daysToSubtract = utc.weekday - 1;
        final monday = utc.subtract(Duration(days: daysToSubtract));
        return DateTime.utc(monday.year, monday.month, monday.day);
      case TimeSeriesBucketInterval.monthly:
        return DateTime.utc(utc.year, utc.month, 1);
    }
  }

  /// Advances a truncated timestamp by one bucket step.
  DateTime next(DateTime dt) {
    final t = truncate(dt);
    switch (this) {
      case TimeSeriesBucketInterval.hourly:
        return t.add(const Duration(hours: 1));
      case TimeSeriesBucketInterval.daily:
        return t.add(const Duration(days: 1));
      case TimeSeriesBucketInterval.weekly:
        return t.add(const Duration(days: 7));
      case TimeSeriesBucketInterval.monthly:
        if (t.month == 12) {
          return DateTime.utc(t.year + 1, 1, 1);
        } else {
          return DateTime.utc(t.year, t.month + 1, 1);
        }
    }
  }

  /// Alias for [next].
  DateTime nextBucket(DateTime dt) => next(dt);

  /// Formats a timestamp into an intuitive human-readable bucket label.
  String formatLabel(DateTime dt) {
    final t = truncate(dt);
    final mStr = t.month.toString().padLeft(2, '0');
    final dStr = t.day.toString().padLeft(2, '0');
    switch (this) {
      case TimeSeriesBucketInterval.hourly:
        final hStr = t.hour.toString().padLeft(2, '0');
        return '$mStr-$dStr $hStr:00';
      case TimeSeriesBucketInterval.daily:
        return '${t.year}-$mStr-$dStr';
      case TimeSeriesBucketInterval.weekly:
        return 'Wk ${t.year}-$mStr-$dStr';
      case TimeSeriesBucketInterval.monthly:
        return '${t.year}-$mStr';
    }
  }
}
