import '../../l10n/app_localizations.dart';

/// Maps Failure / cubit English keys → localized UI text.
class FailureMessages {
  FailureMessages._();

  static final _sharesEqual = RegExp(
    r'^Shares \((.+)\) must equal receipt \((.+)\)\.$',
  );

  static String localize(AppLocalizations l10n, String message) {
    final shares = _sharesEqual.firstMatch(message);
    if (shares != null) {
      return l10n.errSharesMustEqual(shares[1]!, shares[2]!);
    }

    return switch (message) {
      'Something went wrong. Try again.' => l10n.somethingWentWrong,
      'Authentication failed.' => l10n.errAuthFailed,
      "You don't have permission to perform this action." =>
        l10n.errPermissionDenied,
      'Not found.' => l10n.errNotFound,
      "You're offline. Changes will sync when connection returns." =>
        l10n.errOffline,
      'Not signed in.' => l10n.errNotSignedIn,
      'Sign in to create a room.' => l10n.errSignInToCreateRoom,
      'Sign in to join a room.' => l10n.errSignInToJoinRoom,
      'Invalid room code.' => l10n.errInvalidRoomCode,
      'Room not found.' => l10n.errRoomNotFound,
      'This room has already ended.' => l10n.errRoomEnded,
      'Guests are not allowed in this room.' => l10n.errGuestsNotAllowed,
      'Room is full.' => l10n.errRoomFull,
      'Join the room first.' => l10n.errJoinRoomFirst,
      'Email and password required.' => l10n.errEmailPasswordRequired,
      'All fields required.' => l10n.errAllFieldsRequired,
      'Login failed.' => l10n.errLoginFailed,
      'Registration failed.' => l10n.errRegistrationFailed,
      'Guest sign-in failed.' => l10n.errGuestSignInFailed,
      'Account created. Activate your email if required, then log in.' =>
        l10n.signupSuccessLogin,
      'Activate your account first before you can join.' =>
        l10n.errActivateAccountFirst,
      'Need at least 2 restaurants.' => l10n.errNeedTwoRestaurants,
      'Restaurant name required.' => l10n.errRestaurantNameRequired,
      'Suggestion limit reached.' => l10n.errSuggestionLimit,
      'Voting is not open.' => l10n.errVotingNotOpen,
      'No votes yet.' => l10n.errNoVotesYet,
      'Host pick is only for vote-only rooms.' => l10n.errHostPickVoteOnly,
      'Pick one of the tied restaurants.' => l10n.errPickTiedRestaurant,
      'Orders are locked.' => l10n.errOrdersLocked,
      'Enter receipt total.' => l10n.errEnterReceiptTotal,
      'Enter a valid receipt total.' => l10n.errEnterValidReceiptTotal,
      'Select a receipt image first.' => l10n.errSelectReceiptImage,
      'Room not ready.' => l10n.errRoomNotReady,
      'No submitted orders to split.' => l10n.errNoOrdersToSplit,
      'Calculate the split first.' => l10n.errCalculateSplitFirst,
      'Order saved for next time.' => l10n.orderSavedForNext,
      'Saved order loaded.' => l10n.savedOrderLoaded,
      'No items to save.' => l10n.noItemsToSave,
      _ => message,
    };
  }
}
