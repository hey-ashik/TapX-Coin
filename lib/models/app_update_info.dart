class AppUpdateInfo {
  final bool hasUpdate;
  final bool isForceUpdate;
  final String currentVersion;
  final String latestVersion;
  final String minVersion;
  final String apkUrl;
  final String releaseNotes;
  final String updatedAt;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.isForceUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.minVersion,
    required this.apkUrl,
    required this.releaseNotes,
    required this.updatedAt,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      hasUpdate: json['has_update'] == true,
      isForceUpdate: json['is_force_update'] == true,
      currentVersion: json['current_version'] ?? '1.0.0',
      latestVersion: json['latest_version'] ?? '1.0.0',
      minVersion: json['min_version'] ?? '1.0.0',
      apkUrl: json['apk_url'] ?? '',
      releaseNotes: json['release_notes'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}
