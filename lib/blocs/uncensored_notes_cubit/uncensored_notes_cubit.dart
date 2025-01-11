import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'uncensored_notes_state.dart';

const FETCH_NEW = 'new';
const FETCH_NEEDS_MORE_HELP = 'needs-more-help';
const FETCH_HELPFUL = 'sealed';

class UncensoredNotesCubit extends Cubit<UncensoredNotesState> {
  UncensoredNotesCubit()
      : super(
          UncensoredNotesState(
            unNewFlashNews: [],
            loading: true,
            balance: 0,
            index: 0,
            page: 0,
            userStatus: getUserStatus(),
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            addingFlashNewsStatus: UpdatingState.success,
          ),
        ) {
    getBalance();
    getUnFlashnews(FETCH_NEW, 0);

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

  late StreamSubscription bookmarksSubscription;

  void setIndex(int index) {
    if (index == 0) {
      emit(
        state.copyWith(
          loading: true,
          index: 0,
          page: 0,
          addingFlashNewsStatus: UpdatingState.success,
          unNewFlashNews: [],
        ),
      );

      getUnFlashnews(FETCH_NEW, 0);
    } else if (index == 1) {
      emit(
        state.copyWith(
          loading: true,
          index: 1,
          page: 0,
          addingFlashNewsStatus: UpdatingState.success,
          unNewFlashNews: [],
        ),
      );

      getUnFlashnews(FETCH_NEEDS_MORE_HELP, 0);
    } else {
      emit(
        state.copyWith(
          loading: true,
          index: 2,
          page: 0,
          addingFlashNewsStatus: UpdatingState.success,
          unNewFlashNews: [],
        ),
      );

      getUnFlashnews(FETCH_HELPFUL, 0);
    }
  }

  void getBalance() async {
    final balance = await HttpFunctionsRepository.getBalance();
    emit(
      state.copyWith(
        balance: balance,
      ),
    );
  }

  void getUnFlashnews(String extension, int page) async {
    try {
      final unFlashNews =
          await HttpFunctionsRepository.getNewFlashnews(extension, page);

      emit(
        state.copyWith(
          unNewFlashNews: unFlashNews,
          loading: false,
        ),
      );
    } catch (e) {
      Logger().i(e);
    }
  }

  void addMoreUnFlashnews() async {
    try {
      final extension = state.index == 0
          ? FETCH_NEW
          : state.index == 1
              ? FETCH_NEEDS_MORE_HELP
              : FETCH_HELPFUL;

      emit(
        state.copyWith(
          addingFlashNewsStatus: UpdatingState.progress,
        ),
      );

      final flashnews = await HttpFunctionsRepository.getNewFlashnews(
        extension,
        state.page + 1,
      );

      if (flashnews.isEmpty) {
        emit(
          state.copyWith(
            addingFlashNewsStatus: UpdatingState.idle,
          ),
        );
      } else {
        emit(
          state.copyWith(
            addingFlashNewsStatus: UpdatingState.success,
            unNewFlashNews: [...state.unNewFlashNews, ...flashnews],
            page: state.page + 1,
          ),
        );
      }
    } catch (e) {
      Logger().i(e);
      emit(
        state.copyWith(
          addingFlashNewsStatus: UpdatingState.idle,
        ),
      );
    }
  }

  void deleteRating({
    required String uncensoredNoteId,
    required String ratingId,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    final isSuccessful = await NostrFunctionsRepository.deleteEvent(
      eventId: ratingId,
      lable: FN_SEARCH_VALUE,
      type: 'r',
    );

    if (isSuccessful) {
      BotToastUtils.showSuccess('Your rating has been deleted');
      onSuccess.call();
    } else {
      BotToastUtils.showError('Error occured while deleting your rating');
    }

    _cancel.call();
  }

  @override
  Future<void> close() {
    bookmarksSubscription.cancel();
    return super.close();
  }
}
