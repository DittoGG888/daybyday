// File: lib/services/journal_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save journal entry
  Future<String> saveJournalEntry({
    required String userId,
    required String type, // 'general', 'reflection', 'gratitude'
    required String content,
    String? prompt,
    List<String>? gratitudeItems,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('journalEntries')
          .add({
        'type': type,
        'content': content,
        'prompt': prompt,
        'gratitudeItems': gratitudeItems,
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'date': _formatDate(DateTime.now()),
      });

      return docRef.id;
    } catch (e) {
      print('Error saving journal entry: $e');
      rethrow;
    }
  }

  // Get journal entries by type
  Future<List<Map<String, dynamic>>> getJournalEntries(
    String userId,
    String type, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('journalEntries')
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting journal entries: $e');
      return [];
    }
  }

  // Get all journal entries
  Future<List<Map<String, dynamic>>> getAllJournalEntries(
    String userId, {
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('journalEntries')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting all journal entries: $e');
      return [];
    }
  }

  // Update journal entry
  Future<void> updateJournalEntry(
    String userId,
    String entryId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('journalEntries')
          .doc(entryId)
          .update(data);
    } catch (e) {
      print('Error updating journal entry: $e');
      rethrow;
    }
  }

  // Delete journal entry
  Future<void> deleteJournalEntry(String userId, String entryId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('journalEntries')
          .doc(entryId)
          .delete();
    } catch (e) {
      print('Error deleting journal entry: $e');
      rethrow;
    }
  }

  // Get journal stats
  Future<Map<String, int>> getJournalStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('journalEntries')
          .get();

      int general = 0;
      int reflection = 0;
      int gratitude = 0;

      for (var doc in snapshot.docs) {
        final type = doc.data()['type'] as String?;
        switch (type) {
          case 'general':
            general++;
            break;
          case 'reflection':
            reflection++;
            break;
          case 'gratitude':
            gratitude++;
            break;
        }
      }

      return {
        'general': general,
        'reflection': reflection,
        'gratitude': gratitude,
        'total': snapshot.docs.length,
      };
    } catch (e) {
      print('Error getting journal stats: $e');
      return {'general': 0, 'reflection': 0, 'gratitude': 0, 'total': 0};
    }
  }

  // Search journal entries
  Future<List<Map<String, dynamic>>> searchJournalEntries(
    String userId,
    String searchQuery,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('journalEntries')
          .orderBy('createdAt', descending: true)
          .get();

      final results = snapshot.docs.where((doc) {
        final data = doc.data();
        final content = (data['content'] as String? ?? '').toLowerCase();
        final prompt = (data['prompt'] as String? ?? '').toLowerCase();
        final query = searchQuery.toLowerCase();
        
        return content.contains(query) || prompt.contains(query);
      }).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      return results;
    } catch (e) {
      print('Error searching journal entries: $e');
      return [];
    }
  }

  // Get entries for a specific date
  Future<List<Map<String, dynamic>>> getEntriesForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final dateStr = _formatDate(date);
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('journalEntries')
          .where('date', isEqualTo: dateStr)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting entries for date: $e');
      return [];
    }
  }

  // Get entry streak (consecutive days with entries)
  Future<int> getEntryStreak(String userId) async {
    try {
      final now = DateTime.now();
      int streak = 0;
      DateTime checkDate = now;

      for (int i = 0; i < 365; i++) {
        final entries = await getEntriesForDate(userId, checkDate);
        
        if (entries.isEmpty) {
          break;
        }
        
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      return streak;
    } catch (e) {
      print('Error getting entry streak: $e');
      return 0;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}