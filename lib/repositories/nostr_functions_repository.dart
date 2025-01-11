import 'dart:async';
import 'dart:math';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:uuid/v4.dart';
import 'package:yakihonne/database/cache_manager_db.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/bookmark_list_model.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/points_system_models.dart';
import 'package:yakihonne/models/poll_model.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/topic.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/user_status_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';

class NostrFunctionsRepository {
  static final uuid = UuidV4();
  // * clear cache
  static Future<bool> clearCache() async {
    final _cancel = BotToast.showLoading();
    try {
      localDatabaseRepository.deleteNewestGiftWrap();
      await CacheManagerDB.clearData();
      _cancel.call();
      BotToastUtils.showSuccess('Cache has been cleared');
      return true;
    } catch (_) {
      lg.i(_);
      BotToastUtils.showError('Error occured while emptying the cache');
      _cancel.call();
      return true;
    }
  }

  // * get tag data
  static void getTagData({
    required Function(List<Article>) onArticles,
    required Function(List<FlashNews>) onFlashNews,
    required Function(List<VideoModel>) onVideos,
    required Function(List<DetailedNoteModel>) onNotes,
    required Function() onDone,
    required String tag,
  }) async {
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();
    Map<String, VideoModel> videosToBeEmitted = {};
    Map<String, Article> articlesToBeEmitted = {};
    Map<String, FlashNews> flashnewsToBeEmitted = {};
    Map<String, DetailedNoteModel> notesToBeEmitted = {};

    final f1 = Filter(
      kinds: [
        EventKind.VIDEO_HORIZONTAL,
        EventKind.VIDEO_VERTICAL,
        EventKind.LONG_FORM,
      ],
      t: [tag],
    );

    final f2 = Filter(
      kinds: [EventKind.TEXT_NOTE],
      l: [FN_SEARCH_VALUE],
      t: [tag],
    );

    final f3 = Filter(
      kinds: [EventKind.TEXT_NOTE],
      t: [tag],
      limit: 40,
    );

    final id = NostrConnect.sharedInstance.addSubscription(
      [f1, f2, f3],
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.VIDEO_HORIZONTAL ||
            event.kind == EventKind.VIDEO_VERTICAL) {
          final video = VideoModel.fromEvent(event);

          if (video.url.isNotEmpty) {
            final old = videosToBeEmitted[video.identifier];

            if (old == null || old.createdAt.compareTo(video.createdAt) < 1) {
              videosToBeEmitted[video.identifier] = video;
            }
          }
        } else if (event.kind == EventKind.LONG_FORM) {
          final article = Article.fromEvent(event);
          final old = articlesToBeEmitted[article.identifier];
          if (old == null || old.createdAt.compareTo(article.createdAt) < 1) {
            articlesToBeEmitted[article.identifier] = article;
          }
        } else if (event.kind == EventKind.TEXT_NOTE) {
          if (event.isFlashNews()) {
            final flashnews = FlashNews.fromEvent(event);
            final old = flashnewsToBeEmitted[flashnews.id];
            if (old == null ||
                old.createdAt.compareTo(flashnews.createdAt) < 1) {
              flashnewsToBeEmitted[flashnews.id] = flashnews;
            }
          } else if (event.isSimpleNote()) {
            final note = DetailedNoteModel.fromEvent(event);
            final old = notesToBeEmitted[note.id];
            if (old == null || old.createdAt.compareTo(note.createdAt) < 1) {
              notesToBeEmitted[note.id] = note;
            }
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (videosToBeEmitted.isNotEmpty)
          onVideos.call(videosToBeEmitted.values.toList());
        if (articlesToBeEmitted.isNotEmpty)
          onArticles.call(articlesToBeEmitted.values.toList());
        if (flashnewsToBeEmitted.isNotEmpty)
          onFlashNews.call(flashnewsToBeEmitted.values.toList());
        if (notesToBeEmitted.isNotEmpty)
          onNotes.call(notesToBeEmitted.values.toList());
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          timer.cancel();
          onDone.call();
          NostrConnect.sharedInstance.closeRequests([id]);
        }
      },
    );
  }

  // * get buzz feed /
  static void getBuzzFeed({
    required Function(List<BuzzFeedModel>) onAiFeedFunc,
    required Function() onDone,
    List<String>? pubkeys,
    List<String>? tags,
    List<String>? ids,
    int? since,
    int? until,
    int? limit,
  }) {
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();
    Map<String, BuzzFeedModel> aiFeedToBeEmitted = {};

    final f1 = Filter(
      kinds: [EventKind.TEXT_NOTE],
      l: [AF_SEARCH_VALUE],
      authors: pubkeys,
      t: tags,
      ids: ids,
      until: until,
      limit: limit,
    );

    final id = NostrConnect.sharedInstance.addSubscription(
      [f1],
      [],
      eventCallBack: (event, relay) {
        final aiFeed = BuzzFeedModel.fromEvent(event);
        final oldFlashNews = aiFeedToBeEmitted[aiFeed.id];

        if (aiFeed.isAuthentic &&
            !nostrRepository.mutes.contains(aiFeed.pubkey)) {
          if (oldFlashNews == null ||
              aiFeed.createdAt.isAfter(oldFlashNews.createdAt)) {
            aiFeedToBeEmitted[aiFeed.id] = aiFeed;
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (ok.status && aiFeedToBeEmitted.isNotEmpty) {
          Set<String> authors = {};

          aiFeedToBeEmitted.values.forEach((element) {
            authors.add(element.pubkey);
          });

          final updatedFlashNews = aiFeedToBeEmitted.values.toList();

          updatedFlashNews.sort(
            (a, b) => b.publishedAt.compareTo(a.publishedAt),
          );

          onAiFeedFunc.call(updatedFlashNews);

          authorsCubit.getAuthors(authors.toList());
        }

        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          timer.cancel();
          onDone.call();
          NostrConnect.sharedInstance.closeRequests([id]);
        }
      },
    );
  }

  // * get zap polls /
  static void getZapPolls({
    required Function(List<PollModel>) onPollsFunc,
    required Function() onDone,
    List<String>? pubkeys,
    List<String>? tags,
    List<String>? ids,
    int? since,
    int? until,
    int? limit,
  }) {
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();
    Map<String, PollModel> pollsToBeEmitted = {};

    final f1 = Filter(
      kinds: [EventKind.POLL],
      authors: pubkeys,
      t: tags,
      ids: ids,
      until: until,
      limit: limit,
    );

    final id = NostrConnect.sharedInstance.addSubscription(
      [f1],
      [],
      eventCallBack: (event, relay) {
        final poll = PollModel.fromEvent(event);
        final oldPoll = pollsToBeEmitted[poll.id];

        if (oldPoll == null || poll.createdAt.isAfter(oldPoll.createdAt)) {
          pollsToBeEmitted[poll.id] = poll;
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (ok.status && pollsToBeEmitted.isNotEmpty) {
          Set<String> authors = {};

          pollsToBeEmitted.values.forEach((element) {
            authors.add(element.pubkey);
          });

          final updatedPolls = pollsToBeEmitted.values.toList();

          updatedPolls.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );

          onPollsFunc.call(updatedPolls);

          authorsCubit.getAuthors(authors.toList());
        }

        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          timer.cancel();
          onDone.call();
          NostrConnect.sharedInstance.closeRequests([id]);
        }
      },
    );
  }

  // * get notes  /
  static void getDetailedNotes({
    required Function(List<Event>) onNotesFunc,
    required Function() onDone,
    required List<int> kinds,
    List<String>? pubkeys,
    List<String>? tags,
    List<String>? lTags,
    List<String>? ids,
    int? since,
    int? until,
    int? limit,
  }) {
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();
    Map<String, Event> notesToBeEmitted = {};

    final f1 = Filter(
      kinds: kinds,
      authors: pubkeys,
      t: tags,
      l: lTags,
      ids: ids,
      until: until,
      limit: limit,
    );

    final id = NostrConnect.sharedInstance.addSubscription(
      [f1],
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.TEXT_NOTE) {
          final isNote = event.isSimpleNote();

          if (isNote) {
            final note = DetailedNoteModel.fromEvent(event);

            if (note.isRoot) {
              final oldNote = notesToBeEmitted[note.id];

              if (!nostrRepository.mutes.contains(note.pubkey)) {
                if (oldNote == null || event.createdAt > oldNote.createdAt) {
                  notesToBeEmitted[note.id] = event;
                }
              }
            }
          }
        } else if (event.kind == EventKind.REPOST) {
          if (!nostrRepository.mutes.contains(event.pubkey)) {
            final oldRepost = notesToBeEmitted[event.id];
            if (oldRepost == null || event.createdAt > oldRepost.createdAt) {
              notesToBeEmitted[event.id] = event;
            }
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (ok.status && notesToBeEmitted.isNotEmpty) {
          Set<String> authors = {};

          notesToBeEmitted.values.forEach((element) {
            authors.add(element.pubkey);
          });

          final updatedNotes = notesToBeEmitted.values.toList();

          updatedNotes.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );

          onNotesFunc.call(updatedNotes);

          authorsCubit.getAuthors(authors.toList());
        }

        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          timer.cancel();
          onDone.call();
          NostrConnect.sharedInstance.closeRequests([id]);
        }
      },
    );
  }

  // * get user stats /
  static void getVideos({
    required bool loadHorizontal,
    required bool loadVertical,
    required Function(List<VideoModel>) onHorizontalVideos,
    required Function(List<VideoModel>) onVerticalVideos,
    Function(List<VideoModel>)? onAllVideos,
    required Function() onDone,
    int? since,
    int? until,
    int? limit,
    String? relay,
    List<String>? pubkeys,
    List<String>? videosIds,
  }) async {
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();
    Map<String, VideoModel> horizontalEvents = {};
    Map<String, VideoModel> verticalEvents = {};
    Map<String, VideoModel> allEvents = {};

    final f1 = Filter(
      kinds: [
        EventKind.VIDEO_HORIZONTAL,
      ],
      since: since,
      until: until,
      d: videosIds,
      limit: limit,
      authors: pubkeys,
    );

    final f2 = Filter(
      kinds: [
        EventKind.VIDEO_VERTICAL,
      ],
      since: since,
      until: until,
      d: videosIds,
      limit: limit,
      authors: pubkeys,
    );

    final id = NostrConnect.sharedInstance.addSubscription(
      [if (loadHorizontal) f1, if (loadVertical) f2],
      StringUtil.isBlank(relay) ? [] : [relay!],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.VIDEO_HORIZONTAL ||
            event.kind == EventKind.VIDEO_VERTICAL) {
          final isHorizontal = event.kind == EventKind.VIDEO_HORIZONTAL;
          final video = VideoModel.fromEvent(event, relay: relay);

          if (video.url.isNotEmpty) {
            final old = isHorizontal
                ? horizontalEvents[video.identifier]
                : verticalEvents[video.identifier];

            final chosen = filterVideoModel(
              oldVideoModel: old,
              newVideoModel: video,
            );

            allEvents[chosen.identifier] = chosen;

            if (isHorizontal) {
              horizontalEvents[chosen.identifier] = chosen;
            } else {
              verticalEvents[chosen.identifier] = chosen;
            }
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (allEvents.isNotEmpty) onAllVideos?.call(allEvents.values.toList());
        if (horizontalEvents.isNotEmpty)
          onHorizontalVideos.call(horizontalEvents.values.toList());
        if (verticalEvents.isNotEmpty)
          onVerticalVideos.call(verticalEvents.values.toList());
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          timer.cancel();
          onDone.call();
          NostrConnect.sharedInstance.closeRequests([id]);
        }
      },
    );
  }

  static VideoModel filterVideoModel({
    required VideoModel? oldVideoModel,
    required VideoModel newVideoModel,
  }) {
    if (oldVideoModel != null) {
      final isNew = oldVideoModel.createdAt.isBefore(newVideoModel.createdAt);

      if (isNew) {
        newVideoModel.relays.addAll(oldVideoModel.relays);
        return newVideoModel;
      } else {
        oldVideoModel.relays.addAll(newVideoModel.relays);
        return oldVideoModel;
      }
    } else {
      return newVideoModel;
    }
  }

  // * get user dms /
  static String getUserDms({
    int? since,
    int? since1059,
    required Function(Event) kind1059Events,
    required Function(Event) kind4Events,
  }) {
    Set<String> dms = {};
    final pubkey = nostrRepository.usm!.pubKey;

    final f1 = Filter(
      kinds: [
        EventKind.DIRECT_MESSAGE,
      ],
      p: [pubkey],
      since: since,
    );

    final f3 = Filter(
      kinds: [
        EventKind.DIRECT_MESSAGE,
      ],
      authors: [pubkey],
      since: since,
    );

    final f2 = Filter(
      kinds: [
        EventKind.GIFT_WRAP,
      ],
      since: since1059 != null ? since1059 - 604800 : null,
      p: [pubkey],
    );

    return NostrConnect.sharedInstance.addSubscription(
      [f1, f2, f3],
      [],
      eventCallBack: (event, relay) async {
        if (!dms.contains(event.id)) {
          dms.add(event.id);
          if (event.kind == EventKind.GIFT_WRAP) {
            kind1059Events.call(event);
          } else if (event.kind == EventKind.DIRECT_MESSAGE) {
            kind4Events.call(event);
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {},
    );
  }

  // * get user notifications /
  static Stream<List<Event>> getUserNotifications({
    required String pubkey,
    List<String>? followings,
    int? limit,
    int? since,
    int? until,
  }) {
    var controller = StreamController<List<Event>>();
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();

    List<String> eventsToBeEmitted = [];
    List<Event> events = [];

    final filter = Filter(
      kinds: [
        EventKind.TEXT_NOTE,
        EventKind.REACTION,
        EventKind.APP_CUSTOM,
        EventKind.ZAP,
      ],
      p: [pubkey],
      since: since,
      until: until,
      limit: limit,
    );

    final filter2 = Filter(
      kinds: [
        EventKind.TEXT_NOTE,
      ],
      authors: followings ?? nostrRepository.followings,
      l: [FN_SEARCH_VALUE],
      since: since,
      until: until,
      limit: limit,
    );

    final filter3 = Filter(
      kinds: [
        EventKind.CURATION_ARTICLES,
        EventKind.CURATION_VIDEOS,
        EventKind.LONG_FORM,
        EventKind.VIDEO_HORIZONTAL,
        EventKind.VIDEO_VERTICAL,
        EventKind.SMART_WIDGET,
      ],
      authors: nostrRepository.followings,
      since: since,
      until: until,
      limit: limit,
    );

    final id = NostrConnect.sharedInstance.addSubscription(
      [
        filter,
        filter2,
        filter3,
      ],
      [],
      eventCallBack: (event, relay) {
        if (!eventsToBeEmitted.contains(event.id) && event.pubkey != pubkey) {
          eventsToBeEmitted.add(event.id);
          events.add(event);

          if (event.kind == EventKind.ZAP) {
            authorsCubit.getAuthors([getZapPubkey(event.tags).first]);
          } else {
            authorsCubit.getAuthors([event.pubkey]);
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;

        if (!controller.isClosed) {
          controller.add(
            events
              ..sort(
                (a, b) => b.createdAt.compareTo(a.createdAt),
              ),
          );
        }

        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
          NostrConnect.sharedInstance.closeRequests([id]);
        }
      },
    );

    return controller.stream;
  }

  // * app curations /
  static Stream<List<Curation>> getCurationsByPubkeys({
    required List<String> pubkeys,
  }) {
    var controller = StreamController<List<Curation>>();
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();
    Map<String, Curation> curationsToBeEmitted = {};

    NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: [EventKind.CURATION_ARTICLES, EventKind.CURATION_VIDEOS],
          authors: pubkeys,
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.CURATION_ARTICLES ||
            event.kind == EventKind.CURATION_VIDEOS) {
          final curation = Curation.fromEvent(event, relay);

          final oldCuration = curationsToBeEmitted[curation.identifier];

          curationsToBeEmitted[curation.identifier] = filterCuration(
            oldCuration: oldCuration,
            newCuration: curation,
          );
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (curationsToBeEmitted.isNotEmpty) {
          final values = curationsToBeEmitted.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (!controller.isClosed) controller.add(values);
          authorsCubit.getAuthors(values.map((e) => e.pubKey).toSet().toList());
        }

        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  static void getCurations({
    required Function(List<Curation>) onCurations,
    required Function() onDone,
  }) {
    Map<String, Curation> curationsToBeEmitted = {};
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();

    NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: [EventKind.CURATION_ARTICLES, EventKind.CURATION_VIDEOS],
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        if ((event.kind == EventKind.CURATION_ARTICLES ||
            event.kind == EventKind.CURATION_VIDEOS)) {
          final curation = Curation.fromEvent(event, relay);
          if (curation.eventsIds.isNotEmpty) {
            final oldCuration = curationsToBeEmitted[curation.identifier];

            curationsToBeEmitted[curation.identifier] = filterCuration(
              oldCuration: oldCuration,
              newCuration: curation,
            );
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (curationsToBeEmitted.isNotEmpty) {
          final authors = curationsToBeEmitted.values
              .map((curation) => curation.pubKey)
              .toSet()
              .toList();

          final updatedCurations = curationsToBeEmitted.values.toList();

          updatedCurations.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );

          nostrRepository.curationsMemBox.setCurationsList(
            updatedCurations,
          );

          authorsCubit.getAuthors(authors);
          onCurations.call(updatedCurations);
        }

        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          onDone.call();
          timer.cancel();
        }
      },
    );
  }

  static Curation filterCuration({
    required Curation? oldCuration,
    required Curation newCuration,
  }) {
    if (oldCuration != null) {
      final isNew = oldCuration.createdAt.compareTo(newCuration.createdAt) < 1;

      if (isNew) {
        newCuration.relays.addAll(oldCuration.relays);
        return newCuration;
      } else {
        oldCuration.relays.addAll(newCuration.relays);
        return oldCuration;
      }
    } else {
      return newCuration;
    }
  }

  // * get events * /
  static Stream<Event> getEvents({
    List<String>? ids,
    List<String>? dTags,
    List<String>? pubkeys,
    List<String>? tags,
    List<String>? aTags,
    List<String>? eTags,
    List<int>? kinds,
    int? limit,
    String? relay,
    int? until,
  }) {
    var controller = StreamController<Event>();
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();

    NostrConnect.sharedInstance.addSubscription(
      [
        if (dTags != null)
          Filter(
            d: dTags,
            authors: pubkeys,
            t: tags,
            limit: limit,
            until: until,
          ),
        Filter(
          ids: ids,
          authors: pubkeys,
          e: eTags,
          t: tags,
          limit: limit,
          kinds: kinds,
          until: until,
        ),
      ],
      relay != null ? [relay] : [],
      eventCallBack: (event, relay) {
        if (!controller.isClosed) controller.add(event);
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  static Stream<Event> getNoteStats({
    required List<String> noteIds,
    required List<String>? pubkeys,
    required bool isSelfStats,
  }) {
    var controller = StreamController<Event>();
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();

    final f2 = Filter(
      q: noteIds,
      authors: pubkeys,
      kinds: [EventKind.TEXT_NOTE],
    );

    NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          e: noteIds,
          authors: pubkeys,
          kinds: [EventKind.TEXT_NOTE, EventKind.REACTION, EventKind.REPOST],
        ),
        f2,
        if (!isSelfStats)
          Filter(
            e: noteIds,
            kinds: [
              EventKind.ZAP,
            ],
          ),
      ],
      [],
      eventCallBack: (event, relay) {
        if (!controller.isClosed) controller.add(event);
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  static Stream<Event> getForwardingEvents({
    List<String>? ids,
    List<String>? dTags,
    List<String>? pubkeys,
    List<int>? kinds,
    List<String>? relays,
  }) {
    var controller = StreamController<Event>();
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.relays();

    final filter = Filter(d: dTags, authors: pubkeys, ids: ids, kinds: kinds);

    NostrConnect.sharedInstance.addSubscription(
      [
        filter,
      ],
      relays ?? [],
      eventCallBack: (event, relay) {
        if (!controller.isClosed) controller.add(event);
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  // * Authors metadata /
  static void startSearchForAuthors(
    List<String> pubkeys, {
    bool? resetPubkeys,
    required Function(List<String>) toBeSearchedAuthorsFunc,
    required Function(Map<String, UserModel>) authorsFunc,
    required Function() onDone,
  }) {
    List<String> toBeSearchedAuthors = pubkeys;
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();
    Map<String, UserModel> currentAuthors =
        Map<String, UserModel>.from(authorsCubit.state.authors);

    if (resetPubkeys == null) {
      final availableAuthors = List<String>.from(currentAuthors.keys);

      toBeSearchedAuthors.removeWhere(
        (author) {
          return availableAuthors.contains(author);
        },
      );
    }

    toBeSearchedAuthors
        .removeWhere((element) => authorsCubit.notFound.contains(element));

    if (toBeSearchedAuthors.isNotEmpty) {
      Map<String, UserModel> resettingAuthors = {};

      NostrConnect.sharedInstance.addSubscription(
        [
          Filter(
            kinds: [EventKind.METADATA],
            authors: toBeSearchedAuthors,
          ),
        ],
        [],
        eventCallBack: (event, relay) {
          final author = UserModel.fromJson(
            event.content,
            event.pubkey,
            event.tags,
            event.createdAt,
          );

          toBeSearchedAuthors.remove(author.pubKey);

          final canBeAdded = resetPubkeys != null
              ? resettingAuthors[event.pubkey] == null ||
                  resettingAuthors[event.pubkey]!
                          .createdAt
                          .compareTo(author.createdAt) <
                      0
              : currentAuthors[event.pubkey] == null ||
                  currentAuthors[event.pubkey]!
                          .createdAt
                          .compareTo(author.createdAt) <
                      0;

          if (canBeAdded) {
            checkNip05Validity(event);

            if (resetPubkeys == null) {
              currentAuthors[author.pubKey] = author;
            } else {
              resettingAuthors[author.pubKey] = author;
            }
          }
        },
        eoseCallBack: (authorRequestId, ok, relay, unCompletedRelays) {
          if (ok.status) {
            authorsFunc(
              resetPubkeys != null ? resettingAuthors : currentAuthors,
            );
          }
          currentUncompletedRelays = unCompletedRelays;
          toBeSearchedAuthorsFunc(toBeSearchedAuthors);
          NostrConnect.sharedInstance.closeSubscription(authorRequestId, relay);
        },
      );
    }

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks + 10) {
          onDone.call();
          timer.cancel();
        }
      },
    );
  }

  static Future<void> checkNip05Validity(Event event) async {
    try {
      if (authorsCubit.state.nip05Validations[event.pubkey] == null ||
          !authorsCubit.state.nip05Validations[event.pubkey]!) {
        final dns = await Nip5.decode(event);

        if (dns != null) {
          final validity = await HttpFunctionsRepository.checkNip05Validity(
            domain: dns.domain,
            name: dns.name,
            pubkey: event.pubkey,
          );

          if (validity) {
            final nip05Validations =
                Map<String, bool>.from(authorsCubit.state.nip05Validations);
            nip05Validations[event.pubkey] = true;
            authorsCubit.setNip05Validations(nip05Validations);
          }
        }
      }
    } catch (e) {
      lg.i(e);
    }
  }

  static Future<void> checkNip05ValidityFromData({
    required String pubkey,
    required String nip05,
  }) async {
    try {
      if (authorsCubit.state.nip05Validations[pubkey] == null ||
          !authorsCubit.state.nip05Validations[pubkey]!) {
        final dns = await Nip5.decodeFromString(nip05: nip05, pubkey: pubkey);

        if (dns != null) {
          final validity = await HttpFunctionsRepository.checkNip05Validity(
            domain: dns.domain,
            name: dns.name,
            pubkey: pubkey,
          );

          if (validity) {
            final nip05Validations =
                Map<String, bool>.from(authorsCubit.state.nip05Validations);
            nip05Validations[pubkey] = true;

            authorsCubit.setNip05Validations(nip05Validations);
          }
        }
      }
    } catch (e) {
      lg.i(e);
    }
  }

  // * User bookmarks /
  static void setBookmarks({
    required bool isReplaceableEvent,
    required String bookmarkIdentifier,
    required String identifier,
    required String pubkey,
    required String image,
    required int kind,
  }) async {
    final bookmarkList = nostrRepository.bookmarksLists[bookmarkIdentifier];

    if (bookmarkList == null) {
      BotToastUtils.showError('Insure that bookmarks list exist!');
      return;
    }

    bool isEnabled = false;

    late EventCoordinates bookmarkEvent;

    final isBookmarkAvailable = isReplaceableEvent
        ? bookmarkList.isReplaceableEventAvailable(
            identifier: identifier,
            isReplaceableEvent: isReplaceableEvent,
          )
        : bookmarkList.bookmarkedEvents.contains(identifier);

    if (!isBookmarkAvailable && isReplaceableEvent) {
      bookmarkEvent = EventCoordinates(
        kind,
        pubkey,
        identifier,
        null,
      );
    }

    final bookmarksLoadingIdentifiers =
        nostrRepository.loadingBookmarks[bookmarkIdentifier];

    if (bookmarksLoadingIdentifiers != null) {
      bookmarksLoadingIdentifiers.add(identifier);
    } else {
      nostrRepository.loadingBookmarks[bookmarkIdentifier] = {identifier};
    }

    nostrRepository.loadingBookmarksController
        .add(nostrRepository.loadingBookmarks);

    late BookmarkListModel newBookmarkListModel;

    if (isReplaceableEvent) {
      List<EventCoordinates> updatedReplaceableEvents = [];

      if (isBookmarkAvailable) {
        updatedReplaceableEvents = bookmarkList.bookmarkedReplaceableEvents
          ..removeWhere((event) => event.identifier == identifier);
      } else {
        updatedReplaceableEvents = bookmarkList.bookmarkedReplaceableEvents
          ..add(bookmarkEvent);
      }

      newBookmarkListModel = bookmarkList.copyWith(
        bookmarkedReplaceableEvents: updatedReplaceableEvents,
        image: image.isNotEmpty && !isBookmarkAvailable
            ? image
            : bookmarkList.image,
      );
    } else {
      List<String> updatedEvents = [];

      if (isBookmarkAvailable) {
        updatedEvents = bookmarkList.bookmarkedEvents
          ..removeWhere((event) => event == identifier);
      } else {
        updatedEvents = bookmarkList.bookmarkedEvents
          ..add(
            identifier,
          );
      }

      newBookmarkListModel = bookmarkList.copyWith(
        bookmarkedEvents: updatedEvents,
        image: image.isNotEmpty && !isBookmarkAvailable
            ? image
            : bookmarkList.image,
      );
    }

    final bookmarksEvent =
        await newBookmarkListModel.bookmarkListModelToEvent();

    if (bookmarksEvent == null) {
      BotToastUtils.showError('Error occured while adding the bookmark!');
      return;
    }

    NostrConnect.sharedInstance.sendEvent(
      bookmarksEvent,
      [],
      sendCallBack: (ok, relay, unCompletedRelays) {
        if (ok.status && !isEnabled) {
          isEnabled = true;
          nostrRepository.bookmarksLists[bookmarkIdentifier] =
              newBookmarkListModel;
          nostrRepository.loadingBookmarks[bookmarkIdentifier]
              ?.remove(identifier);
          nostrRepository.loadingBookmarksController
              .add(nostrRepository.loadingBookmarks);
          nostrRepository.bookmarksController
              .add(nostrRepository.bookmarksLists);

          if (!isBookmarkAvailable) {
            HttpFunctionsRepository.sendActionThroughEvent(bookmarksEvent);
          }
        }
      },
    );
  }

  static String getBookmarks({
    required BookmarkListModel bookmarksModel,
    required Function(List<dynamic>) contentFunc,
  }) {
    final filteredCurations = bookmarksModel.bookmarkedReplaceableEvents
        .where(
          (event) =>
              event.kind == EventKind.CURATION_ARTICLES ||
              event.kind == EventKind.CURATION_VIDEOS,
        )
        .toList();

    final filteredArticles = bookmarksModel.bookmarkedReplaceableEvents
        .where(
          (event) => event.kind == EventKind.LONG_FORM,
        )
        .toList();

    final filteredVideos = bookmarksModel.bookmarkedReplaceableEvents
        .where(
          (event) =>
              event.kind == EventKind.VIDEO_HORIZONTAL ||
              event.kind == EventKind.VIDEO_VERTICAL,
        )
        .toList();

    if (filteredArticles.isEmpty &&
        filteredCurations.isEmpty &&
        filteredVideos.isEmpty &&
        bookmarksModel.bookmarkedEvents.isEmpty) {
      return '';
    }

    final searchFilters = <Filter>[
      if (bookmarksModel.bookmarkedEvents.isNotEmpty)
        Filter(
          kinds: [EventKind.TEXT_NOTE],
          ids: bookmarksModel.bookmarkedEvents,
        ),
      Filter(
        kinds: [EventKind.CURATION_ARTICLES, EventKind.CURATION_VIDEOS],
        d: filteredCurations.map((e) => e.identifier).toList(),
      ),
      Filter(
        kinds: [EventKind.LONG_FORM],
        d: filteredArticles.map((e) => e.identifier).toList(),
      ),
      Filter(
        kinds: [EventKind.VIDEO_HORIZONTAL, EventKind.VIDEO_VERTICAL],
        d: filteredVideos.map((e) => e.identifier).toList(),
      ),
    ];

    Map<String, DetailedNoteModel> notes = {};
    Map<String, FlashNews> flashNewsList = {};
    Map<String, BuzzFeedModel> aiFeedList = {};
    Map<String, Curation> curations = {};
    Map<String, Article> articles = {};
    Map<String, VideoModel> videos = {};

    return NostrConnect.sharedInstance.addSubscription(
      searchFilters,
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.TEXT_NOTE) {
          final tags = event.tags.firstWhere(
            (element) =>
                element.first == 'l' &&
                (element[1] == FN_SEARCH_VALUE ||
                    element[1] == AF_SEARCH_VALUE),
            orElse: () => [],
          );

          if (tags.isEmpty) {
            final note = DetailedNoteModel.fromEvent(event);

            if (notes[event.id] == null ||
                notes[event.id]!.createdAt.compareTo(note.createdAt) < 1) {
              notes[event.id] = note;
              authorsCubit.getAuthors(
                [note.pubkey],
              );
            }
          } else if (tags[1] == FN_SEARCH_VALUE) {
            final flashNews = FlashNews.fromEvent(event);

            if (flashNews.isAuthentic) {
              if (flashNewsList[flashNews.id] == null ||
                  flashNews.createdAt
                      .isAfter(flashNewsList[flashNews.id]!.createdAt)) {
                flashNewsList[flashNews.id] = flashNews;
              }
            }
          } else {
            final aiFeedModel = BuzzFeedModel.fromEvent(event);

            if (aiFeedModel.isAuthentic) {
              if (aiFeedList[aiFeedModel.id] == null ||
                  aiFeedModel.createdAt
                      .isAfter(aiFeedList[aiFeedModel.id]!.createdAt)) {
                aiFeedList[aiFeedModel.id] = aiFeedModel;
              }
            }
          }
        } else if (event.kind == EventKind.CURATION_ARTICLES ||
            event.kind == EventKind.CURATION_VIDEOS) {
          final curation = Curation.fromEvent(
            event,
            relay,
          );

          if (curations[curation.identifier] == null ||
              curations[curation.identifier]!
                      .createdAt
                      .compareTo(curation.createdAt) <
                  1) {
            curations[curation.identifier] = curation;
            authorsCubit.getAuthors(
              [curation.pubKey],
            );
          }
        } else if (event.kind == EventKind.LONG_FORM) {
          final article = Article.fromEvent(
            event,
          );

          if (articles[article.identifier] == null ||
              articles[article.identifier]!
                      .createdAt
                      .compareTo(article.createdAt) <
                  1) {
            articles[article.identifier] = article;
            authorsCubit.getAuthors(
              [article.pubkey],
            );
          }
        } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
            event.kind == EventKind.VIDEO_VERTICAL) {
          final video = VideoModel.fromEvent(
            event,
          );

          if (videos[video.identifier] == null ||
              videos[video.identifier]!.createdAt.compareTo(video.createdAt) <
                  1) {
            videos[video.identifier] = video;
            authorsCubit.getAuthors(
              [video.pubkey],
            );
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        if (ok.status &&
            (notes.isNotEmpty ||
                curations.isNotEmpty ||
                articles.isNotEmpty ||
                flashNewsList.isNotEmpty)) {
          List<dynamic> content = [
            ...notes.values.toList(),
            ...curations.values.toList(),
            ...flashNewsList.values.toList(),
            ...articles.values.toList(),
            ...videos.values.toList(),
            ...aiFeedList.values.toList(),
          ];

          content.sort(
            (a, b) {
              final aDate = a is DetailedNoteModel
                  ? a.createdAt
                  : a is Curation
                      ? a.createdAt
                      : a is FlashNews
                          ? a.createdAt
                          : a is VideoModel
                              ? a.createdAt
                              : a is BuzzFeedModel
                                  ? a.createdAt
                                  : (a as Article).createdAt;

              final bDate = b is DetailedNoteModel
                  ? b.createdAt
                  : b is Curation
                      ? b.createdAt
                      : b is FlashNews
                          ? b.createdAt
                          : b is VideoModel
                              ? b.createdAt
                              : b is BuzzFeedModel
                                  ? b.createdAt
                                  : (b as Article).createdAt;

              return aDate.compareTo(bDate);
            },
          );

          contentFunc.call(content);
        }

        NostrConnect.sharedInstance.closeSubscription(requestId, relay);
      },
    );
  }

  // * get user stats /
  static getUserFollowers({
    required String pubkey,
    required Function(Set<String>) onFollowers,
    required Function(Set<String>) onDone,
  }) {
    Set<String> followers = {};
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();

    NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: [EventKind.CONTACT_LIST],
          p: [pubkey],
        ),
      ],
      [],
      eventCallBack: (event, relay) async {
        if (event.kind == EventKind.CONTACT_LIST && event.pubkey != pubkey) {
          if (!followers.contains(event.pubkey)) {
            followers.add(event.pubkey);
          }
        }
      },
      eoseCallBack: (authorRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        NostrConnect.sharedInstance.closeSubscription(authorRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          timer.cancel();
          onDone.call(followers);
        } else {
          onFollowers.call(followers);
        }
      },
    );
  }

  static String getUserProfile({
    required String authorPubkey,
    required Function(Set<String>) followersFunc,
    required Function(Set<String>) followingsFunc,
    required Function(Set<String>) relaysFunc,
    required Function(List<Article>) articleFunc,
    required Function(List<FlashNews>) flashNewsFunc,
    required Function(List<VideoModel>) videosFunc,
    required Function(List<DetailedNoteModel>) notesFunc,
    required Function(List<Curation>) curationsFunc,
    required Function(double) zaps,
    required Function() onDone,
  }) {
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();

    Set<String> followers = {};
    Set<String> receivedZaps = {};
    double addedZaps = 0;
    Set<String> followings = {};
    Set<String> relays = {};
    DateTime kind3Date = DateTime(2000);
    DateTime kind10002Date = DateTime(2000);
    Map<String, Article> articlesToBeEmitted = {};
    Map<String, FlashNews> flashNewsToBeEmitted = {};
    Map<String, VideoModel> videosToBeEmitted = {};
    Map<String, DetailedNoteModel> notesToBeEmitted = {};
    Map<String, Curation> curationsToBeEmitted = {};

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          onDone.call();
          timer.cancel();
        }
      },
    );

    return NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: [EventKind.CONTACT_LIST, EventKind.ZAP],
          p: [authorPubkey],
        ),
        Filter(
          kinds: [EventKind.CONTACT_LIST],
          authors: [authorPubkey],
        ),
        Filter(
          kinds: [EventKind.RELAY_LIST_METADATA],
          authors: [authorPubkey],
        ),
        Filter(
          kinds: [EventKind.LONG_FORM],
          authors: [authorPubkey],
        ),
        Filter(
          kinds: [EventKind.CURATION_ARTICLES, EventKind.CURATION_VIDEOS],
          authors: [authorPubkey],
        ),
        Filter(
          kinds: [EventKind.TEXT_NOTE],
          l: [FN_SEARCH_VALUE],
          authors: [authorPubkey],
        ),
        Filter(
          kinds: [EventKind.VIDEO_HORIZONTAL, EventKind.VIDEO_VERTICAL],
          authors: [authorPubkey],
        ),
        Filter(
          kinds: [EventKind.TEXT_NOTE],
          authors: [authorPubkey],
          limit: 20,
        ),
      ],
      [],
      eventCallBack: (event, relay) async {
        if (event.kind == EventKind.CONTACT_LIST &&
            event.pubkey != authorPubkey) {
          if (!followers.contains(event.pubkey)) {
            followers.add(event.pubkey);
            followersFunc.call(followers);
          }
        } else if (event.kind == EventKind.CONTACT_LIST &&
            event.pubkey == authorPubkey) {
          final eventDate =
              DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);

          if (kind3Date.compareTo(eventDate) < 1) {
            kind3Date = eventDate;

            for (final tag in event.tags) {
              if (tag.first == 'p' && tag.length > 1) {
                final id = tag[1];

                if (!followings.contains(id)) {
                  followings.add(id);
                }
              }
            }

            followingsFunc.call(followings);

            if (nostrRepository.usm == UserStatus.UsingPrivKey &&
                nostrRepository.user.pubKey == authorPubkey) {
              final user = nostrRepository.user.copyWith(
                followings: followings
                    .map(
                      (e) => Profile(e, '', ''),
                    )
                    .toList(),
              );

              nostrRepository.setUserModelFollowing(user);
            }
          }
        } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
            event.kind == EventKind.VIDEO_VERTICAL &&
                event.pubkey == authorPubkey) {
          final video = VideoModel.fromEvent(event);

          if (video.url.isNotEmpty) {
            final old = videosToBeEmitted[video.identifier];

            if (old == null || old.createdAt.compareTo(video.createdAt) < 1) {
              videosToBeEmitted[video.identifier] = video;
              videosFunc.call(videosToBeEmitted.values.toList());
            }
          }
        } else if (event.kind == EventKind.CURATION_ARTICLES ||
            event.kind == EventKind.CURATION_VIDEOS &&
                event.pubkey == authorPubkey) {
          final curation = Curation.fromEvent(event, relay);

          final oldCuration = curationsToBeEmitted[curation.identifier];

          curationsToBeEmitted[curation.identifier] = filterCuration(
            oldCuration: oldCuration,
            newCuration: curation,
          );

          curationsFunc.call(curationsToBeEmitted.values.toList());
        } else if (event.kind == EventKind.ZAP) {
          if (!receivedZaps.contains(event.id)) {
            receivedZaps.add(event.id);

            final receipt = Nip57.getZapReceipt(event);

            if (receipt.bolt11.isNotEmpty) {
              try {
                final req = Bolt11PaymentRequest(receipt.bolt11);
                final amount = req.amount.toDouble() * 100000000;
                addedZaps = (addedZaps.round() + amount).toDouble();
                zaps.call(addedZaps);
              } catch (_) {}
            }
          }
        } else if (event.kind == EventKind.RELAY_LIST_METADATA) {
          final eventDate =
              DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);

          if (kind10002Date.compareTo(eventDate) < 1) {
            for (final tag in event.tags) {
              if (tag.first == 'r' && tag.length > 1) {
                if (!relays.contains(tag[1]) && !relays.contains(tag[1])) {
                  relays.add(tag[1]);
                }
              }
            }

            relaysFunc.call(relays);
          }
        } else if (event.kind == EventKind.LONG_FORM) {
          final article = Article.fromEvent(event);
          final oldArticle = articlesToBeEmitted[article.identifier];

          if (oldArticle == null ||
              article.createdAt.isAfter(oldArticle.createdAt)) {
            articlesToBeEmitted[article.identifier] = article;
            final sortedArticles = articlesToBeEmitted.values.toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            articleFunc.call(sortedArticles);
          }
        } else if (event.kind == EventKind.TEXT_NOTE) {
          if (event.isFlashNews()) {
            final flashNews = FlashNews.fromEvent(event);

            if (flashNewsToBeEmitted[flashNews.id] == null ||
                flashNews.createdAt
                    .isAfter(flashNewsToBeEmitted[flashNews.id]!.createdAt)) {
              flashNewsToBeEmitted[flashNews.id] = flashNews;
              final sortedFlashnews = flashNewsToBeEmitted.values.toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              flashNewsFunc.call(sortedFlashnews);
            }
          } else if (event.isSimpleNote()) {
            final note = DetailedNoteModel.fromEvent(event);

            if (notesToBeEmitted[note.id] == null ||
                note.createdAt.isAfter(notesToBeEmitted[note.id]!.createdAt)) {
              notesToBeEmitted[note.id] = note;
              final sortedNotes = notesToBeEmitted.values.toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              notesFunc.call(sortedNotes);
            }
          }
        }
      },
      eoseCallBack: (authorRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        NostrConnect.sharedInstance.closeSubscription(authorRequestId, relay);
      },
    );
  }

  static sendZapsToPoints({
    required List<ZapsToPoints> zapsToPointsList,
    String? id,
  }) {
    if (id != null) NostrConnect.sharedInstance.closeRequests([id]);

    List<String> receivedZaps = [];

    final filters = zapsToPointsList.map((e) {
      return Filter(
        p: [e.pubkey],
        since: e.actionTimeStamp,
        e: e.eventId != null ? [e.eventId!] : null,
        kinds: [EventKind.ZAP],
      );
    }).toList();

    id = NostrConnect.sharedInstance.addSubscription(
      filters,
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.ZAP) {
          if (!receivedZaps.contains(event.id)) {
            receivedZaps.add(event.id);

            String pTag = '';
            String eventId = '';

            for (final tag in event.tags) {
              if (tag.first == 'p' && tag.length > 1 && pTag.isEmpty) {
                pTag = tag[1];
              }

              if (tag.first == 'e' && tag.length > 1) {
                eventId = tag[1];
              }
            }

            final index = zapsToPointsList.indexWhere(
              (element) =>
                  element.pubkey == pTag &&
                  (eventId.isNotEmpty ? element.eventId == eventId : true),
            );

            if (index != -1) {
              final sats = getZapValue(event);

              if (sats != 0) {
                zapsToPointsList.removeAt(index);
                pointsManagementCubit.sendZapsPoints(sats);
              } else {
                zapsToPointsList.removeAt(index);
              }
            }
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {},
    );
  }

// * connect to relay /
  static Future<bool> connectToRelay(String relay) async {
    try {
      final completer = Completer<bool>();
      bool isSuccessful = false;

      final newRelays = List<String>.from(NostrConnect.sharedInstance.relays())
        ..add(relay);

      final event = await Event.genEvent(
        content: '',
        kind: EventKind.RELAY_LIST_METADATA,
        privkey: nostrRepository.usm!.privKey,
        tags: newRelays.map((relay) => ['r', relay]).toList(),
        pubkey: nostrRepository.usm!.pubKey,
      );

      if (event == null) {
        completer.complete(false);
      } else {
        NostrConnect.sharedInstance.sendEvent(
          event,
          nostrRepository.relays.toList(),
          sendCallBack: (ok, relay, unCompletedRelays) {
            if (ok.status) {
              isSuccessful = true;
            }
          },
        );

        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
          if (isSuccessful || timer.tick >= timerTicks) {
            timer.cancel();
            completer.complete(isSuccessful);
            if (isSuccessful) {
              nostrRepository.setRelays(newRelays.toSet());
            }
          }
        });
      }

      return completer.future;
    } catch (e) {
      return false;
    }
  }

  // * get events stats /
  static Future<bool> addEvent({
    required Event event,
    List<String>? relays,
  }) async {
    final completer = Completer<bool>();
    bool isSuccessful = false;
    final id = uuid.generate();

    NostrConnect.sharedInstance.sendEvent(
      event,
      relays ?? [],
      sendCallBack: (ok, relay, unCompletedRelays) {
        relaysProgressCubit.setRelays(
          requestId: id,
          incompleteRelays: unCompletedRelays,
        );

        if (ok.status && !isSuccessful) {
          isSuccessful = true;
        }
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (isSuccessful || timer.tick > timerTicks) {
          completer.complete(isSuccessful);
          timer.cancel();
          if (isSuccessful) {
            HttpFunctionsRepository.sendActionThroughEvent(event);
          }
        }
      },
    );

    return await completer.future;
  }

  static Stream<dynamic> getStats({
    required bool isEtag,
    required int eventKind,
    String? eventPubkey,
    List<int>? selectedKinds,
    List<String>? eventIds,
    String? identifier,
    bool? getViews,
  }) {
    var controller = StreamController<dynamic>();
    Map<String, Comment> comments = {};
    Map<String, double> zaps = {};
    List<String> zapsEventIds = [];
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();
    Map<String, Map<String, VoteModel>> votes = {};
    Set<String> reports = {};
    List<String> views = [];
    EventCoordinates? identifierTag;

    if (!isEtag) {
      identifierTag = EventCoordinates(
        eventKind,
        eventPubkey!,
        identifier!,
        null,
      );
    }

    final aTag = !isEtag ? [identifierTag.toString()] : null;

    final filters = [
      if (selectedKinds == null || selectedKinds.contains(EventKind.TEXT_NOTE))
        Filter(
          kinds: [EventKind.TEXT_NOTE],
          e: !isEtag ? null : eventIds,
          a: aTag,
        ),
      if (selectedKinds == null || selectedKinds.contains(EventKind.REACTION))
        Filter(
          kinds: [EventKind.REACTION],
          e: eventIds,
          a: aTag,
        ),
      if (selectedKinds == null || selectedKinds.contains(EventKind.REPORTING))
        Filter(
          kinds: [EventKind.REPORTING],
          e: eventIds,
          a: aTag,
        ),
      if (selectedKinds == null || selectedKinds.contains(EventKind.ZAP))
        Filter(
          kinds: [EventKind.ZAP],
          p: eventPubkey == null ? null : [eventPubkey],
          e: eventIds,
          a: aTag,
        ),
      if (getViews != null)
        Filter(
          a: aTag,
          d: aTag,
          kinds: [
            EventKind.VIDEO_VIEW,
          ],
        )
    ];

    NostrConnect.sharedInstance.addSubscription(
      filters,
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.TEXT_NOTE) {
          if ((isEtag && !event.isUncensoredNote()) || !isEtag) {
            final comment = Comment.fromEvent(event);

            filterComments(
              comment: comment,
              comments: comments,
              controller: controller,
            );
          }
        } else if (event.kind == EventKind.ZAP) {
          filterZaps(
            zapsEventIds: zapsEventIds,
            zaps: zaps,
            event: event,
            isEtag: isEtag,
            identifier: identifierTag?.identifier,
            controller: controller,
          );
        } else if (event.kind == EventKind.REACTION) {
          filterVotes(
            votes: votes,
            event: event,
            isEtag: isEtag,
            identifier: identifierTag.toString(),
            controller: controller,
          );
        } else if (event.kind == EventKind.REPORTING) {
          filterReports(
            report: event.pubkey,
            reports: reports,
            controller: controller,
          );
        } else if (event.kind == EventKind.VIDEO_VIEW) {
          if (!views.contains(event.pubkey)) {
            views.add(event.pubkey);
            controller.add(views);
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        NostrConnect.sharedInstance.closeSubscription(requestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  // * get user by pubkey /
  static void getCurrentUserMetadata({
    required String pubKey,
    required bool isPrivKey,
    required UserStatusModel userStatusModel,
  }) async {
    DateTime kind3Date = DateTime(2000);
    DateTime kind10002Date = DateTime(2000);
    DateTime kind30100Date = DateTime(2000);
    DateTime kind10000Date = DateTime(2000);

    final relays = NostrConnect.sharedInstance.relays()
      ..removeWhere((element) => constantRelays.contains(element));
    nostrRepository.relays = constantRelays.toSet();

    await NostrConnect.sharedInstance.closeConnect(relays);

    NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: [
            EventKind.METADATA,
            EventKind.CONTACT_LIST,
            EventKind.RELAY_LIST_METADATA,
            if (isPrivKey) EventKind.MUTE_LIST,
          ],
          authors: [pubKey],
        ),
        Filter(
          kinds: [EventKind.APP_CUSTOM],
          authors: [pubKey],
          d: [yakihonneTopicTag],
        ),
      ],
      [],
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) async {
        NostrConnect.sharedInstance.closeSubscription(requestId, relay);
      },
      eventCallBack: (event, relay) {
        if (event.kind == 0) {
          final newUser = UserModel.fromJson(
            event.content,
            event.pubkey,
            event.tags,
            event.createdAt,
          );

          if (nostrRepository.user.createdAt.compareTo(newUser.createdAt) < 0) {
            final updatedUser = newUser.copyWith(
              followings: nostrRepository.user.followings,
            );

            authorsCubit.addAuthor(updatedUser, event: event);
            nostrRepository.setUserModelFollowing(updatedUser);
          }
        } else if (event.kind == EventKind.CONTACT_LIST) {
          if (kind3Date.toSecondsSinceEpoch().compareTo(event.createdAt) < 1) {
            kind3Date =
                DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
            final newUser = nostrRepository.user.copyWith(
              followings: Nip2.toProfiles(event.tags),
            );

            nostrRepository.setUserModelFollowing(newUser);
          }
        } else if (event.kind == EventKind.RELAY_LIST_METADATA) {
          if (kind10002Date.toSecondsSinceEpoch().compareTo(event.createdAt) <
              1) {
            kind10002Date =
                DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
            if (event.tags.isNotEmpty) {
              for (final tag in event.tags) {
                if (tag.first == 'r' && tag.length > 1) {
                  if (!nostrRepository.relays.contains(tag[1])) {
                    nostrRepository.relays.add(tag[1]);
                    NostrConnect.sharedInstance.connect(tag[1]);
                  }
                }
              }

              nostrRepository.relaysController.add(nostrRepository.relays);
            }
          }
        } else if (event.kind == EventKind.MUTE_LIST) {
          if (kind10000Date.toSecondsSinceEpoch().compareTo(event.createdAt) <
              1) {
            nostrRepository.muteListAdditionalData.clear();

            kind10000Date =
                DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);

            if (event.tags.isNotEmpty) {
              for (final tag in event.tags) {
                if (tag.first == 'p' && tag.length > 1) {
                  nostrRepository.mutes.add(tag[1]);
                } else {
                  nostrRepository.muteListAdditionalData.add(tag);
                }
              }

              nostrRepository.mutesController.add(nostrRepository.mutes);
            }
          }
        } else if (event.kind == EventKind.APP_CUSTOM) {
          if (kind30100Date.toSecondsSinceEpoch().compareTo(event.createdAt) <
              1) {
            kind30100Date =
                DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);

            final topics = topicsFromEvent(event);
            nostrRepository.userTopics = topics;
            nostrRepository.userTopicsController.add(topics);
          }
        }
      },
    );
  }

  static Stream<UserModel> getUserMetaData({
    required String pubkey,
  }) {
    var controller = StreamController<UserModel>();
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();

    DateTime authorCreatedAt = DateTime(2000);

    NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: [EventKind.METADATA],
          authors: [pubkey],
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.METADATA) {
          final author = UserModel.fromJson(
            event.content,
            event.pubkey,
            event.tags,
            event.createdAt,
          );

          if (authorCreatedAt.compareTo(author.createdAt) < 1) {
            authorCreatedAt = author.createdAt;
            controller.add(author);
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  static void setCustomTopics(String topic) async {
    final _cancel = BotToast.showLoading();

    List<String> currentTopics = List<String>.from(nostrRepository.userTopics);

    if (currentTopics.contains(topic.trim())) {
      currentTopics.remove(topic.trim());
    } else {
      currentTopics.add(topic);
    }

    final event = await Event.genEvent(
      kind: EventKind.APP_CUSTOM,
      tags: [
        ['d', yakihonneTopicTag],
        ...currentTopics.map((e) => ['t', e]).toList(),
      ],
      content: '',
      privkey: nostrRepository.usm!.privKey,
      pubkey: nostrRepository.usm!.pubKey,
    );

    if (event == null) {
      _cancel.call();
      return;
    }

    final isSuccessful = await NostrFunctionsRepository.addEvent(event: event);

    if (isSuccessful) {
      nostrRepository.setTopics(currentTopics);
      BotToastUtils.showSuccess('Your topics have been updated');
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }

    _cancel.call();
  }

  // * get home page data /
  static Stream<List<dynamic>> getHomePageData({
    required bool isBuzzFeed,
    List<String>? pubkeys,
    List<String>? tags,
    int? limit,
    int? until,
    String? relay,
    bool? addNotes,
  }) {
    var controller = StreamController<List<dynamic>>();
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();
    Map<String, Article> articlesToBeEmitted = {};
    Map<String, VideoModel> videosToBeEmitted = {};
    Map<String, FlashNews> flashNewsToBeEmitted = {};
    Map<String, BuzzFeedModel> buzzFeedModelToBeEmitted = {};
    Map<String, DetailedNoteModel> notesToBeEmitted = {};

    String id = '';
    try {
      id = NostrConnect.sharedInstance.addSubscription(
        [
          if (!isBuzzFeed) ...[
            Filter(
              kinds: [
                EventKind.LONG_FORM,
                EventKind.VIDEO_HORIZONTAL,
                EventKind.VIDEO_VERTICAL,
              ],
              authors: pubkeys,
              t: tags,
              until: until,
              limit: limit,
            ),
            Filter(
              kinds: [EventKind.TEXT_NOTE],
              authors: pubkeys,
              t: tags,
              l: [FN_SEARCH_VALUE, AF_SEARCH_VALUE],
              until: until,
              limit: limit,
            ),
          ],
          Filter(
            kinds: [EventKind.TEXT_NOTE],
            authors: pubkeys,
            t: tags,
            l: [AF_SEARCH_VALUE],
            until: until,
            limit: limit,
          ),
          if (addNotes != null)
            Filter(
              kinds: [EventKind.TEXT_NOTE],
              authors: pubkeys,
              t: tags,
              until: until,
              limit: limit,
            ),
        ],
        relay != null ? [relay] : [],
        eventCallBack: (event, relay) {
          if (!nostrRepository.mutes.contains(event.pubkey)) {
            if (event.kind == EventKind.LONG_FORM) {
              final article = Article.fromEvent(
                event,
                relay: relay,
              );

              final oldArticle = articlesToBeEmitted[article.identifier];

              articlesToBeEmitted[article.identifier] = filterArticle(
                oldArticle: oldArticle,
                newArticle: article,
              );
            } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
                event.kind == EventKind.VIDEO_VERTICAL) {
              final video = VideoModel.fromEvent(
                event,
                relay: relay,
              );

              final oldVideo = videosToBeEmitted[video.identifier];
              if (oldVideo == null ||
                  oldVideo.createdAt.isBefore(video.createdAt)) {
                videosToBeEmitted[video.identifier] = video;
              }
            } else if (event.kind == EventKind.TEXT_NOTE) {
              if (event.isFlashNews()) {
                flashNewsToBeEmitted[event.id] = FlashNews.fromEvent(event);
              } else if (event.isBuzzFeed()) {
                buzzFeedModelToBeEmitted[event.id] =
                    BuzzFeedModel.fromEvent(event);
              } else if (event.isSimpleNote()) {
                notesToBeEmitted[event.id] = DetailedNoteModel.fromEvent(event);
              }
            }
          }
        },
        eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
          currentUncompletedRelays = unCompletedRelays;

          final articles = orderedList(articlesToBeEmitted.values.toList());
          final videos = orderedList(videosToBeEmitted.values.toList());
          final flashNews = orderedList(flashNewsToBeEmitted.values.toList());
          final buzzFeed =
              orderedList(buzzFeedModelToBeEmitted.values.toList());
          final notes = orderedList(notesToBeEmitted.values.toList());

          final length = [
            articles.length,
            videos.length,
            flashNews.length,
            buzzFeed.length,
            notes.length,
          ].reduce(max);

          if (ok.status && length != 0) {
            List<CreatedAtTag> list = [];

            for (int i = 0; i < length; i++) {
              if (flashNews.length != 0) {
                list.add(flashNews.removeAt(0));
              }
              if (videos.length != 0) {
                list.add(videos.removeAt(0));
              }

              if (articles.length != 0) {
                list.add(articles.removeAt(0));
              }
              if (buzzFeed.length != 0) {
                list.add(buzzFeed.removeAt(0));
              }
              if (notes.length != 0) {
                list.add(notes.removeAt(0));
              }
            }

            if (!controller.isClosed) controller.add(list);

            authorsCubit.getAuthors(list.map((e) => e.pubkey).toSet().toList());
          }

          NostrConnect.sharedInstance
              .closeSubscription(curationRequestId, relay);
        },
      );
    } catch (e) {
      lg.i(e);
    }

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
          NostrConnect.sharedInstance.closeRequests([id]);
        }
      },
    );

    return controller.stream;
  }

  static List<CreatedAtTag> orderedList(List<CreatedAtTag> list) {
    final values = list
      ..sort((a, b) => (b is BuzzFeedModel ? b.publishedAt : b.createdAt)
          .compareTo(a is BuzzFeedModel ? a.publishedAt : a.createdAt));

    return values;
  }

  // * get smart widgets /
  static Stream<List<SmartWidgetModel>> getSmartWidgets({
    List<String>? smartWidgetsIds,
    List<String>? pubkeys,
    List<String>? tags,
    int? limit,
    int? until,
    String? relay,
  }) {
    var controller = StreamController<List<SmartWidgetModel>>();

    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();
    Map<String, SmartWidgetModel> smartWidgetsToBeEmitted = {};

    final id = NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: [EventKind.SMART_WIDGET],
          d: smartWidgetsIds?.toList(),
          authors: pubkeys,
          t: tags,
          until: until,
          limit: limit,
        ),
      ],
      relay != null ? [relay] : [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.SMART_WIDGET &&
            !nostrRepository.mutes.contains(event.pubkey)) {
          final smartWidget = SmartWidgetModel.fromEvent(
            event,
          );

          final oldSmartWidget =
              smartWidgetsToBeEmitted[smartWidget.identifier];
          if (oldSmartWidget == null ||
              oldSmartWidget.createdAt.compareTo(smartWidget.createdAt) <= 0) {
            smartWidgetsToBeEmitted[smartWidget.identifier] = smartWidget;
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;

        if (ok.status && smartWidgetsToBeEmitted.isNotEmpty) {
          final values = smartWidgetsToBeEmitted.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (!controller.isClosed) controller.add(values);

          authorsCubit.getAuthors(values.map((e) => e.pubkey).toSet().toList());
        }

        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
          NostrConnect.sharedInstance.closeRequests([id]);
        }
      },
    );

    return controller.stream;
  }

  // * get articles /
  static Stream<List<Article>> getArticles({
    List<String>? articlesIds,
    List<String>? pubkeys,
    List<String>? tags,
    int? limit,
    int? until,
    String? relay,
    ArticleFilter? articleFilter,
  }) {
    var controller = StreamController<List<Article>>();
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();
    Map<String, Article> articlesToBeEmitted = {};

    final id = NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: articleFilter == null
              ? [EventKind.LONG_FORM]
              : articleFilter == ArticleFilter.All
                  ? [EventKind.LONG_FORM, EventKind.LONG_FORM_DRAFT]
                  : articleFilter == ArticleFilter.Published
                      ? [EventKind.LONG_FORM]
                      : [EventKind.LONG_FORM_DRAFT],
          d: articlesIds?.toList(),
          authors: pubkeys,
          t: tags,
          until: until,
          limit: limit,
        ),
      ],
      relay != null ? [relay] : [],
      eventCallBack: (event, relay) {
        if ((event.kind == EventKind.LONG_FORM ||
                event.kind == EventKind.LONG_FORM_DRAFT) &&
            !nostrRepository.mutes.contains(event.pubkey)) {
          final article = Article.fromEvent(
            event,
            relay: relay,
            isDraft: event.kind == EventKind.LONG_FORM_DRAFT,
          );

          final oldArticle = articlesToBeEmitted[article.identifier];

          articlesToBeEmitted[article.identifier] = filterArticle(
            oldArticle: oldArticle,
            newArticle: article,
          );
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;

        if (ok.status && articlesToBeEmitted.isNotEmpty) {
          final values = articlesToBeEmitted.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (!controller.isClosed) controller.add(values);

          authorsCubit.getAuthors(values.map((e) => e.pubkey).toSet().toList());
        }

        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
          NostrConnect.sharedInstance.closeRequests([id]);
        }
      },
    );

    return controller.stream;
  }

  static Stream<List<String>> sendEventWithRelays({
    required Event event,
    required List<String> relays,
  }) {
    var controller = StreamController<List<String>>();
    Set<String> successfulRelays = {};
    List<String> currentUncompletedRelays = relays;
    bool isSuccessful = false;

    NostrConnect.sharedInstance.sendEvent(
      event,
      relays,
      sendCallBack: (ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;

        if (ok.status) {
          isSuccessful = true;
          successfulRelays.add(relay);
          controller.add(successfulRelays.toList());
        }
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
          if (isSuccessful) {
            HttpFunctionsRepository.sendActionThroughEvent(event);
          }
        }
      },
    );

    return controller.stream;
  }

  // * get flash news events /
  static Stream<List<FlashNews>> getUserFlashNews({
    required String pubkey,
  }) {
    var controller = StreamController<List<FlashNews>>();
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();
    Map<String, FlashNews> flashNewsToBeEmitted = {};

    NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: [EventKind.TEXT_NOTE],
          l: [FN_SEARCH_VALUE],
          authors: [pubkey],
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        final flashNews = FlashNews.fromEvent(event);

        if (flashNews.isAuthentic) {
          if (flashNewsToBeEmitted[flashNews.id] == null ||
              flashNews.createdAt
                  .isAfter(flashNewsToBeEmitted[flashNews.id]!.createdAt)) {
            flashNewsToBeEmitted[flashNews.id] = flashNews;
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        if (ok.status && flashNewsToBeEmitted.isNotEmpty) {
          final updatedFlashnews = flashNewsToBeEmitted.values.toList();
          updatedFlashnews.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );

          if (!controller.isClosed) controller.add(updatedFlashnews);
        }

        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  static Stream<Map<String, List<FlashNews>>> getFlashNewsWithTime({
    required DateTime since,
    required DateTime until,
  }) {
    var controller = StreamController<Map<String, List<FlashNews>>>();
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();

    Map<String, Map<String, FlashNews>> flashNewsToBeEmitted = {
      dateFormat2.format(until): {},
      dateFormat2.format(since): {},
    };

    NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: [EventKind.TEXT_NOTE],
          l: [FN_SEARCH_VALUE],
          since: since.toSecondsSinceEpoch(),
          until: until.toSecondsSinceEpoch(),
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        final flashNews = FlashNews.fromEvent(event);

        if (flashNews.isAuthentic) {
          if (flashNewsToBeEmitted[flashNews.formattedDate] == null) {
            flashNewsToBeEmitted[flashNews.formattedDate] = {
              flashNews.id: flashNews,
            };
          } else {
            final flashNewsList =
                flashNewsToBeEmitted[flashNews.formattedDate]!;
            final canBeAdded = flashNewsList[flashNews.id] == null ||
                flashNewsList[flashNews.id]!
                        .createdAt
                        .compareTo(flashNews.createdAt) <
                    1;

            if (canBeAdded) {
              flashNewsList.addAll(
                {
                  flashNews.id: flashNews,
                },
              );
            }
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (ok.status && flashNewsToBeEmitted.isNotEmpty) {
          Map<String, List<FlashNews>> updatedFlashNews = {};
          Set<String> authors = {};

          flashNewsToBeEmitted.forEach(
            (key, value) {
              updatedFlashNews[key] = value.values.toList()
                ..sort(
                  (a, b) => b.createdAt.compareTo(a.createdAt),
                );

              authors.addAll(value.values.map((e) => e.pubkey).toList());
            },
          );
          if (!controller.isClosed) controller.add(updatedFlashNews);
          authorsCubit.getAuthors(authors.toList());
        }

        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  static Stream<List<FlashNews>> getFlashNews({
    List<String>? tags,
    List<String>? pubkeys,
    List<String>? ids,
    int? limit,
  }) {
    var controller = StreamController<List<FlashNews>>();
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();
    Map<String, FlashNews> flashNewsToBeEmitted = {};

    final id = NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: [EventKind.TEXT_NOTE],
          l: [FN_SEARCH_VALUE],
          authors: pubkeys,
          t: tags,
          ids: ids,
          limit: limit,
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        final flashNews = FlashNews.fromEvent(event);
        final oldFlashNews = flashNewsToBeEmitted[flashNews.id];

        if (flashNews.isAuthentic &&
            !nostrRepository.mutes.contains(flashNews.pubkey)) {
          if (oldFlashNews == null ||
              flashNews.createdAt.isAfter(oldFlashNews.createdAt)) {
            flashNewsToBeEmitted[flashNews.id] = flashNews;
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (ok.status && flashNewsToBeEmitted.isNotEmpty) {
          Set<String> authors = {};

          flashNewsToBeEmitted.values.forEach((element) {
            authors.add(element.pubkey);
          });

          final updatedFlashNews = flashNewsToBeEmitted.values.toList();

          updatedFlashNews.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );

          if (!controller.isClosed) controller.add(updatedFlashNews);
          authorsCubit.getAuthors(authors.toList());
        }

        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
          NostrConnect.sharedInstance.closeRequests([id]);
        }
      },
    );

    return controller.stream;
  }

  // * add voting event /
  static Future<String?> addVote({
    required String eventId,
    required bool upvote,
    required bool isEtag,
    required String eventPubkey,
    String? identifier,
    int? kind,
  }) async {
    final completer = Completer<String?>();

    final event = await Event.genEvent(
      kind: 7,
      content: upvote ? '+' : '-',
      pubkey: nostrRepository.usm!.pubKey,
      privkey: nostrRepository.usm!.privKey,
      verify: true,
      tags: [
        isEtag
            ? ['e', eventId]
            : Nip33.coordinatesToTag(
                EventCoordinates(
                  kind!,
                  eventPubkey,
                  identifier!,
                  '',
                ),
              ),
        ['p', eventPubkey],
      ],
    );

    if (event == null) {
      completer.complete(null);
    } else {
      bool isSuccessful = false;
      final id = uuid.generate();

      NostrConnect.sharedInstance.sendEvent(
        event,
        [],
        sendCallBack: (ok, relay, unCompletedRelays) {
          relaysProgressCubit.setRelays(
            requestId: id,
            incompleteRelays: unCompletedRelays,
          );
          if (ok.status && !isSuccessful) {
            isSuccessful = true;
          }
        },
      );

      Timer.periodic(
        const Duration(milliseconds: 500),
        (timer) {
          if (isSuccessful || timer.tick > timerTicks) {
            completer.complete(isSuccessful ? event.id : null);
            timer.cancel();
            if (isSuccessful) {
              HttpFunctionsRepository.sendActionThroughEvent(event);
            }
          }
        },
      );
    }

    return await completer.future;
  }

  // * add comment event /

  // * add comment event /
  static Future<Event?> addNoteReply({
    required DetailedNoteModel note,
    required String content,
    required List<String> mentions,
  }) async {
    final completer = Completer<Event?>();
    final prefix = await localDatabaseRepository.getPrefix();
    final comment = commentShearableLink(
      status: prefix,
      comment: content,
      id: note.id,
      pubkey: note.pubkey,
      kind: EventKind.TEXT_NOTE,
    );

    final root = [
      'e',
      note.isRoot ? note.id : note.originId ?? note.id,
      '',
      'root'
    ];

    final event = await Event.genEvent(
      kind: 1,
      content: comment,
      pubkey: nostrRepository.usm!.pubKey,
      privkey: nostrRepository.usm!.privKey,
      verify: true,
      tags: [
        root,
        if (!note.isRoot) ['e', note.id, '', 'reply'],
        for (final mention in mentions)
          if (content.contains(Nip19.encodePubkey(mention))) ['p', mention],
        ['p', note.pubkey],
      ],
    );

    if (event == null) {
      completer.complete(null);
    } else {
      bool isSuccessful = false;
      Event? successfulEvent;

      NostrConnect.sharedInstance.sendEvent(
        event,
        [],
        sendCallBack: (ok, relay, unCompletedRelays) {
          if (ok.status && !isSuccessful) {
            isSuccessful = true;
            successfulEvent = event;
          }
        },
      );

      Timer.periodic(
        const Duration(milliseconds: 500),
        (timer) {
          if (isSuccessful || timer.tick > timerTicks) {
            completer.complete(successfulEvent);
            timer.cancel();
            if (isSuccessful) {
              HttpFunctionsRepository.sendActionThroughEvent(event);
            }
          }
        },
      );
    }

    return await completer.future;
  }

  static Future<Comment?> addComment({
    required String eventId,
    required String eventPubkey,
    required int eventKind,
    required bool isEtag,
    required String content,
    required String replyCommentId,
    required List<String> mentions,
    int? selectedEventKind,
    String? identifier,
  }) async {
    final completer = Completer<Comment?>();
    final prefix = await localDatabaseRepository.getPrefix();
    final comment = commentShearableLink(
      status: prefix,
      comment: content,
      id: isEtag ? eventId : identifier!,
      pubkey: eventPubkey,
      kind: eventKind,
    );

    final event = await Event.genEvent(
      kind: 1,
      content: comment,
      pubkey: nostrRepository.usm!.pubKey,
      privkey: nostrRepository.usm!.privKey,
      verify: true,
      tags: [
        isEtag
            ? ['e', eventId, '', 'root']
            : Nip33.coordinatesToTag(
                EventCoordinates(
                  selectedEventKind!,
                  eventPubkey,
                  identifier!,
                  '',
                ),
              )
          ..add('root'),
        if (replyCommentId.isNotEmpty) ['e', replyCommentId, '', 'reply'],
        for (final mention in mentions)
          if (content.contains(Nip19.encodePubkey(mention))) ['p', mention],
        ['p', eventPubkey],
      ],
    );

    if (event == null) {
      completer.complete(null);
    } else {
      bool isSuccessful = false;
      Comment? addedComment;

      NostrConnect.sharedInstance.sendEvent(
        event,
        [],
        sendCallBack: (ok, relay, unCompletedRelays) {
          if (ok.status && !isSuccessful) {
            isSuccessful = true;

            addedComment = Comment(
              id: ok.eventId,
              pubKey: event.pubkey,
              content: comment,
              createdAt: DateTime.now(),
              isRoot: replyCommentId.isEmpty,
              replyTo: replyCommentId,
            );
          }
        },
      );

      Timer.periodic(
        const Duration(milliseconds: 500),
        (timer) {
          if (isSuccessful || timer.tick > timerTicks) {
            completer.complete(addedComment);
            timer.cancel();
            if (isSuccessful) {
              HttpFunctionsRepository.sendActionThroughEvent(event);
            }
          }
        },
      );
    }

    return await completer.future;
  }

  static Future<Event?> getEventById({
    required String eventId,
    required bool isIdentifier,
    List<int>? kinds,
  }) async {
    final completer = Completer<Event?>();
    List<String> uncompletedRelays = NostrConnect.sharedInstance.relays();
    Event? event;

    final f1 = Filter(
      ids: isIdentifier ? null : [eventId],
      d: isIdentifier ? [eventId] : null,
      kinds: kinds,
    );

    NostrConnect.sharedInstance.addSubscription(
      [f1],
      [],
      eventCallBack: (newEvent, relay) {
        event = newEvent;
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        uncompletedRelays = unCompletedRelays;
        NostrConnect.sharedInstance.closeSubscription(requestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (uncompletedRelays.isEmpty ||
            event != null ||
            timer.tick > timerTicks) {
          completer.complete(event);
          timer.cancel();
        }
      },
    );
    return completer.future;
  }

  // * flash news invoice
  static Future<bool> checkPayment(String eventId) async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    final completer = Completer<bool>();

    bool isChecked = false;

    NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: [EventKind.ZAP],
          p: [yakihonneHex],
          e: [eventId],
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.ZAP) {
          isChecked = true;
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        NostrConnect.sharedInstance.closeSubscription(requestId, relay);
      },
    );

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (isChecked) {
        timer.cancel();
        completer.complete(true);
      } else if (timer.tick > 6) {
        timer.cancel();
        completer.complete(false);
      }
    });

    return completer.future;
  }

  // * mute user /

  static Future<bool> setMuteList(String pubkey) async {
    if (nostrRepository.usm == null || !nostrRepository.usm!.isUsingPrivKey) {
      Set<String> newMuteList = Set<String>.from(nostrRepository.mutes);

      if (newMuteList.contains(pubkey)) {
        newMuteList.remove(pubkey);
      } else {
        newMuteList.add(pubkey);
      }

      nostrRepository.mutes = newMuteList;
      nostrRepository.mutesController.add(newMuteList);
      localDatabaseRepository.setLocalMutes(newMuteList.toList());

      return true;
    } else {
      Set<String> newMuteList = Set<String>.from(nostrRepository.mutes);

      if (newMuteList.contains(pubkey)) {
        newMuteList.remove(pubkey);
      } else {
        newMuteList.add(pubkey);
      }

      final event = await Event.genEvent(
        kind: EventKind.MUTE_LIST,
        tags: [
          ...newMuteList
              .map((user) => [
                    'p',
                    user,
                  ])
              .toList(),
          ...nostrRepository.muteListAdditionalData,
        ],
        content: '',
        privkey: nostrRepository.usm!.privKey,
        pubkey: nostrRepository.usm!.pubKey,
      );

      if (event == null) {
        return false;
      }

      bool isSuccessful = false;

      NostrConnect.sharedInstance.sendEvent(
        event,
        [],
        sendCallBack: (ok, relay, unCompletedRelays) {
          if (ok.status && !isSuccessful) {
            isSuccessful = true;
          }
        },
      );

      Completer<bool> completer = Completer<bool>();

      Timer.periodic(
        const Duration(milliseconds: 500),
        (timer) {
          if (isSuccessful || timer.tick > timerTicks) {
            if (isSuccessful) {
              nostrRepository.mutes = newMuteList;
              nostrRepository.mutesController.add(newMuteList);
            }

            timer.cancel();
            completer.complete(isSuccessful);
          }
        },
      );

      return completer.future;
    }
  }

  // * report event /
  static Future<bool> report({
    required String reason,
    required String comment,
    required bool isEtag,
    required String eventPubkey,
    String? identifier,
    String? eventId,
    int? kind,
  }) async {
    final completer = Completer<bool>();

    final event = await Event.genEvent(
      kind: 1984,
      tags: [
        if (isEtag) ['e', eventId!, reason],
        if (!isEtag)
          Nip33.coordinatesToTag(
            EventCoordinates(
              kind!,
              eventPubkey,
              identifier!,
              reason,
            ),
          ),
        ['p', eventPubkey],
      ],
      content: comment,
      privkey: nostrRepository.usm!.privKey,
      pubkey: nostrRepository.usm!.pubKey,
    );

    if (event == null) {
      completer.complete(false);
    } else {
      bool isSuccessful = false;

      NostrConnect.sharedInstance.sendEvent(
        event,
        [],
        sendCallBack: (ok, relay, unCompletedRelays) {
          if (ok.status && !isSuccessful) {
            isSuccessful = true;
          }
        },
      );

      Timer.periodic(
        const Duration(milliseconds: 500),
        (timer) {
          if (isSuccessful || timer.tick > timerTicks) {
            completer.complete(isSuccessful);
            timer.cancel();
          }
        },
      );
    }

    return await completer.future;
  }

  static Future<bool> setFollowingEvent({
    required bool isFollowingAuthor,
    required String targetPubkey,
  }) async {
    final completer = Completer<bool>();

    bool isSuccessful = false;
    List<Profile> profiles = [];

    if (isFollowingAuthor) {
      profiles = nostrRepository.user.followings
          .where(
            (profile) => profile.key != targetPubkey,
          )
          .toList();
    } else {
      profiles = List<Profile>.from(nostrRepository.user.followings)
        ..add(
          Profile(targetPubkey, '', ''),
        );
    }

    final profilesList = Nip2.toTags(profiles);

    final event = await Event.genEvent(
      kind: EventKind.CONTACT_LIST,
      content: '',
      privkey: nostrRepository.usm!.privKey,
      pubkey: nostrRepository.usm!.pubKey,
      tags: profilesList,
    );

    if (event == null) {
      completer.complete(false);
    } else {
      NostrConnect.sharedInstance.sendEvent(
        event,
        [],
        sendCallBack: (ok, relay, unCompletedRelays) {
          if (ok.status && !isSuccessful) {
            nostrRepository.setUserModelFollowing(
              nostrRepository.user.copyWith(
                followings: profiles,
              ),
            );

            isSuccessful = true;
          }
        },
      );

      Timer.periodic(
        const Duration(milliseconds: 500),
        (timer) {
          if (isSuccessful || timer.tick > timerTicks) {
            completer.complete(isSuccessful);
            timer.cancel();

            if (isSuccessful) {
              HttpFunctionsRepository.sendActionThroughEvent(event);
            }
          }
        },
      );
    }

    return completer.future;
  }

  // * delete an event /
  static Future<bool> deleteEvent({
    required String eventId,
    String? type,
    String? lable,
    String? relay,
  }) async {
    final completer = Completer<bool>();

    final event = await Event.genEvent(
      kind: EventKind.EVENT_DELETION,
      tags: [
        ['e', eventId],
        if (lable != null) ['l', lable, type!],
      ],
      content: 'this event is to be deleted',
      privkey: nostrRepository.usm!.privKey,
      pubkey: nostrRepository.usm!.pubKey,
    );

    if (event == null) {
      completer.complete(false);
    } else {
      bool isSuccessful = false;

      NostrConnect.sharedInstance.sendEvent(
        event,
        relay != null ? [relay] : [],
        sendCallBack: (ok, relay, unCompletedRelays) {
          if (ok.status && !isSuccessful) {
            isSuccessful = true;
          }
        },
      );

      Timer.periodic(
        const Duration(milliseconds: 500),
        (timer) {
          if (isSuccessful || timer.tick > timerTicks) {
            completer.complete(isSuccessful);
            timer.cancel();
          }
        },
      );
    }

    return await completer.future;
  }

  // * authors by pubkeys

  static Stream<Map<String, UserModel>> getAuthorsByPubkeys({
    required List<String> authors,
  }) {
    Map<String, UserModel> authorsToBeEmitted = {};
    StreamController<Map<String, UserModel>> controller = StreamController();
    List<String> currentUncompletedRelays =
        NostrConnect.sharedInstance.activeRelays();

    if (authors.isNotEmpty) {
      NostrConnect.sharedInstance.addSubscription(
        [
          Filter(
            kinds: [0],
            authors: authors,
          ),
        ],
        [],
        eventCallBack: (event, relay) {
          final author = UserModel.fromJson(
            event.content,
            event.pubkey,
            event.tags,
            event.createdAt,
          );

          if (authorsToBeEmitted[event.pubkey] == null ||
              authorsToBeEmitted[event.pubkey]!
                      .createdAt
                      .compareTo(author.createdAt) <
                  0) {
            authorsToBeEmitted[event.pubkey] = author;
            if (!controller.isClosed) controller.add(authorsToBeEmitted);
          }
        },
        eoseCallBack: (authorRequestId, ok, relay, unCompletedRelays) {
          currentUncompletedRelays = unCompletedRelays;
          if (authorsToBeEmitted.isNotEmpty) {
            authorsCubit.addAuthors(authorsToBeEmitted.values.toList());
          }
          NostrConnect.sharedInstance.closeSubscription(authorRequestId, relay);
        },
      );
    }

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  // * delete an event /
  static Future<bool> sendEvent({
    required Event event,
    required bool setProgress,
  }) async {
    final completer = Completer<bool>();
    bool isSuccessful = false;
    final id = uuid.generate();

    NostrConnect.sharedInstance.sendEvent(
      event,
      [],
      sendCallBack: (ok, relay, unCompletedRelays) {
        if (setProgress) {
          relaysProgressCubit.setRelays(
            requestId: id,
            incompleteRelays: unCompletedRelays,
          );
        }

        if (ok.status && !isSuccessful) {
          isSuccessful = true;
        }
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (isSuccessful || timer.tick > timerTicks) {
          completer.complete(isSuccessful);
          timer.cancel();
          if (isSuccessful) {
            HttpFunctionsRepository.sendActionThroughEvent(event);
          }
        }
      },
    );

    return await completer.future;
  }

  // ! filters
  static void filterComments({
    required Comment comment,
    required Map<String, Comment> comments,
    StreamController? controller,
  }) {
    final canBeAdded = comments[comment.id] == null ||
        comments[comment.id]!.createdAt.compareTo(comment.createdAt) < 1;

    if (canBeAdded) {
      comments[comment.id] = comment;
      if (controller != null && !controller.isClosed) controller.add(comments);
    }
  }

  static void filterReports({
    required String report,
    required Set<String> reports,
    StreamController? controller,
  }) {
    reports.add(report);
    if (controller != null && !controller.isClosed) controller.add(reports);
  }

  static void filterZaps({
    required List<String> zapsEventIds,
    required Map<String, double> zaps,
    required Event event,
    required bool isEtag,
    String? identifier,
    StreamController? controller,
  }) {
    final isATagAvailable = event.tags.where(
      (element) {
        if (isEtag) {
          return element.first == 'e';
        } else {
          if (element.first == 'a') {
            final c = Nip33.getEventCoordinates(element);
            return c.identifier == identifier;
          } else {
            return false;
          }
        }
      },
    );

    if (isATagAvailable.isEmpty) {
      return;
    }

    if (!zapsEventIds.contains(event.id)) {
      final receipt = Nip57.getZapReceipt(event);
      final req = Bolt11PaymentRequest(receipt.bolt11);

      zapsEventIds.add(event.id);
      final zapPubkey = getZapPubkey(event.tags).first;
      final usedPubkey = zapPubkey.isNotEmpty ? zapPubkey : event.pubkey;

      if (zaps[usedPubkey] == null) {
        zaps[usedPubkey] =
            (req.amount.toDouble() * 100000000).round().toDouble();
      } else {
        zaps[usedPubkey] =
            ((zaps[usedPubkey] ?? 0) + (req.amount.toDouble() * 100000000))
                .round()
                .toDouble();
        ;
      }

      if (controller != null && !controller.isClosed) controller.add(zaps);
    }
  }

  static void filterVotes({
    required Map<String, Map<String, VoteModel>> votes,
    required Event event,
    required bool isEtag,
    String? identifier,
    StreamController? controller,
  }) {
    if (event.content == '+' || event.content == '-') {
      final isATagAvailable = event.tags.lastWhere(
        (element) => isEtag
            ? element.first == 'e'
            : element.first == 'a' && element[1] == identifier.toString(),
        orElse: () => [],
      );

      if (isATagAvailable.isEmpty) {
        return;
      }

      EventCoordinates? eventCoordinates;

      if (!isEtag) {
        eventCoordinates = Nip33.getEventCoordinates(isATagAvailable);
      }

      final selectedKey =
          isEtag ? isATagAvailable[1] : eventCoordinates!.identifier;

      if (votes[selectedKey] == null) {
        votes[selectedKey] = {
          event.pubkey: VoteModel.fromEvent(event),
        };
      } else {
        votes[selectedKey]!.addAll({
          event.pubkey: VoteModel.fromEvent(event),
        });
      }

      if (controller != null && !controller.isClosed) controller.add(votes);
    }
  }

  static Article filterArticle({
    required Article? oldArticle,
    required Article newArticle,
  }) {
    if (oldArticle != null) {
      final isNew = oldArticle.createdAt.isBefore(newArticle.createdAt);

      if (isNew) {
        newArticle.relays.addAll(oldArticle.relays);
        return newArticle;
      } else {
        oldArticle.relays.addAll(newArticle.relays);
        return oldArticle;
      }
    } else {
      return newArticle;
    }
  }
}
