// File: lib/chat/chat_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime? timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.timestamp,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      text: data['text'] as String? ?? '',
      isUser: data['isUser'] as bool? ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}