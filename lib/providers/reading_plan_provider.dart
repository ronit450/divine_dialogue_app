import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/reading_plan.dart';
import '../data/reading_plan_repository.dart';
import '../services/notification_service.dart';

class ReadingPlanState {
  const ReadingPlanState({
    this.plans = const [],
    this.isLoading = true,
  });

  final List<ReadingPlan> plans;
  final bool isLoading;

  ReadingPlan? planForText(String textId) =>
      plans.where((p) => p.textId == textId).firstOrNull;

  ReadingPlanState copyWith({List<ReadingPlan>? plans, bool? isLoading}) =>
      ReadingPlanState(
        plans: plans ?? this.plans,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ReadingPlanNotifier extends StateNotifier<ReadingPlanState> {
  ReadingPlanNotifier() : super(const ReadingPlanState()) {
    _load();
  }

  final _repo = ReadingPlanRepository.instance;

  Future<void> _load() async {
    // Remote is source of truth for authenticated users.
    // Fall back to local cache (e.g. guest, offline first launch),
    // then migrate any local-only plans up to Firestore.
    var plans = await _repo.loadRemotePlans();
    if (plans.isEmpty) {
      plans = await _repo.loadPlans();
      for (final p in plans) {
        await _repo.upsertRemotePlan(p);
      }
    } else {
      await _repo.savePlans(plans);
    }
    if (mounted) {
      state = state.copyWith(plans: plans, isLoading: false);
      _rescheduleAll(plans);
    }
  }

  void _rescheduleAll(List<ReadingPlan> plans) {
    for (final p in plans) {
      if (p.reminderEnabled) {
        NotificationService.instance.schedulePlanReminder(
          planId: p.id,
          textTitle: p.textTitle,
          hour: p.reminderHour,
          minute: p.reminderMinute,
          dayNumber: p.dayNumber,
          durationDays: p.durationDays,
          unitsPerDay: p.unitsPerDay,
          unitLabel: p.unitLabel,
          estimatedMins: p.estimatedMinutesPerDay,
        );
      }
    }
  }

  Future<void> _save(List<ReadingPlan> plans) async {
    state = state.copyWith(plans: plans);
    await _repo.savePlans(plans);
    for (final p in plans) {
      await _repo.upsertRemotePlan(p);
    }
  }

  Future<void> addPlan(ReadingPlan plan) async {
    // If replacing an existing plan for the same text, remove the old one remotely.
    final old =
        state.plans.where((p) => p.textId == plan.textId).firstOrNull;
    if (old != null) {
      await _repo.deleteRemotePlan(old.id);
    }
    final updated = [
      ...state.plans.where((p) => p.textId != plan.textId),
      plan,
    ];
    await _save(updated);
  }

  Future<void> markTodayDone(String planId) async {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await _save(state.plans
        .map((p) => p.id == planId
            ? p.copyWith(completedDates: {...p.completedDates, today})
            : p)
        .toList());
  }

  Future<void> updateDuration(
      String planId, int? durationDays, int unitsPerDay) async {
    await _save(state.plans
        .map((p) => p.id == planId
            ? p.copyWith(
                durationDays: durationDays,
                clearDuration: durationDays == null,
                unitsPerDay: unitsPerDay,
              )
            : p)
        .toList());
  }

  Future<void> updateReminder(
      String planId, int hour, int minute, bool enabled) async {
    await _save(state.plans
        .map((p) => p.id == planId
            ? p.copyWith(
                reminderHour: hour,
                reminderMinute: minute,
                reminderEnabled: enabled,
              )
            : p)
        .toList());
  }

  Future<void> updateStreakSettings(
      String planId, bool streakFreezes, bool catchUpMode) async {
    await _save(state.plans
        .map((p) => p.id == planId
            ? p.copyWith(
                streakFreezes: streakFreezes,
                catchUpMode: catchUpMode,
              )
            : p)
        .toList());
  }

  Future<void> deletePlan(String planId) async {
    await _save(state.plans.where((p) => p.id != planId).toList());
    await _repo.deleteRemotePlan(planId);
  }

  void clear() {
    state = const ReadingPlanState(isLoading: true);
  }

  Future<void> reload() async {
    state = const ReadingPlanState(isLoading: true);
    await _load();
  }

  Future<void> updateLastRead(String planId, int unit) async {
    final updated = state.plans
        .map((p) => p.id == planId ? p.copyWith(lastReadUnit: unit) : p)
        .toList();
    state = state.copyWith(plans: updated);
    await _repo.savePlans(updated);
    final changed = updated.firstWhere((p) => p.id == planId);
    unawaited(_repo.upsertRemotePlan(changed));
  }
}

final readingPlanProvider =
    StateNotifierProvider<ReadingPlanNotifier, ReadingPlanState>(
  (ref) => ReadingPlanNotifier(),
);
