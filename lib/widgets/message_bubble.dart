import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI Assistant',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  MarkdownBody(
                    data: text,
                    styleSheet: MarkdownStyleSheet(
                      p: theme.textTheme.bodyLarge?.copyWith(
                        color: isUser ? Colors.white : theme.colorScheme.onSurface,
                        fontSize: 15,
                      ),
                      h1: theme.textTheme.headlineSmall?.copyWith(
                        color: isUser ? Colors.white : theme.colorScheme.onSurface,
                      ),
                      h2: theme.textTheme.titleLarge?.copyWith(
                        color: isUser ? Colors.white : theme.colorScheme.onSurface,
                      ),
                      h3: theme.textTheme.titleMedium?.copyWith(
                        color: isUser ? Colors.white : theme.colorScheme.onSurface,
                      ),
                      code: TextStyle(
                        backgroundColor: (isUser ? Colors.white : theme.colorScheme.onSurface)
                            .withOpacity(0.1),
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: isUser ? Colors.white : theme.colorScheme.onSurface,
                      ),
                      codeblockPadding: const EdgeInsets.all(12),
                      codeblockDecoration: BoxDecoration(
                        color: (isUser ? Colors.white : theme.colorScheme.onSurface)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      blockquote: theme.textTheme.bodyLarge?.copyWith(
                        color: isUser ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      blockquotePadding: const EdgeInsets.all(12),
                      blockquoteDecoration: BoxDecoration(
                        color: (isUser ? Colors.white : theme.colorScheme.onSurface)
                            .withOpacity(0.05),
                        border: Border(
                          left: BorderSide(
                            color: theme.colorScheme.secondary,
                            width: 3,
                          ),
                        ),
                      ),
                      listBullet: theme.textTheme.bodyLarge?.copyWith(
                        color: isUser ? Colors.white : theme.colorScheme.onSurface,
                      ),
                      tableBorder: TableBorder.all(
                        color: (isUser ? Colors.white : theme.colorScheme.onSurface)
                            .withOpacity(0.2),
                      ),
                      tableCellsPadding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(timestamp),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}