class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String avatarUrl;
  final int rank;
  final int level;
  final int streakDays;
  final int totalTaps;
  final String joinedDate;
  final String phone;
  final String twitterHandle;
  final String discordUsername;
  final String facebookUrl;
  final String instagramUrl;
  final List<double> weeklyActivity;

  const UserModel({
    required this.id,
    this.name = 'New Tapper',
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.rank,
    this.level = 1,
    required this.streakDays,
    required this.totalTaps,
    required this.joinedDate,
    this.phone = '',
    this.twitterHandle = '',
    this.discordUsername = '',
    this.facebookUrl = '',
    this.instagramUrl = '',
    this.weeklyActivity = const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  });

  bool get isGuest =>
      id.startsWith('guest_') ||
      email.contains('guest_') ||
      username.startsWith('Guest') ||
      id == 'usr_init' ||
      rank == 0;

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? avatarUrl,
    int? rank,
    int? level,
    int? streakDays,
    int? totalTaps,
    String? joinedDate,
    String? phone,
    String? twitterHandle,
    String? discordUsername,
    String? facebookUrl,
    String? instagramUrl,
    List<double>? weeklyActivity,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rank: rank ?? this.rank,
      level: level ?? this.level,
      streakDays: streakDays ?? this.streakDays,
      totalTaps: totalTaps ?? this.totalTaps,
      joinedDate: joinedDate ?? this.joinedDate,
      phone: phone ?? this.phone,
      twitterHandle: twitterHandle ?? this.twitterHandle,
      discordUsername: discordUsername ?? this.discordUsername,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      weeklyActivity: weeklyActivity ?? this.weeklyActivity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'rank': rank,
      'level': level,
      'streakDays': streakDays,
      'totalTaps': totalTaps,
      'joinedDate': joinedDate,
      'phone': phone,
      'twitterHandle': twitterHandle,
      'discordUsername': discordUsername,
      'facebookUrl': facebookUrl,
      'instagramUrl': instagramUrl,
      'weeklyActivity': weeklyActivity,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 'usr_guest',
      name: json['name'] ?? 'Tapper',
      username: json['username'] ?? 'tapper',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'] ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(json['name'] ?? 'User')}&background=1A1A1E&color=FFFFFF&bold=true&size=256',
      rank: json['rank'] ?? 1,
      level: json['level'] ?? 1,
      streakDays: json['streakDays'] ?? 1,
      totalTaps: json['totalTaps'] ?? 0,
      joinedDate: json['joinedDate'] ?? '2026',
      phone: json['phone'] ?? '',
      twitterHandle: json['twitterHandle'] ?? '',
      discordUsername: json['discordUsername'] ?? '',
      facebookUrl: json['facebookUrl'] ?? '',
      instagramUrl: json['instagramUrl'] ?? '',
      weeklyActivity: json['weeklyActivity'] != null
          ? List<double>.from((json['weeklyActivity'] as List).map((x) => (x as num).toDouble()))
          : const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    );
  }
}
