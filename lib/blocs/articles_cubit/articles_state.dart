// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'articles_cubit.dart';

class ArticlesState extends Equatable {
  final bool isLoading;
  final UpdatingState loadingState;
  final List<Article> articles;
  final String selectedRelay;
  final Set<String> relays;
  final Set<String> bookmarks;
  final List<String> followings;
  final List<String> mutes;

  ArticlesState({
    required this.isLoading,
    required this.loadingState,
    required this.articles,
    required this.selectedRelay,
    required this.relays,
    required this.bookmarks,
    required this.followings,
    required this.mutes,
  });

  @override
  List<Object> get props => [
        isLoading,
        loadingState,
        articles,
        selectedRelay,
        relays,
        bookmarks,
        followings,
        mutes,
      ];

  ArticlesState copyWith({
    bool? isLoading,
    UpdatingState? loadingState,
    List<Article>? articles,
    String? selectedRelay,
    Set<String>? relays,
    Set<String>? bookmarks,
    List<String>? followings,
    List<String>? mutes,
  }) {
    return ArticlesState(
      isLoading: isLoading ?? this.isLoading,
      loadingState: loadingState ?? this.loadingState,
      articles: articles ?? this.articles,
      selectedRelay: selectedRelay ?? this.selectedRelay,
      relays: relays ?? this.relays,
      bookmarks: bookmarks ?? this.bookmarks,
      followings: followings ?? this.followings,
      mutes: mutes ?? this.mutes,
    );
  }
}
