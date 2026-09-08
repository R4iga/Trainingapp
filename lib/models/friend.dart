class Friend {
  Friend({
    required this.id,
    required this.name,
    required this.code,
    required this.addedAt,
  });

  final String id;
  String name;
  final String code;
  final DateTime addedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'addedAt': addedAt.toIso8601String(),
      };

  factory Friend.fromJson(Map<String, dynamic> j) => Friend(
        id: j['id'] as String,
        name: j['name'] as String,
        code: j['code'] as String,
        addedAt: DateTime.tryParse(j['addedAt'] as String? ?? '') ?? DateTime.now(),
      );
}