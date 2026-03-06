import 'package:arcane_jaspr/arcane_jaspr.dart';

import '../components/app_header.dart';
import '../utils/constants.dart';

/// About screen - information about the application
class AboutScreen extends StatelessComponent {
  final bool isDark;
  final VoidCallback? onThemeToggle;

  const AboutScreen({super.key, this.isDark = true, this.onThemeToggle});

  @override
  Component build(BuildContext context) {
    return ArcaneDiv(
      styles: const ArcaneStyleData(
        minHeight: '100vh',
        display: Display.flex,
        flexDirection: FlexDirection.column,
      ),
      children: [
        // Header
        AppHeader(isDark: isDark, onThemeToggle: onThemeToggle),

        // Content
        _Content(),
      ],
    );
  }
}

class _Content extends StatelessComponent {
  const _Content();

  @override
  Component build(BuildContext context) {
    return ArcaneDiv(
      styles: const ArcaneStyleData(
        padding: PaddingPreset.sectionY,
        flexGrow: 1,
      ),
      children: [
        ArcaneBox(
          maxWidth: MaxWidth.content,
          margin: MarginPreset.autoX,
          children: [
            ArcaneColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              style: const ArcaneStyleData(gap: Gap.lg),
              children: [
                // Page title using ArcaneSectionHeader
                ArcaneColumn(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  style: const ArcaneStyleData(gap: Gap.sm),
                  children: const [
                    ArcaneText.heading('About'),
                    ArcaneText.body(
                      '${AppConstants.appName} is the account-linking portal for Rampancy services.',
                    ),
                  ],
                ),

                // Description text
                ArcaneDiv(
                  styles: const ArcaneStyleData(
                    fontSize: FontSize.lg,
                    textColor: TextColor.muted,
                    lineHeight: LineHeight.relaxed,
                  ),
                  children: [
                    ArcaneText(
                      'Use this site to connect your Bungie account first, unlock '
                      'Discord second, and manage the linked record tied to your '
                      'Rampancy profile.',
                    ),
                  ],
                ),

                // Getting Started section
                ArcaneDiv(
                  styles: const ArcaneStyleData(margin: MarginPreset.topXl),
                  children: [const ArcaneText.heading2('Connection Flow')],
                ),

                // Getting started checklist using ArcaneCheckList
                ArcaneCard(
                  child: ArcaneDiv(
                    styles: const ArcaneStyleData(padding: PaddingPreset.lg),
                    children: [
                      ArcaneColumn(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        style: const ArcaneStyleData(gap: Gap.sm),
                        children: const [
                          _ChecklistItem(
                            text: 'Enter through the home screen.',
                          ),
                          _ChecklistItem(text: 'Open the connection screen.'),
                          _ChecklistItem(
                            text:
                                'Link Bungie first to initialize your account record.',
                          ),
                          _ChecklistItem(
                            text:
                                'Link Discord after Bungie unlocks the second step.',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tech stack section
                ArcaneDiv(
                  styles: const ArcaneStyleData(margin: MarginPreset.topXl),
                  children: [const ArcaneText.heading2('Linked Services')],
                ),

                // Tech stack badges
                ArcaneRow(
                  style: const ArcaneStyleData(
                    gap: Gap.sm,
                    flexWrap: FlexWrap.wrap,
                  ),
                  children: [
                    const ArcaneStatusBadge.info('Bungie'),
                    const ArcaneStatusBadge.success('Discord'),
                    const ArcaneStatusBadge.info('Firebase'),
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

class _ChecklistItem extends StatelessComponent {
  final String text;

  const _ChecklistItem({required this.text});

  @override
  Component build(BuildContext context) {
    return ArcaneRow(
      style: const ArcaneStyleData(gap: Gap.sm, alignItems: AlignItems.center),
      children: [
        ArcaneIcon.check(size: IconSize.sm),
        ArcaneText(text),
      ],
    );
  }
}
