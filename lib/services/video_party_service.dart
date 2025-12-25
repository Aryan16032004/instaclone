import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class VideoPartyService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // Public getter for supabase client
  SupabaseClient get supabase => _supabase;

  // Create a new video party
  Future<Map<String, dynamic>?> createVideoParty({
    required String title,
    String? description,
    required int maxParticipants,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Generate unique Agora channel name
      final channelName = 'video_${_uuid.v4().replaceAll('-', '_')}';

      final response = await _supabase
          .from('video_parties')
          .insert({
            'host_id': userId,
            'title': title,
            'description': description,
            'agora_channel_name': channelName,
            'max_participants': maxParticipants,
            'current_participants': 1,
            'status': 'active',
          })
          .select()
          .single();

      // Add host as participant
      await _supabase.from('video_party_participants').insert({
        'party_id': response['id'],
        'user_id': userId,
      });

      return response;
    } catch (e) {
      print('Error creating video party: $e');
      return null;
    }
  }

  // Get active video parties
  Future<List<Map<String, dynamic>>> getActiveParties() async {
    try {
      final response = await _supabase
          .from('video_parties')
          .select('''
            *,
            host:profiles(id, username, avatar_url)
          ''')
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching active parties: $e');
      // If join fails, get parties without host info
      try {
        final response = await _supabase
            .from('video_parties')
            .select('*')
            .eq('status', 'active')
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      } catch (e2) {
        print('Error fetching parties without host: $e2');
        return [];
      }
    }
  }

  // Join a video party
  Future<bool> joinParty(String partyId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Check if already joined
      final existing = await _supabase
          .from('video_party_participants')
          .select()
          .eq('party_id', partyId)
          .eq('user_id', userId);

      if (existing.isNotEmpty) return true; // Already joined

      // Check if party is full
      final party = await _supabase
          .from('video_parties')
          .select()
          .eq('id', partyId)
          .single();

      if (party['current_participants'] >= party['max_participants']) {
        return false;
      }

      // Add participant
      await _supabase.from('video_party_participants').insert({
        'party_id': partyId,
        'user_id': userId,
      });

      // Update participant count
      await _supabase
          .from('video_parties')
          .update({'current_participants': party['current_participants'] + 1})
          .eq('id', partyId);

      return true;
    } catch (e) {
      print('Error joining party: $e');
      return false;
    }
  }

  // Leave a video party
  Future<bool> leaveParty(String partyId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Remove participant
      await _supabase
          .from('video_party_participants')
          .delete()
          .eq('party_id', partyId)
          .eq('user_id', userId);

      // Check how many participants are still in the party
      final remainingParticipants = await _supabase
          .from('video_party_participants')
          .select()
          .eq('party_id', partyId);

      final newCount = remainingParticipants.length;

      if (newCount <= 0) {
        // Only end party if truly no participants left (including host)
        await _supabase
            .from('video_parties')
            .update({
              'status': 'ended',
              'ended_at': DateTime.now().toIso8601String(),
              'current_participants': 0,
            })
            .eq('id', partyId);
      } else {
        // Update the participant count based on actual count
        await _supabase
            .from('video_parties')
            .update({'current_participants': newCount})
            .eq('id', partyId);
      }

      return true;
    } catch (e) {
      print('Error leaving party: $e');
      return false;
    }
  }

  // Get party participants
  Future<List<Map<String, dynamic>>> getParticipants(String partyId) async {
    try {
      final response = await _supabase
          .from('video_party_participants')
          .select('''
            *,
            user:profiles(id, username, avatar_url)
          ''')
          .eq('party_id', partyId)
          .order('joined_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching participants: $e');
      return [];
    }
  }

  // End a video party (DELETE PERMANENTLY)
  Future<bool> endParty(String partyId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Delete all participants first
      await _supabase
          .from('video_party_participants')
          .delete()
          .eq('party_id', partyId);

      // Then delete the party itself
      await _supabase
          .from('video_parties')
          .delete()
          .eq('id', partyId)
          .eq('host_id', userId);

      return true;
    } catch (e) {
      print('Error deleting video party: $e');
      return false;
    }
  }

  // Stream party updates
  Stream<Map<String, dynamic>?> streamParty(String partyId) {
    return _supabase
        .from('video_parties')
        .stream(primaryKey: ['id'])
        .eq('id', partyId)
        .map((data) => data.isNotEmpty ? data.first : null);
  }

  // Stream participants updates
  Stream<List<Map<String, dynamic>>> streamParticipants(String partyId) {
    return _supabase
        .from('video_party_participants')
        .stream(primaryKey: ['id'])
        .eq('party_id', partyId)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
}
