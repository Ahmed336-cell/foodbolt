import '../../../../core/usecase/usecase.dart';
import '../entities/race_state.dart';
import '../repositories/race_repository.dart';

class PrepareRace extends UseCase<RaceState, PrepareRaceParams> {
  PrepareRace(this._repo);
  final RaceRepository _repo;

  @override
  Future<Result<RaceState>> call(PrepareRaceParams params) =>
      _repo.prepareRace(params.roomId, candidateIds: params.candidateIds);
}

class PrepareRaceParams {
  const PrepareRaceParams({required this.roomId, this.candidateIds});
  final String roomId;
  final List<String>? candidateIds;
}

class StartRace extends UseCase<RaceState, String> {
  StartRace(this._repo);
  final RaceRepository _repo;

  @override
  Future<Result<RaceState>> call(String roomId) => _repo.startRace(roomId);
}
