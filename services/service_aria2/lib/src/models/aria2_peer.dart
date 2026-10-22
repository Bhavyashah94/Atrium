import 'package:freezed_annotation/freezed_annotation.dart';

import 'aria2_json.dart';

part 'aria2_peer.freezed.dart';
part 'aria2_peer.g.dart';

/// One peer connected to a BitTorrent download as `aria2.getPeers` reports it.
@freezed
abstract class Aria2Peer with _$Aria2Peer {
  const Aria2Peer._();

  const factory Aria2Peer({
    @Default('') String peerId,
    @Default('') String ip,
    @JsonKey(fromJson: aria2Int) @Default(0) int port,
    @Default('') String bitfield,
    @JsonKey(fromJson: aria2Bool) @Default(false) bool amChoking,
    @JsonKey(fromJson: aria2Bool) @Default(false) bool peerChoking,
    @JsonKey(fromJson: aria2Int) @Default(0) int downloadSpeed,
    @JsonKey(fromJson: aria2Int) @Default(0) int uploadSpeed,
    @JsonKey(fromJson: aria2Bool) @Default(false) bool seeder,
  }) = _Aria2Peer;

  factory Aria2Peer.fromJson(Map<String, dynamic> json) =>
      _$Aria2PeerFromJson(json);

  /// A human-readable client name decoded from the peer ID when possible.
  String get clientName {
    if (peerId.isEmpty) return 'Unknown Peer';
    try {
      final String decoded = Uri.decodeComponent(peerId);
      return decoded.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    } catch (_) {
      return peerId;
    }
  }

  /// Estimated peer progress 0..1 from bitfield or seeder flag.
  double get progress {
    if (seeder) return 1.0;
    if (bitfield.isEmpty) return 0.0;
    int setBits = 0;
    int totalBits = 0;
    for (int i = 0; i < bitfield.length; i++) {
      final int? hex = int.tryParse(bitfield[i], radix: 16);
      if (hex != null) {
        totalBits += 4;
        setBits +=
            (hex & 1) + ((hex >> 1) & 1) + ((hex >> 2) & 1) + ((hex >> 3) & 1);
      }
    }
    return totalBits == 0 ? 0.0 : (setBits / totalBits).clamp(0.0, 1.0);
  }
}
