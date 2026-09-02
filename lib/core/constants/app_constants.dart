class AppConstants {
  AppConstants._();

  static const appName = 'FoodRush';
  static const tagline = 'Decide. Race. Order. Split.';
  static const currency = 'EGP';
  static const defaultVoteLimit = 1;

  /// Child Safety point of contact (Google Play Child Safety Standards).
  static const childSafetyEmail = 'ahmaher04@gmail.com';

  /// Custom URL scheme registered on Android / iOS.
  static const inviteScheme = 'foodrush';

  /// Default invite base — hosted free on GitHub Pages (no domain needed).
  /// Override with `INVITE_BASE_URL` in `.env` if you register a real domain.
  static const inviteBase = 'https://ahmed336-cell.github.io/foodbolt/join';

  @Deprecated('Use InviteLinks.forToken / inviteBase')
  static const mockInviteBase = inviteBase;
}
