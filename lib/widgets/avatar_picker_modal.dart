import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/image_picker_service.dart';
import '../theme/app_colors.dart';
import 'app_toast.dart';

class AvatarPickerModal extends StatefulWidget {
  final ValueChanged<String>? onAvatarSelected;

  const AvatarPickerModal({super.key, this.onAvatarSelected});

  static void show(BuildContext context, {ValueChanged<String>? onAvatarSelected}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (context) => AvatarPickerModal(onAvatarSelected: onAvatarSelected),
    );
  }

  @override
  State<AvatarPickerModal> createState() => _AvatarPickerModalState();
}

class _AvatarPickerModalState extends State<AvatarPickerModal> {
  final TextEditingController _customUrlController = TextEditingController();

  final List<String> _presetAvatars = [
    'https://api.dicebear.com/7.x/bottts/png?seed=QuantumTapper&backgroundColor=1A1A1E',
    'https://api.dicebear.com/7.x/bottts/png?seed=CyberGhost&backgroundColor=1A1A1E',
    'https://api.dicebear.com/7.x/bottts/png?seed=NovaStriker&backgroundColor=1A1A1E',
    'https://api.dicebear.com/7.x/bottts/png?seed=VortexMaster&backgroundColor=1A1A1E',
    'https://api.dicebear.com/7.x/bottts/png?seed=HyperPulse&backgroundColor=1A1A1E',
    'https://api.dicebear.com/7.x/bottts/png?seed=ApexPredator&backgroundColor=1A1A1E',
    'https://api.dicebear.com/7.x/bottts/png?seed=ShadowTap&backgroundColor=1A1A1E',
    'https://api.dicebear.com/7.x/bottts/png?seed=NeonFlash&backgroundColor=1A1A1E',
    'https://ui-avatars.com/api/?name=TapX+Pro&background=10B981&color=FFFFFF&bold=true&size=256',
    'https://ui-avatars.com/api/?name=VIP+Tapper&background=6366F1&color=FFFFFF&bold=true&size=256',
    'https://ui-avatars.com/api/?name=Gold+Strike&background=F59E0B&color=FFFFFF&bold=true&size=256',
    'https://ui-avatars.com/api/?name=Shadow+X&background=EF4444&color=FFFFFF&bold=true&size=256',
  ];

  @override
  void dispose() {
    _customUrlController.dispose();
    super.dispose();
  }

  void _selectAvatar(String url) {
    if (widget.onAvatarSelected != null) {
      widget.onAvatarSelected!(url);
      Navigator.pop(context);
    } else {
      context.read<AuthProvider>().updateProfile(avatarUrl: url);
      Navigator.pop(context);
      AppToast.show(context, message: 'Avatar updated successfully!');
    }
  }

  void _applyCustomUrl() {
    final url = _customUrlController.text.trim();
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('data:image/'))) {
      AppToast.show(context, message: 'Please enter a valid image URL (http/https)', isError: true);
      return;
    }
    _selectAvatar(url);
  }

  void _generateFromName() {
    final auth = context.read<AuthProvider>();
    final username = auth.currentUser.username;
    final url = AuthProvider.generateInitialAvatar(username);
    _selectAvatar(url);
  }

  void _pickLocalImage() {
    ImagePickerPlatform.pickImage((base64DataUrl, fileName) {
      if (mounted) {
        _selectAvatar(base64DataUrl);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatar = context.watch<AuthProvider>().currentUser.avatarUrl;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: const Border(top: BorderSide(color: AppColors.borderStrong, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.9),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Avatar',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Upload your photo or select a cyber character',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Upload Photo from Device Button
            InkWell(
              onTap: _pickLocalImage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.15),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.add_photo_alternate_outlined, color: AppColors.ctaText, size: 24),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Photo (PNG / JPG)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ctaText,
                            ),
                          ),
                          Text(
                            'Choose an image from your device gallery',
                            style: TextStyle(fontSize: 11, color: Color(0xFF444444)),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward, size: 18, color: AppColors.ctaText),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quick Actions: Initials Avatar
            InkWell(
              onTap: _generateFromName,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceCard,
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Generate from Name',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Creates a clean typography badge using your username',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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

            // Preset Avatars Grid
            Text(
              'CYBER AVATARS',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _presetAvatars.length,
              itemBuilder: (context, index) {
                final url = _presetAvatars[index];
                final isSelected = currentAvatar == url;

                return InkWell(
                  onTap: () => _selectAvatar(url),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.borderStrong,
                        width: isSelected ? 2.5 : 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.25),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.person, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Custom Image URL Input
            Text(
              'CUSTOM IMAGE URL',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customUrlController,
                    style: const TextStyle(color: AppColors.primary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'https://example.com/avatar.jpg',
                      prefixIcon: Icon(Icons.link, color: AppColors.textMuted, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _applyCustomUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.ctaText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
