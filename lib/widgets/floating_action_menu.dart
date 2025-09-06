import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_colors.dart';

class FloatingActionMenu extends StatelessWidget {
  final Animation<double> menuAnimation;
  final Animation<double> rotationAnimation;
  final bool isMenuOpen;
  final VoidCallback toggleMenu;
  final VoidCallback navigateToChatBot;

  const FloatingActionMenu({
    super.key,
    required this.menuAnimation,
    required this.rotationAnimation,
    required this.isMenuOpen,
    required this.toggleMenu,
    required this.navigateToChatBot,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedBuilder(
            animation: menuAnimation,
            builder: (_, __) => Transform.scale(
              scale: menuAnimation.value,
              child: Opacity(
                opacity: menuAnimation.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      icon: Icons.chat,
                      label: "Chat Assistant",
                      onTap: navigateToChatBot,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: rotationAnimation,
            builder: (_, __) => Transform.rotate(
              angle: rotationAnimation.value * 2 * 3.14159,
              child: FloatingActionButton(
                onPressed: toggleMenu,
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 8,
                child: Icon(isMenuOpen ? Icons.close : Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
