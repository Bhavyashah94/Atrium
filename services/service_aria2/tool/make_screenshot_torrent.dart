// Scratch tool: builds a .torrent for the screenshot fixture and writes its
// base64 next to it. Not part of the package - deleted after the run.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class _Bytes {
  const _Bytes(this.value);
  final List<int> value;
}

String _bencode(Object? value) {
  if (value is int) return 'i${value}e';
  if (value is _Bytes) {
    return '${value.value.length}:${String.fromCharCodes(value.value)}';
  }
  if (value is String) return '${utf8.encode(value).length}:$value';
  if (value is List) return 'l${value.map(_bencode).join()}e';
  if (value is Map) {
    final List<String> keys =
        value.keys.map((Object? k) => k! as String).toList()..sort();
    final StringBuffer buffer = StringBuffer('d');
    for (final String key in keys) {
      buffer
        ..write(_bencode(key))
        ..write(_bencode(value[key]));
    }
    buffer.write('e');
    return buffer.toString();
  }
  throw ArgumentError('cannot bencode ${value.runtimeType}');
}

void main() {
  const int pieceLength = 16 * 1024;
  const String name = 'Big Buck Bunny (2008) 1080p BluRay.x264-GROUP';
  final Uint8List content = Uint8List(8 * 1024 * 1024);
  final Random random = Random(20080613);
  for (int i = 0; i < content.length; i++) {
    content[i] = random.nextInt(256);
  }

  final List<int> pieces = <int>[];
  for (int offset = 0; offset < content.length; offset += pieceLength) {
    final int end = min(offset + pieceLength, content.length);
    pieces.addAll(sha1.convert(content.sublist(offset, end)).bytes);
  }

  final Map<String, Object?> torrent = <String, Object?>{
    'announce': 'http://127.0.0.1:1/announce',
    'created by': 'atrium screenshot fixture',
    'info': <String, Object?>{
      'length': content.length,
      'name': name,
      'piece length': pieceLength,
      'pieces': _Bytes(pieces),
    },
  };

  final String base64 = base64Encode(latin1.encode(_bencode(torrent)));
  final File out = File(
    r'C:\Users\bhavy\AppData\Local\Temp\opencode\aria2-live\torrent.b64',
  );
  out.writeAsStringSync(base64);
  stdout.writeln('wrote ${out.path} (${base64.length} chars)');
}
