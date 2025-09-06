import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_colors.dart';

class TypingIndicator extends StatefulWidget {
  final bool isVisible;

  const TypingIndicator({
    super.key,
    required this.isVisible,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isVisible) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.repeat();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.agriculture,
              color: primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Row(
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(
                        0.3 +
                            (0.4 * (((_animation.value + index * 0.3) % 1.0))),
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            "टाइप कर रहा है...",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
