import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/ai_model.dart';
import '../models/chat_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final List<AIModel> _availableModels = [
    // AIModel(
    //   id: 'openai/gpt-4',
    //   name: 'GPT-4',
    //   description: 'OpenAI GPT-4',
    //   provider: 'OpenAI',
    //   isDefault: true,
    // ),
    // AIModel(
    //   id: 'anthropic/claude-3-haiku',
    //   name: 'Claude 3 Haiku',
    //   description: 'Anthropic Claude 3 Haiku',
    //   provider: 'Anthropic',
    // ),
    // AIModel(
    //   id: 'mistralai/mixtral-8x7b',
    //   name: 'Mixtral 8x7B',
    //   description: 'Mistral AI Mixtral 8x7B',
    //   provider: 'Mistral AI',
    // ),
    // AIModel(
    //   id: 'google/gemini-pro',
    //   name: 'Gemini Pro',
    //   description: 'Google Gemini Pro',
    //   provider: 'Google',
    // ),
    // Free AI Models from OpenRouter
    AIModel(
      id: 'google/gemini-2.0-flash-exp:free',
      name: 'Gemini 2.0 Flash (Free)',
      description: 'Google Gemini 2.0 Flash - Free tier',
      provider: 'Google',
    ),
    AIModel(
      id: 'google/gemini-2.0-flash-thinking-exp:free',
      name: 'Gemini 2.0 Flash Thinking (Free)',
      description: 'Google Gemini 2.0 Flash Thinking - Free tier',
      provider: 'Google',
    ),
    AIModel(
      id: 'meta-llama/llama-3.2-3b-instruct:free',
      name: 'Llama 3.2 3B (Free)',
      description: 'Meta Llama 3.2 3B Instruct - Free tier',
      provider: 'Meta',
    ),
    AIModel(
      id: 'meta-llama/llama-3.1-8b-instruct:free',
      name: 'Llama 3.1 8B (Free)',
      description: 'Meta Llama 3.1 8B Instruct - Free tier',
      provider: 'Meta',
    ),
    // Removed: microsoft/phi-3-mini-128k-instruct:free - returns 404
    AIModel(
      id: 'mistralai/mistral-7b-instruct:free',
      name: 'Mistral 7B (Free)',
      description: 'Mistral 7B Instruct - Free tier',
      provider: 'Mistral AI',
    ),
    // Removed: openchat/openchat-7b:free - returns 404
    // Removed: gryphe/mythomax-l2-13b:free - returns 404
    // Additional Free Models
    AIModel(
      id: 'deepseek/deepseek-chat:free',
      name: 'DeepSeek Chat (Free)',
      description: 'DeepSeek Chat - Free tier',
      provider: 'DeepSeek',
    ),
    // Removed: moonshotai/kimi-k2:free - returns 404
    AIModel(
      id: 'qwen/qwen-2.5-7b-instruct:free',
      name: 'Qwen 2.5 7B (Free)',
      description: 'Qwen 2.5 7B Instruct - Free tier',
      provider: 'Qwen',
    ),
    AIModel(
      id: 'cohere/command-r7b-12-2024:free',
      name: 'Command R7B (Free)',
      description: 'Cohere Command R7B - Free tier',
      provider: 'Cohere',
    ),
    AIModel(
      id: 'nousresearch/hermes-3-llama-3.1-8b:free',
      name: 'Hermes 3 8B (Free)',
      description: 'Nous Research Hermes 3 Llama 3.1 8B - Free tier',
      provider: 'Nous Research',
    ),
    AIModel(
      id: 'huggingfaceh4/zephyr-7b-beta:free',
      name: 'Zephyr 7B Beta (Free)',
      description: 'Hugging Face Zephyr 7B Beta - Free tier',
      provider: 'Hugging Face',
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
    on<SelectModel>(_onSelectModel);
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    try {
      emit(
        ChatLoaded(
          messages: [...(state is ChatLoaded ? (state as ChatLoaded).messages : [])],
          selectedModel: _getSelectedModel(event.modelId),
          isTyping: true,
        ),
      );

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

      // Diagnostic logging for model validation
      print('🔍 DIAGNOSTIC: Attempting to use model: $modelId');
      print('🔍 DIAGNOSTIC: Request URL: $url');
      print('🔍 DIAGNOSTIC: API Key present: ${apiKey != null ? 'Yes' : 'No'}');

      final request = http.Request('POST', url);

      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': 'https://your-app.com',
        'X-Title': 'AI Coder Chat',
      });

      final requestBody = {
        'model': modelId,
        'messages': [
          {'role': 'user', 'content': message},
        ],
        'stream': true,
        'temperature': 0.7,
      };

      print('🔍 DIAGNOSTIC: Request body: ${jsonEncode(requestBody)}');
      request.body = jsonEncode(requestBody);

      final streamedResponse = await request.send();

      print('🔍 DIAGNOSTIC: Response status: ${streamedResponse.statusCode}');
      print('🔍 DIAGNOSTIC: Response reason: ${streamedResponse.reasonPhrase}');

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
                    add(
                      UpdateStreamingMessage(
                        messageId: messageId,
                        content: contentBuffer.toString(),
                      ),
                    );
                  }
                } catch (e) {
                  // Skip malformed JSON chunks
                }
              }
            }
          }
        }

        // Final update with complete content
        add(UpdateStreamingMessage(messageId: messageId, content: contentBuffer.toString()));
      } else if (streamedResponse.statusCode == 403) {
        // Handle 403 Forbidden errors specifically
        final errorBody = await streamedResponse.stream.bytesToString();
        String errorMessage = 'Access denied (403): ';

        if (errorBody.contains('insufficient_quota')) {
          errorMessage += 'Insufficient credits. Please add credits to your OpenRouter account.';
        } else if (errorBody.contains('rate_limit')) {
          errorMessage += 'Rate limit exceeded. Please wait before making more requests.';
        } else if (errorBody.contains('invalid_api_key')) {
          errorMessage += 'Invalid API key. Please check your API key in settings.';
        } else {
          errorMessage += 'Access forbidden. This might be due to model restrictions or account limitations.';
        }

        errorMessage += '\n\nTroubleshooting:\n1. Check your API key in Settings\n2. Verify your OpenRouter account has sufficient credits\n3. Try a different free model\n4. Check OpenRouter status page';

        emit(ChatError(errorMessage));
      } else if (streamedResponse.statusCode == 401) {
        emit(ChatError('Authentication failed (401): Invalid API key. Please check your API key in Settings.'));
      } else if (streamedResponse.statusCode == 429) {
        emit(ChatError('Rate limit exceeded (429): Too many requests. Please wait before making more requests.'));
      } else if (streamedResponse.statusCode == 400) {
        final errorBody = await streamedResponse.stream.bytesToString();
        print('🔍 DIAGNOSTIC: 400 Bad Request for model: $modelId');
        print('🔍 DIAGNOSTIC: Error response: $errorBody');
        emit(ChatError('Bad request (400): Model "$modelId" - $errorBody'));
      } else if (streamedResponse.statusCode == 404) {
        final errorBody = await streamedResponse.stream.bytesToString();
        print('🔍 DIAGNOSTIC: 404 Not Found for model: $modelId');
        print('🔍 DIAGNOSTIC: Error response: $errorBody');
        emit(ChatError('Model not found (404): "$modelId" - This model may no longer be available'));
      } else {
        final errorBody = await streamedResponse.stream.bytesToString();
        print('🔍 DIAGNOSTIC: HTTP ${streamedResponse.statusCode} for model: $modelId');
        print('🔍 DIAGNOSTIC: Error response: $errorBody');
        emit(ChatError('HTTP Error (${streamedResponse.statusCode}): Model "$modelId" - ${streamedResponse.reasonPhrase}'));
      }
    } on http.ClientException catch (e) {
      emit(ChatError('Network error: ${e.message}\n\nPlease check your internet connection.'));
    } on FormatException catch (e) {
      emit(ChatError('Data format error: ${e.message}\n\nThe response format is invalid.'));
    } on TimeoutException catch (e) {
      emit(ChatError('Request timeout: ${e.message}\n\nThe request took too long to complete.'));
    } catch (e) {
      emit(ChatError('Streaming error: ${e.toString()}\n\nPlease try again or check your settings.'));
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

  Future<void> _onLoadChatHistory(LoadChatHistory event, Emitter<ChatState> emit) async {
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

      emit(ChatLoaded(messages: messages, selectedModel: selectedModel));
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

  void _onUpdateStreamingMessage(UpdateStreamingMessage event, Emitter<ChatState> emit) {
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

  Future<void> _onSelectModel(SelectModel event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(currentState.copyWith(selectedModel: event.model));
      await saveSelectedModel(event.model.id);
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
      await _secureStorage.write(key: 'chat_history', value: jsonEncode(jsonMessages));
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

  // Diagnostic method to validate all models
  Future<Map<String, dynamic>> validateModels() async {
    print('🔍 DIAGNOSTIC: Starting model validation...');
    final results = <String, dynamic>{
      'total_models': _availableModels.length,
      'valid_models': [],
      'invalid_models': [],
      'errors': {},
    };

    final apiKey = await _secureStorage.read(key: 'openrouter_api_key');
    if (apiKey == null) {
      results['error'] = 'API key not found';
      return results;
    }

    // Get available models from OpenRouter
    try {
      final url = Uri.parse('https://openrouter.ai/api/v1/models');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final availableModelIds = (data['data'] as List)
            .map((model) => model['id'] as String)
            .toSet();

        print('🔍 DIAGNOSTIC: Found ${availableModelIds.length} available models from OpenRouter');

        for (final model in _availableModels) {
          if (availableModelIds.contains(model.id)) {
            results['valid_models'].add(model.id);
            print('🔍 DIAGNOSTIC: ✅ Valid model: ${model.id}');
          } else {
            results['invalid_models'].add(model.id);
            results['errors'][model.id] = 'Model not found in OpenRouter API';
            print('🔍 DIAGNOSTIC: ❌ Invalid model: ${model.id}');
          }
        }
      } else {
        results['error'] = 'Failed to fetch models: ${response.statusCode}';
        print('🔍 DIAGNOSTIC: Failed to fetch models: ${response.statusCode}');
      }
    } catch (e) {
      results['error'] = 'Validation error: ${e.toString()}';
      print('🔍 DIAGNOSTIC: Validation error: $e');
    }

    return results;
  }
}
