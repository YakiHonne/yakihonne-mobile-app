import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/utils.dart';

part 'articles_state.dart';

class ArticlesCubit extends Cubit<ArticlesState> {
  ArticlesCubit()
      : super(
          ArticlesState(
            articles: [],
            isLoading: true,
            loadingState: UpdatingState.success,
            selectedRelay: '',
            followings: nostrRepository.usm != null
                ? nostrRepository.user.followings.map((e) => e.key).toList()
                : [],
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            mutes: nostrRepository.mutes.toList(),
            relays: nostrRepository.relays,
          ),
        ) {
    getArticles(isAdd: false);

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
  }

  late StreamSubscription muteListSubscription;
  late StreamSubscription followingsSubscription;
  late StreamSubscription bookmarksSubscription;

  void getArticles({required bool isAdd, String? relay}) {
    final oldArticles = List<Article>.from(state.articles);
    if (isAdd) {
      emit(
        state.copyWith(
          loadingState: UpdatingState.progress,
          selectedRelay: relay,
        ),
      );
    } else {
      emit(
        state.copyWith(
          articles: [],
          isLoading: true,
          selectedRelay: relay,
        ),
      );
    }

    List<Article> addedArticles = [];

    NostrFunctionsRepository.getArticles(
      articleFilter: ArticleFilter.Published,
      limit: 20,
      relay: state.selectedRelay.isNotEmpty ? state.selectedRelay : null,
      until: isAdd
          ? state.articles.last.createdAt.toSecondsSinceEpoch() - 1
          : null,
    ).listen((articles) {
      if (isAdd) {
        addedArticles = articles;

        emit(
          state.copyWith(
            articles: [...oldArticles, ...articles],
            loadingState: UpdatingState.success,
          ),
        );
      } else {
        emit(
          state.copyWith(
            articles: articles,
            isLoading: false,
          ),
        );
      }
    }).onDone(
      () {
        emit(
          state.copyWith(
            isLoading: false,
            loadingState:
                isAdd && addedArticles.isEmpty ? UpdatingState.idle : null,
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    muteListSubscription.cancel();
    followingsSubscription.cancel();
    bookmarksSubscription.cancel();
    return super.close();
  }
}
