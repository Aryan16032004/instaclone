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

  /// Get list of followers with profile data
  Future<List<Map<String, dynamic>>> getFollowersList(String userId) async {
    try {
      // Get all follower IDs
      final followsData = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);

      if (followsData.isEmpty) {
        print('No followers found in follows table for user: $userId');
        return [];
      }

      // Extract follower IDs
      final followerIds = followsData
          .map((row) => row['follower_id'] as String)
          .toList();

      print('Found ${followerIds.length} follower IDs: $followerIds');

      // Get profile data for all followers
      final profiles = await _supabase
          .from('profiles')
          .select('id, username, name, avatar_url')
          .inFilter('id', followerIds);

      print('Fetched ${profiles.length} follower profiles');

      return List<Map<String, dynamic>>.from(
        profiles.map((profile) => {'profiles': profile}),
      );
    } catch (e) {
      print('Error fetching followers list: $e');
      return [];
    }
  }

  /// Get list of following with profile data
  Future<List<Map<String, dynamic>>> getFollowingList(String userId) async {
    try {
      // Get all following IDs
      final followsData = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);

      if (followsData.isEmpty) {
        print('No following found in follows table for user: $userId');
        return [];
      }

      // Extract following IDs
      final followingIds = followsData
          .map((row) => row['following_id'] as String)
          .toList();

      print('Found ${followingIds.length} following IDs: $followingIds');

      // Get profile data for all following
      final profiles = await _supabase
          .from('profiles')
          .select('id, username, name, avatar_url')
          .inFilter('id', followingIds);

      print('Fetched ${profiles.length} following profiles');

      return List<Map<String, dynamic>>.from(
        profiles.map((profile) => {'profiles': profile}),
      );
    } catch (e) {
      print('Error fetching following list: $e');
      return [];
    }
  }
}
