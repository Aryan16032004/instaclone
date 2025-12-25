import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CreateMenuScreen extends StatelessWidget {
  final VoidCallback onUploadPressed;
  final VoidCallback onGoLivePressed;
  final VoidCallback onAudioPartyPressed;
  final VoidCallback onVideoPartyPressed;

  const CreateMenuScreen({
    super.key,
    required this.onUploadPressed,
    required this.onGoLivePressed,
    required this.onAudioPartyPressed,
    required this.onVideoPartyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.darkBackground, AppTheme.darkPurple],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Create',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Menu Cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMenuCard(
                        context,
                        icon: Icons.photo_camera_rounded,
                        title: 'Upload Post',
                        description: 'Share photos and videos',
                        color: AppTheme.primaryPink,
                        onTap: onUploadPressed,
                      ),
                      const SizedBox(height: 16),
                      _buildMenuCard(
                        context,
                        icon: Icons.live_tv_rounded,
                        title: 'Go Live',
                        description: 'Start live streaming',
                        color: const Color(0xFFFF3B3B),
                        onTap: onGoLivePressed,
                      ),
                      const SizedBox(height: 16),
                      _buildMenuCard(
                        context,
                        icon: Icons.mic_rounded,
                        title: 'Audio Party',
                        description: 'Voice chat with friends',
                        color: const Color(0xFF4ECDC4),
                        onTap: onAudioPartyPressed,
                      ),
                      const SizedBox(height: 16),
                      _buildMenuCard(
                        context,
                        icon: Icons.videocam_rounded,
                        title: 'Video Party',
                        description: 'Video chat with friends',
                        color: const Color(0xFFFF6B6B),
                        onTap: onVideoPartyPressed,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
