import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:convert/src/hex.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/user_status_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/connectivity_repository.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/article_view/article_view.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_details.dart';
import 'package:yakihonne/views/curation_view/curation_view.dart';
import 'package:yakihonne/views/flash_news_details_view/flash_news_details_view.dart';
import 'package:yakihonne/views/main_view/widgets/update_popup_screen.dart';
import 'package:yakihonne/views/note_view/note_view.dart';
import 'package:yakihonne/views/profile_view/profile_view.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_checker.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/un_flashnews_details.dart';
import 'package:yakihonne/views/version_news/version_news.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/vertical_video_view.dart';
import 'package:yakihonne/views/widgets/modal_with_blur.dart';

part 'main_state.dart';

class MainCubit extends Cubit<MainState> {
  MainCubit({
    required this.localDatabaseRepository,
    required this.connectivityRepository,
    required this.nostrRepository,
    required this.context,
  }) : super(
          MainState(
            selectedIndex: 0,
            mainView: MainViews.home,
            userStatus: getUserStatus(),
            image: '',
            random: '',
            nip05: '',
            name: '',
            pubKey: nostrRepository.usm?.pubKey ?? '',
            isMyContentShrinked: true,
            isHorizontal: true,
          ),
        ) {
    authorsCubit.getInitialAuthors();
    initView();
    notificationsCubit.delayedQuery();
    initUniLinks();
    checkCurrentVersionNews();

    homeViewSubcription = nostrRepository.homeViewStream.listen(
      (hasConnection) {
        if (!isClosed)
          emit(
            state.copyWith(
              mainView: MainViews.home,
              selectedIndex: 0,
            ),
          );
      },
    );

    connectivityStream =
        connectivityRepository.connectivityChangeStream.listen((hasConnection) {
      if (hasConnection) {
        NostrConnect.sharedInstance
            .connectRelays(nostrRepository.relays.toList());
      }
    });

    userSubcription = nostrRepository.userModelStream.listen(
      (user) {
        final userModel = nostrRepository.user;

        if (user == null) {
          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: UserStatus.notConnected,
                image: '',
                pubKey: '',
                name: '',
              ),
            );
        } else {
          final pubKey = Nip19.encodePubkey(user.pubKey);

          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: user.isUsingPrivKey
                    ? UserStatus.UsingPrivKey
                    : UserStatus.UsingPubKey,
                image: userModel.picture,
                random: userModel.picturePlaceholder,
                name: userModel.name.isEmpty
                    ? pubKey.nineCharacters()
                    : userModel.name,
                nip05: userModel.nip05,
                pubKey: pubKey,
              ),
            );
        }
      },
    );

    nostrRepository.fetchCurations();
  }

  final LocalDatabaseRepository localDatabaseRepository;
  final NostrDataRepository nostrRepository;
  final ConnectivityRepository connectivityRepository;
  late StreamSubscription userSubcription;
  late StreamSubscription homeViewSubcription;
  late StreamSubscription connectivityStream;
  StreamSubscription? _sub;
  BuildContext context;

  void displayPopup() async {
    await Future.delayed(const Duration(seconds: 1)).then(
      (value) {
        showBlurredModal(
          context: context,
          view: UpdatePopupScreen(),
        );
      },
    );
  }

  void checkCurrentVersionNews() async {
    final status = localDatabaseRepository.canDisplayVersionNews(appVersion);

    if (status) {
      await Future.delayed(const Duration(seconds: 3)).then(
        (_) {
          Navigator.push(
            context,
            createViewFromBottom(
              VersionNews(
                onClosed: () => displayPopup(),
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> initUniLinks() async {
    final _appLinks = AppLinks();
    final initial = await _appLinks.getLatestAppLinkString();

    if (_sub == null && initial != null) {
      if (!initial.startsWith('nostr+walletconnect') &&
          !initial.contains('yakihonne.com/wallet/alby'))
        forwardView(
          uriString: initial,
          isNostrScheme: initial.startsWith('nostr:'),
          skipDelay: false,
        );
    }

    _sub = _appLinks.uriLinkStream.listen((uri) {
      final uriString = uri.toString();

      if (uriString.isNotEmpty) {
        if (uriString.startsWith('nostr+walletconnect')) {
          lightningZapsCubit.addNwc(uriString);
        } else if (uri.toString().contains('yakihonne.com/wallet/alby')) {
          lightningZapsCubit.addAlby(uri.toString());
        } else {
          forwardView(
            uriString: uriString,
            isNostrScheme: uriString.startsWith('nostr:'),
            skipDelay: false,
          );
        }
      }
    }, onError: (err) {
      Logger().i(err);
    });
  }

  void forwardView({
    required String uriString,
    required bool isNostrScheme,
    required bool skipDelay,
  }) async {
    if (!skipDelay) await Future.delayed(const Duration(seconds: 2));
    final nostrUri = (isNostrScheme
            ? uriString.split('nostr:').last
            : uriString.split('/').last)
        .trim();

    if (uriString.contains('yakihonne.com/article')) {
      String special = '';
      String author = '';

      if (nostrUri.startsWith('naddr')) {
        final nostrDecode = Nip19.decodeShareableEntity(nostrUri);
        final hexCode = hex.decode(nostrDecode['special']);
        author = nostrDecode['author'];
        special = String.fromCharCodes(hexCode);
      } else {
        special = nostrUri;
      }

      final event = await getForwardedEvent(
        kinds: [EventKind.LONG_FORM],
        identifier: special,
        author: author,
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
    } else if (uriString.contains('yakihonne.com/curations')) {
      if (nostrUri == 'curations') {
        updateIndex(1);
        return;
      }
      String author = '';
      String special = '';
      if (nostrUri.startsWith('naddr')) {
        final nostrDecode = Nip19.decodeShareableEntity(nostrUri);
        final hexCode = hex.decode(nostrDecode['special']);
        special = String.fromCharCodes(hexCode);
        author = nostrDecode['author'];
      } else {
        special = nostrUri;
      }

      final event = await getForwardedEvent(
        kinds: [EventKind.CURATION_ARTICLES],
        identifier: special,
        author: author,
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
    } else if (uriString.contains('yakihonne.com/smart-widget-checker')) {
      String special = '';
      String author = '';
      if (nostrUri.startsWith('smart-widget-checker')) {
        final naddr = nostrUri.split('?').last.replaceAll('naddr=', '');
        final nostrDecode = Nip19.decodeShareableEntity(naddr);
        final hexCode = hex.decode(nostrDecode['special']);
        author = nostrDecode['author'];
        special = String.fromCharCodes(hexCode);
      } else {
        special = nostrUri;
      }

      final event = await getForwardedEvent(
        kinds: [EventKind.SMART_WIDGET],
        identifier: special,
        author: author,
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
    } else if (uriString.contains('yakihonne.com/videos')) {
      if (nostrUri == 'videos') {
        updateIndex(13);
        return;
      }

      String special = '';
      String author = '';
      if (nostrUri.startsWith('naddr')) {
        final nostrDecode = Nip19.decodeShareableEntity(nostrUri);

        final hexCode = hex.decode(nostrDecode['special']);
        special = String.fromCharCodes(hexCode);
        author = nostrDecode['author'];
      } else {
        special = nostrUri;
      }

      final event = await getForwardedEvent(
        kinds: [EventKind.VIDEO_HORIZONTAL, EventKind.VIDEO_VERTICAL],
        identifier: special,
        author: author,
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
    } else if (nostrUri.startsWith('nprofile') ||
        nostrUri.startsWith('npub1')) {
      String pubkey = '';
      if (nostrUri.startsWith('nprofile')) {
        final nostrDecode = Nip19.decodeShareableEntity(nostrUri);
        pubkey = nostrDecode['special'];
      } else {
        pubkey = Nip19.decodePubkey(nostrUri);
      }

      final user = authorsCubit.getAuthor(pubkey);

      if (user != null) {
        Navigator.pushNamed(
          context,
          ProfileView.routeName,
          arguments: user.pubKey,
        );
      } else {
        final event = await getForwardedEvent(
          kinds: [EventKind.METADATA],
          author: pubkey,
        );

        if (event == null) {
          BotToastUtils.showError('User could not be found');
        } else {
          final newUser = UserModel.fromJson(
            event.content,
            event.pubkey,
            event.tags,
            event.createdAt,
          );

          authorsCubit.addAuthor(newUser);

          Navigator.pushNamed(
            context,
            ProfileView.routeName,
            arguments: newUser.pubKey,
          );
        }
      }
    } else if (nostrUri.startsWith('note1')) {
      final id = Nip19.decodeNote(nostrUri);

      final event = await getForwardedEvent(
        kinds: [EventKind.TEXT_NOTE],
        identifier: id,
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
    } else if (nostrUri.startsWith('nevent')) {
      final nostrDecode = Nip19.decodeShareableEntity(nostrUri);
      authorsCubit.getAuthor(nostrDecode['author'] ?? '');

      final event = await getForwardedEvent(
        kinds: nostrDecode['kind'] != null ? [nostrDecode['kind']] : null,
        identifier: nostrDecode['special'],
        author: nostrDecode['author'],
      );

      if (event == null) {
        BotToastUtils.showError('Event could not be found');
      } else {
        if (event.isFlashNews() &&
            uriString.contains('yakihonne.com/flash-news')) {
          Navigator.pushNamed(
            context,
            FlashNewsDetailsView.routeName,
            arguments: [
              MainFlashNews(flashNews: FlashNews.fromEvent(event)),
              true,
            ],
          );
        } else if (event.isFlashNews() &&
            uriString.contains('yakihonne.com/uncensored-notes')) {
          final unFlashNews = await HttpFunctionsRepository.getUnFlashNews(
            event.id,
          );

          if (unFlashNews != null) {
            Navigator.pushNamed(
              context,
              UnFlashNewsDetails.routeName,
              arguments: unFlashNews,
            );
          } else {
            BotToastUtils.showError('Uncensored note could not be found');
          }
        } else if (event.isBuzzFeed() &&
            uriString.contains('yakihonne.com/buzz-feed')) {
          Navigator.pushNamed(
            context,
            BuzzFeedDetails.routeName,
            arguments: BuzzFeedModel.fromEvent(event),
          );
        } else if (event.isSimpleNote() &&
            uriString.contains('yakihonne.com/notes')) {
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
    } else if (nostrUri.startsWith('naddr')) {
      final nostrDecode = Nip19.decodeShareableEntity(nostrUri);
      authorsCubit.getAuthor(nostrDecode['author'] ?? '');
      final hexCode = hex.decode(nostrDecode['special']);
      final special = String.fromCharCodes(hexCode);

      final event = await getForwardedEvent(
        kinds: nostrDecode['kind'] != null ? [nostrDecode['kind']] : null,
        identifier: special,
        author: nostrDecode['author'],
      );

      if (event == null) {
        BotToastUtils.showError('Event could not be found');
      } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
          event.kind == EventKind.VIDEO_VERTICAL) {
        final video = VideoModel.fromEvent(event);

        Navigator.pushNamed(
          context,
          video.kind == EventKind.VIDEO_HORIZONTAL
              ? HorizontalVideoView.routeName
              : VerticalVideoView.routeName,
          arguments: [video],
        );
      } else if (event.kind == EventKind.LONG_FORM) {
        final article = Article.fromEvent(event);
        Navigator.pushNamed(
          context,
          ArticleView.routeName,
          arguments: article,
        );
      } else if (event.kind == EventKind.CURATION_ARTICLES ||
          event.kind == EventKind.CURATION_VIDEOS) {
        final curation = Curation.fromEvent(event, '');

        Navigator.pushNamed(
          context,
          CurationView.routeName,
          arguments: curation,
        );
      } else if (event.kind == EventKind.LONG_FORM) {
        final article = Article.fromEvent(event);
        Navigator.pushNamed(
          context,
          ArticleView.routeName,
          arguments: article,
        );
      } else if (event.kind == EventKind.SMART_WIDGET) {
        final smartWidgetModel = SmartWidgetModel.fromEvent(event);

        Navigator.pushNamed(
          context,
          SmartWidgetChecker.routeName,
          arguments: [smartWidgetModel.getNaddr(), smartWidgetModel],
        );
      } else {
        BotToastUtils.showError('Event could not be recognized');
      }
    } else if (nostrUri == 'flash-news') {
      updateIndex(9);
    } else if (nostrUri == 'uncensored-notes') {
      updateIndex(11);
    } else if (nostrUri == 'buzz-feed') {
      updateIndex(15);
    }
  }

  Future<Event?> getForwardEvent({
    List<int>? kinds,
    String? identifier,
    String? author,
    List<String>? relays,
  }) {
    final completer = Completer<Event?>();
    Event? event;

    NostrFunctionsRepository.getForwardingEvents(
      kinds: kinds,
      dTags: identifier != null && kinds != null && isReplaceable(kinds.first)
          ? [identifier]
          : null,
      ids: identifier != null &&
              (kinds != null && !isReplaceable(kinds.first) || kinds == null)
          ? [identifier]
          : null,
      pubkeys: author != null && author.isNotEmpty ? [author] : null,
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

  Future<Event?> getForwardedEvent({
    List<int>? kinds,
    String? identifier,
    String? author,
  }) async {
    final event = await getForwardEvent(
      author: author,
      identifier: identifier,
      kinds: kinds,
    );

    if (event != null) {
      return event;
    } else {
      if (author != null && author.isNotEmpty) {
        final relaysListEvent = await getForwardEvent(
          kinds: [
            EventKind.RELAY_LIST_METADATA,
          ],
          author: author,
        );

        if (relaysListEvent != null) {
          Set<String> searchedRelays = {};

          for (final tag in relaysListEvent.tags) {
            if (tag.first == 'r' && tag.length > 1) {
              if (!searchedRelays.contains(tag[1]) &&
                  !searchedRelays.contains(tag[1])) {
                searchedRelays.add(tag[1]);
              }
            }
          }

          if (searchedRelays.isNotEmpty) {
            final connectedRelays =
                NostrConnect.sharedInstance.relays().toSet();

            final differedRelays = searchedRelays.difference(connectedRelays);

            if (differedRelays.isNotEmpty) {
              BotToastUtils.showInformation(
                "Fetching event from user's relays",
              );

              NostrConnect.sharedInstance.connectRelays(
                [
                  ...connectedRelays.toList(),
                  ...differedRelays.toList(),
                ],
              );

              await Future.delayed(
                const Duration(seconds: 2),
              );

              final e = await getForwardEvent(
                author: author,
                identifier: identifier,
                kinds: kinds,
              );

              await NostrConnect.sharedInstance
                  .closeConnect(differedRelays.toList());

              return e;
            } else {
              return null;
            }
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
  }

  void toggleVideo() {
    emit(
      state.copyWith(
        isHorizontal: !state.isHorizontal,
      ),
    );
  }

  void toggleMyContentShrink() {
    emit(
      state.copyWith(
        isMyContentShrinked: !state.isMyContentShrinked,
      ),
    );
  }

  Future<void> initView() async {
    final user = nostrRepository.usm;

    if (user == null) {
      if (!isClosed)
        emit(
          state.copyWith(
            userStatus: UserStatus.notConnected,
            image: '',
            pubKey: '',
            name: '',
            nip05: '',
          ),
        );
    } else {
      nostrRepository.getUserMetaData(
        hex: nostrRepository.isUsingExternalSigner
            ? Nip19.encodePubkey(user.pubKey)
            : !user.isUsingPrivKey
                ? user.pubKey
                : user.privKey,
        isPrivKey: user.isUsingPrivKey,
        isExternalSigner: nostrRepository.isUsingExternalSigner ? true : null,
      );

      final pubkey = Nip19.encodePubkey(user.pubKey);

      emit(
        state.copyWith(
          userStatus: getUserStatus(),
          name: pubkey.nineCharacters(),
          pubKey: pubkey,
        ),
      );
    }
  }

  void updateIndex(int index) {
    late MainViews mainView;
    notificationsCubit.setNotificationView(index == 8);
    dmsCubit.setDmsView(index == 12);

    switch (index) {
      case 0:
        mainView = MainViews.home;
        break;
      case 1:
        mainView = MainViews.curations;
        break;
      case 2:
        mainView = MainViews.search;
        break;
      case 3:
        mainView = MainViews.selfCurations;
        break;
      case 4:
        mainView = MainViews.selfArticles;
        break;
      case 5:
        mainView = MainViews.properties;
        break;
      case 6:
        mainView = MainViews.settings;
        break;
      case 7:
        mainView = MainViews.bookmarks;
        break;
      case 8:
        mainView = MainViews.notifications;
        break;
      case 9:
        mainView = MainViews.flashNews;
        break;
      case 10:
        mainView = MainViews.selfFlashNews;
        break;
      case 11:
        mainView = MainViews.uncensoredNotes;
        break;
      case 12:
        mainView = MainViews.dms;
        break;
      case 13:
        mainView = MainViews.videosFeed;
        break;
      case 14:
        mainView = MainViews.selfVideos;
        break;
      case 15:
        mainView = MainViews.buzzFeed;
        break;
      case 16:
        mainView = MainViews.articles;
        break;
      case 17:
        mainView = MainViews.notes;
        break;
      case 18:
        mainView = MainViews.polls;
        break;
      case 19:
        mainView = MainViews.wallet;
        break;
      case 20:
        mainView = MainViews.selfNotes;
      case 21:
        mainView = MainViews.selfSmartWidgets;
      case 22:
        mainView = MainViews.smartWidgets;
        break;
      default:
        mainView = MainViews.home;
        break;
    }

    if (!isClosed)
      emit(
        state.copyWith(
          selectedIndex: index,
          mainView: mainView,
        ),
      );
  }

  void disconnect() {
    nostrRepository.disconnect();

    if (!isClosed)
      emit(
        state.copyWith(
          mainView: MainViews.home,
          selectedIndex: 0,
          pubKey: '',
        ),
      );
  }

  void switchAccount(UserStatusModel usm) {
    nostrRepository.setActiveUser(usm, true);
    setDefault();
  }

  void disconnectAccount(UserStatusModel usm) {
    nostrRepository.usmList.remove(usm.pubKey);

    if (nostrRepository.usmList.isEmpty) {
      disconnect();
    } else {
      localDatabaseRepository.setUsmList(nostrRepository.usmList);
      nostrRepository.setActiveUser(
        nostrRepository.usmList.entries.first.value,
        true,
      );
      setDefault();
    }
  }

  void setDefault() {
    emit(
      state.copyWith(
        mainView: MainViews.home,
        selectedIndex: 0,
        pubKey: nostrRepository.usm?.pubKey ?? '',
      ),
    );
  }

  @override
  Future<void> close() {
    userSubcription.cancel();
    homeViewSubcription.cancel();
    _sub?.cancel();
    return super.close();
  }
}
