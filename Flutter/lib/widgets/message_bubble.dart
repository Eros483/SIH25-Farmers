import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../utils/theme_colors.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: _buildMessageContainer(context),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            _buildUserAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: message.isError
            ? Colors.red.withOpacity(0.1)
            : primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        message.isError ? Icons.error : Icons.agriculture,
        color: message.isError ? Colors.red : primaryColor,
        size: 20,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: accentColor,
        size: 20,
      ),
    );
  }

  Widget _buildMessageContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: _getBorderRadius(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: _getBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          message.isUser
              ? Text(
                  message.text,
                  style: GoogleFonts.inter(
                    color: _getTextColor(),
                    fontSize: 14,
                    height: 1.4,
                  ),
                )
              : GptMarkdown(
                  message.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: _getTextColor(),
                    fontFamily: GoogleFonts.inter().fontFamily,
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            _formatTime(message.timestamp),
            style: GoogleFonts.inter(
              color: _getTimeColor(),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    if (message.isUser) {
      return primaryColor;
    } else if (message.isError) {
      return Colors.red.withOpacity(0.1);
    } else {
      return Colors.white;
    }
  }

  BorderRadius _getBorderRadius() {
    return BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft:
          message.isUser ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight:
          message.isUser ? const Radius.circular(4) : const Radius.circular(16),
    );
  }

  Border? _getBorder() {
    if (!message.isUser && !message.isError) {
      return Border.all(color: primaryColor.withOpacity(0.1));
    }
    return null;
  }

  Color _getTextColor() {
    if (message.isUser) {
      return Colors.white;
    } else if (message.isError) {
      return Colors.red[700]!;
    } else {
      return Colors.black87;
    }
  }

  Color _getTimeColor() {
    if (message.isUser) {
      return Colors.white.withOpacity(0.7);
    } else {
      return Colors.grey[600]!;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    } else {
      return "${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    }
  }
}
