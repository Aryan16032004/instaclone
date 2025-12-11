import 'package:supabase_flutter/supabase_flutter.dart';

class FollowService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if [followerId] follows [followingId]
  Future<bool> isFollowing(String followerId, String followingId) async {
    final res = await _supabase
        .from('follows')
        .select()
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();
    return res != null;
  }

  /// Follow a user
  Future<void> followUser(String followerId, String followingId) async {
    await _supabase.from('follows').insert({
      'follower_id': followerId,
      'following_id': followingId,
    });
    // Update stats logic omitted for brevity, usually handled by triggers or manual update
  }

  /// Unfollow a user
  Future<void> unfollowUser(String followerId, String followingId) async {
    await _supabase
        .from('follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
  }

  /// Get followers count
  Future<int> getFollowersCount(String userId) async {
    final res =
        await _supabase
                .from('follows')
                .select('follower_id')
                .eq('following_id', userId)
            as dynamic;
    if (res is List) return res.length;
    return 0; // fallback
  }

  /// Get following count
  Future<int> getFollowingCount(String userId) async {
    final res =
        await _supabase
                .from('follows')
                .select('following_id')
                .eq('follower_id', userId)
            as dynamic;
    if (res is List) return res.length;
    return 0; // fallback
  }
}
