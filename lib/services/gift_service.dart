import 'package:supabase_flutter/supabase_flutter.dart';

class GiftService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all available gifts
  Future<List<Map<String, dynamic>>> getGifts() async {
    try {
      final response = await _supabase
          .from('gifts')
          .select()
          .eq('is_active', true)
          .order('coin_cost', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching gifts: $e');
      return [];
    }
  }

  // Get gifts by category
  Future<List<Map<String, dynamic>>> getGiftsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('gifts')
          .select()
          .eq('is_active', true)
          .eq('category', category)
          .order('coin_cost', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching gifts by category: $e');
      return [];
    }
  }

  // Send a gift to a user
  Future<bool> sendGift({
    required String toUserId,
    required String giftId,
    String? liveRoomId,
    String? postId,
  }) async {
    try {
      final fromUserId = _supabase.auth.currentUser?.id;
      if (fromUserId == null) return false;

      // Get gift details
      final gift = await _supabase
          .from('gifts')
          .select()
          .eq('id', giftId)
          .single();

      final coinCost = gift['coin_cost'] as int;

      // Transfer coins using wallet service
      final transferSuccess = await _supabase.rpc(
        'transfer_coins',
        params: {
          'p_from_user_id': fromUserId,
          'p_to_user_id': toUserId,
          'p_amount': coinCost,
          'p_transaction_type': 'gift',
          'p_description': 'Gift: ${gift['name']}',
          'p_post_id': postId,
          'p_gift_id': giftId,
        },
      );

      if (transferSuccess != true) {
        return false;
      }

      // Record gift transaction
      await _supabase.from('gift_transactions').insert({
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'gift_id': giftId,
        'live_room_id': liveRoomId,
        'post_id': postId,
      });

      return true;
    } catch (e) {
      print('Error sending gift: $e');
      return false;
    }
  }

  // Get gifts received by user
  Future<List<Map<String, dynamic>>> getReceivedGifts({
    String? userId,
    int limit = 50,
  }) async {
    try {
      final targetUserId = userId ?? _supabase.auth.currentUser?.id;
      if (targetUserId == null) return [];

      final response = await _supabase
          .from('gift_transactions')
          .select('''
            *,
            gift:gifts(*),
            from_user:profiles!gift_transactions_from_user_id_fkey(id, username, avatar_url)
          ''')
          .eq('to_user_id', targetUserId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching received gifts: $e');
      return [];
    }
  }

  // Get gifts sent by user
  Future<List<Map<String, dynamic>>> getSentGifts({int limit = 50}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('gift_transactions')
          .select('''
            *,
            gift:gifts(*),
            to_user:profiles!gift_transactions_to_user_id_fkey(id, username, avatar_url)
          ''')
          .eq('from_user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching sent gifts: $e');
      return [];
    }
  }

  // Get total gifts received count for a user
  Future<int> getReceivedGiftsCount(String userId) async {
    try {
      final response = await _supabase
          .from('gift_transactions')
          .select('id')
          .eq('to_user_id', userId);

      return response.length;
    } catch (e) {
      print('Error fetching received gifts count: $e');
      return 0;
    }
  }

  // Stream gift transactions for live updates (useful in live streams)
  Stream<List<Map<String, dynamic>>> streamGiftTransactions({
    String? liveRoomId,
    String? postId,
  }) {
    // Note: Supabase stream filters need to be applied differently
    // For now, we'll stream all and filter in-app
    return _supabase.from('gift_transactions').stream(primaryKey: ['id']).map((
      data,
    ) {
      var filtered = List<Map<String, dynamic>>.from(data);
      if (liveRoomId != null) {
        filtered = filtered
            .where((item) => item['live_room_id'] == liveRoomId)
            .toList();
      }
      if (postId != null) {
        filtered = filtered.where((item) => item['post_id'] == postId).toList();
      }
      return filtered;
    });
  }

  // Get gift categories
  Future<List<String>> getGiftCategories() async {
    try {
      final response = await _supabase
          .from('gifts')
          .select('category')
          .eq('is_active', true);

      final categories = <String>{};
      for (var gift in response) {
        categories.add(gift['category'] as String);
      }

      return categories.toList();
    } catch (e) {
      print('Error fetching gift categories: $e');
      return ['general', 'romantic', 'premium', 'fun', 'celebration'];
    }
  }
}
