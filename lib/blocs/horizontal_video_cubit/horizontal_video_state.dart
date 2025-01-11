// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'horizontal_video_cubit.dart';

class HorizontalVideoState extends Equatable {
  final UserModel author;
  final VideoModel video;
  final String currentUserPubkey;
  final bool isSameArticleAuthor;
  final bool isFollowingAuthor;
  final bool canBeZapped;
  final bool isLoading;
  final bool isBookmarked;
  final UserStatus userStatus;
  final Map<String, double> zaps;
  final Set<String> reports;
  final Map<String, VoteModel> votes;
  final List<Comment> comments;
  final List<String> mutes;
  final List<String> viewsCount;

  HorizontalVideoState({
    required this.author,
    required this.video,
    required this.currentUserPubkey,
    required this.isSameArticleAuthor,
    required this.isFollowingAuthor,
    required this.canBeZapped,
    required this.isLoading,
    required this.isBookmarked,
    required this.userStatus,
    required this.zaps,
    required this.reports,
    required this.votes,
    required this.comments,
    required this.mutes,
    required this.viewsCount,
  });

  @override
  List<Object> get props => [
        author,
        video,
        currentUserPubkey,
        isSameArticleAuthor,
        isFollowingAuthor,
        canBeZapped,
        isLoading,
        isBookmarked,
        userStatus,
        zaps,
        reports,
        votes,
        comments,
        mutes,
        viewsCount,
      ];

  HorizontalVideoState copyWith({
    UserModel? author,
    VideoModel? video,
    String? currentUserPubkey,
    bool? isSameArticleAuthor,
    bool? isFollowingAuthor,
    bool? canBeZapped,
    bool? isLoading,
    bool? isBookmarked,
    UserStatus? userStatus,
    Map<String, double>? zaps,
    Set<String>? reports,
    Map<String, VoteModel>? votes,
    List<Comment>? comments,
    List<String>? mutes,
    List<String>? viewsCount,
  }) {
    return HorizontalVideoState(
      author: author ?? this.author,
      video: video ?? this.video,
      currentUserPubkey: currentUserPubkey ?? this.currentUserPubkey,
      isSameArticleAuthor: isSameArticleAuthor ?? this.isSameArticleAuthor,
      isFollowingAuthor: isFollowingAuthor ?? this.isFollowingAuthor,
      canBeZapped: canBeZapped ?? this.canBeZapped,
      isLoading: isLoading ?? this.isLoading,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      userStatus: userStatus ?? this.userStatus,
      zaps: zaps ?? this.zaps,
      reports: reports ?? this.reports,
      votes: votes ?? this.votes,
      comments: comments ?? this.comments,
      mutes: mutes ?? this.mutes,
      viewsCount: viewsCount ?? this.viewsCount,
    );
  }
}
