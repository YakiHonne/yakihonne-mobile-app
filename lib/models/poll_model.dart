// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:yakihonne/nostr/nostr.dart';

class PollModel extends Equatable {
  final String id;
  final String pubkey;
  final String zapPubkey;
  final String content;
  final num valMin;
  final num valMax;
  final num threshold;
  final DateTime createdAt;
  final DateTime closedAt;
  final List<PollOption> options;
  final Event event;

  PollModel({
    required this.id,
    required this.pubkey,
    required this.zapPubkey,
    required this.content,
    required this.valMin,
    required this.valMax,
    required this.threshold,
    required this.createdAt,
    required this.closedAt,
    required this.options,
    required this.event,
  });

  @override
  List<Object?> get props => [
        id,
        pubkey,
        zapPubkey,
        content,
        valMin,
        valMax,
        threshold,
        createdAt,
        closedAt,
        options,
      ];

  PollModel copyWith({
    String? id,
    String? pubkey,
    String? zapPubkey,
    String? content,
    num? valMin,
    num? valMax,
    num? threshold,
    DateTime? createdAt,
    DateTime? closedAt,
    List<PollOption>? options,
  }) {
    return PollModel(
      id: id ?? this.id,
      event: this.event,
      pubkey: pubkey ?? this.pubkey,
      zapPubkey: zapPubkey ?? this.zapPubkey,
      content: content ?? this.content,
      valMin: valMin ?? this.valMin,
      valMax: valMax ?? this.valMax,
      threshold: threshold ?? this.threshold,
      createdAt: createdAt ?? this.createdAt,
      closedAt: closedAt ?? this.closedAt,
      options: options ?? this.options,
    );
  }

  factory PollModel.fromEvent(Event event) {
    int valMin = -1;
    int valMax = -1;
    int threshold = -1;
    DateTime closedAt = DateTime(1950, 1, 1);
    List<PollOption> options = [];
    String zapPubkey = event.pubkey;

    for (final tag in event.tags) {
      if (tag.length > 1) {
        if (tag.first == 'p') {
          zapPubkey = tag[1];
        } else if (tag.first == 'poll_option' && tag.length > 2) {
          options.add(
            PollOption(index: int.tryParse(tag[1]) ?? 0, content: tag[2]),
          );
        } else if (tag.first == 'value_maximum') {
          valMax = int.tryParse(tag[1]) ?? -1;
        } else if (tag.first == 'value_minimum') {
          valMin = int.tryParse(tag[1]) ?? -1;
        } else if (tag.first == 'consensus_threshold') {
          threshold = int.tryParse(tag[1]) ?? -1;
        } else if (tag.first == 'closed_at') {
          int? unixTimeStamp = int.tryParse(tag[1]);
          if (unixTimeStamp != null) {
            closedAt =
                DateTime.fromMillisecondsSinceEpoch(unixTimeStamp * 1000);
          }
        }
      }
    }

    return PollModel(
      id: event.id,
      pubkey: event.pubkey,
      zapPubkey: zapPubkey,
      content: event.content,
      valMin: valMin,
      valMax: valMax,
      threshold: threshold,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      closedAt: closedAt,
      options: options,
      event: event,
    );
  }
}

class PollOption extends Equatable {
  final int index;
  final String content;

  PollOption({
    required this.index,
    required this.content,
  });

  @override
  List<Object?> get props => [
        index,
        content,
      ];

  PollOption copyWith({
    int? index,
    String? content,
  }) {
    return PollOption(
      index: index ?? this.index,
      content: content ?? this.content,
    );
  }
}

class PollStat {
  final String pubkey;
  final num zapAmount;
  final DateTime createdAt;
  final int index;

  PollStat({
    required this.pubkey,
    required this.zapAmount,
    required this.createdAt,
    required this.index,
  });
}
