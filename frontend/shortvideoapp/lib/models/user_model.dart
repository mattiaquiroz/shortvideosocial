class User {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final String? profilePictureUrl;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final DateTime createdAt;
  final bool isPrivateAccount;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.profilePictureUrl,
    this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.createdAt,
    required this.isPrivateAccount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'],
      profilePictureUrl: json['profilePictureUrl'],
      bio: json['bio'],
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      isPrivateAccount: json['privateAccount'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'profilePictureUrl': profilePictureUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'createdAt': createdAt.toIso8601String(),
      'privateAccount': isPrivateAccount,
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? profilePictureUrl,
    String? bio,
    int? followersCount,
    int? followingCount,
    DateTime? createdAt,
    bool? isPrivateAccount,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      createdAt: createdAt ?? this.createdAt,
      isPrivateAccount: isPrivateAccount ?? this.isPrivateAccount,
    );
  }
}
