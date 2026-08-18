import 'package:equatable/equatable.dart';

import '../../../../core/avatar/app_avatars.dart';
import '../../../../core/phase/room_phase.dart';

class RoomSettings extends Equatable {
  const RoomSettings({
    this.maxParticipants = 12,
    this.votingDurationSeconds = 60,
    this.maxSuggestions = 8,
    this.allowMemberSuggestions = true,
    this.guestAccess = true,
    this.voteLimit = 1,
  });

  final int maxParticipants;
  final int votingDurationSeconds;
  final int maxSuggestions;
  final bool allowMemberSuggestions;
  final bool guestAccess;
  final int voteLimit;

  @override
  List<Object?> get props => [
        maxParticipants,
        votingDurationSeconds,
        maxSuggestions,
        allowMemberSuggestions,
        guestAccess,
        voteLimit,
      ];
}

class Room extends Equatable {
  const Room({
    required this.id,
    required this.code,
    required this.name,
    required this.hostId,
    required this.phase,
    required this.selectionMode,
    required this.settings,
    required this.createdAt,
    this.winnerSuggestionId,
    this.inviteUrl,
  });

  final String id;
  final String code;
  final String name;
  final String hostId;
  final RoomPhase phase;
  final SelectionMode selectionMode;
  final RoomSettings settings;
  final DateTime createdAt;
  final String? winnerSuggestionId;
  final String? inviteUrl;

  bool isHost(String userId) => hostId == userId;

  Room copyWith({
    String? id,
    String? code,
    String? name,
    String? hostId,
    RoomPhase? phase,
    SelectionMode? selectionMode,
    RoomSettings? settings,
    DateTime? createdAt,
    String? winnerSuggestionId,
    String? inviteUrl,
    bool clearWinner = false,
  }) {
    return Room(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      hostId: hostId ?? this.hostId,
      phase: phase ?? this.phase,
      selectionMode: selectionMode ?? this.selectionMode,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      winnerSuggestionId:
          clearWinner ? null : (winnerSuggestionId ?? this.winnerSuggestionId),
      inviteUrl: inviteUrl ?? this.inviteUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        hostId,
        phase,
        selectionMode,
        settings,
        createdAt,
        winnerSuggestionId,
        inviteUrl,
      ];
}

enum MemberRole { host, member }

class RoomMember extends Equatable {
  const RoomMember({
    required this.userId,
    required this.displayName,
    required this.avatar,
    required this.role,
    required this.isGuest,
    required this.isOnline,
    required this.joinedAt,
  });

  final String userId;
  final String displayName;
  /// Catalog id, e.g. `ninja`.
  final String avatar;
  final MemberRole role;
  final bool isGuest;
  final bool isOnline;
  final DateTime joinedAt;

  int get avatarColor => AppAvatars.byId(avatar).color;

  RoomMember copyWith({bool? isOnline}) {
    return RoomMember(
      userId: userId,
      displayName: displayName,
      avatar: avatar,
      role: role,
      isGuest: isGuest,
      isOnline: isOnline ?? this.isOnline,
      joinedAt: joinedAt,
    );
  }

  @override
  List<Object?> get props =>
      [userId, displayName, avatar, role, isGuest, isOnline, joinedAt];
}
