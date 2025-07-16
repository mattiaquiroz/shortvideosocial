class PublicUser {
  final int id;
  final String username;
  final String? fullName;
  final String? profilePictureUrl;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final DateTime createdAt;

  PublicUser({
    required this.id,
    required this.username,
    this.fullName,
    this.profilePictureUrl,
    this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.createdAt,
  });

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    return PublicUser(
      id: json['id'],
      username: json['username'],
      fullName: json['fullName'],
      profilePictureUrl: json['profilePictureUrl'],
      bio: json['bio'],
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'profilePictureUrl': profilePictureUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
