import 'package:arcane_jaspr/arcane_jaspr.dart';
import 'package:rampancy_assault_corps_web/components/app_header.dart';
import 'package:rampancy_assault_corps_web/utils/constants.dart';

class HomeScreen extends StatelessComponent {
  final bool isDark;
  final VoidCallback? onThemeToggle;

  const HomeScreen({super.key, this.isDark = true, this.onThemeToggle});

  @override
  Component build(BuildContext context) {
    return ArcaneDiv(
      styles: const ArcaneStyleData(
        minHeight: '100vh',
        display: Display.flex,
        flexDirection: FlexDirection.column,
      ),
      children: <Component>[
        AppHeader(isDark: isDark, onThemeToggle: onThemeToggle),
        ArcaneDiv(
          styles: const ArcaneStyleData(
            padding: PaddingPreset.sectionY,
            flexGrow: 1,
            display: Display.flex,
            alignItems: AlignItems.center,
          ),
          children: <Component>[
            ArcaneBox(
              maxWidth: MaxWidth.container,
              margin: MarginPreset.autoX,
              children: <Component>[
                ArcaneColumn(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  style: const ArcaneStyleData(gap: Gap.xl),
                  children: <Component>[
                    ArcaneColumn(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      style: const ArcaneStyleData(gap: Gap.md),
                      children: const <Component>[
                        ArcaneStatusBadge.info('Discord + Bungie Linking'),
                        ArcaneText.heading('Link Your Rampancy Account'),
                        ArcaneText.body(
                          'Start with Bungie, add Discord second, and manage the connection from one place.',
                        ),
                      ],
                    ),
                    ArcaneRow(
                      style: const ArcaneStyleData(
                        gap: Gap.md,
                        flexWrap: FlexWrap.wrap,
                      ),
                      children: const <Component>[
                        ArcaneButton.primary(
                          label: 'Get Started',
                          href: AppRoutes.link,
                          showArrow: true,
                        ),
                        ArcaneButton.secondary(
                          label: 'About',
                          href: AppRoutes.about,
                        ),
                      ],
                    ),
                    ArcaneCard(
                      child: ArcaneDiv(
                        styles: const ArcaneStyleData(
                          padding: PaddingPreset.lg,
                        ),
                        children: const <Component>[
                          ArcaneColumn(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            style: ArcaneStyleData(gap: Gap.md),
                            children: <Component>[
                              ArcaneText.heading2('How It Works'),
                              _HomeStep(
                                badge: '1',
                                title: 'Sign in with Bungie',
                                body:
                                    'We create your Firebase record using your Bungie ID and store that ID in the record.',
                              ),
                              _HomeStep(
                                badge: '2',
                                title: 'Connect Discord',
                                body:
                                    'Your Discord OAuth2 account ID is added to the same record so both accounts stay linked together.',
                              ),
                              _HomeStep(
                                badge: '3',
                                title: 'Manage or delete',
                                body:
                                    'The link page shows both accounts as connected and lets you delete only your own stored data.',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeStep extends StatelessComponent {
  final String badge;
  final String title;
  final String body;

  const _HomeStep({
    required this.badge,
    required this.title,
    required this.body,
  });

  @override
  Component build(BuildContext context) {
    return ArcaneRow(
      style: const ArcaneStyleData(
        gap: Gap.md,
        alignItems: AlignItems.flexStart,
      ),
      children: <Component>[
        ArcaneStatusBadge.primary(badge),
        ArcaneColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          style: const ArcaneStyleData(gap: Gap.xs),
          children: <Component>[
            ArcaneText.heading3(title),
            ArcaneText.body(body),
          ],
        ),
      ],
    );
  }
}
