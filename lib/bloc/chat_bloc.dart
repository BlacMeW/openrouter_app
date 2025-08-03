import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/chat_message.dart';
import '../models/ai_model.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final List<AIModel> _availableModels = [
    AIModel(
      id: 'openai/gpt-4',
      name: 'GPT-4',
      description: 'OpenAI GPT-4',
      provider: 'OpenAI',
      isDefault: true,
    ),
    AIModel(
      id: 'anthropic/claude-3-haiku',
      name: 'Claude 3 Haiku',
      description: 'Anthropic Claude 3 Haiku',
      provider: 'Anthropic',
    ),
    AIModel(
      id: 'mistralai/mixtral-8x7b',
      name: 'Mixtral 8x7B',
      description: 'Mistral AI Mixtral 8x7B',
      provider: 'Mistral AI',
    ),
    AIModel(
      id: 'google/gemini-pro',
      name: 'Gemini Pro',
      description: 'Google Gemini Pro',
      provider: 'Google',
    ),
  ];

  ChatBloc() : super(const ChatInitial()) {
    on<SendMessage>(_onSendMessage);
    on<StartTyping>(_onStartTyping);
    on<StopTyping>(_onStopTyping);
    on<ClearChat>(_onClearChat);
    on<LoadChatHistory>(_onLoadChatHistory);
    on<AddMessage>(_onAddMessage);
    on<UpdateStreamingMessage>(_onUpdateStreamingMessage);
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(ChatLoaded(
        messages: [...(state is ChatLoaded ? (state as ChatLoaded).messages : [])],
        selectedModel: _getSelectedModel(event.modelId),
        isTyping: true,
      ));

      final userMessage = ChatMessage.user(event.message);
      add(AddMessage(message: userMessage));

      final apiKey = await _secureStorage.read(key: 'openrouter_api_key');
      if (apiKey == null) {
        emit(ChatError('API key not found. Please set your API key in settings.'));
        return;
      }

      final aiMessage = ChatMessage.ai('', isStreaming: true);
      add(AddMessage(message: aiMessage));

      await _streamResponse(event.message, event.modelId, aiMessage.id, emit);
    } catch (e) {
      emit(ChatError('Failed to send message: ${e.toString()}'));
    }
  }

  Future<void> _streamResponse(
    String message,
    String modelId,
    String messageId,
    Emitter<ChatState> emit,
  ) async {
    try {
      final apiKey = await _secureStorage.read(key: 'openrouter_api_key');
      final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

      final request = http.Request(
        'POST',
        url,
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': 'https://your-app.com',
        'X-Title': 'AI Coder Chat',
      });

      request.body = jsonEncode({
        'model': modelId,
        'messages': [
          {'role': 'user', 'content': message}
        ],
        'stream': true,
        'temperature': 0.7,
      });

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        final stream = streamedResponse.stream;
        final contentBuffer = StringBuffer();

        await for (final chunk in stream.transform(utf8.decoder)) {
          if (chunk.trim().isNotEmpty) {
            final lines = chunk.split('\n');
            for (final line in lines) {
              if (line.startsWith('data: ')) {
                final data = line.substring(6);
                if (data.trim() == '[DONE]') {
                  break;
                }
                try {
                  final json = jsonDecode(data);
                  final content = json['choices']?[0]?['delta']?['content'];
                  if (content != null) {
                    contentBuffer.write(content);
                    add(UpdateStreamingMessage(
                      messageId: messageId,
                      content: contentBuffer.toString(),
                    ));
                  }
                } catch (e) {
                  // Skip malformed JSON chunks
                }
              }
            }
          }
        }

        // Final update with complete content
        add(UpdateStreamingMessage(
          messageId: messageId,
          content: contentBuffer.toString(),
        ));
      } else {
        throw Exception('Failed to get response: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      emit(ChatError('Streaming error: ${e.toString()}'));
    }
  }

  void _onStartTyping(StartTyping event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(isTyping: true));
    }
  }

  void _onStopTyping(StopTyping event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(isTyping: false));
    }
  }

  void _onClearChat(ClearChat event, Emitter<ChatState> emit) {
    emit(const ChatInitial());
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistory event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatLoading());

      // Load saved messages from secure storage
      final savedMessages = await _secureStorage.read(key: 'chat_history');
      List<ChatMessage> messages = [];

      if (savedMessages != null) {
        final List<dynamic> jsonList = jsonDecode(savedMessages);
        messages = jsonList.map((json) => ChatMessage.fromJson(json)).toList();
      }

      // Load selected model
      final savedModelId = await _secureStorage.read(key: 'selected_model');
      final selectedModel = savedModelId != null
          ? _availableModels.firstWhere(
              (model) => model.id == savedModelId,
              orElse: () => _availableModels.first,
            )
          : _availableModels.first;

      emit(ChatLoaded(
        messages: messages,
        selectedModel: selectedModel,
      ));
    } catch (e) {
      emit(ChatError('Failed to load chat history: ${e.toString()}'));
    }
  }

  void _onAddMessage(AddMessage event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final updatedMessages = [...currentState.messages, event.message];
      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  void _onUpdateStreamingMessage(
    UpdateStreamingMessage event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final updatedMessages = currentState.messages.map((message) {
        if (message.id == event.messageId) {
          return message.copyWith(content: event.content);
        }
        return message;
      }).toList();
      emit(currentState.copyWith(messages: updatedMessages, isTyping: false));
    }
  }

  AIModel _getSelectedModel(String modelId) {
    return _availableModels.firstWhere(
      (model) => model.id == modelId,
      orElse: () => _availableModels.first,
    );
  }

  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    try {
      final jsonMessages = messages.map((message) => message.toJson()).toList();
      await _secureStorage.write(
        key: 'chat_history',
        value: jsonEncode(jsonMessages),
      );
    } catch (e) {
      // Handle error silently or log it
    }
  }

  Future<void> saveSelectedModel(String modelId) async {
    try {
      await _secureStorage.write(key: 'selected_model', value: modelId);
    } catch (e) {
      // Handle error silently or log it
    }
  }

  List<AIModel> get availableModels => _availableModels;
}