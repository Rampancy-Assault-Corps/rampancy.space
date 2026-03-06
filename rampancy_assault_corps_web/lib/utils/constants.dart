/// Application constants
class AppConstants {
  AppConstants._();

  /// Application name displayed in header
  static const String appName = 'Rampancy Assault Corps';
  static const String appVersion = '1.0.0';

  /// Application description
  static const String appDescription =
      'Connect Discord and Bungie accounts for stat tracking.';

  static const String footerDisclaimer =
      'Trademarks belong to their respective owners. We are not affiliated with or endorsed by any games or platforms unless explicitly stated.';

  /// GitHub repository URL (leave empty to hide GitHub link)
  static const String githubUrl = '';
}

/// Route constants for the application
abstract class AppRoutes {
  static const String home = '/';
  static const String link = '/link';
  static const String about = '/about';
}

/// API configuration
abstract class ApiConfig {
  static const String serverApiUrl = String.fromEnvironment(
    'RAC_SERVER_API_URL',
    defaultValue: '',
  );
}
