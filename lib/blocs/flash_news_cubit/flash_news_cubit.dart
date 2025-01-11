import 'dart:async';

import 'package:aescryptojs/aescryptojs.dart';
import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'flash_news_state.dart';

class FlashNewsCubit extends Cubit<FlashNewsState> {
  FlashNewsCubit()
      : super(
          FlashNewsState(
            flashNews: {},
            isFlashNewsLoading: true,
            isImportant: false,
            selectedDate: DateTime.now(),
            isSpecificDateSelected: false,
            mutes: nostrRepository.mutes.toList(),
            loadingFlashNews: UpdatingState.success,
            userStatus: getUserStatus(),
            votes: {},
            currentUserPubkey: nostrRepository.user.pubKey,
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            refreshContent: false,
          ),
        ) {
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

    userSubscription = nostrRepository.userModelStream.listen((user) {
      emit(
        state.copyWith(
          userStatus: nostrRepository.usm == null
              ? UserStatus.notConnected
              : nostrRepository.usm!.isUsingPrivKey
                  ? UserStatus.UsingPrivKey
                  : UserStatus.UsingPubKey,
        ),
      );
    });

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
  }

  late StreamSubscription muteListSubscription;
  late StreamSubscription userSubscription;
  late StreamSubscription bookmarksSubscription;

  Set<String> requests = {};
  Map<String, List<MainFlashNews>> flashNewsMap = {};
  int page = 0;
  DateTime currentDate = DateTime.now();
  int currentTotal = 0;

  void getFlashNews({DateTime? selectedDate, required bool add}) async {
    try {
      NostrConnect.sharedInstance.closeRequests(requests.toList());

      if (!add) {
        page = 0;
        currentTotal = 0;
        currentDate = selectedDate ?? currentDate;
        flashNewsMap = {};

        emit(
          state.copyWith(
            loadingFlashNews: UpdatingState.success,
            flashNews: {},
            votes: {},
            isFlashNewsLoading: true,
            selectedDate: currentDate,
          ),
        );
      } else {
        emit(
          state.copyWith(
            selectedDate: selectedDate ?? DateTime.now(),
            loadingFlashNews: UpdatingState.progress,
          ),
        );
      }

      if (currentDate.isBefore(DateTime(2024, 1, 30))) {
        emit(
          state.copyWith(
            loadingFlashNews: UpdatingState.idle,
          ),
        );

        return;
      }

      String formattedCurrentDate = dateFormat2.format(currentDate);

      if (currentTotal == flashNewsMap[formattedCurrentDate]?.length && add) {
        currentDate = currentDate.subtract(Duration(days: 1));
        formattedCurrentDate = dateFormat2.format(currentDate);
        page = 0;
        currentTotal = 0;
      } else if (add) {
        page = page + 1;
      }

      final mainFlashNews = await HttpFunctionsRepository.getFlashNews(
        date: currentDate,
        page: page,
      );

      currentTotal = mainFlashNews['total'];
      final fnList = List<MainFlashNews>.from(mainFlashNews['flashnews']);
      final res = flashNewsMap[formattedCurrentDate];

      if (res == null) {
        flashNewsMap[formattedCurrentDate] = fnList;

        emit(
          state.copyWith(
            flashNews: getFilteredFlashNews(),
            loadingFlashNews: UpdatingState.success,
            isFlashNewsLoading: false,
          ),
        );
      } else {
        flashNewsMap[formattedCurrentDate]!.addAll(fnList);

        emit(
          state.copyWith(
            flashNews: getFilteredFlashNews(),
            loadingFlashNews: UpdatingState.success,
          ),
        );
      }

      final startDate = DateTime(2023, 12, 1);

      if (currentDate.isAfter(startDate) && fnList.isEmpty) {
        getFlashNews(add: true);
      } else if (fnList.isNotEmpty) {
        Set<String> eventIds = {};

        fnList.forEach(
          (element) {
            eventIds.add(element.flashNews.id);
          },
        );

        if (eventIds.isNotEmpty) {
          getVotes(eventIds.toList());
        }
      } else {
        emit(
          state.copyWith(
            loadingFlashNews: UpdatingState.idle,
          ),
        );
      }
    } catch (e) {
      lg.i(e);
    }
  }

  void updateFlashNews({
    required MainFlashNews mainFlashNews,
    required String date,
  }) {
    final map = Map<String, List<MainFlashNews>>.from(state.flashNews);

    List<MainFlashNews> mainFlashNewsList = List<MainFlashNews>.from(
      state.flashNews[date]!,
    );

    final index = mainFlashNewsList.indexOf(mainFlashNews);

    mainFlashNewsList[index] = mainFlashNews.copyWith(
      unPubkeys: [...mainFlashNews.unPubkeys, nostrRepository.usm!.pubKey],
    );

    map[date] = mainFlashNewsList;

    emit(
      state.copyWith(
        refreshContent: !state.refreshContent,
        flashNews: map,
      ),
    );
  }

  void addUncensoredNote({
    required String content,
    required String source,
    required bool isCorrect,
    required FlashNews flashNews,
    required Function() onSuccess,
  }) async {
    final createdAt = currentUnixTimestampSeconds();
    final encryptedMessage = encryptAESCryptoJS(
      createdAt.toString(),
      dotenv.env['FN_KEY']!,
    );

    final event = await Event.genEvent(
      kind: EventKind.TEXT_NOTE,
      content: content,
      createdAt: createdAt,
      privkey: nostrRepository.usm!.privKey,
      pubkey: nostrRepository.usm!.pubKey,
      verify: true,
      tags: [
        ['l', UN_SEARCH_VALUE],
        if (source.isNotEmpty) ['source', source],
        [
          FN_ENCRYPTION,
          encryptedMessage,
        ],
        ['e', flashNews.id],
        ['p', flashNews.pubkey],
        ['type', isCorrect ? '+' : '-'],
      ],
    );

    if (event == null) {
      return;
    }

    final _cancel = BotToast.showLoading();

    final isSuccessful = await NostrFunctionsRepository.addEvent(
      event: event,
    );

    if (isSuccessful) {
      BotToastUtils.showSuccess(
        'Your uncensored note has been added, check your rewards page to claim your writing reward',
      );

      onSuccess.call();
    } else {
      BotToastUtils.showError(
        'Error occured while adding your uncensored note',
      );
    }

    _cancel.call();
  }

  void getVotes(List<String> eventIds) {
    NostrFunctionsRepository.getStats(
      selectedKinds: [EventKind.REACTION],
      eventKind: EventKind.TEXT_NOTE,
      eventIds: eventIds.toSet().toList(),
      isEtag: true,
    ).listen(
      (results) {
        if (results is Map<String, Map<String, VoteModel>>) {
          final votes = Map<String, Map<String, VoteModel>>.from(state.votes)
            ..addAll(results);
          if (!isClosed)
            emit(
              state.copyWith(
                votes: votes,
              ),
            );
        }
      },
    );
  }

  void setVote({
    required bool upvote,
    required String eventId,
    required String eventPubkey,
  }) async {
    final _cancel = BotToast.showLoading();

    final currentVoteModel = state.votes[eventId]?[state.currentUserPubkey];

    if (currentVoteModel == null || upvote != currentVoteModel.vote) {
      final addingEventId = await NostrFunctionsRepository.addVote(
        eventId: eventId,
        upvote: upvote,
        eventPubkey: eventPubkey,
        isEtag: true,
      );

      if (addingEventId != null) {
        if (currentVoteModel != null) {
          await NostrFunctionsRepository.deleteEvent(
            eventId: currentVoteModel.eventId,
          );
        }

        Map<String, VoteModel> newMap = Map.from(state.votes[eventId] ?? {});

        newMap[state.currentUserPubkey] = VoteModel(
          eventId: addingEventId,
          pubkey: state.currentUserPubkey,
          vote: upvote,
        );

        emit(
          state.copyWith(
            votes: Map.from(state.votes)
              ..addAll(
                {eventId: newMap},
              ),
          ),
        );
      } else {
        BotToastUtils.showError('Vote could not be submitted');
      }
    } else {
      final isSuccessful = await NostrFunctionsRepository.deleteEvent(
        eventId: currentVoteModel.eventId,
      );

      if (isSuccessful) {
        Map<String, VoteModel> newMap = Map.from(state.votes[eventId] ?? {});

        newMap.remove(currentVoteModel.pubkey);

        emit(
          state.copyWith(
            votes: Map.from(state.votes)
              ..addAll(
                {eventId: newMap},
              ),
          ),
        );
      } else {
        BotToastUtils.showError('Vote could not be submitted');
      }
    }

    _cancel.call();
  }

  void filterByImportance() {
    final importance = !state.isImportant;
    Map<String, List<MainFlashNews>> updatedFlashNews = {};

    if (importance) {
      flashNewsMap.forEach(
        (key, flashNews) {
          updatedFlashNews[key] = flashNews
              .where((main) => main.flashNews.isImportant == importance)
              .toList();
        },
      );
    } else {
      updatedFlashNews = flashNewsMap;
    }

    emit(
      state.copyWith(
        flashNews: updatedFlashNews,
        isImportant: importance,
      ),
    );
  }

  Map<String, List<MainFlashNews>> getFilteredFlashNews() {
    Map<String, List<MainFlashNews>> updatedFlashNews = {};

    if (state.isImportant) {
      flashNewsMap.forEach(
        (key, flashNews) {
          updatedFlashNews[key] =
              flashNews.where((main) => main.flashNews.isImportant).toList();
        },
      );

      return updatedFlashNews;
    } else {
      flashNewsMap.forEach(
        (key, flashNews) {
          if (flashNews.isNotEmpty) {
            updatedFlashNews[key] = flashNews;
          }
        },
      );
      return updatedFlashNews;
    }
  }

  @override
  Future<void> close() {
    muteListSubscription.cancel();
    bookmarksSubscription.cancel();
    userSubscription.cancel();
    NostrConnect.sharedInstance.closeRequests(requests.toList());
    return super.close();
  }
}
