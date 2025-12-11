class Post {
	final String id;
	final String userId;
	final String mediaUrl;
	final bool isVideo;
	final String caption;
	final DateTime createdAt;
	final int likes;
	final int comments;

	Post({required this.id, required this.userId, required this.mediaUrl, required this.isVideo, required this.caption, required this.createdAt, this.likes = 0, this.comments = 0});

	factory Post.fromMap(Map<String, dynamic> m) {
		// Expect keys: id, user_id, media_url, is_video, caption, created_at, likes, comments
		final created = m['created_at'];
		DateTime createdAt;
		if (created is String) createdAt = DateTime.parse(created);
		else if (created is DateTime) createdAt = created;
		else createdAt = DateTime.now();

		return Post(
			id: m['id']?.toString() ?? '',
			userId: m['user_id'] ?? '',
			mediaUrl: m['media_url'] ?? '',
			isVideo: m['is_video'] ?? false,
			caption: m['caption'] ?? '',
			createdAt: createdAt,
			likes: (m['likes'] is int) ? m['likes'] : (int.tryParse(m['likes']?.toString() ?? '') ?? 0),
			comments: (m['comments'] is int) ? m['comments'] : (int.tryParse(m['comments']?.toString() ?? '') ?? 0),
		);
	}
}