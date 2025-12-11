import 'package:supabase_flutter/supabase_flutter.dart';

class PostService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- LIKES ---
  Future<bool> userHasLiked(String postId, String userId) async {
    final res = await _supabase.from('likes').select().match({'post_id': postId, 'user_id': userId}).maybeSingle();
    return res != null;
  }

  Future<void> toggleLike(String postId, String userId) async {
    final liked = await userHasLiked(postId, userId);
    if (liked) {
      await _supabase.from('likes').delete().match({'post_id': postId, 'user_id': userId});
    } else {
      await _supabase.from('likes').insert({'post_id': postId, 'user_id': userId});
    }
  }

  // --- COMMENTS (Nested) ---
  Future<void> addComment(String postId, String userId, String text, {int? parentId}) async {
    await _supabase.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'text': text,
      'parent_id': parentId, // Null for main comments, ID for replies
    });
  }

  // --- FOLLOW SYSTEM ---
  Future<bool> isFollowing(String myId, String targetUserId) async {
    final res = await _supabase.from('follows')
        .select()
        .match({'follower_id': myId, 'following_id': targetUserId})
        .maybeSingle();
    return res != null;
  }

  Future<void> toggleFollow(String myId, String targetUserId) async {
    final following = await isFollowing(myId, targetUserId);
    if (following) {
      await _supabase.from('follows').delete().match({'follower_id': myId, 'following_id': targetUserId});
    } else {
      await _supabase.from('follows').insert({'follower_id': myId, 'following_id': targetUserId});
    }
  }
}