import '../../../../core/usecase/usecase.dart';
import '../entities/race_state.dart';

abstract class RaceRepository {
  /// [candidateIds] limits the racers, e.g. only the restaurants tied in a vote.
  Future<Result<RaceState>> prepareRace(
    String roomId, {
    List<String>? candidateIds,
  });
  Future<Result<RaceState>> startRace(String roomId);
  Stream<RaceState> watchRace(String roomId);
}
