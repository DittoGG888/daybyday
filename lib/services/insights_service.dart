// File: lib/services/insights_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daybyday/services/checkin_service.dart';
import 'package:daybyday/services/daily_patterns_service.dart';
import 'package:daybyday/services/goal_service.dart';

class InsightsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _checkInService = CheckInService();
  final _dailyPatternsService = DailyPatternsService();
  final _goalService = GoalService();

  // Generate personalized insights for a user
  Future<List<Insight>> generateInsights(String userId) async {
    List<Insight> insights = [];

    try {
      // Analyze sleep patterns
      final sleepInsight = await _analyzeSleepPatterns(userId);
      if (sleepInsight != null) insights.add(sleepInsight);

      // Analyze mood trends
      final moodInsight = await _analyzeMoodTrends(userId);
      if (moodInsight != null) insights.add(moodInsight);

      // Analyze goal completion
      final goalInsight = await _analyzeGoalCompletion(userId);
      if (goalInsight != null) insights.add(goalInsight);

      // Analyze screen time
      final screenTimeInsight = await _analyzeScreenTime(userId);
      if (screenTimeInsight != null) insights.add(screenTimeInsight);

      // Analyze activity levels
      final activityInsight = await _analyzeActivity(userId);
      if (activityInsight != null) insights.add(activityInsight);

      // Analyze check-in consistency
      final consistencyInsight = await _analyzeCheckInConsistency(userId);
      if (consistencyInsight != null) insights.add(consistencyInsight);

      // Sort by priority
      insights.sort((a, b) => b.priority.compareTo(a.priority));

      return insights;
    } catch (e) {
      print('Error generating insights: $e');
      return [];
    }
  }

  // Analyze sleep patterns
  Future<Insight?> _analyzeSleepPatterns(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final twoWeeksAgo = now.subtract(const Duration(days: 14));

      final thisWeekSleep = await _dailyPatternsService.getAverageSleep(
        userId,
        weekAgo,
        now,
      );
      final lastWeekSleep = await _dailyPatternsService.getAverageSleep(
        userId,
        twoWeeksAgo,
        weekAgo,
      );

      final thisWeekMinutes = thisWeekSleep['totalMinutes'] as int? ?? 0;
      final lastWeekMinutes = lastWeekSleep['totalMinutes'] as int? ?? 0;

      if (thisWeekMinutes == 0) return null;

      // Sleeping less than 7 hours
      if (thisWeekMinutes < 420) {
        return Insight(
          title: 'Sleep Quality Alert',
          message:
              'You\'re averaging ${thisWeekSleep['formatted']} of sleep. Aim for 7-9 hours to improve mood and energy.',
          type: InsightType.warning,
          category: InsightCategory.sleep,
          priority: 8,
          actionable: true,
          actionText: 'View sleep tips',
          icon: '😴',
        );
      }

      // Sleep declining
      if (lastWeekMinutes > 0 &&
          thisWeekMinutes < lastWeekMinutes - 30) {
        return Insight(
          title: 'Sleep Pattern Change',
          message:
              'Your sleep has decreased by ${((lastWeekMinutes - thisWeekMinutes) / 60).toStringAsFixed(1)} hours this week.',
          type: InsightType.warning,
          category: InsightCategory.sleep,
          priority: 7,
          actionable: true,
          actionText: 'Adjust sleep schedule',
          icon: '⚠️',
        );
      }

      // Good sleep
      if (thisWeekMinutes >= 420 && thisWeekMinutes <= 540) {
        return Insight(
          title: 'Excellent Sleep',
          message:
              'Great job! You\'re getting consistent, healthy sleep at ${thisWeekSleep['formatted']} per night.',
          type: InsightType.positive,
          category: InsightCategory.sleep,
          priority: 5,
          actionable: false,
          icon: '✨',
        );
      }

      return null;
    } catch (e) {
      print('Error analyzing sleep: $e');
      return null;
    }
  }

  // Analyze mood trends
  Future<Insight?> _analyzeMoodTrends(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final checkIns = await _checkInService.getCheckInsInRange(
        userId,
        weekAgo,
        now,
      );

      if (checkIns.length < 3) return null;

      final moodScores =
          checkIns.map((c) => c['moodScore'] as int).toList();
      final avgMood =
          moodScores.reduce((a, b) => a + b) / moodScores.length;

      // Low mood detected
      if (avgMood < 2.5) {
        return Insight(
          title: 'Mood Support',
          message:
              'Your mood has been lower than usual. Consider reaching out to someone or trying a mindfulness exercise.',
          type: InsightType.warning,
          category: InsightCategory.mood,
          priority: 9,
          actionable: true,
          actionText: 'View support resources',
          icon: '💙',
        );
      }

      // Mood improving
      final recentMood = moodScores.skip(moodScores.length - 3).toList();
      final recentAvg =
          recentMood.reduce((a, b) => a + b) / recentMood.length;

      if (recentAvg > avgMood + 0.5) {
        return Insight(
          title: 'Mood Improving',
          message:
              'Great news! Your mood has been trending upward over the last few days.',
          type: InsightType.positive,
          category: InsightCategory.mood,
          priority: 6,
          actionable: false,
          icon: '📈',
        );
      }

      return null;
    } catch (e) {
      print('Error analyzing mood: $e');
      return null;
    }
  }

  // Analyze goal completion
  Future<Insight?> _analyzeGoalCompletion(String userId) async {
    try {
      final dailyStats = await _goalService.getGoalStats(userId, 'daily');
      final weeklyStats = await _goalService.getGoalStats(userId, 'weekly');

      final dailyTotal = dailyStats['total'] ?? 0;
      final dailyCompleted = dailyStats['completed'] ?? 0;

      if (dailyTotal == 0) return null;

      final completionRate = dailyCompleted / dailyTotal;

      // Low completion rate
      if (completionRate < 0.3) {
        return Insight(
          title: 'Goal Completion Low',
          message:
              'You\'re completing ${(completionRate * 100).toStringAsFixed(0)}% of your daily goals. Consider setting fewer, more achievable goals.',
          type: InsightType.warning,
          category: InsightCategory.goals,
          priority: 6,
          actionable: true,
          actionText: 'Review goals',
          icon: '🎯',
        );
      }

      // High completion rate
      if (completionRate >= 0.8) {
        return Insight(
          title: 'Goal Achiever!',
          message:
              'Excellent! You\'re completing ${(completionRate * 100).toStringAsFixed(0)}% of your daily goals. Keep it up!',
          type: InsightType.positive,
          category: InsightCategory.goals,
          priority: 5,
          actionable: false,
          icon: '🏆',
        );
      }

      return null;
    } catch (e) {
      print('Error analyzing goals: $e');
      return null;
    }
  }

  // Analyze screen time
  Future<Insight?> _analyzeScreenTime(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final screenTime = await _dailyPatternsService.getAverageScreenTime(
        userId,
        weekAgo,
        now,
      );

      final totalMinutes = screenTime['totalMinutes'] as int? ?? 0;

      if (totalMinutes == 0) return null;

      final hours = totalMinutes / 60;

      // Excessive screen time
      if (hours > 6) {
        return Insight(
          title: 'High Screen Time',
          message:
              'You\'re averaging ${screenTime['formatted']} of screen time daily. Consider taking regular breaks.',
          type: InsightType.warning,
          category: InsightCategory.habits,
          priority: 6,
          actionable: true,
          actionText: 'Set screen limits',
          icon: '📱',
        );
      }

      // Healthy screen time
      if (hours >= 2 && hours <= 4) {
        return Insight(
          title: 'Balanced Screen Time',
          message:
              'You\'re maintaining healthy screen time at ${screenTime['formatted']} per day.',
          type: InsightType.positive,
          category: InsightCategory.habits,
          priority: 4,
          actionable: false,
          icon: '⚖️',
        );
      }

      return null;
    } catch (e) {
      print('Error analyzing screen time: $e');
      return null;
    }
  }

  // Analyze activity levels
  Future<Insight?> _analyzeActivity(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final activity = await _dailyPatternsService.getAverageSteps(
        userId,
        weekAgo,
        now,
      );

      final steps = activity['steps'] as int? ?? 0;

      if (steps == 0) return null;

      // Low activity
      if (steps < 5000) {
        return Insight(
          title: 'Activity Reminder',
          message:
              'You\'re averaging ${activity['formatted']} daily. Try to reach 7,000+ steps for better health.',
          type: InsightType.info,
          category: InsightCategory.habits,
          priority: 5,
          actionable: true,
          actionText: 'Plan activity',
          icon: '🚶',
        );
      }

      // Good activity
      if (steps >= 7000) {
        return Insight(
          title: 'Active Lifestyle',
          message:
              'Awesome! You\'re averaging ${activity['formatted']} daily. Stay active!',
          type: InsightType.positive,
          category: InsightCategory.habits,
          priority: 4,
          actionable: false,
          icon: '🏃',
        );
      }

      return null;
    } catch (e) {
      print('Error analyzing activity: $e');
      return null;
    }
  }

  // Analyze check-in consistency
  Future<Insight?> _analyzeCheckInConsistency(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final checkIns = await _checkInService.getCheckInsInRange(
        userId,
        weekAgo,
        now,
      );

      final daysWithCheckIns = <String>{};
      for (var checkIn in checkIns) {
        daysWithCheckIns.add(checkIn['date']);
      }

      final consistency = daysWithCheckIns.length / 7;

      // Low consistency
      if (consistency < 0.5) {
        return Insight(
          title: 'Check-in Reminder',
          message:
              'You\'ve checked in ${daysWithCheckIns.length} out of 7 days. Daily check-ins help track progress better.',
          type: InsightType.info,
          category: InsightCategory.engagement,
          priority: 5,
          actionable: true,
          actionText: 'Set reminder',
          icon: '⏰',
        );
      }

      // High consistency
      if (consistency >= 0.85) {
        return Insight(
          title: 'Consistency Champion',
          message:
              'Amazing! You\'ve checked in ${daysWithCheckIns.length} out of 7 days. Your dedication shows!',
          type: InsightType.positive,
          category: InsightCategory.engagement,
          priority: 5,
          actionable: false,
          icon: '🔥',
        );
      }

      return null;
    } catch (e) {
      print('Error analyzing consistency: $e');
      return null;
    }
  }

  // Save insight to history
  Future<void> saveInsightToHistory(String userId, Insight insight) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('insightHistory')
          .add({
        'title': insight.title,
        'message': insight.message,
        'type': insight.type.toString(),
        'category': insight.category.toString(),
        'priority': insight.priority,
        'icon': insight.icon,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error saving insight: $e');
    }
  }

  // Get insight history
  Future<List<Map<String, dynamic>>> getInsightHistory(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('insightHistory')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting insight history: $e');
      return [];
    }
  }

  // Mark insight as read
  Future<void> markInsightAsRead(String userId, String insightId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('insightHistory')
          .doc(insightId)
          .update({'read': true});
    } catch (e) {
      print('Error marking insight as read: $e');
    }
  }
}

// Insight Model
class Insight {
  final String title;
  final String message;
  final InsightType type;
  final InsightCategory category;
  final int priority; // 1-10, higher = more important
  final bool actionable;
  final String? actionText;
  final String icon;

  Insight({
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.priority,
    required this.actionable,
    this.actionText,
    required this.icon,
  });
}

enum InsightType {
  positive, // Green - celebrating wins
  warning, // Orange - needs attention
  info, // Blue - informational
}

enum InsightCategory {
  mood,
  sleep,
  goals,
  habits,
  engagement,
}