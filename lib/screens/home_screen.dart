import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'shorts_feed.dart';
import 'upload_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart'; // NEW

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  final _pages = [
    FeedScreen(),
    SearchScreen(), // Added Search
    ShortsFeed(), // Moved Shorts to 3rd pos if you want, or replace upload button logic
    UploadScreen(),
    const ProfileScreen(userId: null), // userId null = My Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFFC13584), // Pinkish
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Needed for >3 items
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'), // New
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill), label: 'Reels'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}