import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'add_articles_state.dart';

class AddCurationArticlesCubit extends Cubit<AddCurationArticlesState> {
  AddCurationArticlesCubit({
    required this.curation,
    required this.nostrRepository,
  }) : super(
          AddCurationArticlesState(
            activeArticles: [],
            articles: [],
            activeVideos: [],
            videos: [],
            isActiveArticlesLoading: true,
            isArticlesLoading: false,
            relaysAddingData: UpdatingState.progress,
            chosenRelay: nostrRepository.relays.first,
            relays: nostrRepository.relays,
            searchText: '',
            isAllRelays: true,
            mutes: nostrRepository.mutes.toList(),
            isArticlesCuration: curation.isArticleCuration(),
          ),
        ) {
    relaysSubscription = nostrRepository.relaysStream.listen(
      (relays) {
        if (!isClosed)
          emit(
            state.copyWith(
              relays: relays,
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

  final NostrDataRepository nostrRepository;
  final Curation curation;
  late StreamSubscription relaysSubscription;
  late StreamSubscription muteListSubscription;
  Set<String> requests = {};

  void initView() {
    getItems(null, true);
  }

  void toggleView() {
    if (!isClosed)
      emit(
        state.copyWith(
          isAllRelays: !state.isAllRelays,
        ),
      );
  }

  void getItems(String? relay, bool isActiveItems) {
    List<String> identifiers = [];
    NostrConnect.sharedInstance.closeRequests(requests.toList());

    if (isActiveItems) {
      final items = curation.eventsIds
          .where((event) => curation.isArticleCuration()
              ? event.kind == EventKind.LONG_FORM
              : (event.kind == EventKind.VIDEO_HORIZONTAL ||
                  event.kind == EventKind.VIDEO_VERTICAL))
          .toList();

      if (items.isEmpty) {
        if (!isClosed)
          emit(
            state.copyWith(
              isActiveArticlesLoading: false,
            ),
          );

        return;
      }

      identifiers = items.map((e) => e.identifier).toList();

      if (!isClosed)
        emit(
          state.copyWith(
            isActiveArticlesLoading: true,
            activeArticles: [],
            articles: [],
            searchText: '',
            isAllRelays: true,
          ),
        );
    } else {
      if (!isClosed)
        emit(
          state.copyWith(
            articles: [],
            isArticlesLoading: true,
            searchText: '',
            chosenRelay: relay,
          ),
        );
    }

    if (curation.isArticleCuration()) {
      NostrFunctionsRepository.getArticles(
        pubkeys: state.isAllRelays ? null : [curation.pubKey],
        limit: isActiveItems ? null : 20,
        articlesIds: isActiveItems ? identifiers : null,
        relay: relay,
      ).listen(
        (articles) {
          emit(
            state.copyWith(
              articles: isActiveItems ? null : articles.toList(),
              activeArticles: isActiveItems ? articles.toList() : null,
              isActiveArticlesLoading: isActiveItems ? false : null,
              isArticlesLoading: isActiveItems ? null : false,
            ),
          );
        },
        onDone: () {
          if (!state.isAllRelays) {
            emit(
              state.copyWith(
                isArticlesLoading: false,
              ),
            );
          }
        },
      );
    } else {
      NostrFunctionsRepository.getVideos(
        loadHorizontal: true,
        loadVertical: true,
        relay: relay,
        limit: isActiveItems ? null : 20,
        videosIds: isActiveItems ? identifiers : null,
        pubkeys: state.isAllRelays ? null : [curation.pubKey],
        onAllVideos: (videos) {
          emit(
            state.copyWith(
              videos: isActiveItems ? null : videos,
              activeVideos: isActiveItems ? videos.toList() : null,
              isActiveArticlesLoading: isActiveItems ? false : null,
              isArticlesLoading: isActiveItems ? null : false,
            ),
          );
        },
        onHorizontalVideos: (hVideos) {},
        onVerticalVideos: (vVideos) {},
        onDone: () {
          if (!state.isAllRelays) {
            emit(
              state.copyWith(
                isArticlesLoading: false,
              ),
            );
          }
        },
      );
    }
  }

  Future<void> getMoreItems() async {
    if (curation.isArticleCuration()) {
      int lastIndex = state.articles.length;
      List<Article> existingArticles = List.from(state.articles);

      if (!isClosed)
        emit(
          state.copyWith(
            relaysAddingData: UpdatingState.progress,
          ),
        );

      NostrFunctionsRepository.getArticles(
        pubkeys: state.isAllRelays ? null : [curation.pubKey],
        limit: 20,
        until: lastIndex == 0
            ? null
            : (state.articles[lastIndex - 1]).createdAt.toSecondsSinceEpoch() -
                1,
        relay: state.chosenRelay,
      ).listen(
        (articles) {
          List<Article> updatedArticles = List.from(existingArticles);
          updatedArticles.addAll(articles);

          emit(
            state.copyWith(
              articles: updatedArticles,
              relaysAddingData: UpdatingState.success,
            ),
          );
        },
        onDone: () {
          emit(
            state.copyWith(
              relaysAddingData: UpdatingState.success,
            ),
          );
        },
      );
    } else {
      int lastIndex = state.videos.length;
      List<VideoModel> existingVideos = List.from(state.videos);

      if (!isClosed)
        emit(
          state.copyWith(
            relaysAddingData: UpdatingState.progress,
          ),
        );

      NostrFunctionsRepository.getVideos(
        loadHorizontal: true,
        loadVertical: true,
        relay: state.chosenRelay,
        limit: 20,
        until: lastIndex == 0
            ? null
            : (state.videos[lastIndex - 1]).createdAt.toSecondsSinceEpoch() - 1,
        onAllVideos: (videos) {
          List<VideoModel> updatedVideos = List.from(existingVideos);
          updatedVideos.addAll(videos);

          emit(
            state.copyWith(
              videos: updatedVideos,
              relaysAddingData: UpdatingState.success,
            ),
          );
        },
        onHorizontalVideos: (hVideos) {},
        onVerticalVideos: (vVideos) {},
        onDone: () {
          if (!state.isAllRelays) {
            emit(
              state.copyWith(
                relaysAddingData: UpdatingState.success,
              ),
            );
          }
        },
      );

      NostrFunctionsRepository.getArticles(
        pubkeys: state.isAllRelays ? null : [curation.pubKey],
        limit: 20,
        until: lastIndex == 0
            ? null
            : (state.articles[lastIndex - 1]).createdAt.toSecondsSinceEpoch() -
                1,
        relay: state.chosenRelay,
      ).listen(
        (articles) {
          List<Article> updatedArticles = List.from(existingVideos);
          updatedArticles.addAll(articles);

          emit(
            state.copyWith(
              articles: updatedArticles,
              relaysAddingData: UpdatingState.success,
            ),
          );
        },
        onDone: () {
          emit(
            state.copyWith(
              relaysAddingData: UpdatingState.success,
            ),
          );
        },
      );
    }
  }

  void setSearchText(String text) {
    if (!isClosed)
      emit(
        state.copyWith(
          searchText: text,
        ),
      );
  }

  static List<Article> getUpdatedArticles(List<dynamic> values) {
    List<Article> articles = List.from(
      values[0].sublist(values[3], values[0].length),
    );

    articles.addAll(values[1]);
    articles.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return List.from(values[2])..addAll(articles.toList());
  }

  void setArticleToActive(Article article) {
    if (!isClosed)
      emit(
        state.copyWith(
            activeArticles: List.from(state.activeArticles)..add(article)),
      );
  }

  void setVideoToActive(VideoModel video) {
    if (!isClosed)
      emit(
        state.copyWith(activeVideos: List.from(state.activeVideos)..add(video)),
      );
  }

  void deleteActiveArticle(String id) {
    if (state.isArticlesCuration) {
      final articles = List<Article>.from(state.activeArticles)
        ..removeWhere((element) => element.articleId == id);

      if (!isClosed)
        emit(
          state.copyWith(activeArticles: articles),
        );
    } else {
      final videos = List<VideoModel>.from(state.activeVideos)
        ..removeWhere((element) => element.videoId == id);

      if (!isClosed)
        emit(
          state.copyWith(activeVideos: videos),
        );
    }
  }

  Future<void> addCuration({
    required Function(String) onFailure,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    try {
      List<List<String>> items = [];
      if (state.isArticlesCuration) {
        items = state.activeArticles
            .map(
              (article) => [
                'a',
                EventCoordinates(
                  EventKind.LONG_FORM,
                  article.pubkey,
                  article.identifier,
                  '',
                ).toString()
              ],
            )
            .toList();
      } else {
        items = state.activeVideos
            .map(
              (video) => [
                'a',
                EventCoordinates(
                  video.kind,
                  video.pubkey,
                  video.identifier,
                  '',
                ).toString()
              ],
            )
            .toList();
      }

      final event = await Event.genEvent(
        kind: curation.kind,
        content: '',
        privkey: nostrRepository.usm!.privKey,
        pubkey: nostrRepository.usm!.pubKey,
        verify: true,
        tags: [
          ['d', curation.identifier],
          ['title', curation.title],
          ['description', curation.description],
          ['image', curation.image],
        ]..addAll(items),
      );

      if (event == null) {
        _cancel.call();
        return;
      }

      final isSuccessful = await NostrFunctionsRepository.addEvent(
        event: event,
      );

      if (isSuccessful) {
        onSuccess.call();
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }

      _cancel.call();
    } catch (_) {
      onFailure.call(
        'An error occured while updating the curation',
      );
    }
  }

  void setArticlesNewOrder(int oldIndex, int newIndex) {
    List<Article> newArticles = List.from(state.activeArticles);
    final article = newArticles.removeAt(oldIndex);
    newArticles.insert(newIndex, article);

    if (!isClosed)
      emit(
        state.copyWith(
          activeArticles: newArticles,
        ),
      );
  }

  void setVideossNewOrder(int oldIndex, int newIndex) {
    List<VideoModel> newVideos = List.from(state.activeVideos);
    final video = newVideos.removeAt(oldIndex);
    newVideos.insert(newIndex, video);

    if (!isClosed)
      emit(
        state.copyWith(
          activeVideos: newVideos,
        ),
      );
  }

  @override
  Future<void> close() {
    relaysSubscription.cancel();
    muteListSubscription.cancel();
    NostrConnect.sharedInstance.closeRequests(requests.toList());
    return super.close();
  }
}
