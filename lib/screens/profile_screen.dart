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
    if(mounted) setState(() => _isFollowing = status);
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    // If auth state is lost, show login message or redirect
    if (!auth.isLoggedIn) return const Scaffold(body: Center(child: Text("Please Login")));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        actions: [
          if (_isMe) 
            IconButton(onPressed: () => auth.logout(), icon: const Icon(Icons.logout, color: Colors.white))
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Data Stream
            StreamBuilder(
              stream: Supabase.instance.client.from('profiles').stream(primaryKey: ['id']).eq('id', _targetUserId),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox(height: 50);
                final profile = snapshot.data!.first;
                
                final followers = (profile['followers'] as List?)?.length ?? 0;
                final following = (profile['following'] as List?)?.length ?? 0;
                
                // 🔴 NEW: Fetching the real data
                final displayName = (profile['name'] != null && profile['name'].toString().isNotEmpty) 
                    ? profile['name'] 
                    : (profile['username'] ?? 'User');
                final bio = (profile['bio'] != null && profile['bio'].toString().isNotEmpty) 
                    ? profile['bio'] 
                    : 'No bio yet.';

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _changeProfilePic,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 45,
                                  backgroundColor: Colors.grey[900],
                                  backgroundImage: (profile['avatar_url'] != null) 
                                      ? NetworkImage(profile['avatar_url']) 
                                      : null,
                                  child: (profile['avatar_url'] == null) 
                                      ? const Icon(Icons.person, size: 50, color: Colors.white) 
                                      : null,
                                ),
                                if (_isMe)
                                  Positioned(bottom: 0, right: 0, child: _buildEditIcon()),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _statCol("0", "Posts"), // Requires separate count query or counter column
                                _statCol("$followers", "Followers"),
                                _statCol("$following", "Following"),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    
                    // 🔴 UPDATED: Name & Bio Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Display Name
                            Text(
                              displayName, 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                            ),
                            
                            // 2. Username (Handle)
                            if (profile['name'] != null) 
                              Text(
                                "@${profile['username']}", 
                                style: const TextStyle(color: Colors.white54, fontSize: 14)
                              ),
                            
                            const SizedBox(height: 8),
                            
                            // 3. Bio
                            Text(
                              bio, 
                              style: const TextStyle(color: Colors.white70, fontSize: 14)
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Action Buttons (Edit Profile or Follow)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _isMe 
                        ? _buildButton("Edit Profile", () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                          }) 
                        : _buildButton(_isFollowing ? "Following" : "Follow", _toggleFollow, isPrimary: !_isFollowing),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 15),
            const Divider(color: Colors.grey),

            // Posts Grid
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client.from('posts').stream(primaryKey: ['id']).eq('user_id', _targetUserId).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final posts = snapshot.data!;
                
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return GestureDetector(
                      // Enlarge on Tap
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => FullScreenViewer(posts: posts, initialIndex: index),
                        ));
                      },
                      child: post['is_video'] == true 
                          ? Container(color: Colors.grey[900], child: const Icon(Icons.play_arrow, color: Colors.white))
                          : CachedNetworkImage(imageUrl: post['media_url'], fit: BoxFit.cover),
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

  Widget _buildEditIcon() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
      child: const Icon(Icons.add, size: 16, color: Colors.white),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap, {bool isPrimary = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFFC13584) : Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _statCol(String num, String label) {
    return Column(children: [
      Text(num, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      Text(label, style: const TextStyle(color: Colors.grey)),
    ]);
  }
}