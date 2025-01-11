// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/utils.dart';

class DetailedNoteModel extends Equatable implements CreatedAtTag {
  final String id;
  final String pubkey;
  final String content;
  final DateTime createdAt;
  final bool isRoot;
  final bool isQuote;
  final String replyTo;
  final String? originId;
  final String? reposter;
  final String stringifiedEvent;

  DetailedNoteModel({
    required this.id,
    required this.pubkey,
    required this.content,
    required this.createdAt,
    required this.isRoot,
    required this.isQuote,
    required this.replyTo,
    required this.stringifiedEvent,
    this.originId = '',
    this.reposter,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pubkey': pubkey,
      'content': content,
      'createdAt': createdAt.toSecondsSinceEpoch(),
      'id': id,
      'isRoot': isRoot,
      'isQuote': isQuote,
      'replyTo': replyTo,
      'originId': originId,
      'reposter': reposter,
      'stringifiedEvent': stringifiedEvent,
    };
  }

  factory DetailedNoteModel.fromMap(Map<String, dynamic> map) {
    return DetailedNoteModel(
      id: map['id'],
      pubkey: map['pubkey'],
      content: map['content'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] * 1000),
      isRoot: map['isRoot'],
      isQuote: map['isQuote'],
      replyTo: map['replyTo'],
      stringifiedEvent: map['stringifiedEvent'],
    );
  }

  factory DetailedNoteModel.fromEvent(Event event, {String? reposter}) {
    bool root = true;
    bool isQuote = false;
    String replyTo = '';
    String originEventId = '';

    for (final tag in event.tags) {
      if (tag.isNotEmpty) {
        if (tag.first == 'e') {
          if (tag.length > 3 && (tag[3] == 'reply')) {
            root = false;
            replyTo = tag[1];
          } else if ((tag.length > 3 && (tag[3] == 'root')) ||
              (tag.length == 2)) {
            root = false;
            originEventId = tag[1];
          }
        } else if (tag.first == 'a' && tag.length > 3 && (tag[3] == 'reply')) {
          root = true;
          replyTo = '';
          originEventId = '';
        } else if (tag.first == 'q') {
          isQuote = true;
        }
      }
    }

    if (replyTo == originEventId) {
      root = true;
      replyTo = '';
    }

    return DetailedNoteModel(
      pubkey: event.pubkey,
      content: event.content,
      originId: originEventId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      id: event.id,
      isRoot: root,
      replyTo: replyTo,
      isQuote: isQuote,
      reposter: reposter,
      stringifiedEvent: event.toJsonString(),
    );
  }

  String toJson() => json.encode(toMap());

  factory DetailedNoteModel.fromJson(String note) =>
      DetailedNoteModel.fromMap(jsonDecode(note));

  @override
  List<Object?> get props => [
        id,
        pubkey,
        content,
        createdAt,
        isRoot,
        isQuote,
        replyTo,
        stringifiedEvent,
      ];
}
