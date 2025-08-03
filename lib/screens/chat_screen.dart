import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../models/chat_message.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_updateScrollButtonVisibility);
    // Load chat history and initialize the bloc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(const LoadChatHistory());
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    // _scrollController.dispose();
    // _itemPositionsListener.dispose();
    super.dispose();
  }

  void _updateScrollButtonVisibility() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      final lastItemIndex = positions.last.index;
      final isNearBottom = lastItemIndex >= (positions.length - 3);
      setState(() {
        _showScrollToBottom = !isNearBottom;
      });
    }
  }

  void _scrollToBottom() {
    final state = context.read<ChatBloc>().state;
    if (state is ChatLoaded && state.messages.isNotEmpty) {
      _scrollController.scrollTo(
        index: state.messages.length - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _sendMessage() {
    if (_textController.text.trim().isNotEmpty) {
      final message = _textController.text.trim();
      _textController.clear();
      _focusNode.unfocus();

      final state = context.read<ChatBloc>().state;
      String modelId = 'openai/gpt-4'; // Default model
      if (state is ChatLoaded) {
        modelId = state.selectedModel.id;
      }

      context.read<ChatBloc>().add(SendMessage(message: message, modelId: modelId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coder Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              _showClearChatDialog(context);
            },
            tooltip: 'Clear Chat',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ChatError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            state.message,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ChatBloc>().add(const LoadChatHistory());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ChatLoaded) {
                  return Column(
                    children: [
                      Expanded(
                        child: ScrollablePositionedList.builder(
                          itemScrollController: _scrollController,
                          itemPositionsListener: _itemPositionsListener,
                          reverse: false,
                          padding: const EdgeInsets.all(16),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message = state.messages[index];
                            return MessageBubble(
                              text: message.content,
                              isUser: message.type == MessageType.user,
                              timestamp: message.timestamp,
                            );
                          },
                        ),
                      ),
                      if (state.isTyping) const TypingIndicator(),
                      ChatInput(
                        controller: _textController,
                        focusNode: _focusNode,
                        onSend: _sendMessage,
                        onModelSelected: (modelId) {
                          final bloc = context.read<ChatBloc>();
                          final model = bloc.availableModels.firstWhere(
                            (m) => m.id == modelId,
                            orElse: () => bloc.availableModels.first,
                          );
                          bloc.add(SelectModel(model: model));
                        },
                      ),
                    ],
                  );
                }

                return const Center(child: Text('Start a conversation!'));
              },
            ),
          ),
          if (_showScrollToBottom)
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton(
                onPressed: _scrollToBottom,
                mini: true,
                child: const Icon(Icons.keyboard_arrow_down),
              ),
            ),
        ],
      ),
    );
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<ChatBloc>().add(const ClearChat());
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
