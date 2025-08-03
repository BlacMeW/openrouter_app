import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_state.dart';
import '../models/ai_model.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final Function(String) onModelSelected;

  const ChatInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onModelSelected,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModelSelector(
            onModelSelected: widget.onModelSelected,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: _isExpanded ? 200 : 48,
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    maxLines: null,
                    minLines: 1,
                    expands: _isExpanded,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about coding...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).hintColor.withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isExpanded)
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_up),
                              onPressed: () {
                                setState(() {
                                  _isExpanded = false;
                                });
                              },
                              tooltip: 'Collapse',
                            ),
                          IconButton(
                            icon: const Icon(Icons.attach_file),
                            onPressed: () {
                              // TODO: Implement file attachment
                            },
                            tooltip: 'Attach file',
                          ),
                        ],
                      ),
                    ),
                    onSubmitted: (_) => widget.onSend(),
                    onChanged: (value) {
                      if (value.isNotEmpty && !_isExpanded) {
                        setState(() {
                          _isExpanded = true;
                        });
                      } else if (value.isEmpty && _isExpanded) {
                        setState(() {
                          _isExpanded = false;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                onPressed: widget.controller.text.trim().isNotEmpty ? widget.onSend : null,
                mini: true,
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModelSelector extends StatelessWidget {
  final Function(String) onModelSelected;

  const _ModelSelector({required this.onModelSelected});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is ChatLoaded) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.smart_toy,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                DropdownButton<AIModel>(
                  value: state.selectedModel,
                  underline: Container(),
                  isDense: true,
                  iconSize: 20,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onChanged: (model) {
                    if (model != null) {
                      onModelSelected(model.id);
                    }
                  },
                  items: context.read<ChatBloc>().availableModels.map((AIModel model) {
                    return DropdownMenuItem<AIModel>(
                      value: model,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            model.name,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (model.isDefault)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                'Default',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}