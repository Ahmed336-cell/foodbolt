import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.avatarColor,
    this.email,
    this.isGuest = false,
  });

  final String id;
  final String displayName;
  final int avatarColor;
  final String? email;
  final bool isGuest;

  AppUser copyWith({
    String? id,
    String? displayName,
    int? avatarColor,
    String? email,
    bool? isGuest,
  }) {
    return AppUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarColor: avatarColor ?? this.avatarColor,
      email: email ?? this.email,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  @override
  List<Object?> get props => [id, displayName, avatarColor, email, isGuest];
}
