import 'package:equatable/equatable.dart';
import '../models/chat_message.dart';
import '../models/ai_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final AIModel selectedModel;
  final bool isTyping;
  final String? error;

  const ChatLoaded({
    required this.messages,
    required this.selectedModel,
    this.isTyping = false,
    this.error,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    AIModel? selectedModel,
    bool? isTyping,
    String? error,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      selectedModel: selectedModel ?? this.selectedModel,
      isTyping: isTyping ?? this.isTyping,
      error: error,
    );
  }

  @override
  List<Object> get props => [messages, selectedModel, isTyping, error ?? ''];

  @override
  String toString() {
    return 'ChatLoaded(messages: ${messages.length}, selectedModel: ${selectedModel.name}, isTyping: $isTyping, error: $error)';
  }
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];

  @override
  String toString() => 'ChatError: $message';
}