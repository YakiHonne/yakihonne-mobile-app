import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/nostr/event.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/utils.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit()
      : super(
          NotificationsState(
            events: [],
            index: 0,
            isRead: true,
            userStatus: getUserStatus(),
          ),
        ) {
    userStreamSubscription = nostrRepository.userModelStream.listen(
      (user) {
        emit(
          state.copyWith(
            userStatus: getUserStatus(),
          ),
        );
      },
    );
  }

  int? since;
  bool isNotificationView = false;
  late Map<String, List<String>> registredNotifications = {};
  late Map<String, List<String>> newNotifications = {};
  late StreamSubscription userStreamSubscription;

  void loadNotifications() {
    registredNotifications = localDatabaseRepository.getNotifications(true);
    newNotifications = localDatabaseRepository.getNotifications(false);
  }

  void setNotificationView(bool isNotification) {
    isNotificationView = isNotification;
  }

  void delayedQuery() async {
    await Future.delayed(const Duration(seconds: 2));

    if (NostrConnect.sharedInstance.activeRelays().isNotEmpty) {
      queryNotifications();
    }
  }

  void queryNotifications() {
    final oldEvents = state.events;
    List<Event> newEvents = [];

    if (nostrRepository.usm != null && nostrRepository.usm!.isUsingPrivKey) {
      emit(
        state.copyWith(
          isRead:
              newNotifications[nostrRepository.usm!.pubKey]?.isEmpty ?? true,
        ),
      );

      NostrFunctionsRepository.getUserNotifications(
        pubkey: nostrRepository.usm!.pubKey,
        limit: 40,
        until: DateTime.now().toSecondsSinceEpoch(),
        since: since,
      ).listen(
        (events) {
          newEvents = events;
          if (!isClosed)
            emit(
              state.copyWith(
                events: [...newEvents, ...oldEvents],
              ),
            );
        },
        onDone: () {
          if (newEvents.isNotEmpty) {
            if (isNotificationView) {
              addNotifications();
            } else {
              newEvents.sort(
                (a, b) => b.createdAt.compareTo(a.createdAt),
              );

              if (shouldBeNotified(newEvents)) {
                final pubkey = nostrRepository.usm!.pubKey;

                newNotifications[pubkey] = [
                  ...newNotifications[pubkey] ?? <String>[],
                  ...newEvents.map((e) => e.id).toList(),
                ].toSet().toList();

                localDatabaseRepository.setNotifications(
                  newNotifications,
                  false,
                );

                emit(
                  state.copyWith(
                    isRead: false,
                  ),
                );

                sendNotification(
                  newEvents.first,
                  newEventsNumber(),
                );
              }
            }
          }

          since = DateTime.now().toSecondsSinceEpoch();
        },
      );
    }
  }

  bool shouldBeNotified(List<Event> events, {String? pubkey}) {
    final userNewNotifications =
        newNotifications[pubkey ?? nostrRepository.usm?.pubKey ?? ''];
    final userRegistredNotifications =
        registredNotifications[pubkey ?? nostrRepository.usm!.pubKey];

    final doesNotContainNew = userNewNotifications == null ||
        userNewNotifications.isEmpty ||
        events.where((e) => userNewNotifications.contains(e.id)).length !=
            events.length;

    final doesNotContainRegistred = userRegistredNotifications == null ||
        userRegistredNotifications.isEmpty ||
        events.where((e) => userRegistredNotifications.contains(e.id)).length !=
            events.length;

    return !isNotificationView &&
        events.isNotEmpty &&
        doesNotContainNew &&
        doesNotContainRegistred;
  }

  int newEventsNumber({String? pubkey}) {
    final usedPubkey = pubkey ?? nostrRepository.usm!.pubKey;

    return newNotifications[usedPubkey]?.length ?? 0;
  }

  void addNotifications() {
    final pubkey = nostrRepository.usm!.pubKey;

    final registredNotificationsIds = registredNotifications[pubkey];

    if (registredNotificationsIds == null ||
        registredNotificationsIds.isEmpty) {
      registredNotifications[pubkey] = newNotifications[pubkey] ?? <String>[];
    } else {
      registredNotifications[pubkey] = [
        ...registredNotifications[pubkey]!,
        ...newNotifications[pubkey] ?? <String>[],
      ].toSet().toList();
    }

    localDatabaseRepository.setNotifications(
      registredNotifications,
      true,
    );

    newNotifications.remove(pubkey);

    localDatabaseRepository.setNotifications(
      newNotifications,
      false,
    );
  }

  void setIndex(int index) {
    emit(
      state.copyWith(
        index: index,
      ),
    );
  }

  void sendNotification(Event event, int count) {
    String title = '';
    String? body;

    UserModel? user = authorsCubit.getSpecificAuthor(event.pubkey);
    String name = getAuthorName(
      user ??
          emptyUserModel.copyWith(
            pubKey: event.pubkey,
            picturePlaceholder: getRandomPlaceholder(
              input: event.pubkey,
              isPfp: true,
            ),
          ),
    );

    if (event.kind == EventKind.REACTION) {
      title =
          "$name has reacted with ${event.content.replaceAll('+', '👍').replaceAll('-', '👎')}";
    } else if (event.kind == EventKind.ZAP) {
      var zapNum = getZapValue(event);
      var list = getZapPubkey(event.tags);

      if (list.first.isNotEmpty) {
        user = authorsCubit.getSpecificAuthor(list.first);
        name = getAuthorName(
          user ??
              emptyUserModel.copyWith(
                pubKey: event.pubkey,
                picturePlaceholder: getRandomPlaceholder(
                  input: event.pubkey,
                  isPfp: true,
                ),
              ),
        );
      }

      if (list[1].isNotEmpty) {
        body = list[1];
      }

      title = '$name has zapped you $zapNum sats';
    } else if (event.kind == EventKind.APP_CUSTOM) {
      title = 'YakiHonne notification';

      final isAuthor = event.tags
          .where((element) =>
              element.first == 'author' &&
              element[1] == nostrRepository.usm!.pubKey)
          .toList()
          .isNotEmpty;

      body = isAuthor
          ? 'Your uncensored note has been sealed.'
          : 'An uncensored note you have rated has been sealed.';
    } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
        event.kind == EventKind.VIDEO_HORIZONTAL) {
      final video = VideoModel.fromEvent(event);
      title = "$name's new video";
      body = video.title.isNotEmpty
          ? 'Title: ${video.title}'
          : 'checkout my video';
    } else {
      if (event.isUserTagged()) {
        if (event.isUncensoredNote()) {
          title = "Unknown's uncensored note";
        } else {
          title = '$name replied';
        }

        body = getCommentWithoutPrefix(event.content);
      } else {
        final flash = FlashNews.fromEvent(event);
        if (event.kind == EventKind.TEXT_NOTE && event.isFlashNews()) {
          title = "$name's new flash news";
          body = flash.content.isNotEmpty
              ? 'Content: ${flash.content}'
              : 'check out my flash news';
        } else if (event.kind == EventKind.CURATION_ARTICLES) {
          final curation = Curation.fromEvent(event, '');
          title = "$name's new curation";
          body = curation.title.isNotEmpty
              ? 'Title: ${curation.title}'
              : 'checkout my curation';
        } else if (event.kind == EventKind.LONG_FORM) {
          final article = Article.fromEvent(event);
          title = "$name's new article";
          body = article.title.isNotEmpty
              ? 'Title: ${article.title}'
              : 'checkout my article';
        } else if (event.kind == EventKind.SMART_WIDGET) {
          final sw = SmartWidgetModel.fromEvent(event);
          title = "$name's new smart widget";
          body = sw.title.isNotEmpty
              ? 'Title: ${sw.title}'
              : 'checkout my article';
        }
      }
    }

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: event.id.hashCode,
        channelKey: 'YakiHonne',
        largeIcon: user?.picture,
        title: title,
        body: body,
        payload: {'name': 'new notification'},
        badge: count,
      ),
    );
  }

  void markRead() {
    emit(
      state.copyWith(
        isRead: true,
      ),
    );

    addNotifications();
    AwesomeNotifications().setGlobalBadgeCounter(0);
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {}

  @override
  Future<void> close() {
    userStreamSubscription.cancel();

    return super.close();
  }
}
