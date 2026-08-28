import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

/// Opens the user's email client to report concerns to Child Safety.
Future<bool> launchReportConcernEmail({String subject = 'FoodRush report'}) {
  final uri = Uri(
    scheme: 'mailto',
    path: AppConstants.childSafetyEmail,
    queryParameters: <String, String>{
      'subject': subject,
      'body':
          'Describe the issue (include room code and display names if applicable):\n\n',
    },
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
