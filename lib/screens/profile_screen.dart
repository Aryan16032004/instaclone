import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/upload_service.dart';
import '../services/follow_service.dart';
import '../widgets/full_screen_media_viewer.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // If null, show current user
  const ProfileScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _uploadService = UploadService();
  final _followService = FollowService();
  String? _currentUserId;
  bool _isMe = false;
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isLoadingFollow = true;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _isMe = widget.userId == null || widget.userId == _currentUserId;

    if (!_isMe && _currentUserId != null && widget.userId != null) {
      _checkFollowStatus();
    }
    _loadStats();
  }

  void _checkFollowStatus() async {
    bool following = await _followService.isFollowing(
      _currentUserId!,
      widget.userId!,
    );
    if (mounted) {
      setState(() {
        _isFollowing = following;
        _isLoadingFollow = false;
      });
    }
  }

  void _loadStats() async {
    final targetId = widget.userId ?? _currentUserId;
    if (targetId == null) return;

    // In a real app, you might want to fetch these from a 'profiles' table if you cache them
    // or use count queries. Assuming count queries for now.
    int followers = await _followService.getFollowersCount(targetId);
    int following = await _followService.getFollowingCount(targetId);
    if (mounted) {
      setState(() {
        _followersCount = followers;
        _followingCount = following;
      });
    }
  }

  void _toggleFollow() async {
    if (_currentUserId == null || widget.userId == null) return;

    // Optimistic update
    setState(() {
      _isFollowing = !_isFollowing;
      _followersCount += _isFollowing ? 1 : -1;
    });

    if (_isFollowing) {
      await _followService.followUser(_currentUserId!, widget.userId!);
    } else {
      await _followService.unfollowUser(_currentUserId!, widget.userId!);
    }
  }

  void _changeProfilePic(String userId) async {
    if (!_isMe) return; // Only owner can change pic
    final xFile = await _uploadService.pickImage();
    if (xFile != null) {
      final file = File(xFile.path);
      await _uploadService.updateProfilePic(userId, file);
      setState(() {}); // refresh UI
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we are viewing "my" profile, we get ID from auth via Provider or direct
    // If viewing others, we use widget.userId
    final auth = Provider.of<AuthService>(context, listen: false);
    final targetId = widget.userId ?? auth.user?.id;

    if (targetId == null)
      return const Scaffold(body: Center(child: Text("Not Logged In")));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_isMe ? 'My Profile' : 'Profile'), // Ideally show username
        backgroundColor: Colors.black,
        actions: [
          if (_isMe)
            IconButton(
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: Supabase.instance.client
                  .from('profiles')
                  .select()
                  .eq('id', targetId)
                  .maybeSingle(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 100);
                final profile = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // PROFILE PIC
                          GestureDetector(
                            onTap: () => _changeProfilePic(targetId),
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 45,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage:
                                      (profile['avatar_url'] != null)
                                      ? NetworkImage(profile['avatar_url'])
                                      : null,
                                  child: (profile['avatar_url'] == null)
                                      ? const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                if (_isMe)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Stats
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _statCol(
                                  "0",
                                  "Posts",
                                ), // We could count posts too
                                _statCol("$_followersCount", "Followers"),
                                _statCol("$_followingCount", "Following"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Name & Bio
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile['username'] ?? 'User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              if (profile['bio'] != null)
                                Text(
                                  profile['bio'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Edit Profile or Follow Button
                      if (_isMe)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Center(
                            child: Text(
                              "Edit Profile",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _toggleFollow,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: _isFollowing
                                  ? Colors.grey[900]
                                  : Colors.blue,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Center(
                              child: _isLoadingFollow
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isFollowing ? "Following" : "Follow",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            const Divider(color: Colors.grey),

            // User Posts
            StreamBuilder(
              stream: Supabase.instance.client
                  .from('posts')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', targetId),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final posts = snapshot.data!;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final isVideo = post['is_video'] == true;
                    return GestureDetector(
                      onTap: () {
                        // Enlarge
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenMediaViewer(
                              mediaUrl: post['media_url'],
                              isVideo: isVideo,
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: post['media_url'],
                            fit: BoxFit.cover,
                          ),
                          if (isVideo)
                            const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String num, String label) {
    return Column(
      children: [
        Text(
          num,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
