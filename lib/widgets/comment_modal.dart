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

  void _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    FocusScope.of(context).unfocus();
    await _postService.addComment(widget.postId, _myId, text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F1F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 10),
          const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                final comments = snapshot.data!;
                if (comments.isEmpty) return const Center(child: Text("No comments yet. Be the first!"));

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final c = comments[index];
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: Supabase.instance.client.from('profiles').select().eq('id', c['user_id']).maybeSingle(),
                      builder: (context, userSnap) {
                        final user = userSnap.data;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[800],
                            backgroundImage: (user != null && user['avatar_url'] != null)
                                ? NetworkImage(user['avatar_url']) : null,
                            child: (user == null || user['avatar_url'] == null) ? const Icon(Icons.person, color: Colors.white) : null,
                          ),
                          title: Row(
                            children: [
                              Text(user?['username'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                              const SizedBox(width: 8),
                              Text(timeago.format(DateTime.parse(c['created_at'])), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          subtitle: Text(c['text'], style: const TextStyle(color: Colors.white)),
                        );
                      }
                    );
                  },
                );
              },
            ),
          ),
          
          // Input
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
                IconButton(
                  onPressed: _submit, 
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}