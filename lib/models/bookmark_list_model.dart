// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:yakihonne/main.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/utils.dart';

class BookmarkListModel {
  final String eventId;
  final String title;
  final String description;
  final String image;
  final String placeholder;
  final String identifier;
  final List<EventCoordinates> bookmarkedReplaceableEvents;
  final List<String> bookmarkedEvents;
  final String pubkey;
  final DateTime createAt;

  BookmarkListModel({
    required this.eventId,
    required this.title,
    required this.description,
    required this.image,
    required this.placeholder,
    required this.identifier,
    required this.bookmarkedReplaceableEvents,
    required this.bookmarkedEvents,
    required this.pubkey,
    required this.createAt,
  });

  bool isReplaceableEventAvailable({
    required String identifier,
    required bool isReplaceableEvent,
  }) {
    if (isReplaceableEvent) {
      for (final event in bookmarkedReplaceableEvents) {
        if (event.identifier == identifier) {
          return true;
        }
      }
    } else {
      for (final eventId in bookmarkedEvents) {
        if (eventId == identifier) {
          return true;
        }
      }
    }

    return false;
  }

  Future<Event?> bookmarkListModelToEvent() async {
    try {
      final replaceableEvents = bookmarkedReplaceableEvents
          .map((e) => Nip33.coordinatesToTag(e))
          .toList();

      final events = bookmarkedEvents
          .map(
            (event) => ['e', event],
          )
          .toList();

      return await Event.genEvent(
        kind: EventKind.CATEGORIZED_BOOKMARK,
        tags: [
          ['d', identifier],
          ['title', title],
          ['description', description],
          if (image.isNotEmpty) ['image', image],
          ...replaceableEvents,
          ...events,
        ],
        content: '',
        privkey: nostrRepository.usm!.privKey,
        pubkey: nostrRepository.usm!.pubKey,
      );
    } catch (_) {
      return null;
    }
  }

  factory BookmarkListModel.fromEvent(Event event) {
    String identifier = '';
    String title = '';
    String description = '';
    String image = '';
    List<EventCoordinates> bookmarkedReplaceableEvents = [];
    List<String> bookmarkedEvents = [];

    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);

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
        bookmarkedReplaceableEvents.add(Nip33.getEventCoordinates(tag));
      } else if (tag.first == 'e') {
        bookmarkedEvents.add(tag[1]);
      }
    }

    final placeHolder = getRandomPlaceholder(
      input: identifier,
      isPfp: false,
    );

    return BookmarkListModel(
      eventId: event.id,
      title: title,
      identifier: identifier,
      description: description,
      image: image,
      bookmarkedReplaceableEvents: bookmarkedReplaceableEvents,
      bookmarkedEvents: bookmarkedEvents,
      pubkey: event.pubkey,
      createAt: createdAt,
      placeholder: placeHolder,
    );
  }

  BookmarkListModel copyWith({
    String? eventId,
    String? title,
    String? description,
    String? image,
    String? placeholder,
    String? identifier,
    List<EventCoordinates>? bookmarkedReplaceableEvents,
    List<String>? bookmarkedEvents,
    String? pubkey,
    DateTime? createAt,
  }) {
    return BookmarkListModel(
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      placeholder: placeholder ?? this.placeholder,
      identifier: identifier ?? this.identifier,
      bookmarkedReplaceableEvents:
          bookmarkedReplaceableEvents ?? this.bookmarkedReplaceableEvents,
      bookmarkedEvents: bookmarkedEvents ?? this.bookmarkedEvents,
      pubkey: pubkey ?? this.pubkey,
      createAt: createAt ?? this.createAt,
    );
  }
}
