// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'curation_cubit.dart';

class CurationState extends Equatable {
  final Curation curation;
  final bool isArticleLoading;
  final UserStatus userStatus;
  final List<Article> articles;
  final List<VideoModel> videos;
  final bool isValidUser;
  final bool isSameCurationAuthor;
  final String currentUserPubkey;
  final bool canBeZapped;
  final bool isBookmarked;
  final Map<String, double> zaps;
  final Map<String, VoteModel> votes;
  final Set<String> reports;
  final List<String> mutes;
  final List<Comment> comments;
  final bool isArticlesCuration;

  CurationState({
    required this.curation,
    required this.isArticleLoading,
    required this.userStatus,
    required this.articles,
    required this.videos,
    required this.isValidUser,
    required this.isSameCurationAuthor,
    required this.currentUserPubkey,
    required this.canBeZapped,
    required this.isBookmarked,
    required this.zaps,
    required this.votes,
    required this.reports,
    required this.mutes,
    required this.comments,
    required this.isArticlesCuration,
  });

  @override
  List<Object> get props => [
        isArticleLoading,
        articles,
        curation,
        currentUserPubkey,
        canBeZapped,
        userStatus,
        isBookmarked,
        zaps,
        votes,
        reports,
        comments,
        isValidUser,
        isSameCurationAuthor,
        mutes,
        videos,
        isArticlesCuration,
      ];

  CurationState copyWith({
    Curation? curation,
    bool? isArticleLoading,
    UserStatus? userStatus,
    List<Article>? articles,
    List<VideoModel>? videos,
    bool? isValidUser,
    bool? isSameCurationAuthor,
    String? currentUserPubkey,
    bool? canBeZapped,
    bool? isBookmarked,
    Map<String, double>? zaps,
    Map<String, VoteModel>? votes,
    Set<String>? reports,
    List<String>? mutes,
    List<Comment>? comments,
    bool? isArticlesCuration,
  }) {
    return CurationState(
      curation: curation ?? this.curation,
      isArticleLoading: isArticleLoading ?? this.isArticleLoading,
      userStatus: userStatus ?? this.userStatus,
      articles: articles ?? this.articles,
      videos: videos ?? this.videos,
      isValidUser: isValidUser ?? this.isValidUser,
      isSameCurationAuthor: isSameCurationAuthor ?? this.isSameCurationAuthor,
      currentUserPubkey: currentUserPubkey ?? this.currentUserPubkey,
      canBeZapped: canBeZapped ?? this.canBeZapped,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      zaps: zaps ?? this.zaps,
      votes: votes ?? this.votes,
      reports: reports ?? this.reports,
      mutes: mutes ?? this.mutes,
      comments: comments ?? this.comments,
      isArticlesCuration: isArticlesCuration ?? this.isArticlesCuration,
    );
  }
}
