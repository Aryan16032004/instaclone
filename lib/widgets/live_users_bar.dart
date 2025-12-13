import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/live_screen.dart'; // Import your LiveScreen

class LiveUsersBar extends StatelessWidget {
  const LiveUsersBar({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      // 1. Listen to profiles where is_live == true
      stream: Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('is_live', true), 
      builder: (context, snapshot) {
        // If loading or no one is live, hide the bar completely
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final liveUsers = snapshot.data!;

        return Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: liveUsers.length,
            itemBuilder: (context, index) {
              final user = liveUsers[index];
              return _LiveBubble(user: user);
            },
          ),
        );
      },
    );
  }
}

class _LiveBubble extends StatelessWidget {
  final Map<String, dynamic> user;
  const _LiveBubble({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 2. Join their stream as Audience
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveScreen(
              isBroadcaster: false,
              channelId: user['id'], // Connect to their specific room
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Red Gradient Ring (Instagram Style)
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC13584), Color(0xFFFCAF45)],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                ),
                // Black border to separate ring from image
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
                // Profile Picture
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: (user['avatar_url'] != null)
                      ? NetworkImage(user['avatar_url'])
                      : null,
                  child: user['avatar_url'] == null 
                      ? const Icon(Icons.person, color: Colors.white) 
                      : null,
                ),
                // "LIVE" Badge
                Positioned(
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Text(
                      "LIVE",
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Username
            Text(
              user['username'] ?? 'User',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}