// File: lib/chat/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daybyday/chat/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messagesRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chatMessages');
  }

  Stream<List<ChatMessage>> watchMessages(String userId) {
    return _messagesRef(userId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessage.fromDoc(d)).toList());
  }

  Future<void> sendMessage(String userId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMessage = ChatMessage(id: '', text: trimmed, isUser: true);
    await _messagesRef(userId).add(userMessage.toMap());

    // Placeholder reply — Phase B replaces this with a real call
    // to the Cloud Function backing the Ollama VM.
    await Future.delayed(const Duration(milliseconds: 500));
    final placeholderReply = ChatMessage(
      id: '',
      text: "Thanks for sharing that. (This is a placeholder reply — "
          "the real coach is still being wired up.)",
      isUser: false,
    );
    await _messagesRef(userId).add(placeholderReply.toMap());
  }
}