class AppNotification {
  final int id;
  final String title;
  final String message;
  final String type; // 'payout_completed', 'payout_rejected', 'announcement', 'system', 'bonus'
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  static String _cleanText(String? input) {
    if (input == null || input.isEmpty) return '';
    // Strip standard emojis, pictographs, symbols, and dingbats
    final sanitized = input
        .replaceAll(
          RegExp(
            r'[\u{1F300}-\u{1F9FF}\u{1FA00}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E6}-\u{1F1FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]',
            unicode: true,
          ),
          '',
        )
        .trim();
    return sanitized.isEmpty ? (input.trim()) : sanitized;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: _cleanText(json['title'] ?? 'Notification'),
      message: _cleanText(json['message'] ?? ''),
      type: json['type'] ?? 'system',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  AppNotification copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
