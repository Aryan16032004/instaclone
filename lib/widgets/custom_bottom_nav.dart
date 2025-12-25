import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onFabPressed;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Custom shaped bottom nav bar
        CustomPaint(
          size: Size(MediaQuery.of(context).size.width, 70),
          painter: BottomNavPainter(),
        ),

        // Bottom nav content
        Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 0),
              _buildNavItem(Icons.search_rounded, 1),
              const SizedBox(width: 80), // Space for FAB
              _buildNavItem(Icons.play_circle_rounded, 3),
              _buildNavItem(Icons.person_rounded, 4),
            ],
          ),
        ),

        // Centered FAB (the sexy original design!)
        Positioned(
          bottom: 20,
          child: GestureDetector(
            onTap: onFabPressed,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                gradient: AppTheme.fabGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPink.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: isSelected
            ? BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
          size: isSelected ? 28 : 26,
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    return [];
  }
}

class BottomNavPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1a1a2e)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start from left
    path.moveTo(0, 20);

    // Left curve
    path.quadraticBezierTo(0, 0, 20, 0);

    // Line to notch start
    path.lineTo(size.width * 0.35, 0);

    // Notch curve (for FAB)
    path.quadraticBezierTo(size.width * 0.40, 0, size.width * 0.42, 10);
    path.quadraticBezierTo(size.width * 0.45, 25, size.width * 0.50, 25);
    path.quadraticBezierTo(size.width * 0.55, 25, size.width * 0.58, 10);
    path.quadraticBezierTo(size.width * 0.60, 0, size.width * 0.65, 0);

    // Line to right curve
    path.lineTo(size.width - 20, 0);

    // Right curve
    path.quadraticBezierTo(size.width, 0, size.width, 20);

    // Bottom
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Add shadow
    canvas.drawShadow(path, Colors.black.withOpacity(0.3), 10, false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
