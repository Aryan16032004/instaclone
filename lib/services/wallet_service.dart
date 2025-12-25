import 'package:supabase_flutter/supabase_flutter.dart';

class WalletService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get user's wallet balance
  Future<Map<String, dynamic>?> getWallet(String userId) async {
    try {
      final response = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching wallet: $e');
      return null;
    }
  }

  // Get current user's wallet
  Future<Map<String, dynamic>?> getMyWallet() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    return await getWallet(userId);
  }

  // Transfer coins to another user
  Future<bool> transferCoins({
    required String toUserId,
    required int amount,
    required String transactionType,
    String? description,
    String? postId,
    String? giftId,
  }) async {
    try {
      final fromUserId = _supabase.auth.currentUser?.id;
      if (fromUserId == null) return false;

      final response = await _supabase.rpc(
        'transfer_coins',
        params: {
          'p_from_user_id': fromUserId,
          'p_to_user_id': toUserId,
          'p_amount': amount,
          'p_transaction_type': transactionType,
          'p_description': description,
          'p_post_id': postId,
          'p_gift_id': giftId,
        },
      );

      return response == true;
    } catch (e) {
      print('Error transferring coins: $e');
      return false;
    }
  }

  // Get transaction history
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('transactions')
          .select('''
            *,
            from_user:profiles!transactions_from_user_id_fkey(id, username, avatar_url),
            to_user:profiles!transactions_to_user_id_fkey(id, username, avatar_url)
          ''')
          .or('from_user_id.eq.$userId,to_user_id.eq.$userId')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching transaction history: $e');
      return [];
    }
  }

  // Award engagement coins
  Future<bool> awardEngagementCoins({
    required int coins,
    required String description,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase.rpc(
        'award_engagement_coins',
        params: {
          'p_user_id': userId,
          'p_coins': coins,
          'p_description': description,
        },
      );

      return response == true;
    } catch (e) {
      print('Error awarding engagement coins: $e');
      return false;
    }
  }

  // Stream wallet balance updates
  Stream<Map<String, dynamic>?> streamWalletBalance() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value(null);
    }

    return _supabase
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.isNotEmpty ? data.first : null);
  }

  // Check if user has sufficient balance
  Future<bool> hasSufficientBalance(int requiredAmount) async {
    final wallet = await getMyWallet();
    if (wallet == null) return false;
    return (wallet['balance'] as int) >= requiredAmount;
  }

  // Get wallet statistics
  Future<Map<String, dynamic>> getWalletStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final wallet = await getMyWallet();
      if (wallet == null) return {};

      // Get total received
      final receivedResponse = await _supabase
          .from('transactions')
          .select('amount')
          .eq('to_user_id', userId);

      int totalReceived = 0;
      for (var transaction in receivedResponse) {
        totalReceived += (transaction['amount'] as int);
      }

      // Get total sent
      final sentResponse = await _supabase
          .from('transactions')
          .select('amount')
          .eq('from_user_id', userId);

      int totalSent = 0;
      for (var transaction in sentResponse) {
        totalSent += (transaction['amount'] as int);
      }

      return {
        'balance': wallet['balance'],
        'total_earned': wallet['total_earned'],
        'total_spent': wallet['total_spent'],
        'total_received': totalReceived,
        'total_sent': totalSent,
      };
    } catch (e) {
      print('Error fetching wallet stats: $e');
      return {};
    }
  }

  // Get available coin packages
  Future<List<Map<String, dynamic>>> getCoinPackages() async {
    try {
      final response = await _supabase
          .from('coin_packages')
          .select()
          .order('coins', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching coin packages: $e');
      return [];
    }
  }

  // Purchase coins (placeholder for payment integration)
  Future<bool> purchaseCoins({
    required String packageId,
    required int coins,
    required int priceInr,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // TODO: Integrate with payment gateway (Razorpay, Stripe, etc.)
      // For now, this is a placeholder that would be called after successful payment

      // Add coins to wallet
      final wallet = await getMyWallet();
      if (wallet == null) return false;

      final newBalance = (wallet['balance'] as int) + coins;

      await _supabase
          .from('wallets')
          .update({
            'balance': newBalance,
            'total_earned': (wallet['total_earned'] as int) + coins,
          })
          .eq('user_id', userId);

      // Record transaction
      await _supabase.from('transactions').insert({
        'to_user_id': userId,
        'amount': coins,
        'transaction_type': 'purchase',
        'description': 'Purchased $coins coins for ₹$priceInr',
      });

      return true;
    } catch (e) {
      print('Error purchasing coins: $e');
      return false;
    }
  }
}
