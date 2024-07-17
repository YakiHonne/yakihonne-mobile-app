// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

///Parameterized Replaceable Events
class Nip33 {
  //["a", "<kind>:<pubkey>:<d-identifier>", "<relay url>"]
  static EventCoordinates getEventCoordinates(List<String> tag) {
    if (tag[0] == 'a') {
      List<dynamic> parts = tag[1].split(':');
      int kind = int.parse(parts[0]);
      String pubkey = parts[1];
      String identifier = '';

      for (int i = 2; i < parts.length; i++) {
        identifier = identifier + parts[i];
      }

      String? relay;
      if (tag.length > 2) relay = tag[2];
      return EventCoordinates(kind, pubkey, identifier, relay);
    } else {
      throw Exception("not a 'a' tag");
    }
  }

  static List<String> coordinatesToTag(EventCoordinates eventCoordinates) {
    return [
      'a',
      '${eventCoordinates.kind}:${eventCoordinates.pubkey}:${eventCoordinates.identifier}',
      eventCoordinates.relay ?? ''
    ];
  }
}

class EventCoordinates extends Equatable {
  final int kind;
  final String pubkey;
  final String identifier;
  final String? relay;

  EventCoordinates(this.kind, this.pubkey, this.identifier, this.relay);

  @override
  String toString() {
    return '${kind.toString()}:$pubkey:$identifier';
  }

  EventCoordinates copyWith({
    int? kind,
    String? pubkey,
    String? identifier,
    String? relay,
  }) {
    return EventCoordinates(
      kind ?? this.kind,
      pubkey ?? this.pubkey,
      identifier ?? this.identifier,
      relay ?? this.relay,
    );
  }

  @override
  List<Object?> get props => [
        kind,
        pubkey,
        identifier,
        relay,
      ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'kind': kind,
      'pubkey': pubkey,
      'identifier': identifier,
      'relay': relay,
    };
  }

  factory EventCoordinates.fromMap(Map<String, dynamic> map) {
    return EventCoordinates(
      map['kind'] as int,
      map['pubkey'] as String,
      map['identifier'] as String,
      map['relay'] != null ? map['relay'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory EventCoordinates.fromJson(String source) =>
      EventCoordinates.fromMap(json.decode(source) as Map<String, dynamic>);
}
