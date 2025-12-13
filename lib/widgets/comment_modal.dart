import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/post_service.dart';

class CommentModal extends StatefulWidget {
  final String postId;
  const CommentModal({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentModal> createState() => _CommentModalState();
}

class _CommentModalState extends State<CommentModal> {
  final _controller = TextEditingController();
  final _postService = PostService();
  final _myId = Supabase.instance.client.auth.currentUser!.id;
  int? _replyingToId;
  String _replyingToName = '';

  void _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    FocusScope.of(context).unfocus();
    await _postService.addComment(widget.postId, _myId, text, parentId: _replyingToId);
    setState(() { _replyingToId = null; _replyingToName = ''; });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 15),
              const Text("Comments", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              const Divider(color: Colors.white10, height: 1),

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('comments')
                      .stream(primaryKey: ['id'])
                      .eq('post_id', widget.postId)
                      .order('created_at', ascending: true),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final comments = snapshot.data!;
                    
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        // Using a separate widget for each item to handle Like State efficiently
                        return CommentItem(
                          comment: c,
                          onReply: (id, name) {
                            setState(() {
                              _replyingToId = id;
                              _replyingToName = name;
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              if (_replyingToId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey[900],
                  child: Row(
                    children: [
                      Text("Replying to $_replyingToName", style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        onPressed: () => setState(() => _replyingToId = null),
                      )
                    ],
                  ),
                ),

              _buildInputBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
        left: 10, right: 10, top: 10
      ),
      color: Colors.black,
      child: Row(
        children: [
          const CircleAvatar(radius: 16, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Hello Dear !",
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.alternate_email, color: Colors.grey), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey), onPressed: () {}),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: _submit,
            icon: const Icon(Icons.send, color: Color(0xFFFDD835), size: 30),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------
// NEW: Comment Item Widget (Handles Like Logic Individually)
// --------------------------------------------------------
class CommentItem extends StatefulWidget {
  final Map<String, dynamic> comment;
  final Function(int id, String name) onReply;

  const CommentItem({super.key, required this.comment, required this.onReply});

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool _isLiked = false;
  final _postService = PostService();
  final _myId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  void _checkLikeStatus() async {
    bool liked = await _postService.hasUserLikedComment(widget.comment['id'].toString(), _myId);
    if (mounted) setState(() => _isLiked = liked);
  }

  void _toggleLike() async {
    setState(() => _isLiked = !_isLiked); // Optimistic update
    await _postService.toggleCommentLike(widget.comment['id'].toString(), _myId);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    final bool isReply = c['parent_id'] != null;

    return FutureBuilder<Map<String, dynamic>?>(
      future: Supabase.instance.client.from('profiles').select().eq('id', c['user_id']).maybeSingle(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final username = user?['username'] ?? 'Unknown';
        final avatarUrl = user?['avatar_url'];

        return Padding(
          padding: EdgeInsets.only(left: isReply ? 50 : 16, right: 16, top: 12, bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[800],
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        // Removed verified tick as requested
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(c['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          timeago.format(DateTime.parse(c['created_at']), locale: 'en_short'),
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        const SizedBox(width: 15),
                        GestureDetector(
                          onTap: () => widget.onReply(c['id'], username),
                          child: const Text("Reply", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // LIKE BUTTON COLUMN
              GestureDetector(
                onTap: _toggleLike,
                child: Column(
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : Colors.grey,
                      size: 18
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${c['likes_count'] ?? 0}",
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      }
    );
  }
}