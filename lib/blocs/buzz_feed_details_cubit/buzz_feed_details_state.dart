// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'buzz_feed_details_cubit.dart';

class BuzzFeedDetailsState extends Equatable {
  final BuzzFeedModel aiFeedModel;
  final Map<String, VoteModel> votes;
  final List<Comment> comments;
  final Set<String> bookmarks;
  final List<String> mutes;
  final String currentUserPubkey;
  final bool isSubscribed;

  BuzzFeedDetailsState({
    required this.aiFeedModel,
    required this.votes,
    required this.comments,
    required this.bookmarks,
    required this.mutes,
    required this.currentUserPubkey,
    required this.isSubscribed,
  });

  @override
  List<Object> get props => [
        aiFeedModel,
        votes,
        comments,
        bookmarks,
        mutes,
        currentUserPubkey,
        isSubscribed,
      ];

  BuzzFeedDetailsState copyWith({
    BuzzFeedModel? aiFeedModel,
    Map<String, VoteModel>? votes,
    List<Comment>? comments,
    Set<String>? bookmarks,
    List<String>? mutes,
    String? currentUserPubkey,
    bool? isSubscribed,
  }) {
    return BuzzFeedDetailsState(
      aiFeedModel: aiFeedModel ?? this.aiFeedModel,
      votes: votes ?? this.votes,
      comments: comments ?? this.comments,
      bookmarks: bookmarks ?? this.bookmarks,
      mutes: mutes ?? this.mutes,
      currentUserPubkey: currentUserPubkey ?? this.currentUserPubkey,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}
