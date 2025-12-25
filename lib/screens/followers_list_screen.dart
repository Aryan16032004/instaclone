import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/follow_service.dart';
import '../services/post_service.dart';
import 'profile_screen.dart';

class FollowersListScreen extends StatefulWidget {
  final String userId;
  final int initialTab; // 0 for followers, 1 for following

  const FollowersListScreen({
    Key? key,
    required this.userId,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _followService = FollowService();
  final _postService = PostService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Connections', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE91E63),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFollowersList(), _buildFollowingList()],
      ),
    );
  }

  Widget _buildFollowersList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _followService.getFollowersList(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE91E63)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No followers yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final followers = snapshot.data!;
        return ListView.builder(
          itemCount: followers.length,
          itemBuilder: (context, index) {
            final followerData = followers[index];
            final profile = followerData['profiles'];

            if (profile == null) return const SizedBox.shrink();

            return _buildUserTile(profile);
          },
        );
      },
    );
  }

  Widget _buildFollowingList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _followService.getFollowingList(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE91E63)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Not following anyone yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final following = snapshot.data!;
        return ListView.builder(
          itemCount: following.length,
          itemBuilder: (context, index) {
            final followingData = following[index];
            final profile = followingData['profiles'];

            if (profile == null) return const SizedBox.shrink();

            return _buildUserTile(profile);
          },
        );
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> profile) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMe = profile['id'] == currentUserId;
    final userId = profile['id'] as String;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: GestureDetector(
        onTap: () => _navigateToProfile(userId),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
            ),
          ),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[900],
            backgroundImage: profile['avatar_url'] != null
                ? NetworkImage(profile['avatar_url'])
                : null,
            child: profile['avatar_url'] == null
                ? const Icon(Icons.person, color: Colors.white, size: 25)
                : null,
          ),
        ),
      ),
      title: GestureDetector(
        onTap: () => _navigateToProfile(userId),
        child: Text(
          profile['username'] ?? 'User',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      subtitle: profile['name'] != null && profile['name'].toString().isNotEmpty
          ? GestureDetector(
              onTap: () => _navigateToProfile(userId),
              child: Text(
                profile['name'],
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : null,
      trailing: isMe
          ? null
          : FutureBuilder<bool>(
              future: _postService.isFollowing(currentUserId!, userId),
              builder: (context, snapshot) {
                final isFollowing = snapshot.data ?? false;
                return SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _postService.toggleFollow(currentUserId, userId);
                      setState(() {}); // Refresh to update button state
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing
                          ? Colors.grey[800]
                          : const Color(0xFFE91E63),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _navigateToProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
    );
  }
}
