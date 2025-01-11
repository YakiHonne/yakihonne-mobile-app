import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:yakihonne/models/bookmark_list_model.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';

part 'bookmarks_state.dart';

class BookmarksCubit extends Cubit<BookmarksState> {
  BookmarksCubit({
    required this.nostrRepository,
  }) : super(
          BookmarksState(
            userStatus: getUserStatus(),
            bookmarksLists: nostrRepository.bookmarksLists.values.toList(),
          ),
        ) {
    bookmarksListsSubcription = nostrRepository.bookmarksStream.listen(
      (bookmarksLists) {
        emit(
          state.copyWith(
            bookmarksLists: nostrRepository.bookmarksLists.values.toList(),
          ),
        );
      },
    );

    userSubcription = nostrRepository.userModelStream.listen(
      (user) {
        if (user == null) {
          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: UserStatus.notConnected,
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
  }

  final NostrDataRepository nostrRepository;
  late StreamSubscription userSubcription;
  late StreamSubscription bookmarksListsSubcription;
  String title = '';
  String description = '';

  void setText({required String text, required bool isTitle}) {
    if (isTitle) {
      this.title = text;
    } else {
      this.description = text;
    }
  }

  void deleteBookmarksList({
    required String bookmarkListEventId,
    required String bookmarkListIdentifier,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    final isSuccessful = await NostrFunctionsRepository.deleteEvent(
      eventId: bookmarkListEventId,
    );

    if (isSuccessful) {
      nostrRepository.deleteBookmarkList(bookmarkListIdentifier);
      BotToastUtils.showSuccess('Bookmarks list has been deleted.');
      onSuccess.call();
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }

    _cancel.call();
  }

  void addBookmarkList({
    required BuildContext context,
    required Function(String) onFailure,
    required Function() onSuccess,
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
      image: '',
      placeholder: '',
      identifier: StringUtil.getRandomString(16),
      bookmarkedReplaceableEvents: [],
      bookmarkedEvents: [],
      eventId: '',
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
      BotToastUtils.showSuccess('Bookmarks list has been added!');
      onSuccess.call();
    }

    _cancel.call();
  }

  void showText({
    required String text,
    required BuildContext context,
  }) {
    BotToast.showCustomLoading(
      toastBuilder: (cancelFunc) {
        return Material(
          child: Container(
            padding: const EdgeInsets.all(kDefaultPadding / 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              color: kLightGrey,
            ),
            child: Row(
              children: [
                Text(
                  '${text}',
                ),
                IconButton(
                  onPressed: cancelFunc,
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    userSubcription.cancel();
    bookmarksListsSubcription.cancel();
    return super.close();
  }
}
