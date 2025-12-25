import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/feed_screen.dart';
import '../screens/search_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/upload_screen.dart';
import '../screens/live_screen.dart';
import '../screens/audio_party_screen.dart';
import '../screens/video_party_screen.dart';
import '../screens/create_menu_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/shorts_feed.dart';
import '../widgets/custom_bottom_nav.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      FeedScreen(),
      const SearchScreen(),
      CreateMenuScreen(
        onUploadPressed: _onUploadPressed,
        onGoLivePressed: _onGoLivePressed,
        onAudioPartyPressed: _onAudioPartyPressed,
        onVideoPartyPressed: _onVideoPartyPressed,
      ),
      const ShortsFeed(),
      ProfileScreen(userId: null),
    ];
  }

  void _onNavTap(int index) {
    setState(() => _idx = index);
  }

  void _onUploadPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UploadScreen()),
    );
  }

  void _onAudioPartyPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AudioPartyScreen()),
    );
  }

  void _onVideoPartyPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VideoPartyScreen()),
    );
  }

  void _onGoLivePressed() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    // Mark user as "Live" in database
    await Supabase.instance.client
        .from('profiles')
        .update({'is_live': true})
        .eq('id', userId);

    if (!mounted) return;

    // Navigate to Live Screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveScreen(
          isBroadcaster: true,
          channelId: userId, // Room Name = User ID
        ),
      ),
    );

    // When they come back (close stream), mark as "Not Live"
    await Supabase.instance.client
        .from('profiles')
        .update({'is_live': false})
        .eq('id', userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: _idx == 0 ? _buildAppBar() : null,
      body: _pages[_idx],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _idx,
        onTap: _onNavTap,
        onFabPressed: () {
          setState(() => _idx = 2); // Navigate to CreateMenuScreen (index 2)
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.white, Colors.white70],
        ).createShader(bounds),
        child: const Text(
          'Masti',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 1.2,
          ),
        ),
      ),
      actions: [
        // Wallet/Coins indicator
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WalletScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                SizedBox(width: 4),
                Text(
                  '0',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      elevation: 0,
    );
  }
}
