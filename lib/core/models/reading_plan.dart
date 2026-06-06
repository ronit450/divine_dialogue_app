import 'package:flutter/material.dart';

class TextReadingMeta {
  static const _counts = <String, int>{
    'quran': 780,
    'guru_granth_sahib': 1430,
    'dasam_granth': 1428,
    'bhai_gurdas_vaaran': 40,
    'bhagavad_gita': 18,
    'valmiki_ramayana': 648,
    'bukhari': 97,
    'muslim': 57,
    'abu_dawud': 43,
    'tirmidhi': 49,
    'nasai': 52,
    'ibn_majah': 38,
    'bible_nrsv': 1189,
    'gospels': 89,
    'psalms': 150,
    'paul_letters': 87,
  };

  static const _labels = <String, String>{
    'quran': 'pages',
    'guru_granth_sahib': 'angs',
    'dasam_granth': 'pages',
    'bhai_gurdas_vaaran': 'vaaran',
    'bhagavad_gita': 'chapters',
    'valmiki_ramayana': 'sargas',
    'bukhari': 'chapters',
    'muslim': 'chapters',
    'abu_dawud': 'chapters',
    'tirmidhi': 'chapters',
    'nasai': 'chapters',
    'ibn_majah': 'chapters',
    'bible_nrsv': 'chapters',
    'gospels': 'chapters',
    'psalms': 'psalms',
    'paul_letters': 'chapters',
  };

  static const _minsPerUnit = <String, int>{
    'quran': 5,
    'guru_granth_sahib': 3,
    'dasam_granth': 3,
    'bhai_gurdas_vaaran': 5,
    'bhagavad_gita': 10,
    'valmiki_ramayana': 5,
    'bukhari': 5,
    'muslim': 5,
    'abu_dawud': 5,
    'tirmidhi': 5,
    'nasai': 5,
    'ibn_majah': 5,
    'bible_nrsv': 5,
    'gospels': 5,
    'psalms': 3,
    'paul_letters': 5,
  };

  static int totalUnits(String textId) => _counts[textId] ?? 100;
  static String unitLabel(String textId) => _labels[textId] ?? 'pages';
  static int minutesPerUnit(String textId) => _minsPerUnit[textId] ?? 3;
}

class ReadingPlan {
  ReadingPlan({
    required this.id,
    required this.textId,
    required this.textTitle,
    required this.religionId,
    required this.totalUnits,
    required this.unitLabel,
    required this.minutesPerUnit,
    this.durationDays,
    required this.unitsPerDay,
    required this.reminderHour,
    required this.reminderMinute,
    required this.reminderEnabled,
    required this.startDate,
    required this.completedDates,
    required this.streakFreezes,
    required this.catchUpMode,
  });

  final String id;
  final String textId;
  final String textTitle;
  final String religionId;
  final int totalUnits;
  final String unitLabel;
  final int minutesPerUnit;
  final int? durationDays;
  final int unitsPerDay;
  final int reminderHour;
  final int reminderMinute;
  final bool reminderEnabled;
  final DateTime startDate;
  final Set<String> completedDates;
  final bool streakFreezes;
  final bool catchUpMode;

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int get dayNumber {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    return today.difference(start).inDays + 1;
  }

  bool get todayDone => completedDates.contains(_dateStr(DateTime.now()));

  int get totalDaysCompleted => completedDates.length;

  int get unitsRead => (totalDaysCompleted * unitsPerDay).clamp(0, totalUnits);

  double get progressFraction =>
      totalUnits == 0 ? 0 : unitsRead / totalUnits;

  int get percentRead => totalDaysCompleted > 0
      ? (progressFraction * 100).round().clamp(1, 100)
      : 0;

  int get daysLeft => durationDays != null
      ? (durationDays! - dayNumber + 1).clamp(0, durationDays!)
      : -1;

  int get todayStartUnit =>
      ((dayNumber - 1) * unitsPerDay + 1).clamp(1, totalUnits);
  int get todayEndUnit => (dayNumber * unitsPerDay).clamp(1, totalUnits);

  TimeOfDay get reminderTime =>
      TimeOfDay(hour: reminderHour, minute: reminderMinute);

  int get streak {
    var s = 0;
    var date = DateTime.now();
    if (!todayDone) date = date.subtract(const Duration(days: 1));
    while (completedDates.contains(_dateStr(date))) {
      s++;
      date = date.subtract(const Duration(days: 1));
    }
    return s;
  }

  String get durationLabel {
    if (durationDays == null) return 'No deadline';
    if (durationDays == 90) return '90 days';
    if (durationDays == 180) return '6 months';
    if (durationDays == 365) return '1 year';
    if (durationDays == 730) return '2 years';
    return '$durationDays days';
  }

  int get estimatedMinutesPerDay =>
      (unitsPerDay * minutesPerUnit).clamp(1, 999);

  String get formattedReminderTime {
    final h = reminderHour;
    final m = reminderMinute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour:$m $period';
  }

  ReadingPlan copyWith({
    int? durationDays,
    bool clearDuration = false,
    int? unitsPerDay,
    int? reminderHour,
    int? reminderMinute,
    bool? reminderEnabled,
    Set<String>? completedDates,
    bool? streakFreezes,
    bool? catchUpMode,
  }) {
    return ReadingPlan(
      id: id,
      textId: textId,
      textTitle: textTitle,
      religionId: religionId,
      totalUnits: totalUnits,
      unitLabel: unitLabel,
      minutesPerUnit: minutesPerUnit,
      durationDays:
          clearDuration ? null : (durationDays ?? this.durationDays),
      unitsPerDay: unitsPerDay ?? this.unitsPerDay,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      startDate: startDate,
      completedDates: completedDates ?? this.completedDates,
      streakFreezes: streakFreezes ?? this.streakFreezes,
      catchUpMode: catchUpMode ?? this.catchUpMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'textId': textId,
        'textTitle': textTitle,
        'religionId': religionId,
        'totalUnits': totalUnits,
        'unitLabel': unitLabel,
        'minutesPerUnit': minutesPerUnit,
        'durationDays': durationDays,
        'unitsPerDay': unitsPerDay,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'reminderEnabled': reminderEnabled,
        'startDate': startDate.millisecondsSinceEpoch,
        'completedDates': completedDates.toList(),
        'streakFreezes': streakFreezes,
        'catchUpMode': catchUpMode,
      };

  factory ReadingPlan.fromJson(Map<String, dynamic> json) => ReadingPlan(
        id: json['id'] as String,
        textId: json['textId'] as String,
        textTitle: json['textTitle'] as String,
        religionId: json['religionId'] as String,
        totalUnits: json['totalUnits'] as int,
        unitLabel: json['unitLabel'] as String,
        minutesPerUnit: (json['minutesPerUnit'] as int?) ?? 3,
        durationDays: json['durationDays'] as int?,
        unitsPerDay: json['unitsPerDay'] as int,
        reminderHour: (json['reminderHour'] as int?) ?? 6,
        reminderMinute: (json['reminderMinute'] as int?) ?? 30,
        reminderEnabled: (json['reminderEnabled'] as bool?) ?? true,
        startDate:
            DateTime.fromMillisecondsSinceEpoch(json['startDate'] as int),
        completedDates: Set<String>.from(
            (json['completedDates'] as List).cast<String>()),
        streakFreezes: (json['streakFreezes'] as bool?) ?? true,
        catchUpMode: (json['catchUpMode'] as bool?) ?? false,
      );

  factory ReadingPlan.create({
    required String textId,
    required String textTitle,
    required String religionId,
    required int? durationDays,
    required int unitsPerDay,
    required int reminderHour,
    required int reminderMinute,
    required bool reminderEnabled,
  }) {
    return ReadingPlan(
      id: '${textId}_${DateTime.now().millisecondsSinceEpoch}',
      textId: textId,
      textTitle: textTitle,
      religionId: religionId,
      totalUnits: TextReadingMeta.totalUnits(textId),
      unitLabel: TextReadingMeta.unitLabel(textId),
      minutesPerUnit: TextReadingMeta.minutesPerUnit(textId),
      durationDays: durationDays,
      unitsPerDay: unitsPerDay,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      reminderEnabled: reminderEnabled,
      startDate: DateTime.now(),
      completedDates: {},
      streakFreezes: true,
      catchUpMode: false,
    );
  }
}
