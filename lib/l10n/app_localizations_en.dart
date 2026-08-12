// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FoodRush';

  @override
  String get tagline => 'Decide. Race. Order. Split.';

  @override
  String get currency => 'EGP';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueLabel => 'Continue';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get add => 'Add';

  @override
  String get start => 'Start';

  @override
  String get lock => 'Lock';

  @override
  String get somethingWentWrong => 'Something went wrong. Try again.';

  @override
  String get onboardingTitle1 => 'Gather your crew';

  @override
  String get onboardingBody1 =>
      'Create a room and share one link. Friends join in seconds, no account needed.';

  @override
  String get onboardingTitle2 => 'Vote or race';

  @override
  String get onboardingBody2 =>
      'Suggest restaurants and vote. Equal votes? The tied restaurants race for it.';

  @override
  String get onboardingTitle3 => 'Split it fairly';

  @override
  String get onboardingBody3 =>
      'Upload the receipt, review the bill, and everyone sees exactly what they owe.';

  @override
  String get welcomeSubtitle => 'Friends. Food. Competition. Fun.';

  @override
  String get createRoom => 'Create Room';

  @override
  String get joinRoom => 'Join Room';

  @override
  String get loginOrSignIn => 'Login / Sign In';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get createAccount => 'Create account';

  @override
  String get loginSubtitle => 'Sign in to keep your rooms and history.';

  @override
  String get signupSubtitle => 'Save your rooms, orders and totals.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get displayName => 'Display name';

  @override
  String get needAccount => 'Need an account? Sign up';

  @override
  String get haveAccount => 'Already have an account? Login';

  @override
  String get guestTitle => 'What should friends call you?';

  @override
  String get guestSubtitle => 'Guest mode, no account needed.';

  @override
  String get guest => 'Guest';

  @override
  String get host => 'Host';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get logout => 'Logout';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountBody =>
      'This action is permanent and will remove your profile data.';

  @override
  String get deleteAccountConfirm => 'Delete';

  @override
  String get accountDeleted => 'Account deleted successfully.';

  @override
  String helloUser(String name) {
    return 'Hey, $name';
  }

  @override
  String get homePrompt => 'What should we eat together?';

  @override
  String get createRoomSubtitle => 'Invite friends and start';

  @override
  String get joinRoomSubtitle => 'Enter a room code';

  @override
  String get historyTitle => 'History';

  @override
  String get historySubtitle => 'Past rooms & bills';

  @override
  String get nameYourHangout => 'Name your hangout';

  @override
  String get roomNameHint => 'Friday Lunch (optional)';

  @override
  String get howDecide => 'How do we decide?';

  @override
  String get allowGuests => 'Allow guests';

  @override
  String get modeRaceDirect => 'Add restaurants → Race';

  @override
  String get modeRaceDirectHint =>
      'Suggest places, then race them all. Fast & fun.';

  @override
  String get modeVoteWithTieRace => 'Add restaurants → Vote (race on draw)';

  @override
  String get modeVoteWithTieRaceHint =>
      'Everyone votes. If it\'s a draw, tied places race.';

  @override
  String get modeVoteOnly => 'Add restaurants → Vote only';

  @override
  String get modeVoteOnlyHint =>
      'Everyone votes. No race — host picks if votes tie.';

  @override
  String get pickTiedWinner => 'Votes tied — pick the winner';

  @override
  String get pickTiedWinnerHint => 'Choose one of the tied restaurants.';

  @override
  String get hostPickWinner => 'Pick as winner';

  @override
  String get enterRoomCode => 'Enter the room code';

  @override
  String get roomCodeHint => 'ABC123';

  @override
  String get codeCopied => 'Code copied';

  @override
  String roomCode(String code) {
    return 'Code $code';
  }

  @override
  String get inviteFriends => 'Invite Friends';

  @override
  String playersReady(int count) {
    return '$count players are ready';
  }

  @override
  String get waitingForFriends => 'Waiting for friends…';

  @override
  String get waitingForHostStart => 'Waiting for host to start';

  @override
  String get hostWillStart => 'Hang tight, the host will start soon.';

  @override
  String get startGameQuestion => 'Start the game?';

  @override
  String startAnyway(int count) {
    return 'Only $count player so far. Start anyway?';
  }

  @override
  String inviteMessage(String room, String code) {
    return 'Join $room on FoodRush! Code: $code';
  }

  @override
  String get suggestRestaurants => 'Suggest restaurants';

  @override
  String get cravingPrompt => 'What are we craving?';

  @override
  String get raceHint => 'Every restaurant becomes a racer.';

  @override
  String get voteHint => 'Everyone votes once suggestions are in.';

  @override
  String get addRestaurant => 'Add Restaurant';

  @override
  String get restaurantName => 'Restaurant name';

  @override
  String get chooseCategory => 'Choose a category';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get emptySuggestions => 'No restaurants suggested yet.';

  @override
  String get emptySuggestionsHint => 'Tap Add Restaurant to start.';

  @override
  String get needTwoRestaurants => 'Need at least 2 restaurants';

  @override
  String get startVoting => 'Start Voting';

  @override
  String get startRace => 'Start Race';

  @override
  String bySomeone(String name) {
    return 'by $name';
  }

  @override
  String get catBurger => 'Burger';

  @override
  String get catPizza => 'Pizza';

  @override
  String get catChicken => 'Chicken';

  @override
  String get catShawarma => 'Shawarma';

  @override
  String get catGrill => 'Grill';

  @override
  String get catSeafood => 'Seafood';

  @override
  String get catAsian => 'Asian';

  @override
  String get catPasta => 'Pasta';

  @override
  String get catSushi => 'Sushi';

  @override
  String get catMexican => 'Mexican';

  @override
  String get catKoshary => 'Koshary';

  @override
  String get catSandwich => 'Sandwich';

  @override
  String get catBreakfast => 'Breakfast';

  @override
  String get catSalad => 'Healthy';

  @override
  String get catDessert => 'Dessert';

  @override
  String get catDrinks => 'Drinks';

  @override
  String get catOther => 'Other';

  @override
  String get chooseFavorite => 'Choose your favorite';

  @override
  String get oneVote => 'You have 1 vote.';

  @override
  String get tieHint => 'Equal votes? The tied restaurants race for it.';

  @override
  String get vote => 'Vote';

  @override
  String get switchVote => 'Switch';

  @override
  String get yourVote => 'Your vote';

  @override
  String get votedFor => 'You voted for';

  @override
  String get changeMind => 'Change your mind?';

  @override
  String get revealWinner => 'Reveal Winner';

  @override
  String get waitingReveal => 'Waiting for host to reveal…';

  @override
  String get results => 'Results';

  @override
  String get winner => 'Winner';

  @override
  String votesCount(int count) {
    return '$count votes';
  }

  @override
  String votedProgress(int voted, int total) {
    return '$voted of $total voted';
  }

  @override
  String get tieBanner =>
      'It\'s a tie! The tied restaurants settle it in a race.';

  @override
  String tieSnack(int count) {
    return 'It\'s a tie! $count restaurants race for it.';
  }

  @override
  String get drawTitle => 'It\'s a draw!';

  @override
  String drawSubtitle(int count) {
    return '$count restaurants are tied. Race to decide the winner.';
  }

  @override
  String get tiedRestaurants => 'Tied restaurants';

  @override
  String get goToRace => 'Go to Race';

  @override
  String get waitingHostStartRace => 'Waiting for the host to start the race…';

  @override
  String get noRestaurantsToVote => 'No restaurants to vote on.';

  @override
  String get raceLabel => 'RESTAURANT RACE';

  @override
  String get tiebreakerLabel => 'TIEBREAKER RACE';

  @override
  String get tiebreakerPrompt => 'Votes were equal, let the race decide!';

  @override
  String get racePrompt => 'Let\'s see who wins!';

  @override
  String get raceFastestPrompt => 'Let\'s see who\'s the fastest!';

  @override
  String get raceStartsIn => 'Race starts in';

  @override
  String get howItWorksRace =>
      'We\'ll race all restaurants and the winner will be where we order from!';

  @override
  String get letsGo => 'Let\'s Go!';

  @override
  String get getReady => 'Get ready!';

  @override
  String get neckAndNeck => 'Neck and neck…';

  @override
  String get go => 'GO!';

  @override
  String get weHaveWinner => 'WE HAVE A WINNER!';

  @override
  String get wonTheRace => 'Won the race';

  @override
  String get wonTiebreaker => 'Won the tiebreaker race';

  @override
  String get letsOrder => 'Let\'s Order';

  @override
  String get waitingHostContinue => 'Waiting for the host to continue…';

  @override
  String get liningUp => 'Waiting for the racers to line up…';

  @override
  String get orderingTonightFrom => 'Tonight we\'re ordering from';

  @override
  String viaMode(String mode) {
    return 'via $mode';
  }

  @override
  String get startOrdering => 'Start Ordering';

  @override
  String get waitingHostOrdering => 'Waiting for host to start ordering…';

  @override
  String get yourOrder => 'Your order';

  @override
  String orderingFrom(String name) {
    return 'Ordering from $name';
  }

  @override
  String get whatDoYouWant => 'What do you want?';

  @override
  String get addItem => 'Add item';

  @override
  String get itemName => 'Item name';

  @override
  String get quantity => 'Quantity';

  @override
  String get priceEgp => 'Price (EGP)';

  @override
  String get notes => 'Notes';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get submitMyOrder => 'Submit My Order';

  @override
  String get orderSubmitted => 'Your order has been submitted.';

  @override
  String get yourSubmittedOrder => 'Your submitted order';

  @override
  String get copyOrder => 'Copy order';

  @override
  String get orderCopied => 'Order copied';

  @override
  String get saveOrderForNext => 'Save for next time';

  @override
  String get orderSavedForNext => 'Order saved for next time.';

  @override
  String get savedOrderLoaded => 'Saved order loaded.';

  @override
  String get noItemsToSave => 'No items to save.';

  @override
  String get savedOrders => 'Saved orders';

  @override
  String get useSavedOrder => 'Use';

  @override
  String get deleteSavedOrder => 'Delete';

  @override
  String get editOrder => 'Edit order';

  @override
  String get viewGroupOrders => 'View group orders';

  @override
  String get noItemsYet => 'No items yet. Add something tasty.';

  @override
  String get groupOrders => 'Group orders';

  @override
  String ordersSubmitted(int done, int total) {
    return '$done of $total orders submitted.';
  }

  @override
  String get lockOrders => 'Lock Orders';

  @override
  String get lockOrdersQuestion => 'Lock orders?';

  @override
  String get lockOrdersBody =>
      'After locking, participants cannot edit their orders.';

  @override
  String get submitted => 'Submitted';

  @override
  String get notSubmitted => 'Not submitted';

  @override
  String get uploadReceiptTitle => 'Upload receipt';

  @override
  String get uploadReceiptPrompt => 'Upload the receipt';

  @override
  String get receiptFrameHint => 'Take a photo or choose from gallery';

  @override
  String get receiptTotalHint => 'Receipt total (EGP)';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get retake => 'Retake';

  @override
  String get upload => 'Upload';

  @override
  String get receiptUploaded => 'Receipt uploaded.';

  @override
  String get skipReceipt => 'Skip receipt';

  @override
  String get skipReceiptHint => 'Everyone pays for their own order.';

  @override
  String get payOwnOrderBanner => 'No receipt — everyone pays their own order.';

  @override
  String get costSharing => 'Cost sharing';

  @override
  String get reviewFinalBill => 'Review the final bill';

  @override
  String get expectedOrders => 'Expected orders';

  @override
  String get receiptTotal => 'Receipt total';

  @override
  String get difference => 'Difference';

  @override
  String get additionalCosts => 'Additional costs';

  @override
  String get delivery => 'Delivery';

  @override
  String get service => 'Service';

  @override
  String get tax => 'Tax';

  @override
  String get discount => 'Discount';

  @override
  String get recalculate => 'Recalculate';

  @override
  String get participants => 'Participants';

  @override
  String get sharesTotal => 'Shares total';

  @override
  String get confirmAndSend => 'Confirm & Send';

  @override
  String orderPlusExtras(String order, String extras) {
    return 'Order $order + extras $extras';
  }

  @override
  String get paymentSummary => 'Payment summary';

  @override
  String get yourTotal => 'Your total';

  @override
  String get breakdown => 'Breakdown';

  @override
  String get orderLabel => 'Order';

  @override
  String get extrasFees => 'Extras / fees';

  @override
  String get adjustment => 'Adjustment';

  @override
  String get total => 'Total';

  @override
  String get markAsPaid => 'Mark as Paid';

  @override
  String get requestPaid => 'I paid — notify host';

  @override
  String get paymentRequested => 'Waiting for host confirmation';

  @override
  String get paymentRequestedStatus => 'Payment requested';

  @override
  String get confirmPaid => 'Confirm paid';

  @override
  String get markUnpaid => 'Mark unpaid';

  @override
  String get statusPaid => 'Status: Paid';

  @override
  String get paid => 'Paid';

  @override
  String get unpaid => 'Unpaid';

  @override
  String everyonePaid(int paid, int total) {
    return 'Everyone ($paid/$total paid)';
  }

  @override
  String get roomCompleteTitle => 'All settled!';

  @override
  String get roomCompleteBody => 'Everyone paid. This room is complete.';

  @override
  String participantsCount(int count) {
    return '$count participants';
  }

  @override
  String paidCount(int paid, int total) {
    return 'Paid: $paid/$total';
  }

  @override
  String remainingCount(int remaining, int total) {
    return 'Remaining: $remaining/$total';
  }

  @override
  String get backToHome => 'Back to Home';

  @override
  String get noCompletedRooms => 'No completed rooms yet.';

  @override
  String get profile => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get errAuthFailed => 'Authentication failed.';

  @override
  String get errPermissionDenied =>
      'You don\'t have permission to perform this action.';

  @override
  String get errNotFound => 'Not found.';

  @override
  String get errOffline =>
      'You\'re offline. Changes will sync when connection returns.';

  @override
  String get errNotSignedIn => 'Not signed in.';

  @override
  String get errSignInToCreateRoom => 'Sign in to create a room.';

  @override
  String get errSignInToJoinRoom => 'Sign in to join a room.';

  @override
  String get errInvalidRoomCode => 'Invalid room code.';

  @override
  String get errRoomNotFound => 'Room not found.';

  @override
  String get errRoomEnded => 'This room has already ended.';

  @override
  String get errGuestsNotAllowed => 'Guests are not allowed in this room.';

  @override
  String get errRoomFull => 'Room is full.';

  @override
  String get errJoinRoomFirst => 'Join the room first.';

  @override
  String get errEmailPasswordRequired => 'Email and password required.';

  @override
  String get errAllFieldsRequired => 'All fields required.';

  @override
  String get errLoginFailed => 'Login failed.';

  @override
  String get errRegistrationFailed => 'Registration failed.';

  @override
  String get errGuestSignInFailed => 'Guest sign-in failed.';

  @override
  String get signupSuccessLogin =>
      'Account created. Activate your email if required, then log in.';

  @override
  String get errActivateAccountFirst =>
      'Activate your account first before you can join.';

  @override
  String get guestJoinInviteTitle => 'Join the room as guest';

  @override
  String get guestJoinInviteSubtitle =>
      'Enter a display name to join the invite — no account needed.';

  @override
  String get errNeedTwoRestaurants => 'Need at least 2 restaurants.';

  @override
  String get errRestaurantNameRequired => 'Restaurant name required.';

  @override
  String get errSuggestionLimit => 'Suggestion limit reached.';

  @override
  String get errVotingNotOpen => 'Voting is not open.';

  @override
  String get errNoVotesYet => 'No votes yet.';

  @override
  String get errHostPickVoteOnly => 'Host pick is only for vote-only rooms.';

  @override
  String get errPickTiedRestaurant => 'Pick one of the tied restaurants.';

  @override
  String get errOrdersLocked => 'Orders are locked.';

  @override
  String get errEnterReceiptTotal => 'Enter receipt total.';

  @override
  String get errEnterValidReceiptTotal => 'Enter a valid receipt total.';

  @override
  String get errSelectReceiptImage => 'Select a receipt image first.';

  @override
  String get errRoomNotReady => 'Room not ready.';

  @override
  String get errNoOrdersToSplit => 'No submitted orders to split.';

  @override
  String get errCalculateSplitFirst => 'Calculate the split first.';

  @override
  String errSharesMustEqual(String shares, String receipt) {
    return 'Shares ($shares) must equal receipt ($receipt).';
  }
}
