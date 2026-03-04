/// Application constants
class AppConstants {
  AppConstants._();

  /// Application name displayed in header
  static const String appName = 'Rampancy Assault Corps';

  /// Application description
  static const String appDescription =
      'Connect Discord and Bungie accounts for stat tracking.';

  /// GitHub repository URL (leave empty to hide GitHub link)
  static const String githubUrl = '';
}

/// Route constants for the application
abstract class AppRoutes {
  static const String home = '/';
  static const String about = '/about';
}

/// API configuration
abstract class ApiConfig {
  // Server API URL - update with your production URL
  static const String? serverApiUrl = null;
}
