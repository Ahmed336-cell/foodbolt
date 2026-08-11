import '../../../../core/usecase/usecase.dart';
import '../entities/vote.dart';

abstract class VotingRepository {
  Future<Result<void>> castVote({
    required String roomId,
    required String suggestionId,
  });

  /// Ends voting. Clear winner → restaurant selected.
  /// Tie + voteWithTieRace → race among tied.
  /// Tie + voteOnly → stays revealed; host must [pickTiedWinner].
  Future<Result<VoteRevealOutcome>> revealWinner(String roomId);

  Future<Result<VoteRevealOutcome>> pickTiedWinner({
    required String roomId,
    required String suggestionId,
  });

  Stream<VotingSnapshot> watchVoting(String roomId);
}
