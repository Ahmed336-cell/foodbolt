import '../../../../core/usecase/usecase.dart';
import '../entities/vote.dart';
import '../repositories/voting_repository.dart';

class VoteRestaurant extends UseCase<void, VoteParams> {
  VoteRestaurant(this._repo);
  final VotingRepository _repo;

  @override
  Future<Result<void>> call(VoteParams params) => _repo.castVote(
        roomId: params.roomId,
        suggestionId: params.suggestionId,
      );
}

class VoteParams {
  const VoteParams({required this.roomId, required this.suggestionId});
  final String roomId;
  final String suggestionId;
}

class RevealVoteWinner extends UseCase<VoteRevealOutcome, String> {
  RevealVoteWinner(this._repo);
  final VotingRepository _repo;

  @override
  Future<Result<VoteRevealOutcome>> call(String roomId) =>
      _repo.revealWinner(roomId);
}

class PickTiedWinner extends UseCase<VoteRevealOutcome, PickTiedWinnerParams> {
  PickTiedWinner(this._repo);
  final VotingRepository _repo;

  @override
  Future<Result<VoteRevealOutcome>> call(PickTiedWinnerParams params) =>
      _repo.pickTiedWinner(
        roomId: params.roomId,
        suggestionId: params.suggestionId,
      );
}

class PickTiedWinnerParams {
  const PickTiedWinnerParams({
    required this.roomId,
    required this.suggestionId,
  });
  final String roomId;
  final String suggestionId;
}
