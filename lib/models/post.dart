class Post {
  Post({
    required this.id,
    required this.author,
    required this.code,
    required this.text,
    required this.createdAt,
    this.likes = 0,
    this.liked = false,
  });

  final String id;
  String author;
  final String code;
  String text;
  final DateTime createdAt;
  int likes;
  bool liked;

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'code': code,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'likes': likes,
        'liked': liked,
      };

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: j['id'] as String,
        author: j['author'] as String? ?? '',
        code: j['code'] as String? ?? '',
        text: j['text'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        likes: (j['likes'] as num?)?.toInt() ?? 0,
        liked: j['liked'] as bool? ?? false,
      );
}