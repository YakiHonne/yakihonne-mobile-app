import 'dart:typed_data';

import 'package:bech32/bech32.dart';
import 'package:convert/convert.dart';
import 'package:yakihonne/nostr/utils.dart';
import 'package:yakihonne/utils/utils.dart';

/// bech32-encoded entities
class Nip19 {
  static RegExp nip19regex = RegExp(
    r'@?(nostr:)?@?(nsec1|npub1|nevent1|naddr1|note1|nprofile1|nrelay1)([qpzry9x8gf2tvdw0s3jn54khce6mua7l]+)([\\S]*)',
    caseSensitive: false,
  );

  static String encodePubkey(String pubkey) {
    try {
      return bech32Encode('npub', pubkey);
    } catch (e) {
      return pubkey;
    }
  }

  static String encodePrivkey(String privkey) {
    try {
      return bech32Encode('nsec', privkey);
    } catch (e) {
      return privkey;
    }
  }

  static String encodeNote(String noteid) {
    try {
      return bech32Encode('note', noteid);
    } catch (e) {
      return noteid;
    }
  }

  static String decodePubkey(String data) {
    try {
      Map map = bech32Decode(data);
      if (map['prefix'] == 'npub') {
        return map['data'];
      } else {
        return '';
      }
    } catch (e) {
      return '';
    }
  }

  static String decodePrivkey(String data) {
    try {
      Map map = bech32Decode(data);
      if (map['prefix'] == 'nsec') {
        return map['data'];
      } else {
        return '';
      }
    } catch (e) {
      return '';
    }
  }

  static String decodeNote(String data) {
    try {
      Map map = bech32Decode(data);
      if (map['prefix'] == 'note') {
        return map['data'];
      } else {
        return '';
      }
    } catch (e) {
      return '';
    }
  }

  // 0: special
  // depends on the bech32 prefix:
  // for nprofile it will be the 32 bytes of the profile public key
  // for nevent it will be the 32 bytes of the event id
  // for nrelay, this is the relay URL
  // for naddr, it is the identifier (the "d" tag) of the event being referenced
  // 1: relay
  // for nprofile, nevent and naddr, optionally, a relay in which the entity (profile or event) is more likely to be found, encoded as ascii
  // this may be included multiple times
  // 2: author
  // for naddr, the 32 bytes of the pubkey of the event
  // for nevent, optionally, the 32 bytes of the pubkey of the event
  // 3: kind
  // for naddr, the 32-bit unsigned integer of the kind, big-endian
  // for nevent, optionally, the 32-bit unsigned integer of the kind, big-endian
  static String encodeShareableEntity(
    String prefix,
    String special,
    List<String>? relays,
    String? author,
    int? kind,
  ) {
    try {
      // 0:special
      String result =
          '00${hexToBytes(special).length.toRadixString(16).padLeft(2, '0')}$special';
      // 1:relay
      if (relays != null) {
        for (var relay in relays) {
          result = '${result}01';
          String value = relay.codeUnits
              .map((number) => number.toRadixString(16).padLeft(2, '0'))
              .join('');
          result =
              '$result${hexToBytes(value).length.toRadixString(16).padLeft(2, '0')}$value';
        }
      }
      // 2:author
      if (author != null) {
        result = '${result}02';
        result =
            '$result${hexToBytes(author).length.toRadixString(16).padLeft(2, '0')}$author';
      }

      if (kind != null) {
        final value = intToUint32BigEndian(kind);
        result = '${result}03';
        result =
            '$result${value.length.toRadixString(16).padLeft(2, '0')}${hex.encode(value)}';
      }

      return bech32Encode(prefix, result, maxLength: result.length);
    } catch (e) {
      return '';
    }
  }

  static Map<String, dynamic> decodeShareableEntity(String shareableEntity) {
    try {
      String prefix = '';
      String special = '';
      List<String> relays = [];
      String? author;
      int? kind;
      Map<String, String> decodedMap =
          bech32Decode(shareableEntity, maxLength: shareableEntity.length);
      prefix = decodedMap['prefix']!;
      final data = hexToBytes(decodedMap['data']!);

      var index = 0;
      while (index < data.length) {
        var type = data[index++];
        var length = data[index++];

        var value = data.sublist(index, index + length);
        index += length;

        if (type == 0) {
          special = bytesToHex(value);
        } else if (type == 1) {
          relays.add(String.fromCharCodes(value));
        } else if (type == 2) {
          author = bytesToHex(value);
        } else if (type == 3) {
          final buffer = Uint8List.fromList(value);
          final byteData = ByteData.sublistView(buffer);
          kind = byteData.getUint32(0);
        }
      }

      return {
        'prefix': prefix,
        'special': special,
        'relays': relays,
        'author': author,
        'kind': kind,
      };
    } catch (e) {
      lg.i(e);
      return {};
    }
  }
}

String bech32Encode(String prefix, String hexData, {int? maxLength}) {
  final data = hex.decode(hexData);
  final convertedData = convertBits(data, 8, 5, true);
  final bech32Data = Bech32(prefix, convertedData);
  if (maxLength != null) return bech32.encode(bech32Data, maxLength);
  return bech32.encode(bech32Data);
}

Map<String, String> bech32Decode(String bech32Data, {int? maxLength}) {
  final decodedData = maxLength != null
      ? bech32.decode(bech32Data, maxLength)
      : bech32.decode(bech32Data);
  final convertedData = convertBits(decodedData.data, 5, 8, false);
  final hexData = hex.encode(convertedData);

  return {'prefix': decodedData.hrp, 'data': hexData};
}

List<int> convertBits(List<int> data, int fromBits, int toBits, bool pad) {
  var acc = 0;
  var bits = 0;
  final maxv = (1 << toBits) - 1;
  final result = <int>[];

  for (final value in data) {
    if (value < 0 || value >> fromBits != 0) {
      throw Exception('Invalid value: $value');
    }
    acc = (acc << fromBits) | value;
    bits += fromBits;

    while (bits >= toBits) {
      bits -= toBits;
      result.add((acc >> bits) & maxv);
    }
  }

  if (pad) {
    if (bits > 0) {
      result.add((acc << (toBits - bits)) & maxv);
    }
  } else if (bits >= fromBits || ((acc << (toBits - bits)) & maxv) != 0) {
    throw Exception('Invalid data');
  }

  return result;
}

Uint8List intToUint32BigEndian(int value) {
  final buffer = Uint8List(4);
  final byteData = ByteData.view(buffer.buffer);
  byteData.setUint32(0, value, Endian.big);
  return buffer;
}
