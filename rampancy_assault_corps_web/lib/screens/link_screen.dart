import 'dart:async';

import 'package:arcane_jaspr/arcane_jaspr.dart';
import 'package:fast_log/fast_log.dart';
import 'package:rampancy_assault_corps_web/components/rac_shell.dart';
import 'package:rampancy_assault_corps_web/services/link_status_service.dart';
import 'package:rampancy_assault_corps_web/utils/constants.dart';
import 'package:web/web.dart' as web;

enum _LinkStage { loading, unavailable, locked, bungieReady, fullyLinked }

class LinkScreen extends StatefulComponent {
  final bool isDark;
  final VoidCallback? onThemeToggle;

  const LinkScreen({super.key, this.isDark = true, this.onThemeToggle});

  @override
  State<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  static const int _statusRetryLimit = 3;
  static const String _resumeStorageKey = 'rac_link_resume';
  static const Duration _loadingStageLimit = Duration(seconds: 2);

  LinkStatus? _status;
  bool _loading = true;
  bool _logoutLoading = false;
  bool _deleteLoading = false;
  String? _error;
  String? _notice;
  String? _recentlyLinkedProvider;
  String? _resumeToken;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _hydrateQueryState();
    _startLoadingTimer();
    _loadStatus();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _hydrateQueryState() {
    String query = web.window.location.search;
    String hash = web.window.location.hash;
    _resumeToken =
        _extractResumeToken(query: query, hash: hash) ?? _storedResumeToken();
    if (_resumeToken != null && _resumeToken!.isNotEmpty) {
      _storeResumeToken(_resumeToken!);
    }
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
      _clearResumeToken();
      _notice = 'ACCOUNT DATA DELETED';
      _error = null;
      return;
    }

    if (linked == 'bungie') {
      _recentlyLinkedProvider = 'bungie';
      _notice = 'BUNGIE CONNECTED. DISCORD IS NOW UNLOCKED.';
      _error = null;
      return;
    }

    if (linked == 'discord') {
      _recentlyLinkedProvider = 'discord';
      _notice = 'DISCORD CONNECTED. ACCOUNT LINK COMPLETE.';
      _error = null;
    }
  }

  Future<void> _loadStatus({int attempt = 0}) async {
    verbose('link_status_load_begin attempt=$attempt');
    bool optimisticLinked =
        _hasOptimisticBungieLink || _hasOptimisticDiscordLink;
    if (attempt == 0 && mounted) {
      setState(() {
        _loading = !optimisticLinked;
      });
    }

    LinkStatus status = await LinkStatusService.fetchStatus(
      resumeToken: _resumeToken,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _status = status;
      _loading = false;
    });
    _loadingTimer?.cancel();
    info(
      'link_status_load_done authenticated=${status.authenticated} bungieConnected=${status.bungieConnected} discordConnected=${status.discordConnected}',
    );

    if (_shouldRetryStatus(status, attempt)) {
      int delayMs = 250 * (attempt + 1);
      warn(
        'link_status_load_retry_scheduled attempt=$attempt delayMs=$delayMs provider=$_recentlyLinkedProvider',
      );
      await Future<void>.delayed(Duration(milliseconds: delayMs));
      if (!mounted) {
        return;
      }
      await _loadStatus(attempt: attempt + 1);
    }
  }

  void _startLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = Timer(_loadingStageLimit, () {
      if (!mounted || !_loading) {
        return;
      }
      warn('link_status_loading_timeout_reached');
      setState(() {
        _loading = false;
      });
    });
  }

  void _connectBungie() {
    String url = LinkStatusService.authUrl(
      '/auth/bungie/start',
      resumeToken: _resumeToken,
    );
    info('link_connect_bungie_pressed url=$url');
    web.window.location.href = url;
  }

  void _connectDiscord() {
    String url = LinkStatusService.authUrl(
      '/auth/discord/start',
      resumeToken: _resumeToken,
    );
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
      _clearResumeToken();
      await _loadStatus();
      setState(() {
        _notice = 'SESSION CLEARED';
        _error = null;
      });
      info('link_logout_complete');
    } catch (e) {
      error('link_logout_failed err=$e');
      setState(() {
        _error = 'UNABLE TO LOG OUT RIGHT NOW';
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

    bool confirmed = web.window.confirm('DELETE YOUR LINKED ACCOUNT DATA?');
    if (!confirmed) {
      return;
    }

    setState(() {
      _deleteLoading = true;
    });
    info('link_delete_pressed');

    try {
      await LinkStatusService.deleteAccount(resumeToken: _resumeToken);
      _clearResumeToken();
      web.window.location.href = '${AppRoutes.link}?deleted=account';
    } catch (e) {
      error('link_delete_failed err=$e');
      setState(() {
        _error = 'UNABLE TO DELETE ACCOUNT RIGHT NOW';
      });
    } finally {
      setState(() {
        _deleteLoading = false;
      });
    }
  }

  String _oauthErrorMessage(String code) => switch (code) {
    'bungie_not_configured' =>
      'BUNGIE SIGN-IN IS CURRENTLY UNAVAILABLE. PLEASE TRY AGAIN LATER.',
    'bungie_provider_error' =>
      'BUNGIE SIGN-IN WAS CANCELED OR REJECTED. RETRY TO CONTINUE.',
    'bungie_callback_invalid' =>
      'BUNGIE DID NOT RETURN A VALID AUTHORIZATION CODE.',
    'bungie_state_invalid' => 'BUNGIE SIGN-IN SESSION EXPIRED. START AGAIN.',
    'bungie_link_failed' =>
      'BUNGIE SIGN-IN FAILED WHILE SAVING YOUR CONNECTION.',
    'discord_not_configured' =>
      'DISCORD SIGN-IN IS CURRENTLY UNAVAILABLE. PLEASE TRY AGAIN LATER.',
    'discord_provider_error' =>
      'DISCORD SIGN-IN WAS CANCELED OR REJECTED. RETRY TO CONTINUE.',
    'discord_callback_invalid' =>
      'DISCORD DID NOT RETURN A VALID AUTHORIZATION CODE.',
    'discord_state_invalid' => 'DISCORD SIGN-IN SESSION EXPIRED. START AGAIN.',
    'discord_link_failed' =>
      'DISCORD SIGN-IN FAILED WHILE SAVING YOUR CONNECTION.',
    'discord_requires_bungie' =>
      'BUNGIE MUST BE LINKED BEFORE DISCORD CAN UNLOCK.',
    _ => 'SIGN-IN FAILED. RETRY TO CONTINUE.',
  };

  @override
  Component build(BuildContext context) {
    LinkStatus status = _status ?? LinkStatus.fallback;
    bool bungieConnected = status.bungieConnected || _hasOptimisticBungieLink;
    bool discordConnected =
        status.discordConnected || _hasOptimisticDiscordLink;
    bool showLoading = _loading && !bungieConnected && !discordConnected;

    _LinkStage stage = showLoading
        ? _LinkStage.loading
        : !status.featureEnabled
        ? _LinkStage.unavailable
        : !bungieConnected
        ? _LinkStage.locked
        : !discordConnected
        ? _LinkStage.bungieReady
        : _LinkStage.fullyLinked;

    List<Component> preludeChildren = <Component>[];
    if (_notice != null) {
      preludeChildren.add(
        RacSignalBanner(message: _notice!, tone: RacSignalTone.success),
      );
    }
    if (_error != null) {
      preludeChildren.add(
        RacSignalBanner(message: _error!, tone: RacSignalTone.error),
      );
    }

    bool canDelete =
        status.authenticated ||
        (_resumeToken != null && _resumeToken!.isNotEmpty);

    List<Component> utilityChildren = <Component>[
      if (status.sessionAuthenticated)
        RacActionButton(
          label: _logoutLoading ? 'LOGGING OUT...' : 'LOG OUT',
          onPressed: _logoutLoading ? null : _logout,
          disabled: _logoutLoading,
          tone: RacActionTone.muted,
        ),
      if (canDelete)
        RacIconButton(
          icon: ArcaneIcon.trash(size: IconSize.md),
          label: _deleteLoading ? 'DELETING LINKED DATA' : 'DELETE LINKED DATA',
          onPressed: _deleteLoading ? null : _deleteAccount,
          disabled: _deleteLoading,
          tone: RacActionTone.destructive,
          className: 'rac-utility__delete',
        ),
    ];

    return RacShell(
      pageClassName: 'rac-shell--link',
      headerContextLabel: 'ACCOUNT LINK',
      preludeChildren: preludeChildren,
      utilityChildren: utilityChildren,
      mainChild: _LinkStageSurface(
        stage: stage,
        status: status,
        bungieConnected: bungieConnected,
        discordConnected: discordConnected,
        onConnectBungie: _connectBungie,
        onConnectDiscord: _connectDiscord,
      ),
    );
  }

  bool get _hasOptimisticBungieLink =>
      _recentlyLinkedProvider == 'bungie' ||
      _recentlyLinkedProvider == 'discord';

  bool get _hasOptimisticDiscordLink => _recentlyLinkedProvider == 'discord';

  bool _shouldRetryStatus(LinkStatus status, int attempt) {
    if (attempt >= _statusRetryLimit) {
      return false;
    }

    if (_recentlyLinkedProvider == 'bungie') {
      return !status.authenticated || !status.bungieConnected;
    }

    if (_recentlyLinkedProvider == 'discord') {
      return !status.authenticated ||
          !status.bungieConnected ||
          !status.discordConnected;
    }

    return false;
  }

  String? _extractResumeToken({required String query, required String hash}) {
    if (hash.isNotEmpty) {
      Uri parsedHash = Uri.parse('https://rampancy.space/$hash');
      String? hashToken = parsedHash.fragment.isNotEmpty
          ? Uri.splitQueryString(parsedHash.fragment)['resume']
          : null;
      if (hashToken != null && hashToken.isNotEmpty) {
        return hashToken;
      }
    }

    if (query.isEmpty) {
      return null;
    }

    Uri parsedQuery = Uri.parse('https://rampancy.space$query');
    String? queryToken = parsedQuery.queryParameters['resume'];
    if (queryToken != null && queryToken.isNotEmpty) {
      return queryToken;
    }

    return null;
  }

  String? _storedResumeToken() {
    String? token = web.window.sessionStorage.getItem(_resumeStorageKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  void _storeResumeToken(String token) {
    web.window.sessionStorage.setItem(_resumeStorageKey, token);
  }

  void _clearResumeToken() {
    _resumeToken = null;
    web.window.sessionStorage.removeItem(_resumeStorageKey);
  }
}

class _LinkStageSurface extends StatelessComponent {
  final _LinkStage stage;
  final LinkStatus status;
  final bool bungieConnected;
  final bool discordConnected;
  final VoidCallback onConnectBungie;
  final VoidCallback onConnectDiscord;

  const _LinkStageSurface({
    required this.stage,
    required this.status,
    required this.bungieConnected,
    required this.discordConnected,
    required this.onConnectBungie,
    required this.onConnectDiscord,
  });

  @override
  Component build(BuildContext context) {
    return div([
      div([
        _BungiePanel(
          stage: stage,
          status: status,
          bungieConnected: bungieConnected,
          onConnectBungie: onConnectBungie,
        ),
        _DiscordPanel(
          stage: stage,
          status: status,
          discordConnected: discordConnected,
          onConnectDiscord: onConnectDiscord,
        ),
      ], classes: 'rac-panel-stack'),
    ], classes: 'rac-main rac-main--split');
  }
}

class _BungiePanel extends StatelessComponent {
  final _LinkStage stage;
  final LinkStatus status;
  final bool bungieConnected;
  final VoidCallback onConnectBungie;

  const _BungiePanel({
    required this.stage,
    required this.status,
    required this.bungieConnected,
    required this.onConnectBungie,
  });

  @override
  Component build(BuildContext context) {
    if (stage == _LinkStage.unavailable) {
      return const _LinkRailPanel(
        railLabel: 'BUNGIE',
        stateLabel: 'UNAVAILABLE',
        child: _CenteredCopyBlock(
          title: 'BUNGIE SIGN-IN UNAVAILABLE',
          detail: 'ACCOUNT LINKING IS CURRENTLY UNAVAILABLE.',
          action: RacActionButton(
            label: 'RETURN HOME',
            href: AppRoutes.home,
            tone: RacActionTone.muted,
          ),
        ),
      );
    }

    if (stage == _LinkStage.locked || stage == _LinkStage.loading) {
      String title = stage == _LinkStage.loading
          ? 'SYNCING LINK STATUS'
          : 'LOGIN WITH BUNGIE';
      String detail = stage == _LinkStage.loading
          ? 'CHECKING FOR AN EXISTING BUNGIE LINK.'
          : 'STORE YOUR BUNGIE ID FIRST TO UNLOCK DISCORD.';
      Component? action = stage == _LinkStage.loading
          ? null
          : RacActionButton(
              label: 'LOGIN WITH BUNGIE',
              onPressed: onConnectBungie,
            );

      return _LinkRailPanel(
        railLabel: 'BUNGIE',
        stateLabel: stage == _LinkStage.loading ? 'SYNCING' : 'REQUIRED',
        child: _CenteredCopyBlock(title: title, detail: detail, action: action),
      );
    }

    return _LinkRailPanel(
      railLabel: 'BUNGIE',
      stateLabel: 'CONNECTED',
      child: _IdentityBlock(
        badge: 'BUNGIE CONNECTED',
        title: status.bungieDisplayName,
        detailLines: status.bungieMetaLines,
        avatarUrl: status.bungieAvatarUrl,
        action: RacActionButton(
          label: bungieConnected ? 'REFRESH BUNGIE' : 'LOGIN WITH BUNGIE',
          onPressed: onConnectBungie,
          tone: RacActionTone.muted,
        ),
      ),
    );
  }
}

class _DiscordPanel extends StatelessComponent {
  final _LinkStage stage;
  final LinkStatus status;
  final bool discordConnected;
  final VoidCallback onConnectDiscord;

  const _DiscordPanel({
    required this.stage,
    required this.status,
    required this.discordConnected,
    required this.onConnectDiscord,
  });

  @override
  Component build(BuildContext context) {
    if (stage == _LinkStage.unavailable) {
      return const _LinkRailPanel(
        railLabel: 'DISCORD',
        stateLabel: 'UNAVAILABLE',
        disabled: true,
        child: _CenteredCopyBlock(
          title: 'DISCORD SIGN-IN UNAVAILABLE',
          detail: 'ACCOUNT LINKING IS CURRENTLY UNAVAILABLE.',
        ),
      );
    }

    if (stage == _LinkStage.loading || stage == _LinkStage.locked) {
      String title = stage == _LinkStage.loading
          ? 'DISCORD STANDBY'
          : 'DISCORD LOCKED';
      String detail = stage == _LinkStage.loading
          ? 'WAITING FOR BUNGIE STATUS BEFORE DISCORD CAN ARM.'
          : 'DISCORD UNLOCKS AFTER YOUR BUNGIE LINK IS STORED.';

      return _LinkRailPanel(
        railLabel: 'DISCORD',
        stateLabel: 'LOCKED',
        disabled: true,
        child: _CenteredCopyBlock(title: title, detail: detail),
      );
    }

    if (stage == _LinkStage.bungieReady) {
      return _LinkRailPanel(
        railLabel: 'DISCORD',
        stateLabel: 'UNLOCKED',
        child: _CenteredCopyBlock(
          title: 'CONNECT DISCORD',
          detail:
              'YOUR BUNGIE PROFILE IS STORED. COMPLETE THE SECOND STEP TO FINISH ACCOUNT LINKING.',
          action: RacActionButton(
            label: 'LOGIN WITH DISCORD',
            onPressed: onConnectDiscord,
          ),
        ),
      );
    }

    return _LinkRailPanel(
      railLabel: 'DISCORD',
      stateLabel: 'CONNECTED',
      child: _IdentityBlock(
        badge: 'DISCORD CONNECTED',
        title: status.discordDisplayName,
        detailLines: status.discordMetaLines,
        avatarUrl: status.discordAvatarUrl,
        action: RacActionButton(
          label: discordConnected ? 'REFRESH DISCORD' : 'LOGIN WITH DISCORD',
          onPressed: onConnectDiscord,
          tone: RacActionTone.muted,
        ),
      ),
    );
  }
}

class _LinkRailPanel extends StatelessComponent {
  final String railLabel;
  final String stateLabel;
  final bool disabled;
  final Component child;

  const _LinkRailPanel({
    required this.railLabel,
    required this.stateLabel,
    required this.child,
    this.disabled = false,
  });

  @override
  Component build(BuildContext context) {
    String classes = 'rac-panel';
    if (disabled) {
      classes = '$classes rac-panel--disabled';
    }

    return div([
      div([Component.text(railLabel)], classes: 'rac-panel__rail'),
      div([Component.text(stateLabel)], classes: 'rac-panel__state'),
      div([child], classes: 'rac-panel__content'),
    ], classes: classes);
  }
}

class _CenteredCopyBlock extends StatelessComponent {
  final String title;
  final String detail;
  final Component? action;

  const _CenteredCopyBlock({
    required this.title,
    required this.detail,
    this.action,
  });

  @override
  Component build(BuildContext context) {
    List<Component> children = <Component>[
      div([Component.text(title)], classes: 'rac-copy__title'),
      div([Component.text(detail)], classes: 'rac-copy__detail'),
    ];

    if (action != null) {
      children.add(div([action!], classes: 'rac-copy__action'));
    }

    return div(children, classes: 'rac-copy');
  }
}

class _IdentityBlock extends StatelessComponent {
  final String badge;
  final String title;
  final List<String> detailLines;
  final String? avatarUrl;
  final Component action;

  const _IdentityBlock({
    required this.badge,
    required this.title,
    required this.detailLines,
    required this.avatarUrl,
    required this.action,
  });

  @override
  Component build(BuildContext context) {
    List<Component> detailChildren = <Component>[];
    for (String line in detailLines) {
      detailChildren.add(
        div([Component.text(line)], classes: 'rac-identity__detail'),
      );
    }

    return div([
      div([
        if (avatarUrl != null && avatarUrl!.isNotEmpty)
          img(src: avatarUrl!, alt: title, classes: 'rac-identity__avatar')
        else
          const div(
            [],
            classes: 'rac-identity__avatar rac-identity__avatar--blank',
          ),
      ], classes: 'rac-identity__avatar-frame'),
      div([Component.text(badge)], classes: 'rac-identity__badge'),
      div([Component.text(title)], classes: 'rac-identity__title'),
      div(detailChildren, classes: 'rac-identity__details'),
      div([action], classes: 'rac-identity__action'),
    ], classes: 'rac-identity');
  }
}

extension _LinkStatusPresentation on LinkStatus {
  LinkStatusMembership? get primaryMembership {
    for (LinkStatusMembership membership in memberships) {
      if (membership.isPrimary) {
        return membership;
      }
    }

    if (memberships.isEmpty) {
      return null;
    }

    return memberships.first;
  }

  String get bungieDisplayName {
    LinkStatusMembership? membership = primaryMembership;
    String? displayName = membership?.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    String? membershipId = bungiePrimaryMembershipId;
    if (membershipId != null && membershipId.isNotEmpty) {
      return membershipId;
    }

    return 'BUNGIE ACCOUNT';
  }

  String? get bungieAvatarUrl {
    LinkStatusMembership? membership = primaryMembership;
    String? iconPath = membership?.iconPath;
    if (iconPath == null || iconPath.isEmpty) {
      return null;
    }

    if (iconPath.startsWith('http')) {
      return iconPath;
    }

    return 'https://www.bungie.net$iconPath';
  }

  List<String> get bungieMetaLines {
    List<String> lines = <String>[];
    String? membershipId = bungiePrimaryMembershipId;
    int? membershipType = bungiePrimaryMembershipType;
    if (membershipId != null && membershipId.isNotEmpty) {
      lines.add('ID $membershipId');
    }
    if (membershipType != null) {
      lines.add('TYPE $membershipType');
    }
    if (memberships.isNotEmpty) {
      String suffix = memberships.length == 1 ? '' : 'S';
      lines.add('${memberships.length} MEMBERSHIP$suffix STORED');
    }
    if (lines.isEmpty) {
      lines.add('BUNGIE ACCOUNT READY');
    }
    return lines;
  }

  String get discordDisplayName {
    LinkStatusDiscord? linkedDiscord = discord;
    if (linkedDiscord == null) {
      return 'DISCORD USER';
    }

    String? globalName = linkedDiscord.globalName;
    if (globalName != null && globalName.isNotEmpty) {
      return globalName;
    }

    if (linkedDiscord.username.isNotEmpty) {
      return linkedDiscord.username;
    }

    return 'DISCORD USER';
  }

  String? get discordAvatarUrl {
    LinkStatusDiscord? linkedDiscord = discord;
    if (linkedDiscord == null) {
      return null;
    }

    String? avatar = linkedDiscord.avatarUrl;
    if (avatar == null || avatar.isEmpty) {
      return null;
    }

    return avatar;
  }

  List<String> get discordMetaLines {
    List<String> lines = <String>[];
    LinkStatusDiscord? linkedDiscord = discord;
    if (linkedDiscord == null) {
      return <String>['DISCORD LINK READY'];
    }

    if (linkedDiscord.username.isNotEmpty) {
      lines.add('@${linkedDiscord.username}');
    }
    if (linkedDiscord.id.isNotEmpty) {
      lines.add('ID ${linkedDiscord.id}');
    }
    if (lines.isEmpty) {
      lines.add('DISCORD LINKED');
    }
    return lines;
  }
}
