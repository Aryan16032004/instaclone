import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/create_menu_screen.dart';

class FabMenu extends StatelessWidget {
  final VoidCallback onUploadPressed;
  final VoidCallback onGoLivePressed;
  final VoidCallback onAudioPartyPressed;
  final VoidCallback onVideoPartyPressed;

  const FabMenu({
    super.key,
    required this.onUploadPressed,
    required this.onGoLivePressed,
    required this.onAudioPartyPressed,
    required this.onVideoPartyPressed,
  });

  void _openCreateMenu(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMenuScreen(
          onUploadPressed: onUploadPressed,
          onGoLivePressed: onGoLivePressed,
          onAudioPartyPressed: onAudioPartyPressed,
          onVideoPartyPressed: onVideoPartyPressed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openCreateMenu(context),
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
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}
