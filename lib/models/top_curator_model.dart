// ignore_for_file: public_member_api_docs, sort_constructors_first
class TopCuratorModel {
  final int curations;
  final int articles;
  final String pubKey;

  TopCuratorModel({
    required this.curations,
    required this.articles,
    required this.pubKey,
  });

  TopCuratorModel copyWith({
    int? curations,
    int? articles,
    String? pubKey,
  }) {
    return TopCuratorModel(
      curations: curations ?? this.curations,
      articles: articles ?? this.articles,
      pubKey: pubKey ?? this.pubKey,
    );
  }
}

class TopCreatorModel {
  final Set<String> articles;
  final String pubKey;

  TopCreatorModel({
    required this.articles,
    required this.pubKey,
  });

  TopCreatorModel copyWith({
    Set<String>? articles,
    String? pubKey,
  }) {
    return TopCreatorModel(
      articles: articles ?? this.articles,
      pubKey: pubKey ?? this.pubKey,
    );
  }
}
