class UserModel {
  final String uid;
  final String email;
  final String name;
  final int postsCount;
  final int activePostsCount;
  final int resolvedPostsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.postsCount = 0,
    this.activePostsCount = 0,
    this.resolvedPostsCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      postsCount: json['postsCount'] ?? 0,
      activePostsCount: json['activePostsCount'] ?? 0,
      resolvedPostsCount: json['resolvedPostsCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'postsCount': postsCount,
      'activePostsCount': activePostsCount,
      'resolvedPostsCount': resolvedPostsCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Get initials for avatar
  String getInitials() {
    List<String> names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return '?';
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    int? postsCount,
    int? activePostsCount,
    int? resolvedPostsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      postsCount: postsCount ?? this.postsCount,
      activePostsCount: activePostsCount ?? this.activePostsCount,
      resolvedPostsCount: resolvedPostsCount ?? this.resolvedPostsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
