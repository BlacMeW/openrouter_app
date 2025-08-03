import 'package:equatable/equatable.dart';
import '../models/chat_message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class SendMessage extends ChatEvent {
  final String message;
  final String modelId;

  const SendMessage({required this.message, required this.modelId});

  @override
  List<Object> get props => [message, modelId];
}

class StartTyping extends ChatEvent {
  final String modelId;

  const StartTyping({required this.modelId});

  @override
  List<Object> get props => [modelId];
}

class StopTyping extends ChatEvent {
  const StopTyping();

  @override
  List<Object> get props => [];
}

class ClearChat extends ChatEvent {
  const ClearChat();

  @override
  List<Object> get props => [];
}

class LoadChatHistory extends ChatEvent {
  const LoadChatHistory();

  @override
  List<Object> get props => [];
}

class AddMessage extends ChatEvent {
  final ChatMessage message;

  const AddMessage({required this.message});

  @override
  List<Object> get props => [message];
}

class UpdateStreamingMessage extends ChatEvent {
  final String messageId;
  final String content;

  const UpdateStreamingMessage({
    required this.messageId,
    required this.content,
  });

  @override
  List<Object> get props => [messageId, content];
}