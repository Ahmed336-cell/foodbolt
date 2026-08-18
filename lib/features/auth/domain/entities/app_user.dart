import 'package:equatable/equatable.dart';

import '../../../../core/avatar/app_avatars.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.displayName,
    this.avatar = AppAvatars.defaultId,
    this.email,
    this.isGuest = false,
  });

  final String id;
  final String displayName;
  /// Catalog id, e.g. `ninja` — never an image path.
  final String avatar;
  final String? email;
  final bool isGuest;

  int get avatarColor => AppAvatars.byId(avatar).color;

  AppUser copyWith({
    String? id,
    String? displayName,
    String? avatar,
    String? email,
    bool? isGuest,
  }) {
    return AppUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      email: email ?? this.email,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  @override
  List<Object?> get props => [id, displayName, avatar, email, isGuest];
}
