// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'self_articles_cubit.dart';

class SelfArticlesState extends Equatable {
  final UserStatus userStatus;
  final List<Article> articles;
  final bool isArticlesLoading;
  final String chosenRelay;
  final Set<String> relays;
  final Map<String, Set<String>> articleAvailability;
  final bool articleAvailabilityToggle;
  final ArticleFilter articleFilter;
  final Map<String, int> relaysColors;

  SelfArticlesState({
    required this.userStatus,
    required this.articles,
    required this.isArticlesLoading,
    required this.chosenRelay,
    required this.relays,
    required this.articleAvailability,
    required this.articleAvailabilityToggle,
    required this.articleFilter,
    required this.relaysColors,
  });

  @override
  List<Object> get props => [
        userStatus,
        articles,
        isArticlesLoading,
        chosenRelay,
        relays,
        articleAvailability,
        articleFilter,
        articleAvailabilityToggle,
        relaysColors,
      ];

  SelfArticlesState copyWith({
    UserStatus? userStatus,
    List<Article>? articles,
    bool? isArticlesLoading,
    String? chosenRelay,
    Set<String>? relays,
    Map<String, Set<String>>? articleAvailability,
    bool? articleAvailabilityToggle,
    ArticleFilter? articleFilter,
    Map<String, int>? relaysColors,
  }) {
    return SelfArticlesState(
      userStatus: userStatus ?? this.userStatus,
      articles: articles ?? this.articles,
      isArticlesLoading: isArticlesLoading ?? this.isArticlesLoading,
      chosenRelay: chosenRelay ?? this.chosenRelay,
      relays: relays ?? this.relays,
      articleAvailability: articleAvailability ?? this.articleAvailability,
      articleAvailabilityToggle:
          articleAvailabilityToggle ?? this.articleAvailabilityToggle,
      articleFilter: articleFilter ?? this.articleFilter,
      relaysColors: relaysColors ?? this.relaysColors,
    );
  }
}
