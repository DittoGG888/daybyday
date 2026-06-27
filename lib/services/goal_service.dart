// File: lib/services/goal_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new goal
  Future<String> createGoal({
    required String userId,
    required String description,
    required String category,
    required String duration,
    DateTime? specificDate,
    String? time,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final goalsRef = userRef.collection('goals').doc();

      await _firestore.runTransaction((tx) async {
        final userRef = _firestore.collection('users').doc(userId);
        final goalRef = userRef.collection('goals').doc();

        final userSnap = await tx.get(userRef);
        final hasCreatedFirstGoal =
            userSnap.data()?['hasCreatedFirstGoal'] == true;

        // Create goal with completion tracking
        tx.set(goalRef, {
          'description': description,
          'category': category,
          'duration': duration,
          'specificDate': specificDate?.toIso8601String(),
          'time': time,
          'isCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
          // Add completion tracking for recurring goals
          'completions': {}, // Map of date -> bool
          'lastCompletedDate': null,
        });

        // Mark first goal only once
        if (!hasCreatedFirstGoal) {
          tx.set(userRef, {
            'hasCreatedFirstGoal': true,
          }, SetOptions(merge: true));
        }
      });

      return goalsRef.id;
    } catch (e) {
      print('Error creating goal: $e');
      rethrow;
    }
  }

  // Get all goals for a user with current period completion status
  Future<List<Map<String, dynamic>>> getGoals(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .orderBy('createdAt', descending: true)
          .get();

      final now = DateTime.now();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Calculate if goal is completed for current period
        final duration = data['duration'] as String;
        final completions = data['completions'] as Map<String, dynamic>? ?? {};
        
        data['isCompleted'] = _isCompletedForCurrentPeriod(
          duration: duration,
          completions: completions,
          now: now,
        );
        
        return data;
      }).toList();
    } catch (e) {
      print('Error getting goals: $e');
      return [];
    }
  }

  // Get goals by duration with period-specific completion
  Future<List<Map<String, dynamic>>> getGoalsByDuration(
    String userId,
    String duration,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .where('duration', isEqualTo: duration)
          .orderBy('createdAt', descending: true)
          .get();

      final now = DateTime.now();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Calculate if goal is completed for current period
        final completions = data['completions'] as Map<String, dynamic>? ?? {};
        
        data['isCompleted'] = _isCompletedForCurrentPeriod(
          duration: duration,
          completions: completions,
          now: now,
        );
        
        return data;
      }).toList();
    } catch (e) {
      print('Error getting goals by duration: $e');
      return [];
    }
  }

  // Toggle goal completion for current period
  Future<void> toggleGoalCompletion(
    String userId,
    String goalId,
    bool isCompleted,
  ) async {
    try {
      final goalDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(goalId)
          .get();

      if (!goalDoc.exists) return;

      final data = goalDoc.data()!;
      final duration = data['duration'] as String;
      final completions = Map<String, dynamic>.from(data['completions'] ?? {});
      
      final now = DateTime.now();
      final periodKey = _getPeriodKey(duration, now);
      
      // Update completion for current period
      completions[periodKey] = isCompleted;
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(goalId)
          .update({
            'completions': completions,
            'lastCompletedDate': isCompleted ? _formatDate(now) : data['lastCompletedDate'],
          });
    } catch (e) {
      print('Error toggling goal completion: $e');
      rethrow;
    }
  }

  // Update goal
  Future<void> updateGoal(
    String userId,
    String goalId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(goalId)
          .update(data);
    } catch (e) {
      print('Error updating goal: $e');
      rethrow;
    }
  }

  // Delete goal
  Future<void> deleteGoal(String userId, String goalId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final goalRef = userRef.collection('goals').doc(goalId);

      await _firestore.runTransaction((tx) async {
        final userSnap = await tx.get(userRef);

        final currentCount = (userSnap.data()?['goalsCount'] ?? 0) as int;
        final newCount = (currentCount - 1).clamp(0, 9999);

        // Delete goal
        tx.delete(goalRef);

        // Update goals count
        tx.set(userRef, {'goalsCount': newCount}, SetOptions(merge: true));
      });
    } catch (e) {
      print('Error deleting goal: $e');
      rethrow;
    }
  }

  // Get goal completion stats for current period
  Future<Map<String, int>> getGoalStats(String userId, String duration) async {
    try {
      final goals = await getGoalsByDuration(userId, duration);
      final completed = goals.where((g) => g['isCompleted'] == true).length;
      final total = goals.length;

      return {
        'completed': completed,
        'total': total,
        'remaining': total - completed,
      };
    } catch (e) {
      print('Error getting goal stats: $e');
      return {'completed': 0, 'total': 0, 'remaining': 0};
    }
  }

  // Helper: Check if goal is completed for current period
  bool _isCompletedForCurrentPeriod({
    required String duration,
    required Map<String, dynamic> completions,
    required DateTime now,
  }) {
    final periodKey = _getPeriodKey(duration, now);
    return completions[periodKey] == true;
  }

  // Helper: Get period key for storage
  String _getPeriodKey(String duration, DateTime date) {
    switch (duration) {
      case 'daily':
        return _formatDate(date);
      case 'weekly':
        // Week starts on Monday
        final monday = date.subtract(Duration(days: date.weekday - 1));
        return 'week-${_formatDate(monday)}';
      case 'monthly':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case 'yearly':
        return '${date.year}';
      default:
        return _formatDate(date);
    }
  }

  // Helper: Get period date going back
  DateTime _getPeriodDate(String duration, DateTime now, int periodsBack) {
    switch (duration) {
      case 'daily':
        return now.subtract(Duration(days: periodsBack));
      case 'weekly':
        return now.subtract(Duration(days: periodsBack * 7));
      case 'monthly':
        return DateTime(now.year, now.month - periodsBack, now.day);
      case 'yearly':
        return DateTime(now.year - periodsBack, now.month, now.day);
      default:
        return now;
    }
  }

  // Helper: Get period label for display
  String _getPeriodLabel(String duration, DateTime date) {
    switch (duration) {
      case 'daily':
        return '${date.month}/${date.day}';
      case 'weekly':
        final monday = date.subtract(Duration(days: date.weekday - 1));
        return '${monday.month}/${monday.day}';
      case 'monthly':
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return months[date.month - 1];
      case 'yearly':
        return '${date.year}';
      default:
        return _formatDate(date);
    }
  }

  // Get goal completion history (for analytics)
  Future<Map<String, dynamic>> getGoalCompletionHistory(
    String userId,
    String duration,
    {int periodsBack = 4}
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .where('duration', isEqualTo: duration)
          .get();

      final now = DateTime.now();
      List<Map<String, dynamic>> periodData = [];

      for (int i = periodsBack - 1; i >= 0; i--) {
        final periodDate = _getPeriodDate(duration, now, i);
        final periodKey = _getPeriodKey(duration, periodDate);
        final periodLabel = _getPeriodLabel(duration, periodDate);
        
        int completed = 0;
        int total = snapshot.docs.length;

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final completions = data['completions'] as Map<String, dynamic>? ?? {};
          
          if (completions[periodKey] == true) {
            completed++;
          }
        }

        periodData.add({
          'period': periodLabel,
          'completed': completed,
          'total': total,
          'percentage': total > 0 ? (completed / total * 100).round() : 0,
        });
      }

      return {
        'periods': periodData,
        'duration': duration,
      };
    } catch (e) {
      print('Error getting goal completion history: $e');
      return {'periods': [], 'duration': duration};
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}