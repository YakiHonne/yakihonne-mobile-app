// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'bookmark_details_cubit.dart';

class BookmarkDetailsState extends Equatable {
  final List<dynamic> content;
  final BookmarkListModel bookmarkListModel;
  final Map<String, UserModel> authors;
  final List<String> followings;
  final bool isLoading;
  final UserStatus userStatus;
  final List<String> mutes;

  BookmarkDetailsState({
    required this.content,
    required this.bookmarkListModel,
    required this.authors,
    required this.followings,
    required this.isLoading,
    required this.userStatus,
    required this.mutes,
  });

  @override
  List<Object> get props => [
        content,
        authors,
        followings,
        mutes,
        isLoading,
        bookmarkListModel,
        userStatus,
      ];

  BookmarkDetailsState copyWith({
    List<dynamic>? content,
    BookmarkListModel? bookmarkListModel,
    Map<String, UserModel>? authors,
    List<String>? followings,
    bool? isLoading,
    UserStatus? userStatus,
    List<String>? mutes,
  }) {
    return BookmarkDetailsState(
      content: content ?? this.content,
      bookmarkListModel: bookmarkListModel ?? this.bookmarkListModel,
      authors: authors ?? this.authors,
      followings: followings ?? this.followings,
      isLoading: isLoading ?? this.isLoading,
      userStatus: userStatus ?? this.userStatus,
      mutes: mutes ?? this.mutes,
    );
  }
}
