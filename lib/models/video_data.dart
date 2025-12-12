class VideoData {
  final String thumbnail;
  final String videoUrl;
  final String? caption;
  final String username;
  final int? likeCount;
  final int? commentCount;
  final String? timestamp;
  final String mediaId;
  final String shortcode;
  final Map<String, dynamic>? dimensions;

  VideoData({
    required this.thumbnail,
    required this.videoUrl,
    this.caption,
    required this.username,
    this.likeCount,
    this.commentCount,
    this.timestamp,
    required this.mediaId,
    required this.shortcode,
    this.dimensions,
  });

  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(
      thumbnail: json['thumbnail'] ?? '',
      videoUrl: json['video_url'] ?? '',
      caption: json['caption'],
      username: json['username'] ?? '',
      likeCount: json['like_count'],
      commentCount: json['comment_count'],
      timestamp: json['timestamp'],
      mediaId: json['media_id'] ?? '',
      shortcode: json['shortcode'] ?? '',
      dimensions: json['dimensions'],
    );
  }
}

