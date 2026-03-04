import 'package:arcane_jaspr/arcane_jaspr.dart';

import '../utils/constants.dart';

class AppHeader extends StatelessComponent {
  final bool isDark;
  final VoidCallback? onThemeToggle;
  final bool showLogout;
  final VoidCallback? onLogout;
  final bool logoutLoading;

  const AppHeader({
    super.key,
    this.isDark = true,
    this.onThemeToggle,
    this.showLogout = false,
    this.onLogout,
    this.logoutLoading = false,
  });

  @override
  Component build(BuildContext context) {
    return ArcaneDiv(
      styles: const ArcaneStyleData(
        display: Display.flex,
        alignItems: AlignItems.center,
        justifyContent: JustifyContent.spaceBetween,
        padding: PaddingPreset.horizontalLg,
        heightCustom: '64px',
        borderBottom: BorderPreset.subtle,
        background: Background.surface,
        width: Size.full,
      ),
      children: <Component>[
        ArcaneLink(
          href: AppRoutes.home,
          styles: const ArcaneStyleData(textDecoration: TextDecoration.none),
          child: ArcaneText(
            AppConstants.appName,
            style: const ArcaneStyleData(
              fontWeight: FontWeight.bold,
              fontSize: FontSize.lg,
              textColor: TextColor.primary,
            ),
          ),
        ),
        ArcaneRow(
          style: const ArcaneStyleData(
            gap: Gap.sm,
            alignItems: AlignItems.center,
          ),
          children: <Component>[
            ArcaneButton.ghost(
              label: isDark ? 'Light' : 'Dark',
              onPressed: onThemeToggle,
            ),
            if (showLogout)
              ArcaneButton.secondary(
                label: logoutLoading ? 'Logging out...' : 'Logout',
                onPressed: logoutLoading ? null : onLogout,
              ),
          ],
        ),
      ],
    );
  }
}
