// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:aescryptojs/aescryptojs.dart';
import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'un_flash_news_details_state.dart';

class UnFlashNewsDetailsCubit extends Cubit<UnFlashNewsDetailsState> {
  UnFlashNewsDetailsCubit({
    required this.unFlashNews,
  }) : super(
          UnFlashNewsDetailsState(
            userStatus: nostrRepository.usm == null
                ? UserStatus.notConnected
                : nostrRepository.usm!.isUsingPrivKey
                    ? UserStatus.UsingPrivKey
                    : UserStatus.UsingPubKey,
            isBookmarked: getBookmarkIds(nostrRepository.bookmarksLists)
                .toSet()
                .contains(unFlashNews.flashNews.id),
            loading: true,
            isSealed: unFlashNews.isSealed,
            uncensoredNotes: [],
            notHelpFulNotes: [],
            writingNoteStatus: WritingNoteStatus.disabled,
          ),
        ) {
    getUncensoredNotes();

    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        if (!isClosed)
          emit(
            state.copyWith(
              isBookmarked: getBookmarkIds(bookmarks)
                  .toSet()
                  .contains(unFlashNews.flashNews.id),
            ),
          );
      },
    );

    userSubscription = nostrRepository.userModelStream.listen(
      (userStatusModel) {
        WritingNoteStatus writingNoteStatus = WritingNoteStatus.disabled;

        if (state.userStatus == UserStatus.UsingPrivKey &&
            nostrRepository.user.pubKey != unFlashNews.flashNews.pubkey &&
            !unFlashNews.isSealed) {
          final canBeWritten = state.uncensoredNotes
              .where(
                (element) => element.pubKey == nostrRepository.user.pubKey,
              )
              .toList()
              .isEmpty;

          writingNoteStatus = canBeWritten
              ? WritingNoteStatus.canBeWritten
              : WritingNoteStatus.alreadyWritten;
        }

        if (!isClosed)
          emit(
            state.copyWith(
              writingNoteStatus: writingNoteStatus,
              userStatus: userStatusModel == null
                  ? UserStatus.notConnected
                  : userStatusModel.isUsingPrivKey
                      ? UserStatus.UsingPrivKey
                      : UserStatus.UsingPubKey,
            ),
          );
      },
    );
  }

  late StreamSubscription bookmarksSubscription;
  late StreamSubscription userSubscription;
  final UnFlashNews unFlashNews;

  void getUncensoredNotes() async {
    try {
      emit(
        state.copyWith(
          loading: true,
          uncensoredNotes: [],
          writingNoteStatus: WritingNoteStatus.disabled,
        ),
      );

      final data = await HttpFunctionsRepository.getUncensoredNotes(
        flashNewsId: unFlashNews.flashNews.id,
      );

      List<UncensoredNote> notes = data['notes'] as List<UncensoredNote>;

      if (unFlashNews.isSealed) {
        notes = notes
            .where((element) =>
                element.id != unFlashNews.sealedNote!.uncensoredNote.id)
            .toList();
      }

      WritingNoteStatus writingNoteStatus = WritingNoteStatus.disabled;

      if (state.userStatus == UserStatus.UsingPrivKey &&
          nostrRepository.user.pubKey != unFlashNews.flashNews.pubkey &&
          !unFlashNews.isSealed) {
        final canBeWritten = notes
            .where(
              (element) => element.pubKey == nostrRepository.user.pubKey,
            )
            .toList()
            .isEmpty;

        writingNoteStatus = canBeWritten
            ? WritingNoteStatus.canBeWritten
            : WritingNoteStatus.alreadyWritten;
      }

      emit(
        state.copyWith(
          uncensoredNotes: notes,
          loading: false,
          notHelpFulNotes: data['notHelpful'],
          writingNoteStatus: writingNoteStatus,
        ),
      );
    } catch (e, stack) {
      Logger().i(stack);
    }
  }

  void addUncensoredNotes({
    required String content,
    required String source,
    required bool isCorrect,
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
        ['e', unFlashNews.flashNews.id],
        ['p', unFlashNews.flashNews.pubkey],
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
      getUncensoredNotes();

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
