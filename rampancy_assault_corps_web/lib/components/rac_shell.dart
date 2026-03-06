import 'package:arcane_jaspr/arcane_jaspr.dart';
import 'package:rampancy_assault_corps_web/utils/constants.dart';

enum RacActionTone { primary, muted, destructive }

enum RacSignalTone { success, error }

class RacShell extends StatelessComponent {
  final String pageClassName;
  final String headerContextLabel;
  final List<Component> preludeChildren;
  final Component mainChild;
  final List<Component> utilityChildren;

  const RacShell({
    super.key,
    required this.pageClassName,
    required this.headerContextLabel,
    required this.mainChild,
    this.preludeChildren = const <Component>[],
    this.utilityChildren = const <Component>[],
  });

  @override
  Component build(BuildContext context) {
    String shellClasses = 'rac-shell';
    if (pageClassName.isNotEmpty) {
      shellClasses = '$shellClasses $pageClassName';
    }

    return div([
      header([
        a(
          [
            img(
              src: '/assets/raclogo.svg',
              alt: 'Rampancy Assault Corps',
              classes: 'rac-header__logo',
            ),
            div([
              div([
                Component.text('VERSION ${AppConstants.appVersion}'),
              ], classes: 'rac-header__version'),
              div([
                Component.text(headerContextLabel),
              ], classes: 'rac-header__context'),
            ], classes: 'rac-header__meta'),
          ],
          href: AppRoutes.home,
          classes: 'rac-header__brand',
        ),
      ], classes: 'rac-header'),
      main_([
        if (preludeChildren.isNotEmpty)
          div(preludeChildren, classes: 'rac-prelude'),
        div([mainChild], classes: 'rac-body__inner'),
        if (utilityChildren.isNotEmpty)
          div(utilityChildren, classes: 'rac-utilities'),
      ], classes: 'rac-body'),
      footer([
        div([
          Component.text(AppConstants.appName),
        ], classes: 'rac-footer__title'),
        div([
          Component.text(AppConstants.footerDisclaimer),
        ], classes: 'rac-footer__legal'),
      ], classes: 'rac-footer'),
    ], classes: shellClasses);
  }
}

class RacActionButton extends StatelessComponent {
  final String label;
  final String? href;
  final VoidCallback? onPressed;
  final RacActionTone tone;
  final bool disabled;

  const RacActionButton({
    super.key,
    required this.label,
    this.href,
    this.onPressed,
    this.tone = RacActionTone.primary,
    this.disabled = false,
  });

  @override
  Component build(BuildContext context) {
    String toneClass = switch (tone) {
      RacActionTone.primary => 'rac-action--primary',
      RacActionTone.muted => 'rac-action--muted',
      RacActionTone.destructive => 'rac-action--destructive',
    };
    String classes = 'rac-action $toneClass';
    if (disabled) {
      classes = '$classes is-disabled';
    }

    if (href != null && !disabled && onPressed == null) {
      return a([Component.text(label)], href: href!, classes: classes);
    }

    return button(
      [Component.text(label)],
      classes: classes,
      type: ButtonType.button,
      disabled: disabled,
      onClick: disabled ? null : onPressed,
    );
  }
}

class RacSignalBanner extends StatelessComponent {
  final String message;
  final RacSignalTone tone;

  const RacSignalBanner({super.key, required this.message, required this.tone});

  @override
  Component build(BuildContext context) {
    String toneClass = switch (tone) {
      RacSignalTone.success => 'rac-signal--success',
      RacSignalTone.error => 'rac-signal--error',
    };

    return div([
      div([Component.text(message)], classes: 'rac-signal__copy'),
    ], classes: 'rac-signal $toneClass');
  }
}
