import 'package:supabase_flutter/supabase_flutter.dart';

class PostService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns whether the given user has liked the post.
  Future<bool> userHasLiked(String postId, String userId) async {
    final res =
        await _supabase
                .from('likes')
                .select('id')
                .eq('post_id', postId)
                .eq('user_id', userId)
                .limit(1)
            as dynamic;
    if (res == null) return false;
    if (res is List) return res.isNotEmpty;
    if (res is Map && res['data'] is List)
      return (res['data'] as List).isNotEmpty;
    return false;
  }

  /// Toggle like for [postId] by [userId]. Returns the new likes count.
  Future<int> toggleLike(String postId, String userId) async {
    // check exists
    final liked = await userHasLiked(postId, userId);
    if (liked) {
      await _supabase
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } else {
      await _supabase.from('likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    }

    // recompute count and write back to posts table
    final cntRes =
        await _supabase.from('likes').select('id').eq('post_id', postId)
            as dynamic;
    int count = 0;
    if (cntRes is List)
      count = cntRes.length;
    else if (cntRes is Map && cntRes['count'] != null)
      count = cntRes['count'] as int;

    // update posts.likes for caching/display (best-effort)
    await _supabase.from('posts').update({'likes': count}).eq('id', postId);
    return count;
  }

  /// Add a comment and return the new comment count.
  Future<int> addComment(
    String postId,
    String userId,
    String text, {
    String? parentId,
  }) async {
    await _supabase.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'text': text,
      if (parentId != null) 'parent_id': parentId,
    });

    // Update comment count
    final cntRes =
        await _supabase.from('comments').select('id').eq('post_id', postId)
            as dynamic;
    int count = 0;
    if (cntRes is List)
      count = cntRes.length;
    else if (cntRes is Map && cntRes['count'] != null)
      count = cntRes['count'] as int;

    await _supabase.from('posts').update({'comments': count}).eq('id', postId);
    return count;
  }
}
