// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'buzz_feed_source_cubit.dart';

class BuzzFeedSourceState extends Equatable {
  final List<BuzzFeedModel> buzzFeed;
  final bool isSubscribed;
  final bool isBuzzFeedLoading;
  final UpdatingState loadMoreFeed;
  final Set<String> bookmarks;

  BuzzFeedSourceState({
    required this.buzzFeed,
    required this.isSubscribed,
    required this.isBuzzFeedLoading,
    required this.loadMoreFeed,
    required this.bookmarks,
  });

  @override
  List<Object> get props => [
        buzzFeed,
        isSubscribed,
        isBuzzFeedLoading,
        loadMoreFeed,
        bookmarks,
      ];

  BuzzFeedSourceState copyWith({
    List<BuzzFeedModel>? buzzFeed,
    bool? isSubscribed,
    bool? isBuzzFeedLoading,
    UpdatingState? loadMoreFeed,
    Set<String>? bookmarks,
  }) {
    return BuzzFeedSourceState(
      buzzFeed: buzzFeed ?? this.buzzFeed,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      isBuzzFeedLoading: isBuzzFeedLoading ?? this.isBuzzFeedLoading,
      loadMoreFeed: loadMoreFeed ?? this.loadMoreFeed,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}
