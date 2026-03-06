import 'package:arcane_jaspr/arcane_jaspr.dart';
import 'package:rampancy_assault_corps_web/components/rac_shell.dart';
import 'package:rampancy_assault_corps_web/utils/constants.dart';

class HomeScreen extends StatelessComponent {
  final bool isDark;
  final VoidCallback? onThemeToggle;

  const HomeScreen({super.key, this.isDark = true, this.onThemeToggle});

  @override
  Component build(BuildContext context) {
    return const RacShell(
      pageClassName: 'rac-shell--home',
      headerContextLabel: 'ROOT',
      mainChild: _HomeLandingStage(),
    );
  }
}

class _HomeLandingStage extends StatelessComponent {
  const _HomeLandingStage();

  @override
  Component build(BuildContext context) {
    return div([
      div([
        div([
          const RacActionButton(
            label: '[ Make Contact ]',
            href: AppRoutes.link,
          ),
        ], classes: 'rac-landing__action'),
      ], classes: 'rac-main__frame rac-main__frame--landing'),
    ], classes: 'rac-main rac-main--landing');
  }
}
