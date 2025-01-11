import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:convert/src/hex.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/article_view/article_view.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_details.dart';
import 'package:yakihonne/views/curation_view/curation_view.dart';
import 'package:yakihonne/views/flash_news_details_view/flash_news_details_view.dart';
import 'package:yakihonne/views/note_view/note_view.dart';
import 'package:yakihonne/views/profile_view/profile_view.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_checker.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/vertical_video_view.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit({
    required this.nostrRepository,
    required this.context,
  }) : super(
          SearchState(
            content: [],
            authors: [],
            contentSearchResult: SearchResultsType.noSearch,
            profileSearchResult: SearchResultsType.noSearch,
            search: '',
            followings: nostrRepository.usm != null
                ? nostrRepository.user.followings.map((e) => e.key).toList()
                : [],
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            mutes: nostrRepository.mutes.toList(),
          ),
        ) {
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
              content: state.content
                  .where((article) => !mutes.contains(article.pubkey))
                  .toList(),
              authors: state.authors
                  .where((author) => !mutes.contains(author.pubKey))
                  .toList(),
            ),
          );
      },
    );
  }

  late StreamSubscription followingsSubscription;
  late StreamSubscription bookmarksSubscription;
  late StreamSubscription muteListSubscription;
  final NostrDataRepository nostrRepository;
  BuildContext context;
  Timer? searchOnStoppedTyping;
  String requestId = '';
  Set<String> requests = {};

  void getItemsBySearch(String search) {
    if (requestId.isNotEmpty) {
      NostrConnect.sharedInstance.closeRequests([requestId]);
      requestId = '';
    }

    if (searchOnStoppedTyping != null) {
      searchOnStoppedTyping!.cancel();
    }

    searchOnStoppedTyping = Timer(
      const Duration(seconds: 1),
      () async {
        if (search.isNotEmpty) {
          if (search.startsWith('naddr') || search.startsWith('nostr:naddr')) {
            forwardNaddrView(search);
          } else if (search.startsWith('nostr:npub') ||
              search.startsWith('nostr:nprofile') ||
              search.startsWith('npub') ||
              search.startsWith('nprofile') ||
              search.length == 64) {
            try {
              final newSearch = search.startsWith('nostr:')
                  ? search.split('nostr:').last
                  : search;

              final hex = newSearch.startsWith('npub')
                  ? Nip19.decodePubkey(newSearch)
                  : newSearch.startsWith('nprofile')
                      ? Nip19.decodeShareableEntity(newSearch)['special']
                      : newSearch;

              Navigator.pushNamed(
                context,
                ProfileView.routeName,
                arguments: hex,
              );
            } catch (_) {
              BotToastUtils.showError('Error occured while decoding data');
            }
          } else if (search.startsWith('note1') ||
              search.startsWith('nostr:note1')) {
            final newSearch = search.startsWith('nostr:')
                ? search.split('nostr:').last
                : search;

            forwardNoteView(newSearch);
          } else if (search.startsWith('nevent1') ||
              search.startsWith('nostr:nevent1')) {
            final newSearch = search.startsWith('nostr:')
                ? search.split('nostr:').last
                : search;
            forwardNeventView(newSearch);
          } else {
            if (!isClosed)
              emit(
                state.copyWith(
                  profileSearchResult: SearchResultsType.loading,
                  contentSearchResult: SearchResultsType.loading,
                  content: [],
                  authors: [],
                ),
              );

            getAuthors(search);
            getContent(search);
          }
        } else {
          if (!isClosed)
            emit(
              state.copyWith(
                content: [],
                authors: [],
                contentSearchResult: SearchResultsType.noSearch,
                profileSearchResult: SearchResultsType.noSearch,
                search: '',
              ),
            );
        }
      },
    );
  }

  void getContent(String search) {
    List<dynamic> currentContent = List.from(state.content);
    final searchTag =
        search.startsWith('#') ? search.removeFirstCharacter() : search;

    NostrFunctionsRepository.getHomePageData(
      isBuzzFeed: false,
      addNotes: true,
      tags: [searchTag],
    ).listen(
      (content) {
        List<dynamic> updatedContent = List.from(currentContent);
        updatedContent.addAll(content);

        if (!isClosed)
          emit(
            state.copyWith(
              content: updatedContent,
              contentSearchResult: SearchResultsType.content,
            ),
          );
      },
      onDone: () {
        emit(
          state.copyWith(
            contentSearchResult: SearchResultsType.content,
          ),
        );
      },
    );
  }

  void forwardNeventView(String nostrUri) async {
    try {
      final nostrDecode = Nip19.decodeShareableEntity(nostrUri);
      authorsCubit.getAuthor(nostrDecode['author'] ?? '');

      final event = await getForwardEvent(
        kinds: nostrDecode['kind'] != null ? [nostrDecode['kind']] : null,
        identifier: nostrDecode['special'],
        author: nostrDecode['author'],
      );

      if (event == null) {
        BotToastUtils.showError('Event could not be found');
      } else {
        if (event.isFlashNews()) {
          Navigator.pushNamed(
            context,
            FlashNewsDetailsView.routeName,
            arguments: [
              MainFlashNews(flashNews: FlashNews.fromEvent(event)),
              true,
            ],
          );
        } else if (event.isBuzzFeed()) {
          Navigator.pushNamed(
            context,
            BuzzFeedDetails.routeName,
            arguments: BuzzFeedModel.fromEvent(event),
          );
        } else if (event.isSimpleNote()) {
          final note = DetailedNoteModel.fromEvent(event);

          Navigator.pushNamed(
            context,
            NoteView.routeName,
            arguments: note,
          );
        } else {
          final note = DetailedNoteModel.fromEvent(event);

          Navigator.pushNamed(
            context,
            NoteView.routeName,
            arguments: note,
          );
        }
      }
    } catch (_) {
      lg.i(_);
      BotToastUtils.showError('Error occured while decoding data');
    }
  }

  void forwardNoteView(String note) async {
    try {
      final decodedNote = Nip19.decodeNote(note);

      final event = await getForwardEvent(
        kinds: [EventKind.TEXT_NOTE],
        identifier: decodedNote,
      );

      if (event == null) {
        BotToastUtils.showError('Note could not be found');
      } else {
        final note = DetailedNoteModel.fromEvent(event);
        Navigator.pushNamed(
          context,
          NoteView.routeName,
          arguments: note,
        );
      }
    } catch (_) {
      BotToastUtils.showError('Error occured while decoding data');
    }
  }

  void forwardNaddrView(String naddr) async {
    try {
      final decodedNaddr = Nip19.decodeShareableEntity(naddr);
      final kind = decodedNaddr['kind'];
      final hexCode = hex.decode(decodedNaddr['special']);
      final special = String.fromCharCodes(hexCode);

      if (kind == EventKind.LONG_FORM) {
        final event = await getForwardEvent(
          kinds: [EventKind.LONG_FORM],
          identifier: special,
        );

        if (event == null) {
          BotToastUtils.showError('Article could not be found');
        } else {
          final article = Article.fromEvent(event);
          Navigator.pushNamed(
            context,
            ArticleView.routeName,
            arguments: article,
          );
        }
      } else if (kind == EventKind.CURATION_ARTICLES) {
        final event = await getForwardEvent(
          kinds: [EventKind.CURATION_ARTICLES],
          identifier: special,
        );

        if (event == null) {
          BotToastUtils.showError('Curation could not be found');
        } else {
          final curation = Curation.fromEvent(event, '');

          Navigator.pushNamed(
            context,
            CurationView.routeName,
            arguments: curation,
          );
        }
      } else if (kind == EventKind.VIDEO_HORIZONTAL ||
          kind == EventKind.VIDEO_VERTICAL) {
        final event = await getForwardEvent(
          kinds: [EventKind.VIDEO_HORIZONTAL, EventKind.VIDEO_VERTICAL],
          identifier: special,
        );

        if (event == null) {
          BotToastUtils.showError('Video could not be found');
        } else {
          final video = VideoModel.fromEvent(event);

          Navigator.pushNamed(
            context,
            video.kind == EventKind.VIDEO_HORIZONTAL
                ? HorizontalVideoView.routeName
                : VerticalVideoView.routeName,
            arguments: [video],
          );
        }
      } else if (kind == EventKind.SMART_WIDGET) {
        final event = await getForwardEvent(
          kinds: [EventKind.SMART_WIDGET],
          identifier: special,
        );

        if (event == null) {
          BotToastUtils.showError('Smart widget could not be found');
        } else {
          final smartWidgetModel = SmartWidgetModel.fromEvent(event);
          Navigator.pushNamed(
            context,
            SmartWidgetChecker.routeName,
            arguments: [smartWidgetModel.getNaddr(), smartWidgetModel],
          );
        }
      }
    } catch (_) {
      BotToastUtils.showError('Error occured while decoding data');
    }
  }

  Future<Event?> getForwardEvent({
    List<int>? kinds,
    String? identifier,
    String? author,
  }) {
    final completer = Completer<Event?>();
    Event? event;

    final dTags =
        identifier != null && kinds != null && isReplaceable(kinds.first)
            ? [identifier]
            : null;
    final ids = identifier != null &&
            (kinds != null && !isReplaceable(kinds.first) || kinds == null)
        ? [identifier]
        : null;

    NostrFunctionsRepository.getForwardingEvents(
      kinds: kinds != null ? kinds : null,
      dTags: dTags,
      ids: ids,
      pubkeys: author != null ? [author] : null,
    ).listen((recentEvent) {
      if (event == null ||
          event!.createdAt.compareTo(recentEvent.createdAt) < 0) {
        event = recentEvent;
      }
    }).onDone(
      () {
        completer.complete(event);
      },
    );

    return completer.future;
  }

  void searchAuthors(String search) async {}

  Future<void> getAuthors(String search) async {
    try {
      final searchedUsers = authorsCubit.getAuthorsByNameNip05(search);

      if (!isClosed)
        emit(
          state.copyWith(
            authors: searchedUsers
                .where(
                    (author) => !nostrRepository.mutes.contains(author.pubKey))
                .toList(),
            profileSearchResult: SearchResultsType.content,
          ),
        );

      final users = await HttpFunctionsRepository.getUsers(search);
      final newList = <UserModel>[...state.authors];

      for (final user in users) {
        final userExists = newList
            .where((element) => element.pubKey == user.pubKey)
            .isNotEmpty;

        if (!userExists && !nostrRepository.mutes.contains(user.pubKey)) {
          newList.add(user);
          authorsCubit.addAuthor(user);
        }
      }

      newList.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      if (!isClosed)
        emit(
          state.copyWith(
            authors: newList,
            profileSearchResult: SearchResultsType.content,
          ),
        );
    } catch (e) {
      Logger().i(e);
    }
  }

  @override
  Future<void> close() {
    muteListSubscription.cancel();
    followingsSubscription.cancel();
    bookmarksSubscription.cancel();
    return super.close();
  }
}
