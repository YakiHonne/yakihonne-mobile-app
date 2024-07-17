// // ignore_for_file: public_member_api_docs, sort_constructors_first

// import 'package:nostr_core_dart/nostr.dart';

// class Nip23 {
//   static Event encode(
//     String content,
//     String pubKey,
//     List<List<String>> tags,
//   ) {
//     int createdAt = currentUnixTimestampSeconds();
//     return Event(
//       id,
//       pubkey,
//       createdAt,
//       kind,
//       tags,
//       content,
//       sig,
//     );
//   }

//   static Event encodeArticle() {
//     return Event.partial();
//   }

//   static Article decodeArticle(Event event) {
//     if (event.kind != EventKind.LONG_FORM || event.kind != 30024) {
//       throw Exception("${event.kind} is not nip23 compatible");
//     }

//     String identifier = '';
//     String image = '';
//     String title = '';
//     String summary = '';
//     String client = '';
//     List<String> tags = [];

//     for (List<String> tag in event.tags) {
//       if (tag.first == 'd' && identifier.isEmpty) {
//         identifier = tag[1];
//       } else if (tag.first == 'title') {
//         title = tag[1];
//       } else if (tag.first == 'summary') {
//         summary = tag[1];
//       } else if (tag.first == 'image') {
//         image = tag[1];
//       } else if (tag.first == 't') {
//         tags.add(tag[1]);
//       }
//     }

//     return Article(
//       identifier: identifier,
//       pubKey: event.pubkey,
//       content: event.content,
//       title: title,
//       summary: summary,
//       image: image,
//       createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
//       client: client,
//       tags: tags,
//     );
//   }
// }

// class Article {
//   final String identifier;
//   final String pubKey;
//   final String content;
//   final String title;
//   final String summary;
//   final String image;
//   final DateTime createdAt;
//   final String client;
//   final List<String> tags;

//   Article({
//     required this.identifier,
//     required this.pubKey,
//     required this.content,
//     required this.title,
//     required this.summary,
//     required this.image,
//     required this.createdAt,
//     required this.client,
//     required this.tags,
//   });
// }
