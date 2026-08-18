import 'package:flutter/material.dart';

import '../avatar/app_avatars.dart';
import '../theme/app_theme.dart';

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final avatar in AppAvatars.all)
          _AvatarChoice(
            avatar: avatar,
            selected: avatar.id == selectedId,
            onTap: () => onSelected(avatar.id),
          ),
      ],
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.avatar,
    required this.selected,
    required this.onTap,
  });

  final AppAvatar avatar;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(avatar.color).withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.black12,
            width: selected ? 3 : 1,
          ),
        ),
        child: Text(avatar.emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}
