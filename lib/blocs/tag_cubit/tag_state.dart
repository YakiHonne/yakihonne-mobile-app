// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'tag_cubit.dart';

class TagState extends Equatable {
  final bool isArticleLoading;
  final bool isFlashNewsLoading;
  final bool isVideosLoading;
  final bool isNotesLoading;
  final String tag;
  final List<String> followings;
  final List<Article> articles;
  final List<FlashNews> flashNews;
  final List<VideoModel> videos;
  final List<DetailedNoteModel> notes;
  final Set<String> bookmarks;
  final Set<String> loadingBookmarks;
  final UserStatus userStatus;
  final TagType tagType;
  final bool isSubscribed;
  final Set<String> mutes;

  TagState({
    required this.isArticleLoading,
    required this.isFlashNewsLoading,
    required this.isVideosLoading,
    required this.isNotesLoading,
    required this.tag,
    required this.followings,
    required this.articles,
    required this.flashNews,
    required this.videos,
    required this.notes,
    required this.bookmarks,
    required this.loadingBookmarks,
    required this.userStatus,
    required this.tagType,
    required this.isSubscribed,
    required this.mutes,
  });

  @override
  List<Object> get props => [
        isArticleLoading,
        isFlashNewsLoading,
        tag,
        tagType,
        articles,
        bookmarks,
        mutes,
        flashNews,
        loadingBookmarks,
        userStatus,
        followings,
        isSubscribed,
        isVideosLoading,
        isNotesLoading,
        notes,
        videos,
      ];

  TagState copyWith({
    bool? isArticleLoading,
    bool? isFlashNewsLoading,
    bool? isVideosLoading,
    bool? isNotesLoading,
    String? tag,
    List<String>? followings,
    List<Article>? articles,
    List<FlashNews>? flashNews,
    List<VideoModel>? videos,
    List<DetailedNoteModel>? notes,
    Set<String>? bookmarks,
    Set<String>? loadingBookmarks,
    UserStatus? userStatus,
    TagType? tagType,
    bool? isSubscribed,
    Set<String>? mutes,
  }) {
    return TagState(
      isArticleLoading: isArticleLoading ?? this.isArticleLoading,
      isFlashNewsLoading: isFlashNewsLoading ?? this.isFlashNewsLoading,
      isVideosLoading: isVideosLoading ?? this.isVideosLoading,
      isNotesLoading: isNotesLoading ?? this.isNotesLoading,
      tag: tag ?? this.tag,
      followings: followings ?? this.followings,
      articles: articles ?? this.articles,
      flashNews: flashNews ?? this.flashNews,
      videos: videos ?? this.videos,
      notes: notes ?? this.notes,
      bookmarks: bookmarks ?? this.bookmarks,
      loadingBookmarks: loadingBookmarks ?? this.loadingBookmarks,
      userStatus: userStatus ?? this.userStatus,
      tagType: tagType ?? this.tagType,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      mutes: mutes ?? this.mutes,
    );
  }
}
