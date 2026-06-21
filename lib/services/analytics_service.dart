import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  final _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Tracks when the user entered each feature so we can compute time spent
  final Map<String, DateTime> _enterTimes = {};

  void enterFeature(String feature) {
    _enterTimes[feature] = DateTime.now();
    _analytics.logEvent(name: 'feature_open', parameters: {'feature': feature});
  }

  void exitFeature(String feature) {
    final enter = _enterTimes.remove(feature);
    if (enter == null) return;
    final seconds = DateTime.now().difference(enter).inSeconds;
    _analytics.logEvent(name: 'feature_time_spent', parameters: {
      'feature': feature,
      'duration_seconds': seconds,
    });
  }

  void logEvent(String name, {Map<String, Object>? parameters}) {
    _analytics.logEvent(name: name, parameters: parameters);
  }
}
