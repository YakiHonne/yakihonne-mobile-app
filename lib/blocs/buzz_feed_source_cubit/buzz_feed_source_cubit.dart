import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/utils.dart';

part 'buzz_feed_source_state.dart';

class BuzzFeedSourceCubit extends Cubit<BuzzFeedSourceState> {
  BuzzFeedSourceCubit({
    required this.buzzFeedSource,
  }) : super(
          BuzzFeedSourceState(
            buzzFeed: [],
            isBuzzFeedLoading: true,
            loadMoreFeed: UpdatingState.success,
            isSubscribed: getUserStatus() == UserStatus.UsingPrivKey &&
                List<String>.from(nostrRepository.userTopics).contains(
                  buzzFeedSource.name,
                ),
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
          ),
        ) {
    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        if (!isClosed)
          emit(
            state.copyWith(
              bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            ),
          );
      },
    );

    userTopicsSubscription = nostrRepository.userTopicsStream.listen(
      (topics) {
        if (!isClosed)
          emit(
            state.copyWith(
              isSubscribed: topics.contains(buzzFeedSource.name),
            ),
          );
      },
    );
  }

  late BuzzFeedSource buzzFeedSource;
  late StreamSubscription bookmarksSubscription;
  late StreamSubscription userTopicsSubscription;

  void getBuzzFeed() {
    emit(
      state.copyWith(loadMoreFeed: UpdatingState.success),
    );

    NostrFunctionsRepository.getBuzzFeed(
      tags: [buzzFeedSource.name],
      onAiFeedFunc: (feed) {
        emit(
          state.copyWith(
            buzzFeed: feed,
            isBuzzFeedLoading: false,
          ),
        );
      },
      onDone: () {
        emit(
          state.copyWith(
            isBuzzFeedLoading: false,
          ),
        );
      },
      limit: 20,
    );
  }

  void getMoreBuzzFeed() {
    List<BuzzFeedModel> old = List.from(state.buzzFeed);
    List<BuzzFeedModel> currentFeed = [];

    final createdAt = old.last.createdAt;

    NostrFunctionsRepository.getBuzzFeed(
      tags: [buzzFeedSource.name],
      until: createdAt.toSecondsSinceEpoch() - 1,
      onAiFeedFunc: (feed) {
        currentFeed = feed;
        final updatedFeed = [...old, ...currentFeed];

        emit(
          state.copyWith(
            loadMoreFeed: UpdatingState.success,
            buzzFeed: updatedFeed,
          ),
        );
      },
      onDone: () {
        if (currentFeed.isEmpty) {
          emit(
            state.copyWith(
              loadMoreFeed: UpdatingState.idle,
            ),
          );
        }
      },
      limit: 20,
    );
  }

  @override
  Future<void> close() {
    bookmarksSubscription.cancel();
    userTopicsSubscription.cancel();
    return super.close();
  }
}
