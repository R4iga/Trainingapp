class Group {
  Group({
    required this.id,
    required this.name,
    this.members = const [],
    required this.createdAt,
  });

  final String id;
  String name;
  List<String> members;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'members': members,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Group.fromJson(Map<String, dynamic> j) => Group(
        id: j['id'] as String,
        name: j['name'] as String,
        members: ((j['members'] as List?) ?? const []).cast<String>(),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}