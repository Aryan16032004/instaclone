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
  int? _replyingToId; // ID of the comment being replied to
  String _replyingToName = '';

  void _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    _controller.clear();
    FocusScope.of(context).unfocus();
    
    await _postService.addComment(widget.postId, _myId, text, parentId: _replyingToId);
    
    // Reset reply state
    setState(() {
      _replyingToId = null;
      _replyingToName = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // Taller, like screenshot
      decoration: const BoxDecoration(
        color: Color(0xFF121212), // Dark bg like screens
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          const Divider(color: Colors.grey),
          
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('comments')
                  .stream(primaryKey: ['id'])
                  .eq('post_id', widget.postId)
                  .order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final allComments = snapshot.data!;
                // Separate parent comments and replies could be done here logic-wise
                // For MVP, we list them flat but indent replies
                
                return ListView.builder(
                  itemCount: allComments.length,
                  itemBuilder: (context, index) {
                    final c = allComments[index];
                    final isReply = c['parent_id'] != null;
                    
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: Supabase.instance.client.from('profiles').select().eq('id', c['user_id']).maybeSingle(),
                      builder: (context, userSnap) {
                        final user = userSnap.data;
                        return Padding(
                          padding: EdgeInsets.only(left: isReply ? 50.0 : 10.0, top: 8, bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: (user != null && user['avatar_url'] != null)
                                    ? NetworkImage(user['avatar_url']) : null,
                                child: user?['avatar_url'] == null ? const Icon(Icons.person, size: 15) : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: user?['username'] ?? 'User',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                          ),
                                          const TextSpan(text: "  "),
                                          TextSpan(
                                            text: c['text'],
                                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          timeago.format(DateTime.parse(c['created_at']), locale: 'en_short'),
                                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                                        ),
                                        const SizedBox(width: 15),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _replyingToId = c['id'];
                                              _replyingToName = user?['username'] ?? 'User';
                                            });
                                          },
                                          child: const Text("Reply", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Like button for comment
                              const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                              const SizedBox(width: 10),
                            ],
                          ),
                        );
                      }
                    );
                  },
                );
              },
            ),
          ),
          
          // Reply Indicator
          if (_replyingToId != null)
            Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text("Replying to $_replyingToName", style: const TextStyle(color: Colors.grey)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onPressed: () => setState(() => _replyingToId = null),
                  )
                ],
              ),
            ),

          // Input Field
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 10, 
              left: 10, right: 10, top: 5
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFC13584),
                  radius: 22,
                  child: IconButton(
                    onPressed: _submit, 
                    icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}