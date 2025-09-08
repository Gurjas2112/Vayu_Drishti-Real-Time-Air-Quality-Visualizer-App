class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final bool notificationsEnabled;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.notificationsEnabled = true,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
      'profileImageUrl': profileImageUrl,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
    bool? notificationsEnabled,
    String? profileImageUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
