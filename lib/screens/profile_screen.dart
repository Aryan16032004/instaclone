import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/upload_service.dart';
import '../services/post_service.dart';
import '../widgets/full_screen_viewer.dart';
import 'edit_profile_screen.dart'; // Ensure this import exists
import 'followers_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // If null, shows current user
  const ProfileScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _uploadService = UploadService();
  final _postService = PostService();
  late String _targetUserId;
  bool _isMe = false;
  bool _isFollowing = false;
  int _refreshKey = 0; // For forcing rebuild

  @override
  void initState() {
    super.initState();
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) return; // Basic safety check

    _targetUserId = widget.userId ?? myId;
    _isMe = _targetUserId == myId;

    if (!_isMe) _checkFollowStatus(myId);
  }

  void _checkFollowStatus(String myId) async {
    bool status = await _postService.isFollowing(myId, _targetUserId);
    if (mounted) setState(() => _isFollowing = status);
  }

  void _toggleFollow() async {
    final myId = Supabase.instance.client.auth.currentUser!.id;
    setState(() => _isFollowing = !_isFollowing);
    await _postService.toggleFollow(myId, _targetUserId);
  }

  void _changeProfilePic() async {
    if (!_isMe) return;
    final xFile = await _uploadService.pickImage();
    if (xFile != null) {
      await _uploadService.updateProfilePic(_targetUserId, File(xFile.path));
      setState(() {});
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey++;
    });
    // Re-check follow status if viewing another user
    if (!_isMe) {
      final myId = Supabase.instance.client.auth.currentUser?.id;
      if (myId != null) _checkFollowStatus(myId);
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    // If auth state is lost, show login message or redirect
    if (!auth.isLoggedIn)
      return const Scaffold(body: Center(child: Text("Please Login")));

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isMe)
            IconButton(
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFFC13584),
        backgroundColor: Colors.black,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1a1a2e), Color(0xFF000000)],
            ),
          ),
          child: SingleChildScrollView(
            key: ValueKey(_refreshKey),
            child: Column(
              children: [
                const SizedBox(height: 100), // Space for app bar
                // User Data Stream
                StreamBuilder(
                  stream: Supabase.instance.client
                      .from('profiles')
                      .stream(primaryKey: ['id'])
                      .eq('id', _targetUserId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty)
                      return const SizedBox(height: 50);
                    final profile = snapshot.data!.first;

                    final followers =
                        (profile['followers'] as List?)?.length ?? 0;
                    final following =
                        (profile['following'] as List?)?.length ?? 0;

                    final displayName =
                        (profile['name'] != null &&
                            profile['name'].toString().isNotEmpty)
                        ? profile['name']
                        : (profile['username'] ?? 'User');
                    final bio =
                        (profile['bio'] != null &&
                            profile['bio'].toString().isNotEmpty)
                        ? profile['bio']
                        : 'No bio yet.';

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              // Profile Picture
                              GestureDetector(
                                onTap: _changeProfilePic,
                                child: Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFe91e63),
                                            Color(0xFF9c27b0),
                                            Color(0xFF673ab7),
                                          ],
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.grey[900],
                                        backgroundImage:
                                            (profile['avatar_url'] != null)
                                            ? NetworkImage(
                                                profile['avatar_url'],
                                              )
                                            : null,
                                        child: (profile['avatar_url'] == null)
                                            ? const Icon(
                                                Icons.person,
                                                size: 55,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ),
                                    if (_isMe)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: _buildEditIcon(),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Stats Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _statCol("0", "Posts"),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white24,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FollowersListScreen(
                                            userId: _targetUserId,
                                            initialTab: 0, // Followers tab
                                          ),
                                        ),
                                      );
                                    },
                                    child: _statCol("$followers", "Followers"),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white24,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FollowersListScreen(
                                            userId: _targetUserId,
                                            initialTab: 1, // Following tab
                                          ),
                                        ),
                                      );
                                    },
                                    child: _statCol("$following", "Following"),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Name & Bio Section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  if (profile['name'] != null)
                                    Text(
                                      "@${profile['username']}",
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 15,
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Text(
                                      bio,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Action Button
                              _isMe
                                  ? _buildButton("Edit Profile", () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const EditProfileScreen(),
                                        ),
                                      );
                                    })
                                  : _buildButton(
                                      _isFollowing ? "Following" : "Follow",
                                      _toggleFollow,
                                      isPrimary: !_isFollowing,
                                    ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const Divider(color: Colors.grey, height: 1),
                const SizedBox(height: 8),

                // Posts Grid
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('posts')
                      .stream(primaryKey: ['id'])
                      .eq('user_id', _targetUserId)
                      .order('created_at', ascending: false),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final posts = snapshot.data!;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                          ),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullScreenViewer(
                                  posts: posts,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: post['is_video'] == true
                              ? Container(
                                  color: Colors.grey[900],
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: post['media_url'],
                                  fit: BoxFit.cover,
                                ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditIcon() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add, size: 16, color: Colors.white),
    );
  }

  Widget _buildButton(
    String text,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? const Color(0xFFC13584)
              : Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
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
