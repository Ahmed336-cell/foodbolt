import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/food_visuals.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../room/presentation/cubit/room_cubit.dart';
import '../../../suggestions/domain/entities/restaurant_suggestion.dart';
import '../../../suggestions/presentation/cubit/suggestion_cubit.dart';
import '../../domain/entities/race_state.dart';
import '../../domain/race_duration.dart';
import '../cubit/race_cubit.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/race_track.dart';

class RestaurantRaceScreen extends StatefulWidget {
  const RestaurantRaceScreen({super.key});

  @override
  State<RestaurantRaceScreen> createState() => _RestaurantRaceScreenState();
}

class _RestaurantRaceScreenState extends State<RestaurantRaceScreen>
    with TickerProviderStateMixin {
  late final AnimationController _race = AnimationController(
    vsync: this,
    duration: raceDuration,
  );
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  int? _countdown;
  bool _sequenceStarted = false;
  bool _animationDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickoff());
  }

  @override
  void dispose() {
    _race.dispose();
    _pop.dispose();
    super.dispose();
  }

  bool get _isHost {
    final room = context.read<RoomCubit>().state.room;
    return room != null &&
        room.hostId == context.read<AuthCubit>().state.user?.id;
  }

  Future<void> _kickoff() async {
    final raceCubit = context.read<RaceCubit>();
    final room = context.read<RoomCubit>().state.room;
    if (room == null) return;

    final race = raceCubit.state.race;
    if (race?.status == RaceStatus.finished) {
      setState(() {
        _sequenceStarted = true;
        _animationDone = true;
      });
      _race.value = 1;
      _pop.forward();
      return;
    }

    if (!_isHost) return;
    if (race == null) {
      final prepared = await raceCubit.prepare(room.id);
      if (!prepared || !mounted) return;
    }
    await raceCubit.start(room.id);
  }

  Future<void> _runSequence() async {
    if (_sequenceStarted) return;
    _sequenceStarted = true;

    // Reset hard to 0 so every kart sits on the start line together.
    _race.value = 0;

    for (final n in [3, 2, 1, 0]) {
      if (!mounted) return;
      setState(() => _countdown = n);
      await Future<void>.delayed(
        Duration(milliseconds: n == 0 ? 450 : 600),
      );
    }
    if (!mounted) return;
    setState(() => _countdown = null);

    // One controller drives every lane — identical start, no stagger.
    await _race.forward(from: 0);
    if (!mounted) return;
    setState(() => _animationDone = true);
    _pop.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = context.watch<SuggestionCubit>().state.items;
    final members = context.watch<RoomCubit>().state.members.length;

    return BlocConsumer<RaceCubit, RaceCubitState>(
      listenWhen: (prev, curr) => prev.race?.status != curr.race?.status,
      listener: (context, state) {
        final status = state.race?.status;
        if (status == RaceStatus.racing || status == RaceStatus.countdown) {
          _runSequence();
        }
        if (status == RaceStatus.finished && !_sequenceStarted) {
          setState(() {
            _sequenceStarted = true;
            _animationDone = true;
          });
          _race.value = 1;
          _pop.forward(from: 0);
        }
      },
      builder: (context, state) {
        final race = state.race;
        final status = race?.status;
        if (!_sequenceStarted &&
            (status == RaceStatus.racing || status == RaceStatus.countdown)) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _runSequence());
        }
        final showWinner =
            _animationDone && race?.status == RaceStatus.finished;
        final lanes = _lanesFor(race, suggestions);

        return Scaffold(
          backgroundColor: const Color(0xFF0B0F1F),
          body: showWinner
              ? SafeArea(
                  child: _WinnerView(
                    pop: _pop,
                    lanes: lanes,
                    winner: suggestions
                        .where((s) => s.id == race?.winnerId)
                        .firstOrNull,
                    isTiebreaker: race?.isTiebreaker ?? false,
                    isHost: _isHost,
                  ),
                )
              : _RaceView(
                  race: _race,
                  lanes: lanes,
                  countdown: _countdown,
                  status: race?.status,
                  isTiebreaker: race?.isTiebreaker ?? false,
                  error: state.error,
                  memberCount: members,
                ),
        );
      },
    );
  }

  List<RaceLane> _lanesFor(
    RaceState? race,
    List<RestaurantSuggestion> suggestions,
  ) {
    final ids = race?.suggestionIds ?? suggestions.map((s) => s.id).toList();
    return ids
        .map((id) {
          final s = suggestions.where((e) => e.id == id).firstOrNull;
          if (s == null) return null;
          return RaceLane(
            id: s.id,
            name: s.name,
            category: s.category,
            isWinner: s.id == race?.winnerId,
          );
        })
        .whereType<RaceLane>()
        .toList();
  }
}

class _RaceView extends StatelessWidget {
  const _RaceView({
    required this.race,
    required this.lanes,
    required this.countdown,
    required this.status,
    required this.isTiebreaker,
    required this.error,
    required this.memberCount,
  });

  final AnimationController race;
  final List<RaceLane> lanes;
  final int? countdown;
  final RaceStatus? status;
  final bool isTiebreaker;
  final String? error;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final running = status == RaceStatus.racing && countdown == null;

    return Stack(
      children: [
        const Positioned.fill(child: _NightCityBackdrop()),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70, size: 20),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            isTiebreaker
                                ? '🏁 ${l10n.tiebreakerLabel}'
                                : '🏁 ${l10n.raceLabel}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            l10n.raceFastestPrompt,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.groups_rounded,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$memberCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (countdown != null && countdown! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _CountdownPill(value: countdown!),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: ErrorBanner(message: error!),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
                  child: lanes.isEmpty
                      ? EmptyStateView(
                          message: l10n.liningUp,
                          icon: Icons.sports_score,
                        )
                      : AnimatedBuilder(
                          animation: race,
                          builder: (context, _) => RaceTrack(
                            lanes: lanes,
                            t: race.value,
                            running: running,
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.howItWorksRace,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF2D95), Color(0xFFFF7A18)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2D95)
                                  .withValues(alpha: 0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            running
                                ? '🚀 ${l10n.neckAndNeck}'
                                : countdown == 0
                                    ? '🚀 ${l10n.go}'
                                    : '🚀 ${l10n.letsGo}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (countdown == 0) _GoFlash(label: l10n.go),
      ],
    );
  }
}

class _CountdownPill extends StatelessWidget {
  const _CountdownPill({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.raceStartsIn,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$value',
              style: const TextStyle(
                color: Color(0xFFFFC300),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoFlash extends StatelessWidget {
  const _GoFlash({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.15),
            duration: const Duration(milliseconds: 420),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Opacity(
              opacity: (1.4 - scale).clamp(0.0, 1.0),
              child: Transform.scale(scale: scale, child: child),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFC300),
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NightCityBackdrop extends StatelessWidget {
  const _NightCityBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1040),
            Color(0xFF0B0F1F),
            Color(0xFF070A14),
          ],
        ),
      ),
      child: CustomPaint(painter: _CitySilhouettePainter()),
    );
  }
}

class _CitySilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final skyline = Path()
      ..moveTo(0, size.height * 0.42)
      ..lineTo(size.width * 0.08, size.height * 0.42)
      ..lineTo(size.width * 0.08, size.height * 0.28)
      ..lineTo(size.width * 0.16, size.height * 0.28)
      ..lineTo(size.width * 0.16, size.height * 0.36)
      ..lineTo(size.width * 0.24, size.height * 0.36)
      ..lineTo(size.width * 0.24, size.height * 0.18)
      ..lineTo(size.width * 0.34, size.height * 0.18)
      ..lineTo(size.width * 0.34, size.height * 0.30)
      ..lineTo(size.width * 0.42, size.height * 0.30)
      ..lineTo(size.width * 0.42, size.height * 0.22)
      ..lineTo(size.width * 0.52, size.height * 0.22)
      ..lineTo(size.width * 0.52, size.height * 0.34)
      ..lineTo(size.width * 0.62, size.height * 0.34)
      ..lineTo(size.width * 0.62, size.height * 0.16)
      ..lineTo(size.width * 0.74, size.height * 0.16)
      ..lineTo(size.width * 0.74, size.height * 0.30)
      ..lineTo(size.width * 0.86, size.height * 0.30)
      ..lineTo(size.width * 0.86, size.height * 0.24)
      ..lineTo(size.width, size.height * 0.24)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      skyline,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2A1B5E).withValues(alpha: 0.55),
            const Color(0xFF0B0F1F).withValues(alpha: 0.9),
          ],
        ).createShader(Offset.zero & size),
    );

    // Neon window dots
    final window = Paint()..color = const Color(0xFFFFC300).withValues(alpha: 0.35);
    for (var i = 0; i < 28; i++) {
      final x = (i * 47 % size.width);
      final y = size.height * 0.22 + (i * 29 % 90);
      canvas.drawCircle(Offset(x, y), 1.6, window);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WinnerView extends StatelessWidget {
  const _WinnerView({
    required this.pop,
    required this.lanes,
    required this.winner,
    required this.isTiebreaker,
    required this.isHost,
  });

  final AnimationController pop;
  final List<RaceLane> lanes;
  final RestaurantSuggestion? winner;
  final bool isTiebreaker;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final others = lanes.where((l) => !l.isWinner).toList();
    final l10n = context.l10n;

    return Stack(
      children: [
        const Positioned.fill(child: _NightCityBackdrop()),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.pagePadding,
            8,
            context.pagePadding,
            20,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.contentMaxWidth),
              child: Column(
            children: [
              ScaleTransition(
                scale: CurvedAnimation(parent: pop, curve: Curves.elasticOut),
                child: Text(
                  l10n.weHaveWinner,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFC300),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Image.asset(AppAssets.winnerPodium, height: 190),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            FoodBadge(
                              name: winner?.name ?? '?',
                              category: winner?.category,
                              size: 58,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    winner?.name ?? l10n.winner,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    isTiebreaker
                                        ? l10n.wonTiebreaker
                                        : l10n.wonTheRace,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.emoji_events,
                              size: 34,
                              color: Colors.amber.shade700,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...others.asMap().entries.map(
                            (e) => ListTile(
                              dense: true,
                              leading: Text(
                                '#${e.key + 2}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                              ),
                              title: Text(
                                e.value.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: Text(
                                FoodVisuals.emojiFor(
                                  name: e.value.name,
                                  category: e.value.category,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              if (isHost)
                PrimaryButton(
                  label: l10n.letsOrder,
                  onPressed: () => context
                      .read<RoomCubit>()
                      .advancePhase(RoomPhase.restaurantSelected),
                )
              else
                Text(
                  l10n.waitingHostContinue,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
            ],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: ConfettiOverlay()),
      ],
    );
  }
}
