// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/utils.dart';

const AF_ENCRYPTION = 'yaki_ai_feed';
const AF_SEARCH_KEY = 'l';
const AF_SEARCH_VALUE = 'YAKI AI FEED';

class BuzzFeedModel extends Equatable implements CreatedAtTag {
  final String id;
  final String pubkey;
  final String title;
  final String description;
  final String image;
  final String encryption;
  final String sourceUrl;
  final String sourceName;
  final String sourceDomain;
  final String sourceIcon;
  final DateTime createdAt;
  final DateTime publishedAt;
  final bool isAuthentic;
  final List<String> tags;

  BuzzFeedModel({
    required this.id,
    required this.pubkey,
    required this.title,
    required this.description,
    required this.image,
    required this.encryption,
    required this.sourceUrl,
    required this.sourceName,
    required this.sourceDomain,
    required this.sourceIcon,
    required this.createdAt,
    required this.publishedAt,
    required this.isAuthentic,
    required this.tags,
  });

  factory BuzzFeedModel.fromEvent(Event event) {
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);

    String sourceUrl = '';
    String sourceName = '';
    String sourceDomain = '';
    String sourceIcon = '';
    String description = '';
    String encryption = '';
    String image = '';
    List<String> tags = [];
    DateTime publishedAt = createdAt;

    for (var tag in event.tags) {
      if (tag.first == AF_ENCRYPTION && tag.length > 1) {
        encryption = tag[1];
      } else if (tag.first == 't' && tag.length > 1) {
        tags.add(tag[1]);
      } else if (tag.first == 'image' && tag.length > 1) {
        image = tag[1];
      } else if (tag.first == 'description' && tag.length > 1) {
        description = tag[1];
      } else if (tag.first == 'source_url' && tag.length > 1) {
        sourceUrl = tag[1];
      } else if (tag.first == 'source_domain' && tag.length > 1) {
        sourceDomain = tag[1];
      } else if (tag.first == 'source_name' && tag.length > 1) {
        sourceName = tag[1];
      } else if (tag.first == 'source_icon' && tag.length > 1) {
        sourceIcon = tag[1];
      } else if (tag.first == 'published_at' && tag.length > 1) {
        publishedAt = DateTime.fromMillisecondsSinceEpoch(
          int.parse(tag[1]) * 1000,
        );
      }
    }

    return BuzzFeedModel(
      id: event.id,
      pubkey: event.pubkey,
      title: event.content,
      description: description,
      image: image,
      encryption: encryption,
      sourceUrl: sourceUrl,
      sourceName: sourceName,
      sourceDomain: sourceDomain,
      sourceIcon: sourceIcon,
      createdAt: createdAt,
      publishedAt: publishedAt,
      isAuthentic: checkAuthenticity(encryption, createdAt),
      tags: tags,
    );
  }

  BuzzFeedModel copyWith({
    String? id,
    String? pubkey,
    String? title,
    String? description,
    String? image,
    String? encryption,
    String? sourceUrl,
    String? sourceName,
    String? sourceDomain,
    String? sourceIcon,
    DateTime? createdAt,
    DateTime? publishedAt,
    bool? isAuthentic,
    List<String>? tags,
  }) {
    return BuzzFeedModel(
      id: id ?? this.id,
      pubkey: pubkey ?? this.pubkey,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      encryption: encryption ?? this.encryption,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceName: sourceName ?? this.sourceName,
      sourceDomain: sourceDomain ?? this.sourceDomain,
      sourceIcon: sourceIcon ?? this.sourceIcon,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      isAuthentic: isAuthentic ?? this.isAuthentic,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [];
}

List<BuzzFeedSource> aiFeedSourcesFromArray(List<dynamic> content) => content
    .map(
      (e) => BuzzFeedSource(
        name: e['name'],
        icon: e['icon'],
        url: e['url'] ?? '',
      ),
    )
    .toList();

class BuzzFeedSource {
  String name = '';
  String icon = '';
  String url = '';

  BuzzFeedSource({
    required this.name,
    required this.icon,
    required this.url,
  });
}
