import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One prebuilt avatar: an emoji on a theme-matched
/// gradient circle. This is the v3.5 revert (2026-10-26):
/// the v3.4 image-asset avatars crashed when Change
/// avatar was tapped (missing assets on the user's PC),
/// so the user chose to go back to simple emojis.
/// Set chosen by the user 2026-10-26: Skull, Ghost,
/// Robot, Cat, Dog, Male, Female, Panda.
/// Owl, Frog, Lion and Fox are NOT in this set.
/// Gradients are navy / royal / blue / teal only
/// (the v3.3 theme-matched set).
class ProfileAvatarOption {
  final String emoji;
  final String label;
  final LinearGradient gradient;

  const ProfileAvatarOption({
    required this.emoji,
    required this.label,
    required this.gradient,
  });
}

const avatarOptions = [
  ProfileAvatarOption(
    emoji: '💀',
    label: 'Skull',
    gradient: LinearGradient(
      colors: [Color(0xFF0D2348), Color(0xFF2456D6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ProfileAvatarOption(
    emoji: '👻',
    label: 'Ghost',
    gradient: LinearGradient(
      colors: [Color(0xFF1E90E8), Color(0xFF2EA8C2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ProfileAvatarOption(
    emoji: '🤖',
    label: 'Robot',
    gradient: LinearGradient(
      colors: [Color(0xFF1F7A8C), Color(0xFF0D2348)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ProfileAvatarOption(
    emoji: '🐱',
    label: 'Cat',
    gradient: LinearGradient(
      colors: [Color(0xFF16305E), Color(0xFF1F7A8C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ProfileAvatarOption(
    emoji: '🐶',
    label: 'Dog',
    gradient: LinearGradient(
      colors: [Color(0xFF0D2348), Color(0xFF1E90E8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ProfileAvatarOption(
    emoji: '👨‍💼',
    label: 'Male',
    gradient: LinearGradient(
      colors: [Color(0xFF1F7A8C), Color(0xFF2EA8C2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ProfileAvatarOption(
    emoji: '👩‍💼',
    label: 'Female',
    gradient: LinearGradient(
      colors: [Color(0xFF16305E), Color(0xFF2456D6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  ProfileAvatarOption(
    emoji: '🐼',
    label: 'Panda',
    gradient: LinearGradient(
      colors: [Color(0xFF2456D6), Color(0xFF1E90E8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
];

/// The profile circle itself, used on Home and in Settings.
/// If [avatar] is null, it falls back to the first initial
/// of [displayName] on the brand gradient. Otherwise it
/// shows the chosen emoji on its gradient circle.
/// No image files are involved, so there is no asset
/// that can go missing and crash the picker.
class ProfileAvatar extends StatelessWidget {
  final ProfileAvatarOption? avatar;
  final String displayName;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.avatar,
    required this.displayName,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'U';
    if (avatar == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppTheme.buttonGradient,
          shape: BoxShape.circle,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: avatar!.gradient,
        shape: BoxShape.circle,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Center(
        child: Text(
          avatar!.emoji,
          style: TextStyle(fontSize: size * 0.52),
        ),
      ),
    );
  }
}
