enum PostType { lost, found }
enum PostStatus { active, resolved }

class PostModel {
  final String? id;
  final String userId;
  final String userName;
  final PostType type;
  final String title;
  final String description;
  final String location;
  final String? imageUrl;
  final PostStatus status;
  final int viewCount;
  final int messageCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PostModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    this.imageUrl,
    this.status = PostStatus.active,
    this.viewCount = 0,
    this.messageCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert from JSON
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      type: json['type'] == 'lost' ? PostType.lost : PostType.found,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      imageUrl: json['imageUrl'],
      status: json['status'] == 'resolved' ? PostStatus.resolved : PostStatus.active,
      viewCount: json['viewCount'] ?? 0,
      messageCount: json['messageCount'] ?? 0,
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
      'userId': userId,
      'userName': userName,
      'type': type == PostType.lost ? 'lost' : 'found',
      'title': title,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'status': status == PostStatus.resolved ? 'resolved' : 'active',
      'viewCount': viewCount,
      'messageCount': messageCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  String getTypeLabel() {
    return type == PostType.lost ? 'Perdido' : 'Encontrado';
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    PostType? type,
    String? title,
    String? description,
    String? location,
    String? imageUrl,
    PostStatus? status,
    int? viewCount,
    int? messageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
      messageCount: messageCount ?? this.messageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
