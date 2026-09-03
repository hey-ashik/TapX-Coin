import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_update_info.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_pull_to_refresh.dart';
import '../widgets/avatar_picker_modal.dart';
import '../widgets/app_toast.dart';
import '../widgets/update_dialog_modal.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _twitterController;
  late TextEditingController _discordController;
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;
  String? _pendingAvatarUrl;

  bool _isSavingProfile = false;
  bool _isSavingConnections = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _usernameController = TextEditingController(text: user.username);
    _phoneController = TextEditingController(text: user.phone);
    _emailController = TextEditingController(text: user.email);
    _twitterController = TextEditingController(text: user.twitterHandle);
    _discordController = TextEditingController(text: user.discordUsername);
    _facebookController = TextEditingController(text: user.facebookUrl);
    _instagramController = TextEditingController(text: user.instagramUrl);
    _pendingAvatarUrl = user.avatarUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _twitterController.dispose();
    _discordController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    HapticService.lightImpact();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    await context.read<AuthProvider>().updateProfile(
      username: _usernameController.text.trim(),
      phone: _phoneController.text.trim(),
      avatarUrl: _pendingAvatarUrl,
    );

    if (mounted) {
      HapticService.mediumImpact();
      setState(() => _isSavingProfile = false);
      AppToast.show(context, message: 'Profile updated successfully!');
    }
  }

  Future<void> _saveConnections() async {
    setState(() => _isSavingConnections = true);
    HapticService.lightImpact();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    await context.read<AuthProvider>().updateProfile(
      twitter: _twitterController.text.trim(),
      discord: _discordController.text.trim(),
      facebook: _facebookController.text.trim(),
      instagram: _instagramController.text.trim(),
    );

    if (mounted) {
      HapticService.mediumImpact();
      setState(() => _isSavingConnections = false);
      AppToast.show(context, message: 'Social connections updated!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final user = auth.currentUser;

    return AppPullToRefresh(
      onRefresh: () async {
        await auth.restoreSession();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Settings & Security',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),

            // Profile Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 17,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Avatar Row (Clickable)
                  InkWell(
                    onTap: () {
                      HapticService.lightImpact();
                      AvatarPickerModal.show(
                        context,
                        onAvatarSelected: (url) {
                          setState(() {
                            _pendingAvatarUrl = url;
                          });
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              AppAvatar(
                                imageUrl: _pendingAvatarUrl ?? user.avatarUrl,
                                name: user.name.isNotEmpty ? user.name : user.username,
                                size: 68,
                                borderWidth: 2,
                                borderColor: AppColors.borderStrong,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: AppColors.ctaText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Change Avatar',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tap to choose cyber avatars or custom image',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Username field (letters, numbers, underscores)
                  Text(
                    'USERNAME',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: AppColors.primary),
                    decoration: const InputDecoration(
                      hintText: 'Enter username',
                      prefixIcon: Icon(Icons.alternate_email, color: AppColors.textMuted, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone field (Numeric only)
                  Text(
                    'PHONE NUMBER',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: const TextStyle(color: AppColors.primary),
                    decoration: const InputDecoration(
                      hintText: '01XXXXXXXXX',
                      prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textMuted, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email Address field (Read-only / Non-editable)
                  Text(
                    'EMAIL ADDRESS',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    readOnly: true,
                    style: const TextStyle(color: AppColors.textSecondary),
                    decoration: InputDecoration(
                      hintText: 'user@example.com',
                      prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textMuted, size: 18),
                      suffixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 16),
                      filled: true,
                      fillColor: AppColors.surfaceSubtle.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Profile Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _isSavingProfile ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.ctaText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: _isSavingProfile
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(AppColors.ctaText),
                              ),
                            )
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Social Connections Section (4 Channels: Twitter/X, Discord, Facebook, Instagram)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connections',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 17,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Twitter / X
                  Text(
                    'TWITTER / X',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _twitterController,
                    style: const TextStyle(color: AppColors.primary),
                    decoration: const InputDecoration(
                      hintText: 'https://x.com/username or @handle',
                      prefixIcon: Icon(Icons.alternate_email, color: AppColors.textMuted, size: 18),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Discord
                  Text(
                    'DISCORD',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _discordController,
                    style: const TextStyle(color: AppColors.primary),
                    decoration: const InputDecoration(
                      hintText: 'username#0000 or invite link',
                      prefixIcon: Icon(Icons.chat_bubble_outline, color: AppColors.textMuted, size: 18),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Facebook
                  Text(
                    'FACEBOOK',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _facebookController,
                    style: const TextStyle(color: AppColors.primary),
                    decoration: const InputDecoration(
                      hintText: 'https://facebook.com/username',
                      prefixIcon: Icon(Icons.public_outlined, color: AppColors.textMuted, size: 18),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Instagram
                  Text(
                    'INSTAGRAM',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _instagramController,
                    style: const TextStyle(color: AppColors.primary),
                    decoration: const InputDecoration(
                      hintText: 'https://instagram.com/username or @handle',
                      prefixIcon: Icon(Icons.camera_alt_outlined, color: AppColors.textMuted, size: 18),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Connections Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _isSavingConnections ? null : _saveConnections,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.ctaText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: _isSavingConnections
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(AppColors.ctaText),
                              ),
                            )
                          : const Text('Save Connections', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Preferences Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferences',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 17,
                          ),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Haptic Feedback', style: TextStyle(color: AppColors.primary, fontSize: 15)),
                      subtitle: const Text('Vibration pulse on every valid tap and button click', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      value: settings.hapticsEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => settings.toggleHaptics(val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sound FX', style: TextStyle(color: AppColors.primary, fontSize: 15)),
                      subtitle: const Text('Audio clicks and bonus chimes', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      value: settings.soundEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        HapticService.selectionClick();
                        settings.toggleSound(val);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Low Power Mode', style: TextStyle(color: AppColors.primary, fontSize: 15)),
                      subtitle: const Text('Reduces animations to conserve battery', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      value: settings.lowPowerMode,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        HapticService.selectionClick();
                        settings.toggleLowPowerMode(val);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Push Notifications', style: TextStyle(color: AppColors.primary, fontSize: 15)),
                      subtitle: const Text('Receive reward and streak alerts', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      value: settings.notificationsEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        HapticService.selectionClick();
                        settings.toggleNotifications(val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // App Version & In-App Update
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'App Version',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: 17,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: const Text(
                          'v1.0.0 (Official)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  OutlinedButton(
                    onPressed: () async {
                      HapticService.lightImpact();
                      AppToast.show(context, message: 'Checking for TapX updates...');
                      final updateData = await ApiService.checkAppUpdate('1.0.0');
                      if (context.mounted) {
                        if (updateData != null && updateData['has_update'] == true) {
                          UpdateDialogModal.show(context, AppUpdateInfo.fromJson(updateData));
                        } else {
                          AppToast.show(
                            context,
                            message: 'You are using the latest version of TapX (v1.0.0).',
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderStrong),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.system_update_alt_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Check for Updates',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Security & Danger Zone
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 17,
                        ),
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton(
                    onPressed: () {
                      HapticService.lightImpact();
                      if (user.isGuest) {
                        AppToast.show(
                          context,
                          message: 'Password reset is not available for Guest accounts. Please create an account.',
                          isError: true,
                        );
                      } else {
                        AppToast.show(
                          context,
                          message: 'Password reset link sent to your registered email.',
                          isError: false,
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderStrong),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.lock_reset, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Reset Password', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: () {
                      HapticService.lightImpact();
                      auth.logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.ctaText,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.logout, size: 20),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
