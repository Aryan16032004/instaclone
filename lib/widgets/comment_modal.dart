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
  final _myId = Supabase.instance.client.auth.currentUser?.id;
  final FocusNode _focusNode = FocusNode();

  String? _replyToCommentId;
  String? _replyToUsername;

  void _submit() async {
    if (_myId == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _focusNode.unfocus();

    // reset reply state
    final parentId = _replyToCommentId;
    setState(() {
      _replyToCommentId = null;
      _replyToUsername = null;
    });

    try {
      await _postService.addComment(
        widget.postId,
        _myId!,
        text,
        parentId: parentId,
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _setReply(String commentId, String username) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUsername = username;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // If auth is missing, showing empty or login prompt might be better, but we'll assume auth.
    if (_myId == null)
      return const Center(child: Text("Please log in to comment"));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF121212), // Darker generic background
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Comments",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const Divider(color: Colors.grey, thickness: 0.5),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('comments')
                  .stream(primaryKey: ['id'])
                  .eq('post_id', widget.postId)
                  .order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                // Client-side nesting
                final allComments = snapshot.data!;

                // Tree Construction
                final List<Map<String, dynamic>> rootComments = [];
                final Map<String, List<Map<String, dynamic>>> replies = {};

                for (var c in allComments) {
                  final parentId = c['parent_id'];
                  if (parentId == null) {
                    rootComments.add(c);
                  } else {
                    replies.putIfAbsent(parentId.toString(), () => []).add(c);
                  }
                }

                if (allComments.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No comments yet.",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          "Start the conversation!",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: rootComments.length,
                  itemBuilder: (context, index) {
                    final root = rootComments[index];
                    return _buildCommentTree(root, replies);
                  },
                );
              },
            ),
          ),

          // Reply Indicator
          if (_replyToUsername != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[900],
              child: Row(
                children: [
                  Text(
                    "Replying to ${_replyToUsername}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _replyToCommentId = null;
                      _replyToUsername = null;
                    }),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

          // Input
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 10,
              left: 10,
              right: 10,
              top: 5,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _replyToUsername != null
                          ? "Reply to ${_replyToUsername}..."
                          : "Add a comment...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _submit,
                  icon: const Icon(
                    Icons.send,
                    color: Color(0xFFC13584),
                  ), // Insta Pink
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTree(
    Map<String, dynamic> comment,
    Map<String, List<Map<String, dynamic>>> repliesMap,
  ) {
    final commentId = comment['id'].toString();
    final childReplies = repliesMap[commentId] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentItem(comment),
        if (childReplies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 44.0), // Indent replies
            child: Column(
              children: childReplies
                  .map((r) => _buildCommentItem(r, isReply: true))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> c, {bool isReply = false}) {
    // We need to fetch user details for each comment.
    // Ideally this should be a JOIN or we pass a User Map/Cache.
    // For now we use FutureBuilder per row (not optimal but works for MVP).
    return FutureBuilder<Map<String, dynamic>?>(
      future: Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', c['user_id'])
          .maybeSingle(),
      builder: (context, userSnap) {
        final user = userSnap.data;
        final username = user?['username'] ?? 'User';
        final avatarUrl = user?['avatar_url'];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isReply ? 14 : 18,
                backgroundColor: Colors.grey[800],
                backgroundImage: (avatarUrl != null)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null)
                    ? Icon(
                        Icons.person,
                        size: isReply ? 16 : 20,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeago.format(DateTime.parse(c['created_at'])),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c['text'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _setReply(c['id'].toString(), username),
                      child: const Text(
                        "Reply",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Optional: Like button for comment would go here
            ],
          ),
        );
      },
    );
  }
}
