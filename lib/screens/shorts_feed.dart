import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class ShortsFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Reels')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Only get videos
        stream: Supabase.instance.client
            .from('posts')
            .stream(primaryKey: ['id'])
            .eq('is_video', true) 
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!;
          if (docs.isEmpty) return const Center(child: Text("No Reels yet"));

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _ShortsPlayer(url: docs[index]['media_url']);
            },
          );
        },
      ),
    );
  }
}

class _ShortsPlayer extends StatefulWidget {
  final String url;
  const _ShortsPlayer({required this.url});

  @override
  State<_ShortsPlayer> createState() => _ShortsPlayerState();
}

class _ShortsPlayerState extends State<_ShortsPlayer> {
  late VideoPlayerController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) return Container(color: Colors.black, child: const Center(child: CircularProgressIndicator()));
    
    return Stack(
      children: [
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        // Overlay Icons
        Positioned(
          right: 10,
          bottom: 100,
          child: Column(
            children: [
              IconButton(icon: const Icon(Icons.favorite, color: Colors.white, size: 30), onPressed: (){}),
              const Text("Like", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              IconButton(icon: const Icon(Icons.comment, color: Colors.white, size: 30), onPressed: (){}),
              const Text("Comment", style: TextStyle(color: Colors.white)),
            ],
          ),
        )
      ],
    );
  }
}