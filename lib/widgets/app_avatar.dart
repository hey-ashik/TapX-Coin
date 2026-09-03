import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40.0,
    this.borderColor,
    this.borderWidth = 1.0,
    this.backgroundColor,
  });

  /// Extracts clean initials from a username or full name.
  /// Handles "Ashik" -> "A", "ApexPredator" -> "AP", "Alex Rahman" -> "AR", "QuantumTapper" -> "QT"
  static String getInitials(String name) {
    final clean = name.replaceAll('@', '').trim();
    if (clean.isEmpty) return 'T';

    final parts = clean.split(RegExp(r'[\s_]+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }

    // Check for PascalCase / CamelCase (e.g. ApexPredator -> AP, QuantumTapper -> QT)
    final caps = clean.replaceAll(RegExp(r'[^A-Z]'), '');
    if (caps.length >= 2) {
      return caps.substring(0, 2).toUpperCase();
    }

    // Default to first 1 or 2 letters
    if (clean.length >= 2) {
      return clean.substring(0, clean.length >= 2 ? (clean.length > 2 && clean == clean.toUpperCase() ? 2 : 1) : 1).toUpperCase();
    }
    return clean[0].toUpperCase();
  }

  bool _isValidHttpUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final trimmed = url.trim().toLowerCase();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('data:image');
  }

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(name);
    final hasValidUrl = _isValidHttpUrl(imageUrl);
    final effectiveBorderColor = borderColor ?? AppColors.borderSubtle;
    final effectiveBgColor = backgroundColor ?? AppColors.surfaceSubtle;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBgColor,
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            // Instant Initials Fallback Layer (Always renders underneath, 0 delay)
            Container(
              color: effectiveBgColor,
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Network Image Layer with smooth fade-in and silent error fallback
            if (hasValidUrl)
              Image.network(
                imageUrl!.trim(),
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) {
                  // If image fails or 404s, keep displaying initials layer cleanly
                  return const SizedBox.shrink();
                },
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return child;
                  }
                  // While loading over network, display initials layer
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
      ),
    );
  }
}
