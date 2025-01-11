// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'search_cubit.dart';

class SearchState extends Equatable {
  final List<dynamic> content;
  final List<UserModel> authors;
  final String search;
  final SearchResultsType contentSearchResult;
  final SearchResultsType profileSearchResult;
  final List<String> followings;
  final Set<String> bookmarks;
  final List<String> mutes;

  SearchState({
    required this.content,
    required this.authors,
    required this.search,
    required this.contentSearchResult,
    required this.profileSearchResult,
    required this.followings,
    required this.bookmarks,
    required this.mutes,
  });

  @override
  List<Object> get props => [
        content,
        authors,
        search,
        contentSearchResult,
        profileSearchResult,
        followings,
        bookmarks,
        mutes,
      ];

  SearchState copyWith({
    List<dynamic>? content,
    List<UserModel>? authors,
    String? search,
    SearchResultsType? contentSearchResult,
    SearchResultsType? profileSearchResult,
    List<String>? followings,
    Set<String>? bookmarks,
    List<String>? mutes,
  }) {
    return SearchState(
      content: content ?? this.content,
      authors: authors ?? this.authors,
      search: search ?? this.search,
      contentSearchResult: contentSearchResult ?? this.contentSearchResult,
      profileSearchResult: profileSearchResult ?? this.profileSearchResult,
      followings: followings ?? this.followings,
      bookmarks: bookmarks ?? this.bookmarks,
      mutes: mutes ?? this.mutes,
    );
  }
}
