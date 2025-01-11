// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'article_cubit.dart';

class ArticleState extends Equatable {
  final UserModel author;
  final Article article;
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

  ArticleState({
    required this.author,
    required this.article,
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
  });

  @override
  List<Object> get props => [
        currentUserPubkey,
        reports,
        userStatus,
        author,
        isSameArticleAuthor,
        mutes,
        canBeZapped,
        article,
        votes,
        zaps,
        comments,
        isFollowingAuthor,
        isLoading,
        isBookmarked,
      ];

  ArticleState copyWith({
    UserModel? author,
    Article? article,
    String? currentUserPubkey,
    bool? isSameArticleAuthor,
    bool? isFollowingAuthor,
    bool? canBeZapped,
    bool? isLoading,
    bool? isBookmarked,
    bool? isBookmarkLoading,
    bool? canBeUpvoted,
    bool? canBeDownvoted,
    UserStatus? userStatus,
    Map<String, double>? zaps,
    Set<String>? reports,
    Map<String, VoteModel>? votes,
    List<Comment>? comments,
    Map<String, UserModel>? commentsAuthors,
    List<String>? mutes,
  }) {
    return ArticleState(
      author: author ?? this.author,
      article: article ?? this.article,
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
    );
  }
}
