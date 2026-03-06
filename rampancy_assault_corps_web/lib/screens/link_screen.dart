import 'package:arcane_jaspr/arcane_jaspr.dart';
import 'package:fast_log/fast_log.dart';
import 'package:rampancy_assault_corps_web/components/app_header.dart';
import 'package:rampancy_assault_corps_web/services/link_status_service.dart';
import 'package:rampancy_assault_corps_web/utils/constants.dart';
import 'package:web/web.dart' as web;

class LinkScreen extends StatefulComponent {
  final bool isDark;
  final VoidCallback? onThemeToggle;

  const LinkScreen({super.key, this.isDark = true, this.onThemeToggle});

  @override
  State<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  LinkStatus? _status;
  bool _loading = true;
  bool _logoutLoading = false;
  bool _deleteLoading = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _hydrateQueryState();
    _loadStatus();
  }

  void _hydrateQueryState() {
    String query = web.window.location.search;
    if (query.isEmpty) {
      return;
    }

    Uri parsed = Uri.parse('https://rampancy.space$query');
    String? errorCode = parsed.queryParameters['error'];
    String? linked = parsed.queryParameters['linked'];
    String? deleted = parsed.queryParameters['deleted'];

    if (errorCode != null && errorCode.isNotEmpty) {
      warn('link_oauth_error code=$errorCode');
      _error = _oauthErrorMessage(errorCode);
      _notice = null;
      return;
    }

    if (deleted == 'account') {
      _notice = 'Your linked account data has been deleted.';
      _error = null;
      return;
    }

    if (linked == 'bungie') {
      _notice = 'Bungie connected. Sign into Discord to finish linking.';
      _error = null;
      return;
    }

    if (linked == 'discord') {
      _notice = 'Discord connected. Both accounts are now linked.';
      _error = null;
    }
  }

  Future<void> _loadStatus() async {
    verbose('link_status_load_begin');
    setState(() {
      _loading = true;
    });

    LinkStatus status = await LinkStatusService.fetchStatus();
    setState(() {
      _status = status;
      _loading = false;
    });
    info(
      'link_status_load_done authenticated=${status.authenticated} bungieConnected=${status.bungieConnected} discordConnected=${status.discordConnected}',
    );
  }

  void _connectBungie() {
    String url = LinkStatusService.authUrl('/auth/bungie/start');
    info('link_connect_bungie_pressed url=$url');
    web.window.location.href = url;
  }

  void _connectDiscord() {
    String url = LinkStatusService.authUrl('/auth/discord/start');
    info('link_connect_discord_pressed url=$url');
    web.window.location.href = url;
  }

  Future<void> _logout() async {
    if (_logoutLoading) {
      return;
    }

    setState(() {
      _logoutLoading = true;
    });
    info('link_logout_pressed');

    try {
      await LinkStatusService.logout();
      await _loadStatus();
      setState(() {
        _notice = 'You have been logged out.';
      });
      info('link_logout_complete');
    } catch (e) {
      error('link_logout_failed err=$e');
      setState(() {
        _error = 'Unable to log out right now.';
      });
    } finally {
      setState(() {
        _logoutLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    if (_deleteLoading) {
      return;
    }

    setState(() {
      _deleteLoading = true;
    });
    info('link_delete_pressed');

    try {
      await LinkStatusService.deleteAccount();
      web.window.location.href = '${AppRoutes.link}?deleted=account';
    } catch (e) {
      error('link_delete_failed err=$e');
      setState(() {
        _error = 'Unable to delete your account right now.';
      });
    } finally {
      setState(() {
        _deleteLoading = false;
      });
    }
  }

  String _oauthErrorMessage(String code) => switch (code) {
    'bungie_provider_error' =>
      'Bungie sign-in was canceled or rejected. Please try again.',
    'bungie_callback_invalid' =>
      'Bungie sign-in did not return a valid authorization code.',
    'bungie_state_invalid' =>
      'Bungie sign-in session expired or was invalid. Please try again.',
    'bungie_link_failed' =>
      'Bungie sign-in failed while saving your connection. Please try again.',
    'discord_provider_error' =>
      'Discord sign-in was canceled or rejected. Please try again.',
    'discord_callback_invalid' =>
      'Discord sign-in did not return a valid authorization code.',
    'discord_state_invalid' =>
      'Discord sign-in session expired or was invalid. Please try again.',
    'discord_link_failed' =>
      'Discord sign-in failed while saving your connection. Please try again.',
    'discord_requires_bungie' =>
      'Please sign in with Bungie before connecting Discord.',
    _ => 'Sign-in failed. Please retry.',
  };

  @override
  Component build(BuildContext context) {
    LinkStatus status = _status ?? LinkStatus.fallback;
    bool authenticated = status.authenticated;

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
          showLogout: authenticated,
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
              children: <Component>[
                ArcaneColumn(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  style: const ArcaneStyleData(gap: Gap.lg),
                  children: <Component>[
                    const ArcaneColumn(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      style: ArcaneStyleData(gap: Gap.sm),
                      children: <Component>[
                        ArcaneText.heading('Account Linking'),
                        ArcaneText.body(
                          'Sign in with Bungie first, connect Discord second, and manage both links here.',
                        ),
                      ],
                    ),
                    if (_notice != null)
                      ArcaneAlert.success(
                        title: 'Status Updated',
                        message: _notice,
                      ),
                    if (_error != null)
                      ArcaneAlert.error(
                        title: 'Action Failed',
                        message: _error,
                      ),
                    if (_loading)
                      const ArcaneCard(
                        child: ArcaneDiv(
                          styles: ArcaneStyleData(padding: PaddingPreset.lg),
                          children: <Component>[
                            ArcaneColumn(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              style: ArcaneStyleData(gap: Gap.sm),
                              children: <Component>[
                                ArcaneText.heading2('Loading'),
                                ArcaneText.body(
                                  'Checking your current account-link status.',
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      _LinkContent(
                        status: status,
                        onConnectBungie: _connectBungie,
                        onConnectDiscord: _connectDiscord,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
        if (authenticated)
          ArcaneDiv(
            styles: const ArcaneStyleData(
              position: Position.fixed,
              right: '24px',
              bottom: '24px',
              zIndexCustom: '40',
            ),
            children: <Component>[
              ArcaneButton.destructive(
                label: _deleteLoading ? 'Deleting...' : 'Delete Account',
                icon: ArcaneIcon.trash2(size: IconSize.sm),
                onPressed: _deleteLoading ? null : _deleteAccount,
              ),
            ],
          ),
      ],
    );
  }
}

class _LinkContent extends StatelessComponent {
  final LinkStatus status;
  final VoidCallback onConnectBungie;
  final VoidCallback onConnectDiscord;

  const _LinkContent({
    required this.status,
    required this.onConnectBungie,
    required this.onConnectDiscord,
  });

  @override
  Component build(BuildContext context) {
    if (!status.featureEnabled) {
      return const ArcaneAlert.warning(
        title: 'Linking Unavailable',
        message: 'This feature is currently disabled.',
      );
    }

    if (!status.authenticated || !status.bungieConnected) {
      return _StepCard(
        badge: 'Step 1 of 2',
        title: 'Please Sign In With Bungie',
        body:
            'We use your Bungie ID to create your Firebase account-link record before anything else gets connected.',
        buttonLabel: 'Sign Into Bungie',
        onPressed: onConnectBungie,
      );
    }

    if (!status.discordConnected) {
      return ArcaneColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        style: const ArcaneStyleData(gap: Gap.lg),
        children: <Component>[
          _BungieCard(status: status, onReconnect: onConnectBungie),
          _StepCard(
            badge: 'Step 2 of 2',
            title: 'Connect Discord',
            body:
                'Your Discord OAuth2 account ID will be stored in the same Firebase record as your Bungie ID.',
            buttonLabel: 'Connect Discord',
            onPressed: onConnectDiscord,
          ),
        ],
      );
    }

    return ArcaneColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      style: const ArcaneStyleData(gap: Gap.lg),
      children: <Component>[
        const ArcaneAlert.success(
          title: 'Accounts Linked',
          message: 'Your Bungie and Discord accounts are both connected.',
        ),
        _BungieCard(status: status, onReconnect: onConnectBungie),
        _DiscordCard(status: status, onReconnect: onConnectDiscord),
      ],
    );
  }
}

class _StepCard extends StatelessComponent {
  final String badge;
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _StepCard({
    required this.badge,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Component build(BuildContext context) {
    return ArcaneCard(
      child: ArcaneDiv(
        styles: const ArcaneStyleData(padding: PaddingPreset.lg),
        children: <Component>[
          ArcaneColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            style: const ArcaneStyleData(gap: Gap.md),
            children: <Component>[
              ArcaneStatusBadge.info(badge),
              ArcaneText.heading2(title),
              ArcaneText.body(body),
              ArcaneButton.primary(label: buttonLabel, onPressed: onPressed),
            ],
          ),
        ],
      ),
    );
  }
}

class _BungieCard extends StatelessComponent {
  final LinkStatus status;
  final VoidCallback onReconnect;

  const _BungieCard({required this.status, required this.onReconnect});

  @override
  Component build(BuildContext context) {
    List<Component> membershipRows = <Component>[];
    for (LinkStatusMembership membership in status.memberships) {
      String label =
          membership.displayName == null || membership.displayName!.isEmpty
          ? membership.membershipId
          : membership.displayName!;
      membershipRows.add(
        ArcaneText.body(
          '${membership.membershipType} • $label${membership.isPrimary ? ' (Primary)' : ''}',
        ),
      );
    }

    String bungieId = status.bungiePrimaryMembershipId ?? 'Unavailable';
    String membershipType =
        status.bungiePrimaryMembershipType?.toString() ?? '-';

    return ArcaneCard(
      child: ArcaneDiv(
        styles: const ArcaneStyleData(padding: PaddingPreset.lg),
        children: <Component>[
          ArcaneColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            style: const ArcaneStyleData(gap: Gap.md),
            children: <Component>[
              const ArcaneStatusBadge.success('Bungie Linked'),
              const ArcaneText.heading2('Bungie'),
              ArcaneText.body('Bungie ID: $bungieId'),
              ArcaneText.body('Primary Membership Type: $membershipType'),
              ArcaneText.body(
                'Stored memberships: ${status.memberships.length}',
              ),
              ...membershipRows,
              ArcaneButton.secondary(
                label: 'Reconnect Bungie',
                onPressed: onReconnect,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscordCard extends StatelessComponent {
  final LinkStatus status;
  final VoidCallback onReconnect;

  const _DiscordCard({required this.status, required this.onReconnect});

  @override
  Component build(BuildContext context) {
    LinkStatusDiscord discord =
        status.discord ??
        const LinkStatusDiscord(
          id: '',
          username: '',
          globalName: null,
          avatarUrl: null,
        );

    String displayName = discord.globalName?.isNotEmpty == true
        ? discord.globalName!
        : discord.username;

    List<Component> rows = <Component>[
      const ArcaneStatusBadge.success('Discord Linked'),
      const ArcaneText.heading2('Discord'),
      ArcaneText.body('Display Name: $displayName'),
      ArcaneText.body('Username: ${discord.username}'),
      ArcaneText.body('Discord ID: ${discord.id}'),
    ];
    if (discord.avatarUrl != null && discord.avatarUrl!.isNotEmpty) {
      rows.add(ArcaneText.body('Avatar URL: ${discord.avatarUrl}'));
    }
    rows.add(
      ArcaneButton.secondary(
        label: 'Reconnect Discord',
        onPressed: onReconnect,
      ),
    );

    return ArcaneCard(
      child: ArcaneDiv(
        styles: const ArcaneStyleData(padding: PaddingPreset.lg),
        children: <Component>[
          ArcaneColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            style: const ArcaneStyleData(gap: Gap.md),
            children: rows,
          ),
        ],
      ),
    );
  }
}
