import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/upload_service.dart';
import '../services/auth_service.dart';
import '../widgets/gradient_button.dart';
import 'live_screen.dart'; // Import your new Agora screen

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _file;
  bool _isVideo = false;
  final _captionCtrl = TextEditingController();
  bool _loading = false;
  final _up = UploadService();

  // 🔴 NEW: Function to handle Going Live
  void _goLive() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    
    // 1. Mark user as "Live" in database
    await Supabase.instance.client
        .from('profiles')
        .update({'is_live': true})
        .eq('id', userId);

    if (!mounted) return;

    // 2. Navigate to Live Screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveScreen(
          isBroadcaster: true,
          channelId: userId, // Room Name = User ID
        ),
      ),
    );

    // 3. When they come back (close stream), mark as "Not Live"
    await Supabase.instance.client
        .from('profiles')
        .update({'is_live': false})
        .eq('id', userId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('New Post'), backgroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // LIVE BUTTON SECTION
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.live_tv, size: 40, color: Colors.redAccent),
                    const SizedBox(height: 8),
                    const Text("Start a Live Stream", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GradientButton(
                      child: const Text("GO LIVE NOW", style: TextStyle(fontWeight: FontWeight.bold)),
                      onTap: _goLive,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              const Divider(color: Colors.grey),
              const SizedBox(height: 20),

              // EXISTING UPLOAD LOGIC
              if (_file != null) 
                Container(height: 200, color: Colors.grey[900], child: Center(child: Text(_isVideo ? 'Video selected' : 'Image selected', style: const TextStyle(color: Colors.white)))),
              const SizedBox(height: 12),
              TextField(
                controller: _captionCtrl, 
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Caption', labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)))
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: ElevatedButton(onPressed: () async { final x = await _up.pickImage(); if (x != null) setState(() { _file = File(x.path); _isVideo = false; }); }, child: const Text('Pick Image'))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: () async { final x = await _up.pickVideo(); if (x != null) setState(() { _file = File(x.path); _isVideo = true; }); }, child: const Text('Pick Video'))),
              ]),
              const SizedBox(height: 12),
              _loading ? const CircularProgressIndicator() : GradientButton(child: const Text('Share Post'), onTap: () async {
                if (_file == null) return;
                setState(() { _loading = true; });
                final url = await _up.uploadFile(_file!, _isVideo ? 'videos' : 'images');
                await _up.createPostDoc(userId: auth.user!.id, mediaUrl: url, isVideo: _isVideo, caption: _captionCtrl.text.trim());
                setState(() { _loading = false; _file = null; _captionCtrl.clear(); });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded')));
              }),
            ],
          ),
        ),
      ),
    );
  }
}