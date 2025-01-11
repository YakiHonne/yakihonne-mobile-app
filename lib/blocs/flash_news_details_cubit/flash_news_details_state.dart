// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'flash_news_details_cubit.dart';

class FlashNewsDetailsState extends Equatable {
  final MainFlashNews mainFlashNews;
  final UserStatus userStatus;
  final String currentUserPubkey;
  final Map<String, VoteModel> votes;
  final List<Comment> comments;
  final Map<String, double> zaps;
  final Set<String> bookmarks;
  final List<String> mutes;
  final Set<String> reports;
  final bool canBeZapped;

  FlashNewsDetailsState({
    required this.mainFlashNews,
    required this.userStatus,
    required this.currentUserPubkey,
    required this.votes,
    required this.comments,
    required this.zaps,
    required this.bookmarks,
    required this.mutes,
    required this.reports,
    required this.canBeZapped,
  });

  @override
  List<Object> get props => [
        mainFlashNews,
        userStatus,
        currentUserPubkey,
        votes,
        comments,
        zaps,
        mutes,
        canBeZapped,
        bookmarks,
        reports,
      ];

  FlashNewsDetailsState copyWith({
    MainFlashNews? mainFlashNews,
    UserStatus? userStatus,
    String? currentUserPubkey,
    Map<String, VoteModel>? votes,
    List<Comment>? comments,
    Map<String, double>? zaps,
    Set<String>? bookmarks,
    List<String>? mutes,
    Set<String>? reports,
    bool? canBeZapped,
  }) {
    return FlashNewsDetailsState(
      mainFlashNews: mainFlashNews ?? this.mainFlashNews,
      userStatus: userStatus ?? this.userStatus,
      currentUserPubkey: currentUserPubkey ?? this.currentUserPubkey,
      votes: votes ?? this.votes,
      comments: comments ?? this.comments,
      zaps: zaps ?? this.zaps,
      bookmarks: bookmarks ?? this.bookmarks,
      mutes: mutes ?? this.mutes,
      reports: reports ?? this.reports,
      canBeZapped: canBeZapped ?? this.canBeZapped,
    );
  }
}
