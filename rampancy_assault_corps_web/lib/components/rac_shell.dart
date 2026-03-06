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

    List<Component> githubChildren = <Component>[
      div([
        img(
          src: '/assets/github.png',
          alt: 'GitHub',
          classes: 'rac-header__github-icon-image',
        ),
      ], classes: 'rac-header__github-icon'),
      div([
        div([
          Component.text('OPEN SOURCE'),
        ], classes: 'rac-header__github-label'),
        div([
          Component.text('PUBLIC REPOSITORY'),
        ], classes: 'rac-header__github-value'),
      ], classes: 'rac-header__github-copy'),
    ];

    Component githubBadge = div(githubChildren, classes: 'rac-header__github');
    if (AppConstants.githubUrl.isNotEmpty) {
      githubBadge = a(
        githubChildren,
        href: AppConstants.githubUrl,
        attributes: <String, String>{
          'target': '_blank',
          'rel': 'noopener noreferrer',
        },
        classes: 'rac-header__github',
      );
    }

    return div([
      header([
        a(
          [
            img(
              src: '/assets/raclogo-white.svg',
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
        githubBadge,
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
  final String className;

  const RacActionButton({
    super.key,
    required this.label,
    this.href,
    this.onPressed,
    this.tone = RacActionTone.primary,
    this.disabled = false,
    this.className = '',
  });

  @override
  Component build(BuildContext context) {
    String toneClass = switch (tone) {
      RacActionTone.primary => 'rac-action--primary',
      RacActionTone.muted => 'rac-action--muted',
      RacActionTone.destructive => 'rac-action--destructive',
    };
    String classes = 'rac-action $toneClass';
    if (className.isNotEmpty) {
      classes = '$classes $className';
    }
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

class RacIconButton extends StatelessComponent {
  final Component icon;
  final String label;
  final VoidCallback? onPressed;
  final RacActionTone tone;
  final bool disabled;
  final String className;

  const RacIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.tone = RacActionTone.primary,
    this.disabled = false,
    this.className = '',
  });

  @override
  Component build(BuildContext context) {
    String toneClass = switch (tone) {
      RacActionTone.primary => 'rac-icon-action--primary',
      RacActionTone.muted => 'rac-icon-action--muted',
      RacActionTone.destructive => 'rac-icon-action--destructive',
    };
    String classes = 'rac-icon-action $toneClass';
    if (className.isNotEmpty) {
      classes = '$classes $className';
    }
    if (disabled) {
      classes = '$classes is-disabled';
    }

    return button(
      [icon],
      classes: classes,
      type: ButtonType.button,
      disabled: disabled,
      attributes: <String, String>{'aria-label': label, 'title': label},
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
