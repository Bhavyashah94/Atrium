import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'torrent_share.dart';

/// Receives torrents handed to Atrium by other apps.
///
/// Two paths exist because a cold start and a warm start differ. When Atrium is
/// launched *by* the intent, Dart is not running yet and the payload has to be
/// pulled with [initialShare]. When Atrium is already running the platform
/// pushes it and it arrives on [shares].
class ShareIntake {
  ShareIntake({this.channel = const MethodChannel('app.atrium/share')}) {
    channel.setMethodCallHandler(_handle);
  }

  final MethodChannel channel;

  final StreamController<TorrentShare> _controller =
      StreamController<TorrentShare>.broadcast();

  /// Torrents shared while Atrium was already running.
  Stream<TorrentShare> get shares => _controller.stream;

  Future<void> _handle(MethodCall call) async {
    if (call.method != 'onShare') {
      return;
    }
    final TorrentShare? share = decodeTorrentShare(call.arguments);
    if (share != null && !_controller.isClosed) {
      _controller.add(share);
    }
  }

  /// The torrent Atrium was launched with, if it was launched with one.
  ///
  /// The platform side consumes it, so calling this twice yields null the
  /// second time. That is what stops a rotation from adding the same torrent
  /// again.
  Future<TorrentShare?> initialShare() async {
    try {
      final Object? payload =
          await channel.invokeMethod<Object?>('getInitialShare');
      return decodeTorrentShare(payload);
    } on MissingPluginException {
      // No native side: iOS, and widget tests that do not fake the channel.
      return null;
    } on PlatformException {
      return null;
    }
  }

  void dispose() {
    channel.setMethodCallHandler(null);
    _controller.close();
  }
}

final Provider<ShareIntake> shareIntakeProvider =
    Provider<ShareIntake>((Ref ref) {
  final ShareIntake intake = ShareIntake();
  ref.onDispose(intake.dispose);
  return intake;
});
