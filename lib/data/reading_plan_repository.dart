import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/reading_plan.dart';

class ReadingPlanRepository {
  ReadingPlanRepository._();
  static final instance = ReadingPlanRepository._();

  static const _plansKey = 'reading_plans_v1';
  static const _maybeLaterKey = 'reading_popup_maybe_later_at';
  static const _shownDatesKey = 'reading_popup_shown_dates';

  CollectionReference<Map<String, dynamic>>? _remoteCol() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('readingPlans');
  }

  // ── local cache ────────────────────────────────────────────────────────────

  Future<List<ReadingPlan>> loadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_plansKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => ReadingPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePlans(List<ReadingPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _plansKey, jsonEncode(plans.map((p) => p.toJson()).toList()));
  }

  // ── remote (Firestore) ─────────────────────────────────────────────────────

  Future<List<ReadingPlan>> loadRemotePlans() async {
    final col = _remoteCol();
    if (col == null) return [];
    try {
      final snap = await col.get();
      return snap.docs
          .map((d) => ReadingPlan.fromJson(d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsertRemotePlan(ReadingPlan plan) async {
    final col = _remoteCol();
    if (col == null) return;
    try {
      await col.doc(plan.id).set(plan.toJson());
    } catch (_) {}
  }

  Future<void> deleteRemotePlan(String planId) async {
    final col = _remoteCol();
    if (col == null) return;
    try {
      await col.doc(planId).delete();
    } catch (_) {}
  }

  Future<bool> shouldShowPopup() async {
    final prefs = await SharedPreferences.getInstance();

    final maybeLaterAt = prefs.getInt(_maybeLaterKey);
    if (maybeLaterAt != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - maybeLaterAt;
      if (elapsed < 4 * 24 * 60 * 60 * 1000) return false;
    }

    final today = _todayStr();
    final shownDates = prefs.getStringList(_shownDatesKey) ?? [];
    final shownToday = shownDates.where((d) => d == today).length;
    return shownToday < 2;
  }

  Future<void> recordPopupShown() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final shownDates = prefs.getStringList(_shownDatesKey) ?? [];
    shownDates.add(today);
    final trimmed = shownDates.length > 30
        ? shownDates.sublist(shownDates.length - 30)
        : shownDates;
    await prefs.setStringList(_shownDatesKey, trimmed);
  }

  Future<void> recordMaybeLater() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maybeLaterKey, DateTime.now().millisecondsSinceEpoch);
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
