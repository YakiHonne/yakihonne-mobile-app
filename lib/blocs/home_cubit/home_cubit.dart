import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/top_curator_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/utils.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required this.nostrRepository,
    required this.localDatabaseRepository,
    required this.buildContext,
  }) : super(
          HomeState(
            content: [],
            flashNews: nostrRepository.flashnews,
            mutes: nostrRepository.mutes.toList(),
            followingsContent: [],
            authors: {},
            sources: nostrRepository.buzzFeedSources.values.toList(),
            relays: nostrRepository.relays,
            topCurators: [],
            topCreators: [],
            isFollowingsLoading: true,
            isRelaysLoading: true,
            rebuildCurations: false,
            rebuildRelays: false,
            rebuildFavorites: false,
            isFlashNewsLoading: nostrRepository.flashnews.isEmpty,
            chosenRelay: '',
            relaysAddingData: UpdatingState.success,
            followingsAddingData: UpdatingState.success,
            userStatus: getUserStatus(),
            followings: nostrRepository.usm != null
                ? nostrRepository.user.followings.map((e) => e.key).toList()
                : [],
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            loadingBookmarks:
                getLoadingBookmarkIds(nostrRepository.loadingBookmarks).toSet(),
            userTopics: nostrRepository.userTopics,
            generalTopics: nostrRepository.topics.map((e) => e.topic).toList(),
            selectedRelays: [],
          ),
        ) {
    initView();

    appClientsCubit.getYakiHonneApp();
    userSubcription = nostrRepository.userModelStream.listen(
      (user) {
        if (user == null) {
          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: UserStatus.notConnected,
                followings: [],
                followingsContent: [],
                followingsAddingData: UpdatingState.success,
                isFollowingsLoading: true,
                userTopics: [],
              ),
            );
        } else {
          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: user.isUsingPrivKey
                    ? UserStatus.UsingPrivKey
                    : UserStatus.UsingPubKey,
              ),
            );
        }
      },
    );

    followingsSubscription = nostrRepository.followingsStream.listen(
      (followings) {
        if (!isClosed)
          emit(
            state.copyWith(
              followings: followings,
            ),
          );
      },
    );

    relaysSubscription = nostrRepository.relaysStream.listen(
      (newRelays) {
        if (newRelays.length != state.relays.length ||
            !newRelays.containsAll(state.relays)) {
          if (!isClosed)
            emit(
              state.copyWith(
                relays: newRelays,
              ),
            );
        }
      },
    );

    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        if (!isClosed)
          emit(
            state.copyWith(
              bookmarks: getBookmarkIds(bookmarks).toSet(),
            ),
          );
      },
    );

    muteListSubscription = nostrRepository.mutesStream.listen(
      (mutes) {
        if (!isClosed)
          emit(
            state.copyWith(
              mutes: mutes.toList(),
            ),
          );
      },
    );

    loadingBookmarksSubscription =
        nostrRepository.loadingBookmarksStream.listen(
      (bookmarks) {
        if (!isClosed)
          emit(
            state.copyWith(
              loadingBookmarks: getLoadingBookmarkIds(bookmarks).toSet(),
            ),
          );
      },
    );

    userTopicsSubscription = nostrRepository.userTopicsStream.listen(
      (topics) {
        emit(
          state.copyWith(
            userTopics: [],
          ),
        );

        emit(
          state.copyWith(
            userTopics: topics,
            generalTopics:
                nostrRepository.topics.map((topic) => topic.topic).toList(),
          ),
        );
      },
    );
  }

  final NostrDataRepository nostrRepository;
  late StreamSubscription userSubcription;
  late StreamSubscription relaysSubscription;
  late StreamSubscription followingsSubscription;
  late StreamSubscription bookmarksSubscription;
  late StreamSubscription loadingBookmarksSubscription;
  late StreamSubscription userTopicsSubscription;
  late StreamSubscription muteListSubscription;
  final BuildContext buildContext;
  final LocalDatabaseRepository localDatabaseRepository;

  Timer? articlesTimer;
  int index = 0;
  Set<String> requests = {};
  List<String> tags = [];
  int topicIndex = 0;

  void setIndex(int index) {
    this.index = index;
  }

  void initView() {
    getFlashNews();
    getTopicContent(0, null);
  }

  void setRelay(String relay) {
    if (state.selectedRelays.contains(relay)) {
      emit(
        state.copyWith(
          selectedRelays: List.from(state.selectedRelays)..remove(relay),
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedRelays: List.from(state.selectedRelays)..add(relay),
        ),
      );
    }
  }

  void emptyRelays() {
    emit(
      state.copyWith(
        selectedRelays: [],
      ),
    );
  }

  void getFlashNews() async {
    if (state.flashNews.isNotEmpty) {
      final authors =
          state.flashNews.map((main) => main.flashNews.pubkey).toSet().toList();

      authorsCubit.getAuthors(authors);

      return;
    }

    final mainFlashNews = await HttpFunctionsRepository.getImportantFlashnews();
    nostrRepository.flashnews = mainFlashNews;

    if (!isClosed)
      emit(
        state.copyWith(
          flashNews: mainFlashNews,
          isFlashNewsLoading: false,
        ),
      );
  }

  void setTagsValues(int index) {
    if (index <= 1) {
      tags.clear();
    } else {
      tags.clear();

      final chosenTopic = state.userTopics[index - 2];
      tags.addAll(
        [
          chosenTopic,
          chosenTopic.toLowerCase(),
          chosenTopic.toUpperCase(),
        ],
      );

      for (int i = 0; i < nostrRepository.topics.length; i++) {
        if (nostrRepository.topics[i].topic.toLowerCase() ==
            chosenTopic.toLowerCase()) {
          nostrRepository.topics[i].subTopics.forEach(
              (e) => tags.addAll([e, e.toLowerCase(), e.toUpperCase()]));
        }
      }

      tags = tags.toSet().toList();
    }
  }

  void getTopicContent(
    int? index,
    String? relay,
  ) {
    topicIndex = index ?? topicIndex;
    articlesTimer?.cancel();

    setTagsValues(topicIndex);

    if (topicIndex == 1) {
      final followings =
          nostrRepository.user.followings.map((e) => e.key).toList();

      if (!isClosed)
        emit(
          state.copyWith(
            isRelaysLoading: true,
            relaysAddingData: UpdatingState.success,
            content: [],
            followings: followings.isEmpty ? [yakihonneHex] : followings,
            topCreators: [],
            chosenRelay: relay,
          ),
        );
    } else {
      if (!isClosed)
        emit(
          state.copyWith(
            isRelaysLoading: true,
            relaysAddingData: UpdatingState.success,
            topCreators: [],
            content: [],
            chosenRelay: relay,
          ),
        );
    }

    NostrFunctionsRepository.getHomePageData(
      isBuzzFeed: tags.length == 1 &&
          nostrRepository.buzzFeedSources.keys.contains(tags.first),
      limit: kElPerPage,
      pubkeys: topicIndex == 1 ? state.followings : null,
      tags: topicIndex <= 1 ? null : tags,
      relay: state.chosenRelay.isNotEmpty ? state.chosenRelay : null,
    ).listen(
      (content) {
        if (!isClosed)
          emit(
            state.copyWith(
              content: content,
              isRelaysLoading: false,
            ),
          );
      },
      onDone: () {
        if (!isClosed)
          emit(
            state.copyWith(
              content: List.from(state.content),
              isRelaysLoading: false,
            ),
          );
      },
    );
  }

  Future<void> getMoreTopicContent() async {
    try {
      int lastIndex = state.content.length;
      List<dynamic> onGoingContent = [];
      List<dynamic> currentContent = List.from(state.content);

      if (!isClosed)
        emit(
          state.copyWith(
            relaysAddingData: UpdatingState.progress,
          ),
        );

      final until = lastIndex == 0
          ? null
          : ((state.content[lastIndex - 1]).createdAt as DateTime)
                  .toSecondsSinceEpoch() -
              1;

      NostrFunctionsRepository.getHomePageData(
        isBuzzFeed: tags.length == 1 &&
            nostrRepository.buzzFeedSources.keys.contains(tags.first),
        limit: kElPerPage,
        pubkeys: topicIndex == 1 ? state.followings : null,
        tags: topicIndex <= 1 ? null : tags,
        until: until,
        relay: state.chosenRelay.isNotEmpty ? state.chosenRelay : null,
      ).listen(
        (content) {
          onGoingContent = content;
          if (!isClosed)
            emit(
              state.copyWith(
                content: [...currentContent, ...content],
                isRelaysLoading: false,
                relaysAddingData: UpdatingState.success,
              ),
            );
        },
        onDone: () {
          emit(
            state.copyWith(
              isRelaysLoading: false,
              relaysAddingData:
                  onGoingContent.isEmpty ? UpdatingState.idle : null,
            ),
          );
        },
      );
    } catch (e) {
      lg.i(e);
    }
  }

  @override
  Future<void> close() {
    userSubcription.cancel();
    relaysSubscription.cancel();
    followingsSubscription.cancel();
    bookmarksSubscription.cancel();
    loadingBookmarksSubscription.cancel();
    userTopicsSubscription.cancel();
    muteListSubscription.cancel();
    NostrConnect.sharedInstance.closeRequests(requests.toList());
    return super.close();
  }
}
