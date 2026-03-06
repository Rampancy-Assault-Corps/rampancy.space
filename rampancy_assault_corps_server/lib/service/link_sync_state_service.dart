import 'dart:math';

import 'package:fast_log/fast_log.dart';
import 'package:fire_api/fire_api.dart';
import 'package:rampancy_assault_corps_models/rampancy_assault_corps_models.dart';

class LinkSyncStateService {
  final Random _random;

  LinkSyncStateService({Random? random}) : _random = random ?? Random.secure();

  Future<void> recordAccountLinkStateChange({
    required String accountLinkId,
    required AccountLink? previous,
    required AccountLink? next,
  }) async {
    String? previousDiscordId = _discordId(previous);
    String? discordId = _discordId(next);
    bool previousBungieConnected = previous?.bungieConnected ?? false;
    bool bungieConnected = next?.bungieConnected ?? false;
    bool previousRunnerEligible = _runnerEligible(previous);
    bool runnerEligible = _runnerEligible(next);
    if (!_hasRelevantStateChange(
      previousDiscordId: previousDiscordId,
      discordId: discordId,
      previousBungieConnected: previousBungieConnected,
      bungieConnected: bungieConnected,
      previousRunnerEligible: previousRunnerEligible,
      runnerEligible: runnerEligible,
    )) {
      verbose('link_sync_event_skip accountLinkId=$accountLinkId');
      return;
    }

    int updatedAt = DateTime.now().millisecondsSinceEpoch;
    int sequence =
        (DateTime.now().microsecondsSinceEpoch * 1000) + _random.nextInt(1000);
    DocumentReference eventDocument = FirestoreDatabase.instance
        .collection('link_sync_events')
        .doc('$sequence-$accountLinkId');
    DocumentReference stateDocument = FirestoreDatabase.instance.document(
      'link_sync_state/current',
    );

    await eventDocument.set(<String, dynamic>{
      'accountLinkId': accountLinkId,
      'sequence': sequence,
      'updatedAt': updatedAt,
      'previousDiscordId': previousDiscordId,
      'discordId': discordId,
      'previousBungieConnected': previousBungieConnected,
      'bungieConnected': bungieConnected,
      'previousRunnerEligible': previousRunnerEligible,
      'runnerEligible': runnerEligible,
    });
    await stateDocument.set(<String, dynamic>{
      'accountLinkId': accountLinkId,
      'latestSequence': sequence,
      'updatedAt': updatedAt,
    });
    info(
      'link_sync_event_recorded accountLinkId=$accountLinkId sequence=$sequence previousRunnerEligible=$previousRunnerEligible runnerEligible=$runnerEligible previousDiscordId=$previousDiscordId discordId=$discordId',
    );
  }

  bool _hasRelevantStateChange({
    required String? previousDiscordId,
    required String? discordId,
    required bool previousBungieConnected,
    required bool bungieConnected,
    required bool previousRunnerEligible,
    required bool runnerEligible,
  }) {
    if (previousDiscordId != discordId) {
      return true;
    }
    if (previousBungieConnected != bungieConnected) {
      return true;
    }
    if (previousRunnerEligible != runnerEligible) {
      return true;
    }
    return false;
  }

  bool _runnerEligible(AccountLink? link) {
    String? discordId = _discordId(link);
    return (link?.bungieConnected ?? false) &&
        discordId != null &&
        discordId.isNotEmpty;
  }

  String? _discordId(AccountLink? link) {
    String? discordId = link?.discordId;
    if (discordId == null || discordId.isEmpty) {
      return null;
    }
    return discordId;
  }
}
