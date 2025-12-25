import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class EngagementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Timer? _scrollTimer;
  int _currentScrollTime = 0; // in seconds
  int _postsViewedToday = 0;

  // Constants for coin rewards
  static const int COINS_PER_5_MINUTES = 1;
  static const int COINS_PER_POST_VIEW = 2;
  static const int SCROLL_REWARD_INTERVAL = 300; // 5 minutes in seconds
  static const int POST_VIEW_MIN_DURATION = 3; // seconds
  static const int DAILY_COIN_LIMIT = 200;

  // Start tracking scroll time
  void startScrollTracking() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentScrollTime++;

      // Award coins every 5 minutes
      if (_currentScrollTime % SCROLL_REWARD_INTERVAL == 0) {
        _awardScrollCoins();
      }
    });
  }

  // Stop tracking scroll time
  void stopScrollTracking() {
    _scrollTimer?.cancel();
    _updateScrollTime();
  }

  // Award coins for scrolling
  Future<void> _awardScrollCoins() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final success = await _supabase.rpc(
        'award_engagement_coins',
        params: {
          'p_user_id': userId,
          'p_coins': COINS_PER_5_MINUTES,
          'p_description': 'Scrolling reward (5 minutes)',
        },
      );

      if (success == true) {
        print('Awarded $COINS_PER_5_MINUTES coins for scrolling');
      }
    } catch (e) {
      print('Error awarding scroll coins: $e');
    }
  }

  // Update scroll time in database
  Future<void> _updateScrollTime() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('user_engagement')
          .update({
            'total_scroll_time': _currentScrollTime,
            'last_activity': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      print('Error updating scroll time: $e');
    }
  }

  // Track post view
  Future<void> trackPostView({
    required String postId,
    required int viewDuration, // in seconds
  }) async {
    try {
      // Only award coins if viewed for at least 3 seconds
      if (viewDuration < POST_VIEW_MIN_DURATION) return;

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Update posts viewed count
      await _supabase
          .from('user_engagement')
          .update({
            'posts_viewed': _postsViewedToday + 1,
            'last_activity': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      _postsViewedToday++;

      // Award coins for viewing post
      final success = await _supabase.rpc(
        'award_engagement_coins',
        params: {
          'p_user_id': userId,
          'p_coins': COINS_PER_POST_VIEW,
          'p_description': 'Post view reward',
        },
      );

      if (success == true) {
        print('Awarded $COINS_PER_POST_VIEW coins for viewing post');
      }
    } catch (e) {
      print('Error tracking post view: $e');
    }
  }

  // Get user engagement stats
  Future<Map<String, dynamic>?> getEngagementStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('user_engagement')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching engagement stats: $e');
      return null;
    }
  }

  // Check daily coins earned
  Future<int> getDailyCoinsEarned() async {
    try {
      final stats = await getEngagementStats();
      if (stats == null) return 0;

      final lastReset = DateTime.parse(stats['last_coin_reset'] as String);
      final today = DateTime.now();

      // If it's a new day, return 0
      if (lastReset.day != today.day ||
          lastReset.month != today.month ||
          lastReset.year != today.year) {
        return 0;
      }

      return stats['daily_coins_earned'] as int? ?? 0;
    } catch (e) {
      print('Error getting daily coins earned: $e');
      return 0;
    }
  }

  // Check if user can earn more coins today
  Future<bool> canEarnMoreCoins() async {
    final dailyEarned = await getDailyCoinsEarned();
    return dailyEarned < DAILY_COIN_LIMIT;
  }

  // Get remaining coins that can be earned today
  Future<int> getRemainingDailyCoins() async {
    final dailyEarned = await getDailyCoinsEarned();
    return (DAILY_COIN_LIMIT - dailyEarned).clamp(0, DAILY_COIN_LIMIT);
  }

  // Initialize engagement tracking for new user
  Future<void> initializeEngagement() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Check if engagement record exists
      final existing = await _supabase
          .from('user_engagement')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        // Create new engagement record
        await _supabase.from('user_engagement').insert({
          'user_id': userId,
          'total_scroll_time': 0,
          'posts_viewed': 0,
          'daily_coins_earned': 0,
          'last_coin_reset': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error initializing engagement: $e');
    }
  }

  // Dispose timers
  void dispose() {
    _scrollTimer?.cancel();
  }
}
