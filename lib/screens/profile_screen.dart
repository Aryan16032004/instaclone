import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/upload_service.dart'; // Import Upload Service

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _uploadService = UploadService();

  void _changeProfilePic(String userId) async {
    final xFile = await _uploadService.pickImage();
    if (xFile != null) {
      final file = File(xFile.path);
      await _uploadService.updateProfilePic(userId, file);
      setState(() {}); // refresh UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final userId = auth.user?.id;

    if (userId == null) return const Scaffold(body: Center(child: Text("Not Logged In")));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.black,
        actions: [IconButton(onPressed: () => auth.logout(), icon: const Icon(Icons.logout))],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder(
              stream: Supabase.instance.client.from('profiles').stream(primaryKey: ['id']).eq('id', userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox(height: 100);
                final profile = snapshot.data!.first;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // PROFILE PIC UPLOAD LOGIC
                      GestureDetector(
                        onTap: () => _changeProfilePic(userId),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: (profile['avatar_url'] != null) 
                                  ? NetworkImage(profile['avatar_url']) 
                                  : null,
                              child: (profile['avatar_url'] == null) 
                                  ? const Icon(Icons.person, size: 50, color: Colors.white) 
                                  : null,
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                child: const Icon(Icons.add, size: 16, color: Colors.white),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Stats
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _statCol("0", "Posts"),
                            _statCol("0", "Followers"),
                            _statCol("0", "Following"),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
            
            // Name and Bio section could go here
            const Divider(color: Colors.grey),

            // User Posts
            StreamBuilder(
              stream: Supabase.instance.client.from('posts').stream(primaryKey: ['id']).eq('user_id', userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final posts = snapshot.data!;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    if (post['is_video'] == true) {
                      return Container(
                        color: Colors.grey[900], 
                        child: const Icon(Icons.play_arrow, color: Colors.white)
                      );
                    }
                    return CachedNetworkImage(imageUrl: post['media_url'], fit: BoxFit.cover);
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
    return Column(children: [
      Text(num, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      Text(label, style: const TextStyle(color: Colors.grey)),
    ]);
  }
}