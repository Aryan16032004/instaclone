import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart'; // To open user profile

class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  void _search(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    
    // ILIKE is case-insensitive search
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .ilike('username', '%$query%') 
        .limit(20);

    setState(() {
      _results = List<Map<String, dynamic>>.from(response);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search users...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => _search(_controller.text),
            ),
          ),
          onSubmitted: _search,
        ),
      ),
      body: _loading 
          ? const Center(child: CircularProgressIndicator()) 
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final user = _results[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                    child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(user['username'] ?? 'User', style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    // Navigate to their profile
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ProfileScreen(userId: user['id']),
                    ));
                  },
                );
              },
            ),
    );
  }
}