import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/video_player_item.dart'; 

class FullScreenViewer extends StatelessWidget {
  final List<Map<String, dynamic>> posts;
  final int initialIndex;

  const FullScreenViewer({super.key, required this.posts, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Center(
            child: post['is_video'] == true
                ? VideoPlayerItem(videoUrl: post['media_url'])
                : CachedNetworkImage(imageUrl: post['media_url']),
          );
        },
      ),
    );
  }
}