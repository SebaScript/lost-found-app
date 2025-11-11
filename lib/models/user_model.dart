class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int postsCount;
  final int activePostsCount;
  final int resolvedPostsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.postsCount = 0,
    this.activePostsCount = 0,
    this.resolvedPostsCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoUrl: json['photoUrl'],
      postsCount: json['postsCount'] ?? 0,
      activePostsCount: json['activePostsCount'] ?? 0,
      resolvedPostsCount: json['resolvedPostsCount'] ?? 0,
      createdAt: json['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : (json['createdAt'] as dynamic).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
              : (json['updatedAt'] as dynamic).toDate())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'postsCount': postsCount,
      'activePostsCount': activePostsCount,
      'resolvedPostsCount': resolvedPostsCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String getInitials() {
    List<String> names = displayName.split(' ');
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
    String? displayName,
    String? photoUrl,
    int? postsCount,
    int? activePostsCount,
    int? resolvedPostsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      postsCount: postsCount ?? this.postsCount,
      activePostsCount: activePostsCount ?? this.activePostsCount,
      resolvedPostsCount: resolvedPostsCount ?? this.resolvedPostsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
