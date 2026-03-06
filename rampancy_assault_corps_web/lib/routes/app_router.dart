import 'package:arcane_jaspr/arcane_jaspr.dart';
import 'package:fast_log/fast_log.dart';
import 'package:rampancy_assault_corps_web/screens/about_screen.dart';
import 'package:rampancy_assault_corps_web/screens/home_screen.dart';
import 'package:rampancy_assault_corps_web/screens/link_screen.dart';
import 'package:rampancy_assault_corps_web/utils/constants.dart';

/// Main router component that handles navigation
class AppRouter extends StatelessComponent {
  final bool isDark;
  final VoidCallback? onThemeToggle;

  const AppRouter({super.key, this.isDark = true, this.onThemeToggle});

  @override
  Component build(BuildContext context) {
    verbose('Building AppRouter');
    return RouterOutlet(isDark: isDark, onThemeToggle: onThemeToggle);
  }
}

/// Router outlet that renders the appropriate screen based on path
class RouterOutlet extends StatelessComponent {
  final bool isDark;
  final VoidCallback? onThemeToggle;

  const RouterOutlet({super.key, this.isDark = true, this.onThemeToggle});

  @override
  Component build(BuildContext context) {
    String path = context.url;
    verbose('Routing to path: $path');

    if (path == AppRoutes.about) {
      navigation('Navigating to About');
      return AboutScreen(isDark: isDark, onThemeToggle: onThemeToggle);
    }

    if (path == AppRoutes.link) {
      navigation('Navigating to Link');
      return LinkScreen(isDark: isDark, onThemeToggle: onThemeToggle);
    }

    navigation('Navigating to Home');
    return HomeScreen(isDark: isDark, onThemeToggle: onThemeToggle);
  }
}
