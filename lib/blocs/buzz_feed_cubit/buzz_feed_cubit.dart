import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/utils.dart';

part 'buzz_feed_state.dart';

class BuzzFeedCubit extends Cubit<BuzzFeedState> {
  BuzzFeedCubit()
      : super(
          BuzzFeedState(
            buzzFeed: [],
            isBuzzFeedLoading: true,
            buzzFeedSources: nostrRepository.buzzFeedSources.values.toList(),
            index: 0,
            loadMoreFeed: UpdatingState.success,
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
  }

  late StreamSubscription bookmarksSubscription;

  void getBuzzFeed({
    required int index,
  }) {
    List<String>? tags;
    if (index != 0) {
      final source = state.buzzFeedSources[index - 1];
      tags = [source.name];
    }

    emit(
      state.copyWith(index: index, loadMoreFeed: UpdatingState.success),
    );

    NostrFunctionsRepository.getBuzzFeed(
      tags: tags,
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
    List<String>? tags;

    if (state.index != 0) {
      final source = state.buzzFeedSources[state.index - 1];
      tags = [source.name];
    }

    final createdAt = old.last.createdAt;

    NostrFunctionsRepository.getBuzzFeed(
      tags: tags,
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
    return super.close();
  }
}
