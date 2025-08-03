import 'package:equatable/equatable.dart';

enum MessageType { user, ai }

class ChatMessage extends Equatable {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isStreaming;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isStreaming = false,
  });

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.ai(String content, {bool isStreaming = false}) {
    return ChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      type: MessageType.ai,
      timestamp: DateTime.now(),
      isStreaming: isStreaming,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  @override
  List<Object> get props => [id, content, type, timestamp, isStreaming];

  @override
  String toString() {
    return 'ChatMessage(id: $id, type: $type, content: ${content.length} chars, timestamp: $timestamp)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isStreaming': isStreaming,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      type: _parseMessageType(json['type'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isStreaming: json['isStreaming'] as bool? ?? false,
    );
  }

  static MessageType _parseMessageType(String typeString) {
    switch (typeString) {
      case 'MessageType.user':
        return MessageType.user;
      case 'MessageType.ai':
        return MessageType.ai;
      default:
        return MessageType.user;
    }
  }
}