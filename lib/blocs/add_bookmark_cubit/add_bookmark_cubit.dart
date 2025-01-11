// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/models/bookmark_list_model.dart';
import 'package:yakihonne/nostr/nips/nips.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';

part 'add_bookmark_state.dart';

class AddBookmarkCubit extends Cubit<AddBookmarkState> {
  AddBookmarkCubit({
    required int kind,
    required String identifier,
    required String eventPubkey,
    required String image,
    required this.nostrRepository,
  }) : super(
          AddBookmarkState(
            bookmarks: nostrRepository.bookmarksLists.values.toList(),
            loadingBookmarksList: [],
            kind: kind,
            isBookmarksLists: true,
            eventId: identifier,
            eventPubkey: eventPubkey,
            image: image,
          ),
        ) {
    initView();

    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        if (!isClosed) initView();
      },
    );

    loadingBookmarksSubscription =
        nostrRepository.loadingBookmarksStream.listen(
      (loadingBookmarks) {
        if (!isClosed)
          emit(
            state.copyWith(
              loadingBookmarksList: getLoadingBookmarkIds(loadingBookmarks),
            ),
          );
      },
    );
  }

  late StreamSubscription bookmarksSubscription;
  late StreamSubscription loadingBookmarksSubscription;
  final NostrDataRepository nostrRepository;
  String title = '';
  String description = '';

  void initView() {
    emit(
      state.copyWith(
        bookmarks: nostrRepository.bookmarksLists.values.toList(),
      ),
    );
  }

  void setBookmark({
    required String bookmarkListIdentifier,
  }) {
    NostrFunctionsRepository.setBookmarks(
      isReplaceableEvent: state.kind != EventKind.TEXT_NOTE,
      identifier: state.eventId,
      pubkey: state.eventPubkey,
      bookmarkIdentifier: bookmarkListIdentifier,
      image: state.image,
      kind: state.kind,
    );
  }

  void addBookmarkList({
    required onFailure(String),
  }) async {
    if (title.trim().isEmpty) {
      onFailure.call('A valid title needs to be used');

      return;
    }

    title.trim().capitalize();
    final _cancel = BotToast.showLoading();

    final createdBookmark = BookmarkListModel(
      title: title,
      description: description,
      image: state.image,
      placeholder: '',
      eventId: '',
      identifier: StringUtil.getRandomString(16),
      bookmarkedReplaceableEvents: [
        if (state.kind != EventKind.TEXT_NOTE)
          EventCoordinates(
            state.kind,
            state.eventPubkey,
            state.eventId,
            '',
          ),
      ],
      bookmarkedEvents: [if (state.kind == EventKind.TEXT_NOTE) state.eventId],
      pubkey: nostrRepository.usm!.pubKey,
      createAt: DateTime.now(),
    );

    final event = await createdBookmark.bookmarkListModelToEvent();

    if (event == null) {
      BotToastUtils.showError(
        'Error occured when adding the bookmark',
      );
      return;
    }

    final isSuccessful = await NostrFunctionsRepository.addEvent(event: event);

    if (isSuccessful) {
      nostrRepository.addBookmarkList(
        BookmarkListModel.fromEvent(event),
      );

      title = '';
      description = '';
      setView(true);
      BotToastUtils.showSuccess(
        'Your new bookmark list has been added',
      );
    }

    _cancel.call();
  }

  void setView(bool status) {
    emit(
      state.copyWith(
        isBookmarksLists: status,
      ),
    );
  }

  void setText({required String text, required bool isTitle}) {
    if (isTitle) {
      this.title = text;
    } else {
      this.description = text;
    }
  }

  @override
  Future<void> close() {
    bookmarksSubscription.cancel();
    loadingBookmarksSubscription.cancel();
    return super.close();
  }
}
