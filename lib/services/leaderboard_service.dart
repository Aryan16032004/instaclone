import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get top 100 users from leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 100}) async {
    try {
      final response = await _supabase
          .from('leaderboard')
          .select()
          .order('rank', ascending: true)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }

  // Get user's rank
  Future<Map<String, dynamic>?> getUserRank(String userId) async {
    try {
      final response = await _supabase
          .from('leaderboard')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching user rank: $e');
      return null;
    }
  }

  // Get current user's rank
  Future<Map<String, dynamic>?> getMyRank() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    return await getUserRank(userId);
  }

  // Refresh leaderboard manually
  Future<void> refreshLeaderboard() async {
    try {
      await _supabase.rpc('refresh_leaderboard');
    } catch (e) {
      print('Error refreshing leaderboard: $e');
    }
  }

  // Stream leaderboard updates
  Stream<List<Map<String, dynamic>>> streamLeaderboard({int limit = 100}) {
    return _supabase
        .from('leaderboard')
        .stream(primaryKey: ['user_id'])
        .order('rank', ascending: true)
        .limit(limit)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  // Get top users by specific criteria
  Future<List<Map<String, dynamic>>> getTopUsers({
    required int limit,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('leaderboard')
          .select()
          .order('rank', ascending: true)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching top users: $e');
      return [];
    }
  }

  // Check if user is in top 100
  Future<bool> isInTop100(String userId) async {
    final rank = await getUserRank(userId);
    if (rank == null) return false;
    return (rank['rank'] as int) <= 100;
  }

  // Get users around current user's rank
  Future<List<Map<String, dynamic>>> getUsersAroundRank({
    required int rank,
    int range = 5,
  }) async {
    try {
      final startRank = (rank - range).clamp(1, 100);
      final endRank = (rank + range).clamp(1, 100);

      final response = await _supabase
          .from('leaderboard')
          .select()
          .gte('rank', startRank)
          .lte('rank', endRank)
          .order('rank', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching users around rank: $e');
      return [];
    }
  }
}
