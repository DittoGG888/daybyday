// File: lib/services/assessment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AssessmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save assessment results
  Future<void> saveAssessmentResults({
    required String userId,
    required Map<String, dynamic> results,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('assessments')
          .add({
            'results': results,
            'completedAt': FieldValue.serverTimestamp(),
          });

      // Also save to main user document for easy access
      await _firestore.collection('users').doc(userId).set({
        'latestAssessment': results,
        'hasCompletedAssessment': true,
        'assessmentCompletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving assessment results: $e');
      rethrow;
    }
  }

  // Get latest assessment results
  Future<Map<String, dynamic>?> getLatestAssessment(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['latestAssessment'] as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting latest assessment: $e');
      return null;
    }
  }

  // Get all assessments (history)
  Future<List<Map<String, dynamic>>> getAssessmentHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('assessments')
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting assessment history: $e');
      return [];
    }
  }
}
