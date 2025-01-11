// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'add_articles_cubit.dart';

class AddCurationArticlesState extends Equatable {
  final List<Article> articles;
  final List<Article> activeArticles;
  final List<VideoModel> videos;
  final List<VideoModel> activeVideos;
  final bool isArticlesLoading;
  final bool isActiveArticlesLoading;
  final UpdatingState relaysAddingData;
  final String chosenRelay;
  final Set<String> relays;
  final String searchText;
  final bool isAllRelays;
  final List<String> mutes;
  final bool isArticlesCuration;

  AddCurationArticlesState({
    required this.articles,
    required this.activeArticles,
    required this.videos,
    required this.activeVideos,
    required this.isArticlesLoading,
    required this.isActiveArticlesLoading,
    required this.relaysAddingData,
    required this.chosenRelay,
    required this.relays,
    required this.searchText,
    required this.isAllRelays,
    required this.mutes,
    required this.isArticlesCuration,
  });

  @override
  List<Object> get props => [
        articles,
        activeArticles,
        isActiveArticlesLoading,
        isArticlesLoading,
        relaysAddingData,
        chosenRelay,
        relays,
        searchText,
        isAllRelays,
        mutes,
        videos,
        activeVideos,
        isArticlesCuration,
      ];

  AddCurationArticlesState copyWith({
    List<Article>? articles,
    List<Article>? activeArticles,
    List<VideoModel>? videos,
    List<VideoModel>? activeVideos,
    bool? isArticlesLoading,
    bool? isActiveArticlesLoading,
    UpdatingState? relaysAddingData,
    String? chosenRelay,
    Set<String>? relays,
    String? searchText,
    bool? isAllRelays,
    List<String>? mutes,
    bool? isArticlesCuration,
  }) {
    return AddCurationArticlesState(
      articles: articles ?? this.articles,
      activeArticles: activeArticles ?? this.activeArticles,
      videos: videos ?? this.videos,
      activeVideos: activeVideos ?? this.activeVideos,
      isArticlesLoading: isArticlesLoading ?? this.isArticlesLoading,
      isActiveArticlesLoading:
          isActiveArticlesLoading ?? this.isActiveArticlesLoading,
      relaysAddingData: relaysAddingData ?? this.relaysAddingData,
      chosenRelay: chosenRelay ?? this.chosenRelay,
      relays: relays ?? this.relays,
      searchText: searchText ?? this.searchText,
      isAllRelays: isAllRelays ?? this.isAllRelays,
      mutes: mutes ?? this.mutes,
      isArticlesCuration: isArticlesCuration ?? this.isArticlesCuration,
    );
  }
}
