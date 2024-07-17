// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:yakihonne/nostr/event.dart';
import 'package:yakihonne/utils/static_properties.dart';

class Nip65 {
  static List<FavoriteRelay> decodeRelaysList(Event event) {
    if (event.kind != EventKind.RELAY_LIST_METADATA) {
      throw Exception('${event.kind} is not nip65 compatible');
    }

    List<FavoriteRelay> relays = [];

    for (final tag in event.tags) {
      if (tag.first == 'r') {
        bool read = true;
        bool write = true;

        write = !(tag.length > 2 && tag[2] == 'read');
        read = !(tag.length > 2 && tag[2] == 'write');

        relays.add(
          FavoriteRelay(relay: tag[1], read: read, write: write),
        );
      }
    }

    return relays;
  }

  static List<List<String>> encodeRelaysList(List<FavoriteRelay> relays) {
    List<List<String>> tags = [];
    for (final relay in relays) {
      tags.add(relay.toArray());
    }

    return tags;
  }
}

class FavoriteRelay {
  final String relay;
  final bool read;
  final bool write;

  FavoriteRelay({
    required this.relay,
    required this.read,
    required this.write,
  });

  List<String> toArray() {
    return [
      'r',
      relay,
      if (!read || !write) (read && !write) ? 'read' : 'write'
    ];
  }
}
