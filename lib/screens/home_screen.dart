import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'shorts_feed.dart';
import 'upload_screen.dart';
import 'profile_screen.dart';


class HomeScreen extends StatefulWidget {
@override
_HomeScreenState createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
int _idx = 0;
final _pages = [FeedScreen(), ShortsFeed(), UploadScreen(), ProfileScreen()];


@override
Widget build(BuildContext context) {
return Scaffold(
body: _pages[_idx],
bottomNavigationBar: BottomNavigationBar(
backgroundColor: Colors.black,
selectedItemColor: Colors.white,
unselectedItemColor: Colors.grey,
currentIndex: _idx,
onTap: (i) => setState(() => _idx = i),
items: [
BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill), label: 'Shorts'),
BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Upload'),
BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
],
),
);
}
}