import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// Imports from your project structure
import '../widgets/video_player_item.dart'; 
import '../widgets/comment_modal.dart'; 
import '../widgets/live_users_bar.dart'; // We created this in Step 1
import '../services/post_service.dart';

class FeedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Instagram', 
          style: TextStyle(fontFamily: 'Cursive', fontSize: 32, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
          IconButton(icon: const Icon(Icons.message_outlined), onPressed: () {}),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. LIVE USERS BAR (Stories area)
          const SliverToBoxAdapter(
            child: LiveUsersBar(),
          ),

          // 2. THE POSTS FEED
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('posts')
                .stream(primaryKey: ['id'])
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())));
              }
              final posts = snapshot.data!;
              
              if (posts.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: Text("No posts yet", style: TextStyle(color: Colors.white))));
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PostCard(post: posts[index]),
                  childCount: posts.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// POST CARD WIDGET (Handles Likes, Animations, and Display)
// ---------------------------------------------------------------------------

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _postService = PostService();
  final _userId = Supabase.instance.client.auth.currentUser!.id;
  bool _isLiked = false;
  bool _isAnimating = false; // For double tap heart animation

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  void _checkLikeStatus() async {
    bool hasLiked = await _postService.userHasLiked(widget.post['id'].toString(), _userId);
    if (mounted) setState(() => _isLiked = hasLiked);
  }

  void _toggleLike() async {
    setState(() => _isLiked = !_isLiked); // Optimistic UI update
    await _postService.toggleLike(widget.post['id'].toString(), _userId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A. Post Header (User Avatar + Name)
        FutureBuilder<Map<String, dynamic>?>(
          future: Supabase.instance.client.from('profiles').select().eq('id', widget.post['user_id']).maybeSingle(),
          builder: (context, snap) {
            final user = snap.data;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[900],
                backgroundImage: (user != null && user['avatar_url'] != null)
                    ? NetworkImage(user['avatar_url'])
                    : null,
                child: (user == null || user['avatar_url'] == null) 
                    ? const Icon(Icons.person, color: Colors.white) : null,
              ),
              title: Text(user?['username'] ?? 'User', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              trailing: const Icon(Icons.more_vert, color: Colors.white),
            );
          }
        ),

        // B. Main Media (Double Tap Logic)
        GestureDetector(
          onDoubleTap: () {
            if (!_isLiked) _toggleLike();
            setState(() => _isAnimating = true);
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (mounted) setState(() => _isAnimating = false);
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 400,
                width: double.infinity,
                color: Colors.grey[900],
                child: widget.post['is_video'] == true
                    ? VideoPlayerItem(videoUrl: widget.post['media_url'])
                    : CachedNetworkImage(
                        imageUrl: widget.post['media_url'],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      ),
              ),
              // Big White Heart Animation
              if (_isAnimating)
                const Icon(Icons.favorite, color: Colors.white, size: 100),
            ],
          ),
        ),

        // C. Action Buttons Row
        Row(
          children: [
            IconButton(
              icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, 
                color: _isLiked ? Colors.red : Colors.white),
              onPressed: _toggleLike,
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => CommentModal(postId: widget.post['id'].toString()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_outlined, color: Colors.white),
              onPressed: () {},
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.bookmark_border, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),

        // D. Likes, Caption & Date
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.post['likes']} likes', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white),
                  children: [
                    // Note: In a real app, you'd fetch the username again here or pass it down
                    const TextSpan(text: 'User ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: widget.post['caption'] ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              if (widget.post['comments'] > 0)
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CommentModal(postId: widget.post['id'].toString()),
                  ),
                  child: Text('View all ${widget.post['comments']} comments', 
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              Text(
                timeago.format(DateTime.parse(widget.post['created_at'].toString())),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}