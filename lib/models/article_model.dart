// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/utils.dart';

class Article extends Equatable implements CreatedAtTag {
  final String articleId;
  final String identifier;
  final String pubkey;
  final String title;
  final String summary;
  final String image;
  final DateTime createdAt;
  final DateTime publishedAt;
  final String client;
  final String content;
  final List<String> hashTags;
  final bool isSensitive;
  final bool isDraft;
  final String placeholder;
  final Set<String> relays;
  final List<ZapSplit> zapsSplits;

  Article({
    required this.articleId,
    required this.identifier,
    required this.pubkey,
    required this.title,
    required this.summary,
    required this.image,
    required this.createdAt,
    required this.publishedAt,
    required this.client,
    required this.content,
    required this.hashTags,
    required this.isSensitive,
    required this.isDraft,
    this.placeholder = '',
    required this.relays,
    required this.zapsSplits,
  });

  factory Article.fromEvent(Event event, {bool? isDraft, String? relay}) {
    String identifier = '';
    String title = '';
    String summary = '';
    String image = '';
    String client = '';
    bool isSensitive = false;
    DateTime createdAt =
        DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
    DateTime publishedAt = createdAt;
    List<String> hashTags = [];
    List<ZapSplit> zaps = [];

    for (var tag in event.tags) {
      if (tag.first == 'd' && tag.length > 1 && identifier.isEmpty) {
        identifier = tag[1].trim();
      } else if (tag.first == 't' && tag.length > 1) {
        hashTags.add(tag[1]);
      } else if (tag.first == 'client' && tag.length > 1) {
        client = tag[1];
      } else if (tag.first == 'image' && tag.length > 1) {
        image = tag[1];
      } else if (tag.first == 'summary' && tag.length > 1) {
        summary = tag[1];
      } else if (tag.first == 'title' && tag.length > 1) {
        title = tag[1];
      } else if (tag.first == 'zap' && tag.length > 1) {
        zaps.add(
          ZapSplit(pubkey: tag[1], percentage: int.tryParse(tag[3]) ?? 0),
        );
      } else if (tag.first.toLowerCase() == 'l' &&
          tag.length > 1 &&
          tag[1] == 'content-warning') {
        isSensitive = true;
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

    return Article(
      articleId: event.id,
      identifier: identifier,
      pubkey: event.pubkey,
      content: event.content,
      title: title,
      summary: summary,
      image: image,
      createdAt: createdAt,
      publishedAt: publishedAt,
      client: client,
      hashTags: hashTags,
      isDraft: isDraft ?? false,
      isSensitive: isSensitive,
      placeholder: placeHolder,
      zapsSplits: zaps,
      relays: relay != null ? {relay} : {},
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'articleId': articleId,
      'identifier': identifier,
      'pubKey': pubkey,
      'title': title,
      'summary': summary,
      'image': image,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'publishedAt': publishedAt.millisecondsSinceEpoch,
      'client': client,
      'content': content,
      'hashTags': hashTags,
      'isSensitive': isSensitive,
      'isDraft': isDraft,
    };
  }

  factory Article.fromMap(Map<String, dynamic> map) {
    final placeHolder = getRandomPlaceholder(
      input: map['identifier'] ?? '',
      isPfp: true,
    );

    return Article(
      articleId: map['articleId'] as String,
      identifier: map['identifier'] as String,
      zapsSplits: List<ZapSplit>.from((map['zapSplits'] as List? ?? [])),
      pubkey: map['pubKey'] as String,
      title: map['title'] as String,
      summary: map['summary'] as String,
      image: map['image'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      publishedAt:
          DateTime.fromMillisecondsSinceEpoch(map['publishedAt'] as int),
      client: map['client'] as String,
      content: map['content'] as String,
      hashTags: List<String>.from((map['hashTags'] as List)),
      isSensitive: map['isSensitive'] as bool,
      isDraft: map['isDraft'] as bool,
      placeholder: placeHolder,
      relays: {},
    );
  }

  String toJson() => json.encode(toMap());

  factory Article.fromJson(String source) =>
      Article.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        articleId,
        identifier,
        pubkey,
        title,
        summary,
        image,
        createdAt,
        publishedAt,
        client,
        content,
        hashTags,
        isSensitive,
        isDraft,
        relays,
        zapsSplits,
      ];
}

class ZapSplit extends Equatable {
  final String pubkey;
  final int percentage;

  ZapSplit({
    required this.pubkey,
    required this.percentage,
  });

  @override
  List<Object?> get props => [
        pubkey,
        percentage,
      ];

  ZapSplit copyWith({
    String? pubkey,
    int? percentage,
  }) {
    return ZapSplit(
      pubkey: pubkey ?? this.pubkey,
      percentage: percentage ?? this.percentage,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pubkey': pubkey,
      'percentage': percentage,
    };
  }

  factory ZapSplit.fromMap(Map<String, dynamic> map) {
    return ZapSplit(
      pubkey: map['pubkey'] as String,
      percentage: map['percentage'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory ZapSplit.fromJson(String source) =>
      ZapSplit.fromMap(json.decode(source) as Map<String, dynamic>);
}

class Comment {
  final String id;
  final String pubKey;
  final String content;
  final DateTime createdAt;
  final bool isRoot;
  final String replyTo;
  final String? originId;

  Comment({
    required this.id,
    required this.pubKey,
    required this.content,
    required this.createdAt,
    required this.isRoot,
    required this.replyTo,
    this.originId = '',
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pubKey': pubKey,
      'content': content,
      'createdAt': createdAt,
    };
  }

  factory Comment.fromEvent(Event event) {
    bool root = true;
    String replyTo = '';
    String originEventId = '';

    for (final tag in event.tags) {
      if (tag.first == 'e') {
        if (tag.length > 3 && (tag[3] == 'reply')) {
          root = false;
          replyTo = tag[1];
        } else if (tag.length > 3 && (tag[3] == 'root')) {
          originEventId = tag[1];
        }
      } else if (tag.first == 'a' && tag.length > 3 && (tag[3] == 'reply')) {
        root = true;
        replyTo = '';
        originEventId = '';
      }
    }

    if (replyTo == originEventId) {
      root = true;
      replyTo = '';
    }

    return Comment(
      pubKey: event.pubkey,
      content: event.content,
      originId: originEventId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      id: event.id,
      isRoot: root,
      replyTo: replyTo,
    );
  }
}

class ArticleAutoSaveModel {
  final String content;
  final String title;
  final String description;
  final bool isSensitive;
  final List<String> tags;

  ArticleAutoSaveModel({
    required this.content,
    required this.title,
    required this.description,
    required this.isSensitive,
    required this.tags,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'content': content,
      'title': title,
      'description': description,
      'isSensitive': isSensitive,
      'tags': tags,
    };
  }

  factory ArticleAutoSaveModel.fromMap(Map<String, dynamic> map) {
    return ArticleAutoSaveModel(
      content: map['content'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      isSensitive: map['isSensitive'] as bool,
      tags: List<String>.from((map['tags'] as List)),
    );
  }

  String toJson() => json.encode(toMap());

  factory ArticleAutoSaveModel.fromJson(String source) =>
      ArticleAutoSaveModel.fromMap(json.decode(source) as Map<String, dynamic>);

  ArticleAutoSaveModel copyWith({
    String? content,
    String? title,
    String? description,
    bool? isSensitive,
    List<String>? tags,
  }) {
    return ArticleAutoSaveModel(
      content: content ?? this.content,
      title: title ?? this.title,
      description: description ?? this.description,
      isSensitive: isSensitive ?? this.isSensitive,
      tags: tags ?? this.tags,
    );
  }
}

List<WalletTransactionModel> getNwcWalletTransactions(List zaps) =>
    zaps.map((e) => WalletTransactionModel.fromNwcMap(e)).toList();

List<WalletTransactionModel> getAlbyWalletTransactions(List zaps) =>
    zaps.map((e) => WalletTransactionModel.fromAlbyMap(e)).toList();

class WalletTransactionModel {
  DateTime createdAt;
  double amount;
  double fees;
  String pubkey;
  bool isIncoming;
  String message;

  WalletTransactionModel({
    required this.createdAt,
    required this.amount,
    required this.fees,
    required this.pubkey,
    required this.isIncoming,
    required this.message,
  });

  factory WalletTransactionModel.fromNwcMap(Map<String, dynamic> transaction) {
    final amount = (transaction['amount'] as int? ?? 0) / 1000;
    final fees = (transaction['fees_paid'] as int? ?? 0) / 1000;

    final createdAt = DateTime.fromMillisecondsSinceEpoch(
        (transaction['created_at'] as int) * 1000);

    final isIncoming = transaction['type'] == 'incoming';
    final message = transaction['description'] as String? ?? '';

    String pubkey = '';
    final metadata = transaction['metadata'];

    if (metadata != null && metadata is Map && metadata.isNotEmpty) {
      pubkey = metadata['zap_request']['pubkey'] as String? ?? '';
    }

    return WalletTransactionModel(
      createdAt: createdAt,
      amount: amount,
      fees: fees,
      isIncoming: isIncoming,
      message: message,
      pubkey: pubkey,
    );
  }

  factory WalletTransactionModel.fromAlbyMap(Map<String, dynamic> transaction) {
    final amount = (transaction['amount'] as int? ?? 0).toDouble();
    final fees = (transaction['fees_paid'] as int? ?? 0) / 1000;

    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      (transaction['creation_date'] as int) * 1000,
    );

    final isIncoming = transaction['type'] == 'incoming';
    final message = transaction['comment'] as String? ?? '';

    String pubkey = '';
    final metadata = transaction['metadata'];

    if (metadata != null && metadata is Map && metadata.isNotEmpty) {
      pubkey = metadata['zap_request']['pubkey'] as String? ?? '';
    }

    return WalletTransactionModel(
      createdAt: createdAt,
      amount: amount,
      fees: fees,
      isIncoming: isIncoming,
      message: message,
      pubkey: pubkey,
    );
  }
}
