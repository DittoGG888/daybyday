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

        // Create goal
        tx.set(goalRef, {
          'description': description,
          'category': category,
          'duration': duration,
          'specificDate': specificDate?.toIso8601String(),
          'time': time,
          'isCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
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

  // Get all goals for a user
  Future<List<Map<String, dynamic>>> getGoals(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting goals: $e');
      return [];
    }
  }

  // Get goals by duration (daily, weekly, monthly)
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

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting goals by duration: $e');
      return [];
    }
  }

  // Toggle goal completion
  Future<void> toggleGoalCompletion(
    String userId,
    String goalId,
    bool isCompleted,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(goalId)
          .update({
            'isCompleted': isCompleted,
            'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
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

  // Get goal completion stats
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
}
