import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/bookmark_list_model.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/utils.dart';

part 'bookmark_details_state.dart';

class BookmarkDetailsCubit extends Cubit<BookmarkDetailsState> {
  BookmarkDetailsCubit({
    required this.nostrRepository,
    required BookmarkListModel bookmarkListModel,
  }) : super(
          BookmarkDetailsState(
            content: <dynamic>[],
            authors: {},
            mutes: nostrRepository.mutes.toList(),
            bookmarkListModel: bookmarkListModel,
            followings: nostrRepository.followings,
            isLoading: true,
            userStatus: getUserStatus(),
          ),
        ) {
    getBookmarks();

    bookmarksListsSubcription = nostrRepository.bookmarksStream.listen(
      (bookmarksLists) {
        final newBookmarkList = bookmarksLists[bookmarkListModel.identifier];

        if (newBookmarkList != null) {
          if (!isClosed)
            emit(
              state.copyWith(
                bookmarkListModel: newBookmarkList,
              ),
            );

          getBookmarks();
        }
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
  }

  final NostrDataRepository nostrRepository;
  late StreamSubscription bookmarksListsSubcription;
  late StreamSubscription muteListSubscription;
  List<dynamic> globalContent = [];

  void getBookmarks() {
    final requestId = NostrFunctionsRepository.getBookmarks(
      bookmarksModel: state.bookmarkListModel,
      contentFunc: (content) {
        globalContent = content;

        if (!isClosed)
          emit(
            state.copyWith(
              content: content,
              isLoading: false,
            ),
          );
      },
    );

    if (requestId.isEmpty) {
      if (!isClosed)
        emit(
          state.copyWith(
            content: [],
          ),
        );
    }
  }

  void filterBookmarksByType(String bookmarkType) {
    if (bookmarkType == bookmarksTypes[0]) {
      emit(
        state.copyWith(
          content: globalContent,
        ),
      );
    } else if (bookmarkType == bookmarksTypes[1]) {
      final newContent =
          globalContent.where((item) => item is Article).toList();

      emit(
        state.copyWith(
          content: newContent,
        ),
      );
    } else if (bookmarkType == bookmarksTypes[2]) {
      final newContent =
          globalContent.where((item) => item is Curation).toList();

      emit(
        state.copyWith(
          content: newContent,
        ),
      );
    } else if (bookmarkType == bookmarksTypes[3]) {
      final newContent =
          globalContent.where((item) => item is FlashNews).toList();

      emit(
        state.copyWith(
          content: newContent,
        ),
      );
    } else if (bookmarkType == bookmarksTypes[4]) {
      final newContent =
          globalContent.where((item) => item is DetailedNoteModel).toList();

      emit(
        state.copyWith(
          content: newContent,
        ),
      );
    } else if (bookmarkType == bookmarksTypes[5]) {
      final newContent =
          globalContent.where((item) => item is VideoModel).toList();

      emit(
        state.copyWith(
          content: newContent,
        ),
      );
    } else if (bookmarkType == bookmarksTypes[6]) {
      final newContent =
          globalContent.where((item) => item is BuzzFeedModel).toList();

      emit(
        state.copyWith(
          content: newContent,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    bookmarksListsSubcription.cancel();
    muteListSubscription.cancel();
    return super.close();
  }
}
