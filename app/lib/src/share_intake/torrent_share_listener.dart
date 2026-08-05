import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:core_models/core_models.dart';
import 'package:core_profile/core_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_deluge/service_deluge.dart';
import 'package:service_qbittorrent/service_qbittorrent.dart';
import 'package:service_rtorrent/service_rtorrent.dart';
import 'package:service_transmission/service_transmission.dart';

import '../router.dart';
import 'share_intake.dart';
import 'torrent_share.dart';

/// The instances a shared torrent can be sent to.
///
/// Narrower than the downloader role: SABnzbd and NZBGet are downloaders too
/// but can do nothing with a torrent.
List<Instance> torrentTargets(List<Instance> instances) => instances
    .where((Instance i) => i.kind.acceptsTorrents)
    .toList(growable: false);

/// Watches for torrents shared from other apps and puts them in front of the
/// user.
///
/// Mounted in `MaterialApp.builder`, above the router, so it survives every
/// navigation. That is also why it presents through [rootNavigatorKey] rather
/// than its own context: its context sits above the Navigator and cannot push
/// routes itself.
class TorrentShareListener extends ConsumerStatefulWidget {
  const TorrentShareListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<TorrentShareListener> createState() =>
      _TorrentShareListenerState();
}

class _TorrentShareListenerState extends ConsumerState<TorrentShareListener> {
  StreamSubscription<TorrentShare>? _subscription;

  /// Torrents waiting their turn.
  ///
  /// Handling one occupies the screen until its sheet closes, so anything
  /// shared in the meantime has to wait rather than stack a second picker on
  /// top of the first. They queue instead of being dropped: sharing three
  /// torrents in a row should add three torrents, and silently discarding the
  /// last two would look identical to the app being broken.
  final Queue<TorrentShare> _pending = Queue<TorrentShare>();

  /// Bounds the queue so a misbehaving sender cannot grow it without limit.
  static const int _maxPending = 20;

  bool _draining = false;

  @override
  void initState() {
    super.initState();
    final ShareIntake intake = ref.read(shareIntakeProvider);
    _subscription = intake.shares.listen(_enqueue);
    // Deferred a frame so the router has built and has a context to present
    // from. This is the cold-start path: Atrium was launched by the share.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final TorrentShare? initial = await intake.initialShare();
      if (initial != null) {
        _enqueue(initial);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pending.clear();
    super.dispose();
  }

  void _enqueue(TorrentShare share) {
    if (_pending.length >= _maxPending) {
      return;
    }
    _pending.add(share);
    unawaited(_drain());
  }

  /// Works through the queue one torrent at a time, so each gets the user's
  /// full attention and its own sheet.
  Future<void> _drain() async {
    if (_draining) {
      return;
    }
    _draining = true;
    try {
      while (_pending.isNotEmpty && mounted) {
        await _handle(_pending.removeFirst());
      }
    } finally {
      _draining = false;
    }
  }

  BuildContext? get _presentContext {
    final BuildContext? context = rootNavigatorKey.currentContext;
    return context != null && context.mounted ? context : null;
  }

  /// Puts a single torrent in front of the user. Called only from [_drain],
  /// which serialises them.
  Future<void> _handle(TorrentShare share) async {
    if (share is TorrentShareProblem) {
      await _tell(share.message);
      return;
    }

    // Profiles load from Hive asynchronously. Reading the instance list
    // before that settles would report "no torrent client" on every cold
    // start, which is exactly when a share arrives.
    try {
      await ref.read(profileListProvider.future);
    } catch (_) {
      await _tell(
        'Atrium could not read your saved profiles, so it does not know '
        'where to send this torrent.',
      );
      return;
    }
    if (!mounted) {
      return;
    }

    final List<Instance> targets =
        torrentTargets(ref.read(activeInstancesProvider));
    if (targets.isEmpty) {
      await _tell(
        'No torrent client is set up in Atrium yet. Add qBittorrent, '
        'Deluge, Transmission or rTorrent, then share this again.',
      );
      return;
    }

    final Instance? target =
        targets.length == 1 ? targets.single : await _pickTarget(targets);
    if (target == null) {
      return;
    }
    await _openAddSheet(target, share);
  }

  Future<void> _tell(String message) async {
    final BuildContext? context = _presentContext;
    if (context == null) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Nothing added'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<Instance?> _pickTarget(List<Instance> targets) async {
    final BuildContext? context = _presentContext;
    if (context == null) {
      return null;
    }
    return showModalBottomSheet<Instance>(
      context: context,
      // showModalBottomSheet does not default to the root navigator the way
      // showDialog does, and this is presented from outside the shell.
      useRootNavigator: true,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
                child: Text(
                  'Send torrent to',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              for (final Instance target in targets)
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: Text(target.name),
                  subtitle: Text(target.kind.displayName),
                  onTap: () => Navigator.of(context).pop(target),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAddSheet(Instance target, TorrentShare share) async {
    final BuildContext? context = _presentContext;
    if (context == null) {
      return;
    }

    final String? link = share is TorrentShareLink ? share.uri : null;
    final Uint8List? bytes = share is TorrentShareFile ? share.bytes : null;
    final String? name = share is TorrentShareFile ? share.name : null;

    switch (target.kind) {
      case ServiceKind.qbittorrent:
        await AddTorrentSheet.show(
          context,
          target,
          initialLink: link,
          initialFileBytes: bytes,
          initialFileName: name,
        );
      case ServiceKind.deluge:
        await showDelugeAddSheet(
          context,
          target,
          initialLink: link,
          initialFileBytes: bytes,
          initialFileName: name,
        );
      case ServiceKind.transmission:
        await showTransmissionAddSheet(
          context,
          target,
          initialLink: link,
          initialFileBytes: bytes,
          initialFileName: name,
        );
      case ServiceKind.rtorrent:
        await showRtorrentAddSheet(
          context,
          target,
          initialLink: link,
          initialFileBytes: bytes,
          initialFileName: name,
        );
      // Unreachable: torrentTargets only yields the four kinds above.
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
