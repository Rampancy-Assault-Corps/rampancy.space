import 'package:arcane_jaspr/arcane_jaspr.dart';
import 'package:fast_log/fast_log.dart';
import 'package:web/web.dart' as web;

import '../components/app_header.dart';
import '../services/link_status_service.dart';

class HomeScreen extends StatefulComponent {
  final bool isDark;
  final VoidCallback? onThemeToggle;

  const HomeScreen({super.key, this.isDark = true, this.onThemeToggle});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LinkStatus? _status;
  bool _loading = true;
  bool _logoutLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final LinkStatus status = await LinkStatusService.fetchStatus();
      setState(() {
        _status = status;
        _loading = false;
      });
    } catch (e) {
      error('link_status_load_failed err=$e');
      setState(() {
        _status = null;
        _loading = false;
        _error = 'Unable to load connection status.';
      });
    }
  }

  void _connectDiscord() {
    web.window.location.href = '/auth/discord/start';
  }

  void _connectBungie() {
    web.window.location.href = '/auth/bungie/start';
  }

  Future<void> _logout() async {
    if (_logoutLoading) {
      return;
    }

    setState(() {
      _logoutLoading = true;
    });

    try {
      await LinkStatusService.logout();
      await _loadStatus();
    } catch (e) {
      setState(() {
        _error = 'Unable to log out.';
      });
    } finally {
      setState(() {
        _logoutLoading = false;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    final bool showLogout = _status?.authenticated ?? false;

    return ArcaneDiv(
      styles: const ArcaneStyleData(
        minHeight: '100vh',
        display: Display.flex,
        flexDirection: FlexDirection.column,
      ),
      children: <Component>[
        AppHeader(
          isDark: component.isDark,
          onThemeToggle: component.onThemeToggle,
          showLogout: showLogout,
          onLogout: _logout,
          logoutLoading: _logoutLoading,
        ),
        ArcaneDiv(
          styles: const ArcaneStyleData(
            padding: PaddingPreset.sectionY,
            flexGrow: 1,
          ),
          children: <Component>[
            ArcaneBox(
              maxWidth: MaxWidth.container,
              margin: MarginPreset.autoX,
              children: <Component>[_buildBody()],
            ),
          ],
        ),
      ],
    );
  }

  Component _buildBody() {
    if (_loading) {
      return ArcaneColumn(
        crossAxisAlignment: CrossAxisAlignment.center,
        style: const ArcaneStyleData(gap: Gap.md, textAlign: TextAlign.center),
        children: const <Component>[
          ArcaneText.heading('Loading'),
          ArcaneText.body('Checking your connection status...'),
        ],
      );
    }

    if (_error != null) {
      return ArcaneColumn(
        crossAxisAlignment: CrossAxisAlignment.center,
        style: const ArcaneStyleData(gap: Gap.md, textAlign: TextAlign.center),
        children: <Component>[
          const ArcaneText.heading('Something went wrong'),
          ArcaneText.body(_error!),
          ArcaneButton.secondary(label: 'Retry', onPressed: _loadStatus),
        ],
      );
    }

    final LinkStatus status =
        _status ??
        const LinkStatus(
          featureEnabled: false,
          authenticated: false,
          discordConnected: false,
          bungieConnected: false,
          discord: null,
          memberships: <LinkStatusMembership>[],
        );

    if (!status.featureEnabled) {
      return ArcaneColumn(
        crossAxisAlignment: CrossAxisAlignment.center,
        style: const ArcaneStyleData(gap: Gap.md, textAlign: TextAlign.center),
        children: const <Component>[
          ArcaneText.heading('Account Linking Unavailable'),
          ArcaneText.body('This feature is currently disabled.'),
        ],
      );
    }

    if (!status.authenticated || !status.discordConnected) {
      return ArcaneColumn(
        crossAxisAlignment: CrossAxisAlignment.center,
        style: const ArcaneStyleData(gap: Gap.lg, textAlign: TextAlign.center),
        children: <Component>[
          const ArcaneText.heading('Connect Discord'),
          const ArcaneText.body(
            'Connect your Discord account to begin linking your Bungie profile.',
          ),
          ArcaneButton.primary(
            label: 'Connect Discord',
            onPressed: _connectDiscord,
          ),
        ],
      );
    }

    return ArcaneColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      style: const ArcaneStyleData(gap: Gap.lg),
      children: <Component>[
        _discordConnectedModule(status),
        _bungieModule(status),
      ],
    );
  }

  Component _discordConnectedModule(LinkStatus status) {
    final LinkStatusDiscord discord =
        status.discord ??
        const LinkStatusDiscord(
          id: '',
          username: '',
          globalName: null,
          avatarUrl: null,
        );

    final String title = discord.globalName?.isNotEmpty == true
        ? discord.globalName!
        : discord.username;

    return ArcaneCard(
      child: ArcaneDiv(
        styles: const ArcaneStyleData(padding: PaddingPreset.lg),
        children: <Component>[
          ArcaneColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            style: const ArcaneStyleData(gap: Gap.sm),
            children: <Component>[
              const ArcaneText.heading2('Discord Connected'),
              ArcaneText.body('Name: $title'),
              ArcaneText.body('Username: ${discord.username}'),
              ArcaneText.body('Snowflake: ${discord.id}'),
              if (discord.avatarUrl != null)
                ArcaneText.body('Avatar: ${discord.avatarUrl}'),
            ],
          ),
        ],
      ),
    );
  }

  Component _bungieModule(LinkStatus status) {
    if (!status.bungieConnected) {
      return ArcaneLink(
        href: '/auth/bungie/start',
        styles: const ArcaneStyleData(
          textDecoration: TextDecoration.none,
          width: Size.full,
        ),
        child: ArcaneCard(
          child: ArcaneDiv(
            styles: const ArcaneStyleData(padding: PaddingPreset.lg),
            children: <Component>[
              ArcaneColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                style: const ArcaneStyleData(gap: Gap.sm),
                children: const <Component>[
                  ArcaneText.heading2('Connect Bungie Account'),
                  ArcaneText.body(
                    'Click this card to connect your Bungie account and finish linking.',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final List<Component> membershipRows = <Component>[];
    for (final LinkStatusMembership membership in status.memberships) {
      final String label =
          membership.displayName == null || membership.displayName!.isEmpty
          ? membership.membershipId
          : membership.displayName!;
      membershipRows.add(
        ArcaneText.body(
          '${membership.membershipType} • $label${membership.isPrimary ? ' (Primary)' : ''}',
        ),
      );
    }

    return ArcaneCard(
      child: ArcaneDiv(
        styles: const ArcaneStyleData(padding: PaddingPreset.lg),
        children: <Component>[
          ArcaneColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            style: const ArcaneStyleData(gap: Gap.sm),
            children: <Component>[
              const ArcaneText.heading2('Bungie Connected'),
              ArcaneText.body(
                'Memberships linked: ${status.memberships.length}',
              ),
              ...membershipRows,
              ArcaneButton.secondary(
                label: 'Re-connect Bungie',
                onPressed: _connectBungie,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
