// File: lib/services/daily_patterns_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyPatternsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save daily patterns
  Future<void> saveDailyPatterns({
    required String userId,
    required int sleepHours,
    required int sleepMinutes,
    required int screenHours,
    required int screenMinutes,
    required int steps,
  }) async {
    try {
      final date = _formatDate(DateTime.now());
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyPatterns')
          .doc(date) // Use date as document ID for easy querying
          .set({
        'date': date,
        'sleep': {
          'hours': sleepHours,
          'minutes': sleepMinutes,
          'totalMinutes': (sleepHours * 60) + sleepMinutes,
          'formatted': '${sleepHours}h${sleepMinutes}m',
        },
        'screenTime': {
          'hours': screenHours,
          'minutes': screenMinutes,
          'totalMinutes': (screenHours * 60) + screenMinutes,
          'formatted': '${screenHours}h${screenMinutes}m',
        },
        'activity': {
          'steps': steps,
        },
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge to allow updates
    } catch (e) {
      print('Error saving daily patterns: $e');
      rethrow;
    }
  }

  // Get daily patterns for a specific date
  Future<Map<String, dynamic>?> getDailyPatterns(
    String userId,
    DateTime date,
  ) async {
    try {
      final dateStr = _formatDate(date);
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyPatterns')
          .doc(dateStr)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting daily patterns: $e');
      return null;
    }
  }

  // Get daily patterns for date range
  Future<List<Map<String, dynamic>>> getDailyPatternsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyPatterns')
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr)
          .orderBy('date')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting daily patterns in range: $e');
      return [];
    }
  }

  // Get average sleep for a period
  Future<Map<String, dynamic>> getAverageSleep(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final patterns = await getDailyPatternsInRange(userId, startDate, endDate);
      
      if (patterns.isEmpty) {
        return {
          'hours': 0,
          'minutes': 0,
          'formatted': 'No data',
        };
      }

      final totalMinutes = patterns.fold<int>(
        0,
        (sum, pattern) => sum + (pattern['sleep']['totalMinutes'] as int),
      );

      final avgMinutes = totalMinutes ~/ patterns.length;
      final hours = avgMinutes ~/ 60;
      final minutes = avgMinutes % 60;

      return {
        'hours': hours,
        'minutes': minutes,
        'formatted': 'Avg ${hours}h${minutes}m',
        'totalMinutes': avgMinutes,
      };
    } catch (e) {
      print('Error getting average sleep: $e');
      return {
        'hours': 0,
        'minutes': 0,
        'formatted': 'No data',
      };
    }
  }

  // Get average screen time for a period
  Future<Map<String, dynamic>> getAverageScreenTime(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final patterns = await getDailyPatternsInRange(userId, startDate, endDate);
      
      if (patterns.isEmpty) {
        return {
          'hours': 0,
          'minutes': 0,
          'formatted': 'No data',
        };
      }

      final totalMinutes = patterns.fold<int>(
        0,
        (sum, pattern) => sum + (pattern['screenTime']['totalMinutes'] as int),
      );

      final avgMinutes = totalMinutes ~/ patterns.length;
      final hours = avgMinutes ~/ 60;
      final minutes = avgMinutes % 60;

      return {
        'hours': hours,
        'minutes': minutes,
        'formatted': 'Avg ${hours}h${minutes}m',
        'totalMinutes': avgMinutes,
      };
    } catch (e) {
      print('Error getting average screen time: $e');
      return {
        'hours': 0,
        'minutes': 0,
        'formatted': 'No data',
      };
    }
  }

  // Get average steps for a period
  Future<Map<String, dynamic>> getAverageSteps(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final patterns = await getDailyPatternsInRange(userId, startDate, endDate);
      
      if (patterns.isEmpty) {
        return {
          'steps': 0,
          'formatted': 'No data',
        };
      }

      final totalSteps = patterns.fold<int>(
        0,
        (sum, pattern) => sum + (pattern['activity']['steps'] as int),
      );

      final avgSteps = totalSteps ~/ patterns.length;

      return {
        'steps': avgSteps,
        'formatted': 'Avg ${_formatNumber(avgSteps)} steps',
      };
    } catch (e) {
      print('Error getting average steps: $e');
      return {
        'steps': 0,
        'formatted': 'No data',
      };
    }
  }

  // Get weekly summary
  Future<Map<String, dynamic>> getWeeklySummary(String userId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    try {
      final sleep = await getAverageSleep(userId, weekAgo, now);
      final screenTime = await getAverageScreenTime(userId, weekAgo, now);
      final steps = await getAverageSteps(userId, weekAgo, now);

      return {
        'sleep': sleep['formatted'],
        'screenTime': screenTime['formatted'],
        'steps': steps['formatted'],
      };
    } catch (e) {
      print('Error getting weekly summary: $e');
      return {
        'sleep': 'No data',
        'screenTime': 'No data',
        'steps': 'No data',
      };
    }
  }

  // Get sleep quality trend (percentage of days meeting 7+ hours)
  Future<double> getSleepQualityPercentage(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final patterns = await getDailyPatternsInRange(userId, startDate, endDate);
      
      if (patterns.isEmpty) return 0.0;

      final goodSleepDays = patterns.where(
        (pattern) => pattern['sleep']['totalMinutes'] >= 420, // 7 hours = 420 minutes
      ).length;

      return (goodSleepDays / patterns.length) * 100;
    } catch (e) {
      print('Error getting sleep quality: $e');
      return 0.0;
    }
  }

  // Get screen time trend (percentage change)
  Future<double> getScreenTimeTrend(String userId) async {
    try {
      final now = DateTime.now();
      final thisWeekStart = now.subtract(const Duration(days: 7));
      final lastWeekStart = now.subtract(const Duration(days: 14));
      final lastWeekEnd = now.subtract(const Duration(days: 7));

      final thisWeek = await getAverageScreenTime(userId, thisWeekStart, now);
      final lastWeek = await getAverageScreenTime(userId, lastWeekStart, lastWeekEnd);

      if (lastWeek['totalMinutes'] == 0) return 0.0;

      final change = ((thisWeek['totalMinutes'] - lastWeek['totalMinutes']) / 
                      lastWeek['totalMinutes']) * 100;

      return change;
    } catch (e) {
      print('Error getting screen time trend: $e');
      return 0.0;
    }
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Helper method to format numbers with commas
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}