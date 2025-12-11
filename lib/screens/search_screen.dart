import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/follow_service.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  final _followService = FollowService();
  final _currentUserId = Supabase.instance.client.auth.currentUser?.id;

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    // Simple ILIKE search on username
    final res = await Supabase.instance.client
        .from('profiles')
        .select()
        .ilike('username', '%$query%')
        .limit(20);

    if (mounted) {
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(res ?? []);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search users...',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: _searchResults.isEmpty
          ? const Center(
              child: Text(
                'Search for users to follow',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                if (user['id'] == _currentUserId)
                  return const SizedBox.shrink(); // Hide self

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (user['avatar_url'] != null)
                        ? NetworkImage(user['avatar_url'])
                        : null,
                    backgroundColor: Colors.grey[800],
                    child: user['avatar_url'] == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(
                    user['username'] ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: user['bio'] != null
                      ? Text(
                          user['bio'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        )
                      : null,
                  onTap: () {
                    // Go to profile
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: user['id']),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
