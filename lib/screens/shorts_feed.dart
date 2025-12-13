import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../services/post_service.dart';
import '../widgets/comment_modal.dart';

class ShortsFeed extends StatelessWidget {
  const ShortsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Extends behind status bar for full immersion
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Reels', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: false,
        automaticallyImplyLeading: false, // Hides back button if on main tabs
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('posts')
            .stream(primaryKey: ['id'])
            .eq('is_video', true) // Only Videos
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFC13584)));
          }
          final docs = snapshot.data!;
          if (docs.isEmpty) {
            return const Center(child: Text("No Reels yet", style: TextStyle(color: Colors.white)));
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return ShortsPlayerItem(post: docs[index]);
            },
          );
        },
      ),
    );
  }
}

class ShortsPlayerItem extends StatefulWidget {
  final Map<String, dynamic> post;
  const ShortsPlayerItem({super.key, required this.post});

  @override
  State<ShortsPlayerItem> createState() => _ShortsPlayerItemState();
}

class _ShortsPlayerItemState extends State<ShortsPlayerItem> {
  late VideoPlayerController _controller;
  final _postService = PostService();
  final _myId = Supabase.instance.client.auth.currentUser!.id;

  bool _initialized = false;
  bool _isLiked = false;
  bool _isPlaying = true;
  bool _showHeartAnimation = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _checkLikeStatus();
  }

  void _initVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.post['media_url']));
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() => _initialized = true);
        _controller.setLooping(true);
        _controller.play();
      }
    } catch (e) {
      debugPrint("Video Error: $e");
    }
  }

  void _checkLikeStatus() async {
    bool hasLiked = await _postService.userHasLiked(widget.post['id'].toString(), _myId);
    if (mounted) setState(() => _isLiked = hasLiked);
  }

  void _toggleLike() async {
    setState(() => _isLiked = !_isLiked); // Instant UI update
    await _postService.toggleLike(widget.post['id'].toString(), _myId);
  }

  void _handleDoubleTap() {
    if (!_isLiked) _toggleLike();
    setState(() => _showHeartAnimation = true);
    
    // Hide the big heart after 1.2 seconds
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showHeartAnimation = false);
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying ? _controller.pause() : _controller.play();
      _isPlaying = !_isPlaying;
    });
  }

  @override
  void dispose() {
    _controller.pause(); // Stop playing before disposing
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. FULL SCREEN VIDEO
        GestureDetector(
          onTap: _togglePlay,
          onDoubleTap: _handleDoubleTap,
          child: Container(
            color: Colors.black,
            height: double.infinity,
            width: double.infinity,
            child: _initialized
                ? FittedBox(
                    fit: BoxFit.cover, // Ensures video fills screen completely
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : const Center(child: CircularProgressIndicator(color: Colors.grey)),
          ),
        ),

        // 2. PLAY ICON OVERLAY (When Paused)
        if (!_isPlaying && _initialized)
          const Center(
            child: Icon(Icons.play_arrow, size: 80, color: Colors.white54),
          ),

        // 3. DOUBLE TAP HEART ANIMATION
        if (_showHeartAnimation)
          const Center(
            child: Icon(Icons.favorite, size: 100, color: Colors.white),
          ),

        // 4. RIGHT SIDE ACTIONS (Like, Comment)
        Positioned(
          right: 15,
          bottom: 120, // Adjusted to sit nicely above bottom nav
          child: Column(
            children: [
              // Like Button
              _ActionIcon(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.white,
                label: "${widget.post['likes']}",
                onTap: _toggleLike,
              ),
              const SizedBox(height: 25),

              // Comment Button
              _ActionIcon(
                icon: Icons.comment_rounded,
                color: Colors.white,
                label: "${widget.post['comments']}",
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CommentModal(postId: widget.post['id'].toString()),
                ),
              ),
              
              const SizedBox(height: 25),
              // Spinning Disc (Aesthetic)
              _buildMusicDisc(),
            ],
          ),
        ),

        // 5. BOTTOM INFO (User & Caption)
        Positioned(
          left: 15,
          bottom: 40,
          right: 80, // Space for right icons
          child: FutureBuilder<Map<String, dynamic>?>(
            future: Supabase.instance.client.from('profiles').select().eq('id', widget.post['user_id']).maybeSingle(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              final username = user?['username'] ?? 'User';
              final avatar = user?['avatar_url'];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                        child: avatar == null ? const Icon(Icons.person, size: 20, color: Colors.black) : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        username,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 10),
                      // Follow Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text("Follow", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Caption
                  if (widget.post['caption'] != null && widget.post['caption'].isNotEmpty)
                    Text(
                      widget.post['caption'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMusicDisc() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF444444), width: 8),
      ),
      child: const Center(
        child: CircleAvatar(
          radius: 12,
          backgroundColor: Colors.redAccent,
          child: Icon(Icons.music_note, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3), // Background for better visibility
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}