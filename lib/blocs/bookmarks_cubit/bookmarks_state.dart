// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'bookmarks_cubit.dart';

class BookmarksState extends Equatable {
  final UserStatus userStatus;
  final List<BookmarkListModel> bookmarksLists;

  BookmarksState({
    required this.userStatus,
    required this.bookmarksLists,
  });

  @override
  List<Object> get props => [
        userStatus,
        bookmarksLists,
      ];

  BookmarksState copyWith({
    UserStatus? userStatus,
    List<BookmarkListModel>? bookmarksLists,
  }) {
    return BookmarksState(
      userStatus: userStatus ?? this.userStatus,
      bookmarksLists: bookmarksLists ?? this.bookmarksLists,
    );
  }
}
