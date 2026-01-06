
// File: lib/services/analytics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get weekly mood trend
  Future<List<double>> getWeeklyMoodTrend(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('checkIns')
          .where('date',
              isGreaterThanOrEqualTo: _formatDate(weekAgo))
          .where('date', isLessThanOrEqualTo: _formatDate(now))
          .orderBy('date')
          .get();

      // Group by day and calculate average
      Map<String, List<int>> dailyScores = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = data['date'] as String;
        final score = data['moodScore'] as int;

        if (!dailyScores.containsKey(date)) {
          dailyScores[date] = [];
        }
        dailyScores[date]!.add(score);
      }

      // Calculate daily averages
      List<double> weeklyTrend = [];
      for (int i = 6; i >= 0; i--) {
        final date = _formatDate(now.subtract(Duration(days: i)));
        if (dailyScores.containsKey(date)) {
          final scores = dailyScores[date]!;
          weeklyTrend.add(scores.reduce((a, b) => a + b) / scores.length);
        } else {
          weeklyTrend.add(0.0);
        }
      }

      return weeklyTrend;
    } catch (e) {
      print('Error getting weekly mood trend: $e');
      return List.filled(7, 0.0);
    }
  }

  // Get completion percentage for goals
  Future<double> getGoalCompletionRate(String userId, String duration) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .where('duration', isEqualTo: duration)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      final completed =
          snapshot.docs.where((doc) => doc.data()['isCompleted'] == true).length;
      return (completed / snapshot.docs.length) * 100;
    } catch (e) {
      print('Error getting goal completion rate: $e');
      return 0.0;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
