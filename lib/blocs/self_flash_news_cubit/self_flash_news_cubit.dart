import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'self_flash_news_state.dart';

class SelfFlashNewsCubit extends Cubit<SelfFlashNewsState> {
  SelfFlashNewsCubit()
      : super(
          SelfFlashNewsState(
            flashNews: [],
            isFlashLoading: true,
            pendingFlashNews: [],
            isFlashNewsSelected: true,
            isImportant: false,
            userStatus: getUserStatus(),
          ),
        ) {
    getPendingFlashNews();
  }

  List<FlashNews> flashNewsMap = [];

  void filterByImportance() {
    final importance = !state.isImportant;
    List<FlashNews> updatedFlashNews = [];
    List<PendingFlashNews> updatedPendings = [];

    if (importance) {
      updatedFlashNews = flashNewsMap
          .where((element) => element.isImportant == importance)
          .toList();

      updatedPendings = nostrRepository.pendingFlashNews
          .where(
            (element) =>
                element.flashNews.isImportant == importance &&
                element.pubkey == nostrRepository.usm!.pubKey,
          )
          .toList();
    } else {
      updatedFlashNews = flashNewsMap;
      final filtered = nostrRepository.pendingFlashNews
          .where((element) => element.pubkey == nostrRepository.usm!.pubKey)
          .toList();

      updatedPendings = filtered;
    }

    emit(
      state.copyWith(
        flashNews: updatedFlashNews,
        pendingFlashNews: updatedPendings,
        isImportant: importance,
      ),
    );
  }

  void setFlashNewsSelected(bool isFlashNews) {
    emit(
      state.copyWith(
        isFlashNewsSelected: isFlashNews,
      ),
    );
  }

  void getPendingFlashNews() {
    nostrRepository.getAndFilterPendingFlashNews();

    final filtered = nostrRepository.pendingFlashNews
        .where((element) => element.pubkey == nostrRepository.usm!.pubKey)
        .toList();

    emit(
      state.copyWith(
        pendingFlashNews: filtered,
      ),
    );
  }

  void getFlashNews() {
    NostrFunctionsRepository.getUserFlashNews(
      pubkey: nostrRepository.usm!.pubKey,
    ).listen(
      (flashNews) {
        flashNewsMap = flashNews;

        emit(
          state.copyWith(
            isFlashLoading: false,
            flashNews: flashNews,
          ),
        );
      },
      onDone: () {
        emit(
          state.copyWith(
            isFlashLoading: false,
          ),
        );
      },
    );
  }

  void submitPendingFlashNews({
    required PendingFlashNews pendingFlashNews,
  }) async {
    final _cancel = BotToast.showLoading();

    final isChecked = await NostrFunctionsRepository.checkPayment(
      pendingFlashNews.eventId,
    );

    if (isChecked) {
      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: Event.fromJson(pendingFlashNews.event),
        setProgress: true,
      );

      if (isSuccessful) {
        nostrRepository.deletePendingFlashNews(pendingFlashNews);
        BotToastUtils.showSuccess('Your flash news has been published');

        emit(
          state.copyWith(
            flashNews: List<FlashNews>.from(state.flashNews)
              ..insert(0, pendingFlashNews.flashNews),
            pendingFlashNews: nostrRepository.pendingFlashNews
                .where(
                    (element) => element.pubkey == nostrRepository.usm!.pubKey)
                .toList(),
          ),
        );
      } else {
        BotToastUtils.showError(
          'Error occured while publishing the event',
        );
      }

      _cancel.call();
    } else {
      _cancel.call();
      BotToastUtils.showError(
        "It seemse that you didn't pay the invoice, recheck again",
      );
    }
  }

  void payWithWallet({
    required PendingFlashNews pendingFlashNews,
  }) async {
    final _cancel = BotToast.showLoading();

    final isChecked = await NostrFunctionsRepository.checkPayment(
      pendingFlashNews.eventId,
    );

    if (isChecked) {
      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: Event.fromJson(pendingFlashNews.event),
        setProgress: true,
      );

      if (isSuccessful) {
        nostrRepository.deletePendingFlashNews(pendingFlashNews);
        BotToastUtils.showSuccess('Your flash news has been published');

        emit(
          state.copyWith(
            flashNews: List<FlashNews>.from(state.flashNews)
              ..insert(0, pendingFlashNews.flashNews),
            pendingFlashNews: nostrRepository.pendingFlashNews
                .where(
                    (element) => element.pubkey == nostrRepository.usm!.pubKey)
                .toList(),
          ),
        );
      } else {
        BotToastUtils.showError(
          'Error occured while publishing the event',
        );
      }

      _cancel.call();
    } else {
      _cancel.call();
      BotToastUtils.showError(
        "It seemse that you didn't pay the invoice, recheck again",
      );
    }
  }

  void deleteFlashNews(
    FlashNews flashNews,
    Function() onSuccess,
  ) async {
    final _cancel = BotToast.showLoading();

    final isSuccessful = await NostrFunctionsRepository.deleteEvent(
      eventId: flashNews.id,
      lable: FN_SEARCH_VALUE,
      type: 'f',
    );

    if (isSuccessful) {
      onSuccess.call();

      emit(
        state.copyWith(
          flashNews: state.flashNews
              .where((element) => element.id != flashNews.id)
              .toList(),
        ),
      );
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }

    _cancel.call();
  }
}
