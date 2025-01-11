// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'curations_cubit.dart';

class CurationsState extends Equatable {
  final List<Curation> curations;
  final bool isCurationsLoading;
  final bool isArticleLoading;
  final Map<String, UserModel> authors;
  final Map<String, UserModel> articlesAuthors;
  final List<Article> articles;
  final String chosenRelay;
  final Set<String> relays;
  final Set<String> bookmarks;
  final UserStatus userStatus;

  CurationsState({
    required this.curations,
    required this.isCurationsLoading,
    required this.isArticleLoading,
    required this.authors,
    required this.articlesAuthors,
    required this.articles,
    required this.chosenRelay,
    required this.relays,
    required this.bookmarks,
    required this.userStatus,
  });

  @override
  List<Object> get props => [
        curations,
        isCurationsLoading,
        isArticleLoading,
        authors,
        articlesAuthors,
        articles,
        chosenRelay,
        relays,
        bookmarks,
        userStatus,
      ];

  CurationsState copyWith({
    List<Curation>? curations,
    bool? isCurationsLoading,
    bool? isArticleLoading,
    Map<String, UserModel>? authors,
    Map<String, UserModel>? articlesAuthors,
    List<Article>? articles,
    String? chosenRelay,
    Set<String>? relays,
    Set<String>? bookmarks,
    UserStatus? userStatus,
  }) {
    return CurationsState(
      curations: curations ?? this.curations,
      isCurationsLoading: isCurationsLoading ?? this.isCurationsLoading,
      isArticleLoading: isArticleLoading ?? this.isArticleLoading,
      authors: authors ?? this.authors,
      articlesAuthors: articlesAuthors ?? this.articlesAuthors,
      articles: articles ?? this.articles,
      chosenRelay: chosenRelay ?? this.chosenRelay,
      relays: relays ?? this.relays,
      bookmarks: bookmarks ?? this.bookmarks,
      userStatus: userStatus ?? this.userStatus,
    );
  }
}
