import 'package:supabase_flutter/supabase_flutter.dart';

class AgencyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create a new agency
  Future<Map<String, dynamic>?> createAgency({
    required String name,
    String? description,
    double commissionRate = 10.0,
    bool isCoinSeller = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('agencies')
          .insert({
            'name': name,
            'owner_id': userId,
            'description': description,
            'commission_rate': commissionRate,
            'is_coin_seller': isCoinSeller,
          })
          .select()
          .single();

      // Add owner as member
      await _supabase.from('agency_members').insert({
        'agency_id': response['id'],
        'user_id': userId,
        'role': 'owner',
      });

      return response;
    } catch (e) {
      print('Error creating agency: $e');
      return null;
    }
  }

  // Get all agencies
  Future<List<Map<String, dynamic>>> getAgencies() async {
    try {
      final response = await _supabase
          .from('agencies')
          .select('''
            *,
            owner:profiles!agencies_owner_id_fkey(id, username, avatar_url)
          ''')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching agencies: $e');
      return [];
    }
  }

  // Get user's agencies
  Future<List<Map<String, dynamic>>> getMyAgencies() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('agency_members')
          .select('''
            *,
            agency:agencies(*)
          ''')
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching my agencies: $e');
      return [];
    }
  }

  // Add member to agency
  Future<bool> addMember({
    required String agencyId,
    required String userId,
    String role = 'member',
  }) async {
    try {
      await _supabase.from('agency_members').insert({
        'agency_id': agencyId,
        'user_id': userId,
        'role': role,
      });

      return true;
    } catch (e) {
      print('Error adding member: $e');
      return false;
    }
  }

  // Remove member from agency
  Future<bool> removeMember({
    required String agencyId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('agency_members')
          .delete()
          .eq('agency_id', agencyId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error removing member: $e');
      return false;
    }
  }

  // Get agency members
  Future<List<Map<String, dynamic>>> getMembers(String agencyId) async {
    try {
      final response = await _supabase
          .from('agency_members')
          .select('''
            *,
            user:profiles(id, username, avatar_url)
          ''')
          .eq('agency_id', agencyId)
          .order('joined_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching members: $e');
      return [];
    }
  }

  // Update agency
  Future<bool> updateAgency({
    required String agencyId,
    String? name,
    String? description,
    double? commissionRate,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (commissionRate != null) updates['commission_rate'] = commissionRate;

      await _supabase.from('agencies').update(updates).eq('id', agencyId);

      return true;
    } catch (e) {
      print('Error updating agency: $e');
      return false;
    }
  }

  // Get coin seller agencies
  Future<List<Map<String, dynamic>>> getCoinSellerAgencies() async {
    try {
      final response = await _supabase
          .from('agencies')
          .select('''
            *,
            owner:profiles!agencies_owner_id_fkey(id, username, avatar_url)
          ''')
          .eq('is_coin_seller', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching coin seller agencies: $e');
      return [];
    }
  }

  // Create coin package (for coin seller agencies)
  Future<Map<String, dynamic>?> createCoinPackage({
    required String agencyId,
    required String name,
    required int coinAmount,
    required double price,
    int bonusCoins = 0,
  }) async {
    try {
      final response = await _supabase
          .from('coin_packages')
          .insert({
            'agency_id': agencyId,
            'name': name,
            'coin_amount': coinAmount,
            'price': price,
            'bonus_coins': bonusCoins,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error creating coin package: $e');
      return null;
    }
  }

  // Get coin packages for an agency
  Future<List<Map<String, dynamic>>> getCoinPackages(String agencyId) async {
    try {
      final response = await _supabase
          .from('coin_packages')
          .select()
          .eq('agency_id', agencyId)
          .eq('is_active', true)
          .order('price', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching coin packages: $e');
      return [];
    }
  }

  // Purchase coins (placeholder - needs payment integration)
  Future<bool> purchaseCoins({
    required String packageId,
    required String paymentMethod,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final package = await _supabase
          .from('coin_packages')
          .select('*, agency:agencies(*)')
          .eq('id', packageId)
          .single();

      final totalCoins =
          (package['coin_amount'] as int) + (package['bonus_coins'] as int);

      // Record purchase
      await _supabase.from('coin_purchases').insert({
        'user_id': userId,
        'package_id': packageId,
        'agency_id': package['agency_id'],
        'coins_purchased': totalCoins,
        'amount_paid': package['price'],
        'payment_method': paymentMethod,
        'payment_status':
            'pending', // Would be 'completed' after payment gateway confirmation
      });

      // TODO: Integrate with payment gateway (Razorpay, Stripe, etc.)
      // For now, this is a placeholder

      return true;
    } catch (e) {
      print('Error purchasing coins: $e');
      return false;
    }
  }

  // Get agency earnings
  Future<Map<String, dynamic>> getAgencyEarnings(String agencyId) async {
    try {
      final agency = await _supabase
          .from('agencies')
          .select()
          .eq('id', agencyId)
          .single();

      final purchases = await _supabase
          .from('coin_purchases')
          .select()
          .eq('agency_id', agencyId)
          .eq('payment_status', 'completed');

      double totalRevenue = 0;
      int totalCoinsSold = 0;

      for (var purchase in purchases) {
        totalRevenue += (purchase['amount_paid'] as num).toDouble();
        totalCoinsSold += purchase['coins_purchased'] as int;
      }

      return {
        'total_earnings': agency['total_earnings'],
        'total_revenue': totalRevenue,
        'total_coins_sold': totalCoinsSold,
        'commission_rate': agency['commission_rate'],
      };
    } catch (e) {
      print('Error fetching agency earnings: $e');
      return {};
    }
  }
}
