import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'FoodRush'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Decide. Race. Order. Split.'**
  String get tagline;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get currency;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @lock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lock;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get somethingWentWrong;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Gather your crew'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Create a room and share one link. Friends join in seconds, no account needed.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Vote or race'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Suggest restaurants and vote. Equal votes? The tied restaurants race for it.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Split it fairly'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Upload the receipt, review the bill, and everyone sees exactly what they owe.'**
  String get onboardingBody3;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Friends. Food. Competition. Fun.'**
  String get welcomeSubtitle;

  /// No description provided for @createRoom.
  ///
  /// In en, this message translates to:
  /// **'Create Room'**
  String get createRoom;

  /// No description provided for @joinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join Room'**
  String get joinRoom;

  /// No description provided for @loginOrSignIn.
  ///
  /// In en, this message translates to:
  /// **'Login / Sign In'**
  String get loginOrSignIn;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep your rooms and history.'**
  String get loginSubtitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save your rooms, orders and totals.'**
  String get signupSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @needAccount.
  ///
  /// In en, this message translates to:
  /// **'Need an account? Sign up'**
  String get needAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get haveAccount;

  /// No description provided for @guestTitle.
  ///
  /// In en, this message translates to:
  /// **'What should friends call you?'**
  String get guestTitle;

  /// No description provided for @guestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guest mode, no account needed.'**
  String get guestSubtitle;

  /// No description provided for @guestEphemeralHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a name and avatar. Nothing is saved after the room ends.'**
  String get guestEphemeralHint;

  /// No description provided for @pickAvatar.
  ///
  /// In en, this message translates to:
  /// **'Pick an avatar'**
  String get pickAvatar;

  /// No description provided for @shuffleName.
  ///
  /// In en, this message translates to:
  /// **'Suggest another name'**
  String get shuffleName;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and will remove your profile data.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAccountConfirm;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully.'**
  String get accountDeleted;

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hey, {name}'**
  String helloUser(String name);

  /// No description provided for @homePrompt.
  ///
  /// In en, this message translates to:
  /// **'What should we eat together?'**
  String get homePrompt;

  /// No description provided for @createRoomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite friends and start'**
  String get createRoomSubtitle;

  /// No description provided for @joinRoomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a room code'**
  String get joinRoomSubtitle;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Past rooms & bills'**
  String get historySubtitle;

  /// No description provided for @historyDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Past order'**
  String get historyDetailTitle;

  /// No description provided for @historyNoReceipt.
  ///
  /// In en, this message translates to:
  /// **'No receipt photo'**
  String get historyNoReceipt;

  /// No description provided for @nameYourHangout.
  ///
  /// In en, this message translates to:
  /// **'Name your hangout'**
  String get nameYourHangout;

  /// No description provided for @roomNameHint.
  ///
  /// In en, this message translates to:
  /// **'Friday Lunch (optional)'**
  String get roomNameHint;

  /// No description provided for @howDecide.
  ///
  /// In en, this message translates to:
  /// **'How do we decide?'**
  String get howDecide;

  /// No description provided for @allowGuests.
  ///
  /// In en, this message translates to:
  /// **'Allow guests'**
  String get allowGuests;

  /// No description provided for @modeRaceDirect.
  ///
  /// In en, this message translates to:
  /// **'Add restaurants → Race'**
  String get modeRaceDirect;

  /// No description provided for @modeRaceDirectHint.
  ///
  /// In en, this message translates to:
  /// **'Suggest places, then race them all. Fast & fun.'**
  String get modeRaceDirectHint;

  /// No description provided for @modeVoteWithTieRace.
  ///
  /// In en, this message translates to:
  /// **'Add restaurants → Vote (race on draw)'**
  String get modeVoteWithTieRace;

  /// No description provided for @modeVoteWithTieRaceHint.
  ///
  /// In en, this message translates to:
  /// **'Everyone votes. If it\'s a draw, tied places race.'**
  String get modeVoteWithTieRaceHint;

  /// No description provided for @modeVoteOnly.
  ///
  /// In en, this message translates to:
  /// **'Add restaurants → Vote only'**
  String get modeVoteOnly;

  /// No description provided for @modeVoteOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Everyone votes. No race — host picks if votes tie.'**
  String get modeVoteOnlyHint;

  /// No description provided for @pickTiedWinner.
  ///
  /// In en, this message translates to:
  /// **'Votes tied — pick the winner'**
  String get pickTiedWinner;

  /// No description provided for @pickTiedWinnerHint.
  ///
  /// In en, this message translates to:
  /// **'Choose one of the tied restaurants.'**
  String get pickTiedWinnerHint;

  /// No description provided for @hostPickWinner.
  ///
  /// In en, this message translates to:
  /// **'Pick as winner'**
  String get hostPickWinner;

  /// No description provided for @enterRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the room code'**
  String get enterRoomCode;

  /// No description provided for @roomCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6 characters · CAPITAL letters & numbers'**
  String get roomCodeHint;

  /// No description provided for @roomCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Room code'**
  String get roomCodeLabel;

  /// No description provided for @tapCodeToCopy.
  ///
  /// In en, this message translates to:
  /// **'Tap code to copy'**
  String get tapCodeToCopy;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @roomCode.
  ///
  /// In en, this message translates to:
  /// **'Code {code}'**
  String roomCode(String code);

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @leaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get leaveRoom;

  /// No description provided for @leaveRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave room?'**
  String get leaveRoomTitle;

  /// No description provided for @leaveRoomBody.
  ///
  /// In en, this message translates to:
  /// **'You will leave this room. You can join again with the code if it is still open.'**
  String get leaveRoomBody;

  /// No description provided for @cancelRoom.
  ///
  /// In en, this message translates to:
  /// **'Cancel room'**
  String get cancelRoom;

  /// No description provided for @cancelRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel room?'**
  String get cancelRoomTitle;

  /// No description provided for @cancelRoomBody.
  ///
  /// In en, this message translates to:
  /// **'This ends the room for everyone. Friends will no longer be able to join.'**
  String get cancelRoomBody;

  /// No description provided for @playersReady.
  ///
  /// In en, this message translates to:
  /// **'{count} players are ready'**
  String playersReady(int count);

  /// No description provided for @waitingForFriends.
  ///
  /// In en, this message translates to:
  /// **'Waiting for friends…'**
  String get waitingForFriends;

  /// No description provided for @waitingForHostStart.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host to start'**
  String get waitingForHostStart;

  /// No description provided for @hostWillStart.
  ///
  /// In en, this message translates to:
  /// **'Hang tight, the host will start soon.'**
  String get hostWillStart;

  /// No description provided for @startGameQuestion.
  ///
  /// In en, this message translates to:
  /// **'Start the game?'**
  String get startGameQuestion;

  /// No description provided for @startAnyway.
  ///
  /// In en, this message translates to:
  /// **'Only {count} player so far. Start anyway?'**
  String startAnyway(int count);

  /// No description provided for @inviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Join {room} on FoodRush! Code: {code}'**
  String inviteMessage(String room, String code);

  /// No description provided for @suggestRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Suggest restaurants'**
  String get suggestRestaurants;

  /// No description provided for @cravingPrompt.
  ///
  /// In en, this message translates to:
  /// **'What are we craving?'**
  String get cravingPrompt;

  /// No description provided for @raceHint.
  ///
  /// In en, this message translates to:
  /// **'Every restaurant becomes a racer.'**
  String get raceHint;

  /// No description provided for @voteHint.
  ///
  /// In en, this message translates to:
  /// **'Everyone votes once suggestions are in.'**
  String get voteHint;

  /// No description provided for @addRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Add Restaurant'**
  String get addRestaurant;

  /// No description provided for @restaurantName.
  ///
  /// In en, this message translates to:
  /// **'Restaurant name'**
  String get restaurantName;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get chooseCategory;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @emptySuggestions.
  ///
  /// In en, this message translates to:
  /// **'No restaurants suggested yet.'**
  String get emptySuggestions;

  /// No description provided for @emptySuggestionsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Add Restaurant to start.'**
  String get emptySuggestionsHint;

  /// No description provided for @needTwoRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Need at least 2 restaurants'**
  String get needTwoRestaurants;

  /// No description provided for @startVoting.
  ///
  /// In en, this message translates to:
  /// **'Start Voting'**
  String get startVoting;

  /// No description provided for @startRace.
  ///
  /// In en, this message translates to:
  /// **'Start Race'**
  String get startRace;

  /// No description provided for @bySomeone.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String bySomeone(String name);

  /// No description provided for @catBurger.
  ///
  /// In en, this message translates to:
  /// **'Burger'**
  String get catBurger;

  /// No description provided for @catPizza.
  ///
  /// In en, this message translates to:
  /// **'Pizza'**
  String get catPizza;

  /// No description provided for @catChicken.
  ///
  /// In en, this message translates to:
  /// **'Chicken'**
  String get catChicken;

  /// No description provided for @catShawarma.
  ///
  /// In en, this message translates to:
  /// **'Shawarma'**
  String get catShawarma;

  /// No description provided for @catGrill.
  ///
  /// In en, this message translates to:
  /// **'Grill'**
  String get catGrill;

  /// No description provided for @catSeafood.
  ///
  /// In en, this message translates to:
  /// **'Seafood'**
  String get catSeafood;

  /// No description provided for @catAsian.
  ///
  /// In en, this message translates to:
  /// **'Asian'**
  String get catAsian;

  /// No description provided for @catPasta.
  ///
  /// In en, this message translates to:
  /// **'Pasta'**
  String get catPasta;

  /// No description provided for @catSushi.
  ///
  /// In en, this message translates to:
  /// **'Sushi'**
  String get catSushi;

  /// No description provided for @catMexican.
  ///
  /// In en, this message translates to:
  /// **'Mexican'**
  String get catMexican;

  /// No description provided for @catKoshary.
  ///
  /// In en, this message translates to:
  /// **'Koshary'**
  String get catKoshary;

  /// No description provided for @catSandwich.
  ///
  /// In en, this message translates to:
  /// **'Sandwich'**
  String get catSandwich;

  /// No description provided for @catBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get catBreakfast;

  /// No description provided for @catSalad.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get catSalad;

  /// No description provided for @catDessert.
  ///
  /// In en, this message translates to:
  /// **'Dessert'**
  String get catDessert;

  /// No description provided for @catDrinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get catDrinks;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @chooseFavorite.
  ///
  /// In en, this message translates to:
  /// **'Choose your favorite'**
  String get chooseFavorite;

  /// No description provided for @oneVote.
  ///
  /// In en, this message translates to:
  /// **'You have 1 vote.'**
  String get oneVote;

  /// No description provided for @tieHint.
  ///
  /// In en, this message translates to:
  /// **'Equal votes? The tied restaurants race for it.'**
  String get tieHint;

  /// No description provided for @vote.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get vote;

  /// No description provided for @switchVote.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchVote;

  /// No description provided for @yourVote.
  ///
  /// In en, this message translates to:
  /// **'Your vote'**
  String get yourVote;

  /// No description provided for @votedFor.
  ///
  /// In en, this message translates to:
  /// **'You voted for'**
  String get votedFor;

  /// No description provided for @changeMind.
  ///
  /// In en, this message translates to:
  /// **'Change your mind?'**
  String get changeMind;

  /// No description provided for @revealWinner.
  ///
  /// In en, this message translates to:
  /// **'Reveal Winner'**
  String get revealWinner;

  /// No description provided for @waitingReveal.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host to reveal…'**
  String get waitingReveal;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @winner.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winner;

  /// No description provided for @votesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} votes'**
  String votesCount(int count);

  /// No description provided for @votedProgress.
  ///
  /// In en, this message translates to:
  /// **'{voted} of {total} voted'**
  String votedProgress(int voted, int total);

  /// No description provided for @tieBanner.
  ///
  /// In en, this message translates to:
  /// **'It\'s a tie! The tied restaurants settle it in a race.'**
  String get tieBanner;

  /// No description provided for @tieSnack.
  ///
  /// In en, this message translates to:
  /// **'It\'s a tie! {count} restaurants race for it.'**
  String tieSnack(int count);

  /// No description provided for @drawTitle.
  ///
  /// In en, this message translates to:
  /// **'It\'s a draw!'**
  String get drawTitle;

  /// No description provided for @drawSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} restaurants are tied. Race to decide the winner.'**
  String drawSubtitle(int count);

  /// No description provided for @tiedRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Tied restaurants'**
  String get tiedRestaurants;

  /// No description provided for @goToRace.
  ///
  /// In en, this message translates to:
  /// **'Go to Race'**
  String get goToRace;

  /// No description provided for @waitingHostStartRace.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the host to start the race…'**
  String get waitingHostStartRace;

  /// No description provided for @noRestaurantsToVote.
  ///
  /// In en, this message translates to:
  /// **'No restaurants to vote on.'**
  String get noRestaurantsToVote;

  /// No description provided for @raceLabel.
  ///
  /// In en, this message translates to:
  /// **'RESTAURANT RACE'**
  String get raceLabel;

  /// No description provided for @tiebreakerLabel.
  ///
  /// In en, this message translates to:
  /// **'TIEBREAKER RACE'**
  String get tiebreakerLabel;

  /// No description provided for @tiebreakerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Votes were equal, let the race decide!'**
  String get tiebreakerPrompt;

  /// No description provided for @racePrompt.
  ///
  /// In en, this message translates to:
  /// **'Let\'s see who wins!'**
  String get racePrompt;

  /// No description provided for @raceFastestPrompt.
  ///
  /// In en, this message translates to:
  /// **'Let\'s see who\'s the fastest!'**
  String get raceFastestPrompt;

  /// No description provided for @raceStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Race starts in'**
  String get raceStartsIn;

  /// No description provided for @howItWorksRace.
  ///
  /// In en, this message translates to:
  /// **'We\'ll race all restaurants and the winner will be where we order from!'**
  String get howItWorksRace;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Go!'**
  String get letsGo;

  /// No description provided for @getReady.
  ///
  /// In en, this message translates to:
  /// **'Get ready!'**
  String get getReady;

  /// No description provided for @neckAndNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck and neck…'**
  String get neckAndNeck;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'GO!'**
  String get go;

  /// No description provided for @weHaveWinner.
  ///
  /// In en, this message translates to:
  /// **'WE HAVE A WINNER!'**
  String get weHaveWinner;

  /// No description provided for @wonTheRace.
  ///
  /// In en, this message translates to:
  /// **'Won the race'**
  String get wonTheRace;

  /// No description provided for @wonTiebreaker.
  ///
  /// In en, this message translates to:
  /// **'Won the tiebreaker race'**
  String get wonTiebreaker;

  /// No description provided for @letsOrder.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Order'**
  String get letsOrder;

  /// No description provided for @waitingHostContinue.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the host to continue…'**
  String get waitingHostContinue;

  /// No description provided for @liningUp.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the racers to line up…'**
  String get liningUp;

  /// No description provided for @orderingTonightFrom.
  ///
  /// In en, this message translates to:
  /// **'Tonight we\'re ordering from'**
  String get orderingTonightFrom;

  /// No description provided for @viaMode.
  ///
  /// In en, this message translates to:
  /// **'via {mode}'**
  String viaMode(String mode);

  /// No description provided for @startOrdering.
  ///
  /// In en, this message translates to:
  /// **'Start Ordering'**
  String get startOrdering;

  /// No description provided for @waitingHostOrdering.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host to start ordering…'**
  String get waitingHostOrdering;

  /// No description provided for @yourOrder.
  ///
  /// In en, this message translates to:
  /// **'Your order'**
  String get yourOrder;

  /// No description provided for @orderingFrom.
  ///
  /// In en, this message translates to:
  /// **'Ordering from {name}'**
  String orderingFrom(String name);

  /// No description provided for @whatDoYouWant.
  ///
  /// In en, this message translates to:
  /// **'What do you want?'**
  String get whatDoYouWant;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get itemName;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @priceEgp.
  ///
  /// In en, this message translates to:
  /// **'Price (EGP)'**
  String get priceEgp;

  /// No description provided for @editPrice.
  ///
  /// In en, this message translates to:
  /// **'Edit price'**
  String get editPrice;

  /// No description provided for @savePrice.
  ///
  /// In en, this message translates to:
  /// **'Save price'**
  String get savePrice;

  /// No description provided for @hostEditPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a price to correct it.'**
  String get hostEditPriceHint;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @submitMyOrder.
  ///
  /// In en, this message translates to:
  /// **'Submit My Order'**
  String get submitMyOrder;

  /// No description provided for @emptyOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'You didn\'t add an order'**
  String get emptyOrderTitle;

  /// No description provided for @emptyOrderBody.
  ///
  /// In en, this message translates to:
  /// **'Your list is empty. Send an empty order anyway? The group will see that you\'re not ordering food.'**
  String get emptyOrderBody;

  /// No description provided for @sendEmptyOrder.
  ///
  /// In en, this message translates to:
  /// **'Send empty order'**
  String get sendEmptyOrder;

  /// No description provided for @orderSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your order has been submitted.'**
  String get orderSubmitted;

  /// No description provided for @yourSubmittedOrder.
  ///
  /// In en, this message translates to:
  /// **'Your submitted order'**
  String get yourSubmittedOrder;

  /// No description provided for @copyOrder.
  ///
  /// In en, this message translates to:
  /// **'Copy order'**
  String get copyOrder;

  /// No description provided for @orderCopied.
  ///
  /// In en, this message translates to:
  /// **'Order copied'**
  String get orderCopied;

  /// No description provided for @saveOrderForNext.
  ///
  /// In en, this message translates to:
  /// **'Save for next time'**
  String get saveOrderForNext;

  /// No description provided for @orderSavedForNext.
  ///
  /// In en, this message translates to:
  /// **'Order saved for next time.'**
  String get orderSavedForNext;

  /// No description provided for @savedOrderLoaded.
  ///
  /// In en, this message translates to:
  /// **'Saved order loaded.'**
  String get savedOrderLoaded;

  /// No description provided for @noItemsToSave.
  ///
  /// In en, this message translates to:
  /// **'No items to save.'**
  String get noItemsToSave;

  /// No description provided for @savedOrders.
  ///
  /// In en, this message translates to:
  /// **'Saved orders'**
  String get savedOrders;

  /// No description provided for @useSavedOrder.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get useSavedOrder;

  /// No description provided for @deleteSavedOrder.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteSavedOrder;

  /// No description provided for @editOrder.
  ///
  /// In en, this message translates to:
  /// **'Edit order'**
  String get editOrder;

  /// No description provided for @viewGroupOrders.
  ///
  /// In en, this message translates to:
  /// **'View group orders'**
  String get viewGroupOrders;

  /// No description provided for @noItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No items yet. Add something tasty.'**
  String get noItemsYet;

  /// No description provided for @groupOrders.
  ///
  /// In en, this message translates to:
  /// **'Group orders'**
  String get groupOrders;

  /// No description provided for @ordersSubmitted.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} orders submitted.'**
  String ordersSubmitted(int done, int total);

  /// No description provided for @lockOrders.
  ///
  /// In en, this message translates to:
  /// **'Lock Orders'**
  String get lockOrders;

  /// No description provided for @lockOrdersQuestion.
  ///
  /// In en, this message translates to:
  /// **'Lock orders?'**
  String get lockOrdersQuestion;

  /// No description provided for @lockOrdersBody.
  ///
  /// In en, this message translates to:
  /// **'After locking, participants cannot edit. You will see the combined order to send to the restaurant.'**
  String get lockOrdersBody;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @notSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Not submitted'**
  String get notSubmitted;

  /// No description provided for @orderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order for restaurant'**
  String get orderDetailsTitle;

  /// No description provided for @orderDetailsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Send this order to the restaurant (WhatsApp, call, or delivery app).'**
  String get orderDetailsPrompt;

  /// No description provided for @combinedOrder.
  ///
  /// In en, this message translates to:
  /// **'Combined order'**
  String get combinedOrder;

  /// No description provided for @combinedOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Same items from different people are merged into one line.'**
  String get combinedOrderHint;

  /// No description provided for @sharedBy.
  ///
  /// In en, this message translates to:
  /// **'Shared by {people}'**
  String sharedBy(String people);

  /// No description provided for @orderedBy.
  ///
  /// In en, this message translates to:
  /// **'Ordered by {people}'**
  String orderedBy(String people);

  /// No description provided for @perPersonOrders.
  ///
  /// In en, this message translates to:
  /// **'Per person'**
  String get perPersonOrders;

  /// No description provided for @shareWithRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareWithRestaurant;

  /// No description provided for @orderDetailsCopied.
  ///
  /// In en, this message translates to:
  /// **'Order copied — paste to the restaurant.'**
  String get orderDetailsCopied;

  /// No description provided for @continueToReceipt.
  ///
  /// In en, this message translates to:
  /// **'Continue to receipt'**
  String get continueToReceipt;

  /// No description provided for @waitingHostReceipt.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host to continue…'**
  String get waitingHostReceipt;

  /// No description provided for @uploadReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload receipt'**
  String get uploadReceiptTitle;

  /// No description provided for @uploadReceiptPrompt.
  ///
  /// In en, this message translates to:
  /// **'Upload the receipt'**
  String get uploadReceiptPrompt;

  /// No description provided for @receiptFrameHint.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or choose from gallery'**
  String get receiptFrameHint;

  /// No description provided for @receiptTotalHint.
  ///
  /// In en, this message translates to:
  /// **'Receipt total (EGP)'**
  String get receiptTotalHint;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @receiptUploaded.
  ///
  /// In en, this message translates to:
  /// **'Receipt uploaded.'**
  String get receiptUploaded;

  /// No description provided for @skipReceipt.
  ///
  /// In en, this message translates to:
  /// **'Skip receipt'**
  String get skipReceipt;

  /// No description provided for @skipReceiptHint.
  ///
  /// In en, this message translates to:
  /// **'Skip the photo. You can still add delivery and fees.'**
  String get skipReceiptHint;

  /// No description provided for @skipReceiptFeesHint.
  ///
  /// In en, this message translates to:
  /// **'No receipt photo — add delivery, service, tax, or discount below.'**
  String get skipReceiptFeesHint;

  /// No description provided for @payOwnOrderBanner.
  ///
  /// In en, this message translates to:
  /// **'No receipt photo — split uses orders plus any fees.'**
  String get payOwnOrderBanner;

  /// No description provided for @costSharing.
  ///
  /// In en, this message translates to:
  /// **'Cost sharing'**
  String get costSharing;

  /// No description provided for @reviewFinalBill.
  ///
  /// In en, this message translates to:
  /// **'Review the final bill'**
  String get reviewFinalBill;

  /// No description provided for @expectedOrders.
  ///
  /// In en, this message translates to:
  /// **'Expected orders'**
  String get expectedOrders;

  /// No description provided for @receiptTotal.
  ///
  /// In en, this message translates to:
  /// **'Receipt total'**
  String get receiptTotal;

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get difference;

  /// No description provided for @additionalCosts.
  ///
  /// In en, this message translates to:
  /// **'Additional costs'**
  String get additionalCosts;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @recalculate.
  ///
  /// In en, this message translates to:
  /// **'Recalculate'**
  String get recalculate;

  /// No description provided for @participants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @sharesTotal.
  ///
  /// In en, this message translates to:
  /// **'Shares total'**
  String get sharesTotal;

  /// No description provided for @confirmAndSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Send'**
  String get confirmAndSend;

  /// No description provided for @orderPlusExtras.
  ///
  /// In en, this message translates to:
  /// **'Order {order} + extras {extras}'**
  String orderPlusExtras(String order, String extras);

  /// No description provided for @paymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment summary'**
  String get paymentSummary;

  /// No description provided for @yourTotal.
  ///
  /// In en, this message translates to:
  /// **'Your total'**
  String get yourTotal;

  /// No description provided for @breakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get breakdown;

  /// No description provided for @orderLabel.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get orderLabel;

  /// No description provided for @extrasFees.
  ///
  /// In en, this message translates to:
  /// **'Extras / fees'**
  String get extrasFees;

  /// No description provided for @adjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get adjustment;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @requestPaid.
  ///
  /// In en, this message translates to:
  /// **'I paid — notify host'**
  String get requestPaid;

  /// No description provided for @paymentRequested.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host confirmation'**
  String get paymentRequested;

  /// No description provided for @paymentRequestedStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment requested'**
  String get paymentRequestedStatus;

  /// No description provided for @confirmPaid.
  ///
  /// In en, this message translates to:
  /// **'Confirm paid'**
  String get confirmPaid;

  /// No description provided for @markUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Mark unpaid'**
  String get markUnpaid;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Status: Paid'**
  String get statusPaid;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @everyonePaid.
  ///
  /// In en, this message translates to:
  /// **'Everyone ({paid}/{total} paid)'**
  String everyonePaid(int paid, int total);

  /// No description provided for @roomCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'All settled!'**
  String get roomCompleteTitle;

  /// No description provided for @roomCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Everyone paid. This room is complete.'**
  String get roomCompleteBody;

  /// No description provided for @participantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String participantsCount(int count);

  /// No description provided for @paidCount.
  ///
  /// In en, this message translates to:
  /// **'Paid: {paid}/{total}'**
  String paidCount(int paid, int total);

  /// No description provided for @remainingCount.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {remaining}/{total}'**
  String remainingCount(int remaining, int total);

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @noCompletedRooms.
  ///
  /// In en, this message translates to:
  /// **'No completed rooms yet.'**
  String get noCompletedRooms;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @guideWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FoodRush!'**
  String get guideWelcomeTitle;

  /// No description provided for @guideWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'This quick guide will show you how the app works. Tap Next to continue.'**
  String get guideWelcomeBody;

  /// No description provided for @guideCreateRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a Room'**
  String get guideCreateRoomTitle;

  /// No description provided for @guideCreateRoomBody.
  ///
  /// In en, this message translates to:
  /// **'Start a new room and invite your friends. Everyone joins with a simple code.'**
  String get guideCreateRoomBody;

  /// No description provided for @guideJoinRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a Room'**
  String get guideJoinRoomTitle;

  /// No description provided for @guideJoinRoomBody.
  ///
  /// In en, this message translates to:
  /// **'Got a code from a friend? Enter it here to join their room instantly.'**
  String get guideJoinRoomBody;

  /// No description provided for @guideHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get guideHistoryTitle;

  /// No description provided for @guideHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'View your past rooms — who ordered what, the receipt, and each person\'s share.'**
  String get guideHistoryBody;

  /// No description provided for @guideProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get guideProfileTitle;

  /// No description provided for @guideProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Change your language, manage your account, or log out from here.'**
  String get guideProfileBody;

  /// No description provided for @guideSuggestTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggest Restaurants'**
  String get guideSuggestTitle;

  /// No description provided for @guideSuggestBody.
  ///
  /// In en, this message translates to:
  /// **'Each member can suggest places to eat. The group decides together.'**
  String get guideSuggestBody;

  /// No description provided for @guideVoteRaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Vote or Race'**
  String get guideVoteRaceTitle;

  /// No description provided for @guideVoteRaceBody.
  ///
  /// In en, this message translates to:
  /// **'Vote on restaurants. If it\'s a tie, the tied restaurants race for it!'**
  String get guideVoteRaceBody;

  /// No description provided for @guideOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Place Your Order'**
  String get guideOrderTitle;

  /// No description provided for @guideOrderBody.
  ///
  /// In en, this message translates to:
  /// **'Everyone adds their own items. The host locks orders when ready.'**
  String get guideOrderBody;

  /// No description provided for @guideReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload the Receipt'**
  String get guideReceiptTitle;

  /// No description provided for @guideReceiptBody.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the receipt. Or skip it — you can still split the bill.'**
  String get guideReceiptBody;

  /// No description provided for @guideSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split the Bill'**
  String get guideSplitTitle;

  /// No description provided for @guideSplitBody.
  ///
  /// In en, this message translates to:
  /// **'Delivery, tax, and fees are divided equally. Everyone sees exactly what they owe.'**
  String get guideSplitBody;

  /// No description provided for @errAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed.'**
  String get errAuthFailed;

  /// No description provided for @errPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action.'**
  String get errPermissionDenied;

  /// No description provided for @errNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get errNotFound;

  /// No description provided for @errOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Changes will sync when connection returns.'**
  String get errOffline;

  /// No description provided for @errNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in.'**
  String get errNotSignedIn;

  /// No description provided for @errSignInToCreateRoom.
  ///
  /// In en, this message translates to:
  /// **'Sign in to create a room.'**
  String get errSignInToCreateRoom;

  /// No description provided for @errSignInToJoinRoom.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join a room.'**
  String get errSignInToJoinRoom;

  /// No description provided for @errInvalidRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid room code.'**
  String get errInvalidRoomCode;

  /// No description provided for @errRoomNotFound.
  ///
  /// In en, this message translates to:
  /// **'Room not found.'**
  String get errRoomNotFound;

  /// No description provided for @errRestaurantNotFound.
  ///
  /// In en, this message translates to:
  /// **'Restaurant not found.'**
  String get errRestaurantNotFound;

  /// No description provided for @errRemoveRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove this restaurant.'**
  String get errRemoveRestaurant;

  /// No description provided for @errRoomEnded.
  ///
  /// In en, this message translates to:
  /// **'This room has already ended.'**
  String get errRoomEnded;

  /// No description provided for @errGuestsNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Guests are not allowed in this room.'**
  String get errGuestsNotAllowed;

  /// No description provided for @errRoomFull.
  ///
  /// In en, this message translates to:
  /// **'Room is full.'**
  String get errRoomFull;

  /// No description provided for @errJoinRoomFirst.
  ///
  /// In en, this message translates to:
  /// **'Join the room first.'**
  String get errJoinRoomFirst;

  /// No description provided for @errEmailPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Email and password required.'**
  String get errEmailPasswordRequired;

  /// No description provided for @errAllFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields required.'**
  String get errAllFieldsRequired;

  /// No description provided for @errLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed.'**
  String get errLoginFailed;

  /// No description provided for @errRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed.'**
  String get errRegistrationFailed;

  /// No description provided for @errGuestSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Guest sign-in failed.'**
  String get errGuestSignInFailed;

  /// No description provided for @signupSuccessLogin.
  ///
  /// In en, this message translates to:
  /// **'Account created. Activate your email if required, then log in.'**
  String get signupSuccessLogin;

  /// No description provided for @errActivateAccountFirst.
  ///
  /// In en, this message translates to:
  /// **'Activate your account first before you can join.'**
  String get errActivateAccountFirst;

  /// No description provided for @guestJoinInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Join the room as guest'**
  String get guestJoinInviteTitle;

  /// No description provided for @guestJoinInviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a display name to join the invite — no account needed.'**
  String get guestJoinInviteSubtitle;

  /// No description provided for @errNeedTwoRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Need at least 2 restaurants.'**
  String get errNeedTwoRestaurants;

  /// No description provided for @errRestaurantNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Restaurant name required.'**
  String get errRestaurantNameRequired;

  /// No description provided for @errSuggestionLimit.
  ///
  /// In en, this message translates to:
  /// **'Suggestion limit reached.'**
  String get errSuggestionLimit;

  /// No description provided for @errVotingNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Voting is not open.'**
  String get errVotingNotOpen;

  /// No description provided for @errNoVotesYet.
  ///
  /// In en, this message translates to:
  /// **'No votes yet.'**
  String get errNoVotesYet;

  /// No description provided for @errHostPickVoteOnly.
  ///
  /// In en, this message translates to:
  /// **'Host pick is only for vote-only rooms.'**
  String get errHostPickVoteOnly;

  /// No description provided for @errPickTiedRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Pick one of the tied restaurants.'**
  String get errPickTiedRestaurant;

  /// No description provided for @errOrdersLocked.
  ///
  /// In en, this message translates to:
  /// **'Orders are locked.'**
  String get errOrdersLocked;

  /// No description provided for @errEnterReceiptTotal.
  ///
  /// In en, this message translates to:
  /// **'Enter receipt total.'**
  String get errEnterReceiptTotal;

  /// No description provided for @errEnterValidReceiptTotal.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid receipt total.'**
  String get errEnterValidReceiptTotal;

  /// No description provided for @errSelectReceiptImage.
  ///
  /// In en, this message translates to:
  /// **'Select a receipt image first.'**
  String get errSelectReceiptImage;

  /// No description provided for @errReceiptUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the receipt. Try again.'**
  String get errReceiptUploadFailed;

  /// No description provided for @errRoomNotReady.
  ///
  /// In en, this message translates to:
  /// **'Room not ready.'**
  String get errRoomNotReady;

  /// No description provided for @errNoOrdersToSplit.
  ///
  /// In en, this message translates to:
  /// **'No submitted orders to split.'**
  String get errNoOrdersToSplit;

  /// No description provided for @errCalculateSplitFirst.
  ///
  /// In en, this message translates to:
  /// **'Calculate the split first.'**
  String get errCalculateSplitFirst;

  /// No description provided for @errSharesMustEqual.
  ///
  /// In en, this message translates to:
  /// **'Shares ({shares}) must equal receipt ({receipt}).'**
  String errSharesMustEqual(String shares, String receipt);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
