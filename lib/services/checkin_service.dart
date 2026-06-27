// File: lib/services/checkin_service.dart (ADD THIS METHOD)
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckInService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save check-in
  Future<void> saveCheckIn({
    required String userId,
    required String date,
    required String timeOfDay,
    required String moodLabel,
    required int moodScore,
    required int taskEffectiveness,
    String? reflection,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('checkIns')
          .add({
        'date': date,
        'timeOfDay': timeOfDay,
        'moodLabel': moodLabel,
        'moodScore': moodScore,
        'taskEffectiveness': taskEffectiveness,
        'reflection': reflection,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving check-in: $e');
      rethrow;
    }
  }

  // Get check-ins for a specific date (STRING FORMAT)
  Future<Map<String, Map<String, dynamic>>> getCheckInsForDate(
      String userId, String date) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('checkIns')
          .where('date', isEqualTo: date)
          .get();

      Map<String, Map<String, dynamic>> checkIns = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        checkIns[data['timeOfDay']] = data;
      }
      return checkIns;
    } catch (e) {
      print('Error getting check-ins for date: $e');
      return {};
    }
  }

  // Get check-ins for date range (for analytics)
  Future<List<Map<String, dynamic>>> getCheckInsInRange(
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
          .collection('checkIns')
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr)
          .orderBy('date')
          .orderBy('createdAt')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting check-ins in range: $e');
      return [];
    }
  }

  // Get today's check-in status
  Future<Map<String, bool>> getTodayCheckInStatus(String userId) async {
    final today = _formatDate(DateTime.now());
    final checkIns = await getCheckInsForDate(userId, today);

    return {
      'morning': checkIns.containsKey('morning'),
      'evening': checkIns.containsKey('evening'),
      'night': checkIns.containsKey('night'),
    };
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get average mood for a time period
  Future<double> getAverageMood(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final checkIns = await getCheckInsInRange(userId, startDate, endDate);
    if (checkIns.isEmpty) return 0.0;

    final totalMood = checkIns.fold<int>(
      0,
      (sum, checkIn) => sum + (checkIn['moodScore'] as int),
    );

    return totalMood / checkIns.length;
  }
}