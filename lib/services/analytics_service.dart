// File: lib/services/analytics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get weekly mood trend (7 days) - FIXED
  Future<List<double>> getWeeklyMoodTrend(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 6)); // Changed from 7 to 6

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

      // Calculate daily averages for last 7 days
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

  // Get monthly mood trend (4 weeks) - FIXED
  Future<List<double>> getMonthlyMoodTrend(String userId) async {
    try {
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 27)); // 4 weeks = 28 days

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('checkIns')
          .where('date',
              isGreaterThanOrEqualTo: _formatDate(monthAgo))
          .where('date', isLessThanOrEqualTo: _formatDate(now))
          .orderBy('date')
          .get();

      // Group by week (4 weeks)
      Map<int, List<int>> weeklyScores = {0: [], 1: [], 2: [], 3: []};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = DateTime.parse(data['date'] as String);
        final score = data['moodScore'] as int;
        
        // Calculate which week this belongs to (0-3, where 0 is most recent)
        final daysAgo = now.difference(date).inDays;
        final weekIndex = 3 - (daysAgo ~/ 7).clamp(0, 3);
        
        weeklyScores[weekIndex]!.add(score);
      }

      // Calculate weekly averages (oldest to newest)
      List<double> monthlyTrend = [];
      for (int i = 0; i <= 3; i++) {
        if (weeklyScores[i]!.isEmpty) {
          monthlyTrend.add(0.0);
        } else {
          final avg = weeklyScores[i]!.reduce((a, b) => a + b) / 
                     weeklyScores[i]!.length;
          monthlyTrend.add(avg);
        }
      }

      return monthlyTrend;
    } catch (e) {
      print('Error getting monthly mood trend: $e');
      return List.filled(4, 0.0);
    }
  }

  // Get yearly mood trend (12 months) - FIXED
  Future<List<double>> getYearlyMoodTrend(String userId) async {
    try {
      final now = DateTime.now();
      final yearAgo = DateTime(now.year - 1, now.month, now.day);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('checkIns')
          .where('date',
              isGreaterThanOrEqualTo: _formatDate(yearAgo))
          .where('date', isLessThanOrEqualTo: _formatDate(now))
          .orderBy('date')
          .get();

      // Group by month (12 months)
      Map<String, List<int>> monthlyScores = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = DateTime.parse(data['date'] as String);
        final score = data['moodScore'] as int;
        
        // Create month key (YYYY-MM)
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        
        if (!monthlyScores.containsKey(monthKey)) {
          monthlyScores[monthKey] = [];
        }
        monthlyScores[monthKey]!.add(score);
      }

      // Calculate monthly averages for last 12 months (oldest to newest)
      List<double> yearlyTrend = [];
      for (int i = 11; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        
        if (monthlyScores.containsKey(monthKey)) {
          final scores = monthlyScores[monthKey]!;
          yearlyTrend.add(scores.reduce((a, b) => a + b) / scores.length);
        } else {
          yearlyTrend.add(0.0);
        }
      }

      return yearlyTrend;
    } catch (e) {
      print('Error getting yearly mood trend: $e');
      return List.filled(12, 0.0);
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

  // Get previous week mood trend (for comparison)
  Future<List<double>> getPreviousWeekMoodTrend(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final twoWeeksAgo = now.subtract(const Duration(days: 14));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('checkIns')
          .where('date',
              isGreaterThanOrEqualTo: _formatDate(twoWeeksAgo))
          .where('date', isLessThan: _formatDate(weekAgo))
          .orderBy('date')
          .get();

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

      List<double> previousTrend = [];
      for (int i = 13; i >= 7; i--) {
        final date = _formatDate(now.subtract(Duration(days: i)));
        if (dailyScores.containsKey(date)) {
          final scores = dailyScores[date]!;
          previousTrend.add(scores.reduce((a, b) => a + b) / scores.length);
        } else {
          previousTrend.add(0.0);
        }
      }

      return previousTrend;
    } catch (e) {
      print('Error getting previous week mood trend: $e');
      return List.filled(7, 0.0);
    }
  }

  // Get previous month mood trend (for comparison)
  Future<List<double>> getPreviousMonthMoodTrend(String userId) async {
    try {
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 28));
      final twoMonthsAgo = now.subtract(const Duration(days: 56));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('checkIns')
          .where('date',
              isGreaterThanOrEqualTo: _formatDate(twoMonthsAgo))
          .where('date', isLessThan: _formatDate(monthAgo))
          .orderBy('date')
          .get();

      Map<int, List<int>> weeklyScores = {0: [], 1: [], 2: [], 3: []};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = DateTime.parse(data['date'] as String);
        final score = data['moodScore'] as int;
        
        final daysAgo = monthAgo.difference(date).inDays;
        final weekIndex = (daysAgo / 7).floor().clamp(0, 3);
        
        weeklyScores[weekIndex]!.add(score);
      }

      List<double> previousTrend = [];
      for (int i = 0; i <= 3; i++) {
        if (weeklyScores[i]!.isEmpty) {
          previousTrend.add(0.0);
        } else {
          final avg = weeklyScores[i]!.reduce((a, b) => a + b) / 
                     weeklyScores[i]!.length;
          previousTrend.add(avg);
        }
      }

      return previousTrend;
    } catch (e) {
      print('Error getting previous month mood trend: $e');
      return List.filled(4, 0.0);
    }
  }

  // Get previous year mood trend (for comparison)
  Future<List<double>> getPreviousYearMoodTrend(String userId) async {
    try {
      final now = DateTime.now();
      final yearAgo = DateTime(now.year - 1, now.month, now.day);
      final twoYearsAgo = DateTime(now.year - 2, now.month, now.day);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('checkIns')
          .where('date',
              isGreaterThanOrEqualTo: _formatDate(twoYearsAgo))
          .where('date', isLessThan: _formatDate(yearAgo))
          .orderBy('date')
          .get();

      Map<String, List<int>> monthlyScores = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = DateTime.parse(data['date'] as String);
        final score = data['moodScore'] as int;
        
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        
        if (!monthlyScores.containsKey(monthKey)) {
          monthlyScores[monthKey] = [];
        }
        monthlyScores[monthKey]!.add(score);
      }

      List<double> previousTrend = [];
      for (int i = 11; i >= 0; i--) {
        final date = DateTime(yearAgo.year, yearAgo.month - i, 1);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        
        if (monthlyScores.containsKey(monthKey)) {
          final scores = monthlyScores[monthKey]!;
          previousTrend.add(scores.reduce((a, b) => a + b) / scores.length);
        } else {
          previousTrend.add(0.0);
        }
      }

      return previousTrend;
    } catch (e) {
      print('Error getting previous year mood trend: $e');
      return List.filled(12, 0.0);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}