// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'buzz_feed_cubit.dart';

class BuzzFeedState extends Equatable {
  final List<BuzzFeedModel> buzzFeed;
  final bool isBuzzFeedLoading;
  final List<BuzzFeedSource> buzzFeedSources;
  final UpdatingState loadMoreFeed;
  final Set<String> bookmarks;
  final int index;

  BuzzFeedState({
    required this.buzzFeed,
    required this.isBuzzFeedLoading,
    required this.buzzFeedSources,
    required this.loadMoreFeed,
    required this.bookmarks,
    required this.index,
  });

  @override
  List<Object> get props => [
        buzzFeed,
        isBuzzFeedLoading,
        buzzFeedSources,
        index,
        loadMoreFeed,
        bookmarks,
      ];

  BuzzFeedState copyWith({
    List<BuzzFeedModel>? buzzFeed,
    bool? isBuzzFeedLoading,
    List<BuzzFeedSource>? buzzFeedSources,
    UpdatingState? loadMoreFeed,
    Set<String>? bookmarks,
    int? index,
  }) {
    return BuzzFeedState(
      buzzFeed: buzzFeed ?? this.buzzFeed,
      isBuzzFeedLoading: isBuzzFeedLoading ?? this.isBuzzFeedLoading,
      buzzFeedSources: buzzFeedSources ?? this.buzzFeedSources,
      loadMoreFeed: loadMoreFeed ?? this.loadMoreFeed,
      bookmarks: bookmarks ?? this.bookmarks,
      index: index ?? this.index,
    );
  }
}
