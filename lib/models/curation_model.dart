// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/utils.dart';

class Curation extends Equatable {
  final String eventId;
  final String identifier;
  final String pubKey;
  final String title;
  final String description;
  final String image;
  final DateTime createdAt;
  final DateTime publishedAt;
  final List<EventCoordinates> eventsIds;
  final Set<String> relays;
  final String placeHolder;
  final int kind;
  final List<ZapSplit> zapsSplits;

  const Curation({
    required this.eventId,
    required this.identifier,
    required this.pubKey,
    required this.title,
    required this.description,
    required this.image,
    required this.createdAt,
    required this.publishedAt,
    required this.eventsIds,
    required this.relays,
    this.placeHolder = '',
    required this.kind,
    required this.zapsSplits,
  });

  bool isArticleCuration() => kind == EventKind.CURATION_ARTICLES;

  factory Curation.fromEvent(Event event, String relay) {
    String identifier = '';
    String title = '';
    String description = '';
    String image = '';
    List<EventCoordinates> eventsIds = [];
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
    DateTime publishedAt = createdAt;
    List<ZapSplit> zaps = [];

    for (var tag in event.tags) {
      if (tag.first == 'd' && tag.length > 1 && identifier.isEmpty) {
        identifier = tag[1];
      } else if (tag.first == 'title' && tag.length > 1) {
        title = tag[1];
      } else if (tag.first == 'description' && tag.length > 1) {
        description = tag[1];
      } else if (tag.first == 'image' && tag.length > 1) {
        image = tag[1];
      } else if (tag.first == 'a') {
        eventsIds.add(Nip33.getEventCoordinates(tag));
      } else if (tag.first == 'zap' && tag.length > 1) {
        zaps.add(
          ZapSplit(pubkey: tag[1], percentage: int.tryParse(tag[3]) ?? 0),
        );
      } else if (tag.first == 'published_at') {
        final time = tag[1].toString();

        if (time.isNotEmpty) {
          publishedAt = DateTime.fromMillisecondsSinceEpoch(
            (time.length <= 10
                ? num.parse(time).toInt() * 1000
                : num.parse(time).toInt()),
          );
        }
      }
    }

    final placeHolder = getRandomPlaceholder(
      input: identifier,
      isPfp: false,
    );

    return Curation(
      eventId: event.id,
      kind: event.kind,
      identifier: identifier,
      pubKey: event.pubkey,
      title: title,
      description: description,
      image: image,
      eventsIds: eventsIds,
      createdAt: createdAt,
      publishedAt: publishedAt,
      placeHolder: placeHolder,
      zapsSplits: zaps,
      relays: {relay},
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        identifier,
        pubKey,
        title,
        description,
        image,
        createdAt,
        publishedAt,
        eventsIds,
        relays,
        placeHolder,
      ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'eventId': eventId,
      'identifier': identifier,
      'pubKey': pubKey,
      'title': title,
      'description': description,
      'image': image,
      'createdAt': createdAt.toSecondsSinceEpoch(),
      'publishedAt': publishedAt.toSecondsSinceEpoch(),
      'eventsIds': eventsIds.map((x) => x.toMap()).toList(),
      'relays': relays.toList(),
      'placeHolder': placeHolder,
    };
  }

  factory Curation.fromMap(Map<String, dynamic> map) {
    return Curation(
      eventId: map['eventId'] as String,
      kind: map['kind'] as int,
      identifier: map['identifier'] as String,
      pubKey: map['pubKey'] as String,
      title: map['title'] as String,
      zapsSplits: List<ZapSplit>.from((map['zapSplits'] as List? ?? [])),
      description: map['description'] as String,
      image: map['image'] as String,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as int) * 1000),
      publishedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['publishedAt'] as int) * 1000,
      ),
      eventsIds: List<EventCoordinates>.from(
        (map['eventsIds'] as List).map<EventCoordinates>(
          (x) => EventCoordinates.fromMap(x),
        ),
      ),
      relays: Set<String>.from((map['relays'])),
      placeHolder: map['placeHolder'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Curation.Curation(String source) =>
      Curation.fromMap(json.decode(source) as Map<String, dynamic>);

  Curation copyWith({
    String? eventId,
    String? identifier,
    String? pubKey,
    String? title,
    String? description,
    String? image,
    DateTime? createdAt,
    DateTime? publishedAt,
    List<EventCoordinates>? eventsIds,
    Set<String>? relays,
    String? placeHolder,
    int? kind,
    List<ZapSplit>? zapsSplits,
  }) {
    return Curation(
      eventId: eventId ?? this.eventId,
      identifier: identifier ?? this.identifier,
      pubKey: pubKey ?? this.pubKey,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      eventsIds: eventsIds ?? this.eventsIds,
      relays: relays ?? this.relays,
      placeHolder: placeHolder ?? this.placeHolder,
      kind: kind ?? this.kind,
      zapsSplits: zapsSplits ?? this.zapsSplits,
    );
  }
}
