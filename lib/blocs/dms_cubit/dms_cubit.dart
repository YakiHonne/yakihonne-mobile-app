import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/database/cache_database.dart';
import 'package:yakihonne/database/cache_manager_db.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/dm_models.dart';
import 'package:yakihonne/models/event_mem_box.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nips/nip_017.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/mixins/later_function.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';

part 'dms_state.dart';

class DmsCubit extends Cubit<DmsState> with PendingEventsLaterFunction {
  DmsCubit()
      : super(
          DmsState(
            dmSessionDetails: {},
            index: 0,
            isUsingNip44: nostrRepository.isUsingNip44,
            rebuild: true,
            isSendingMessage: false,
            mutes: nostrRepository.mutes.toList(),
          ),
        ) {
    giftWrapNewestDateTime = localDatabaseRepository.getNewestGiftWrap();
    followingsSubscription = nostrRepository.followingsStream.listen(
      (followings) {
        updateSessionsByFollowings(followings);
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

  late StreamSubscription userSubcription;
  late StreamSubscription followingsSubscription;
  late StreamSubscription muteListSubscription;
  Map<String, DMSessionInfo> infoMap = {};
  Map<String, Event> giftWraps = {};
  int _initSince = 0;
  String? dmsSubscriptionId;
  int? giftWrapNewestDateTime;
  DMSessionDetail? selectedDmSessionDetail;
  bool isDmsView = false;

  void setDmsView(bool isDms) {
    isDmsView = isDms;
  }

  void uploadMediaAndSend({
    required File file,
    required String pubkey,
    required String? replyId,
    required Function() onSuccess,
    required Function() onFailed,
  }) async {
    final _cancel = BotToast.showLoading();

    final imageLink = await HttpFunctionsRepository.uploadMedia(file: file);

    if (imageLink != null) {
      _cancel.call();
      sendEvent(pubkey, imageLink, replyId, onSuccess);
    } else {
      _cancel.call();
      onFailed.call();
      BotToastUtils.showError('Error occured while uploading the media');
    }
  }

  void setUsedMessagingNip(bool isUsingNip44) async {
    if (!isClosed)
      emit(
        state.copyWith(isUsingNip44: isUsingNip44),
      );

    nostrRepository.isUsingNip44 = isUsingNip44;
    localDatabaseRepository.setUsedNip(isUsingNip44);
  }

  DMSessionDetail? findOrNewADetail(String pubkey) {
    return state.dmSessionDetails[pubkey];
  }

  void updateReadedTime(String pubkey) async {
    final detail = state.dmSessionDetails[pubkey];
    if (detail != null && detail.dmSession.newestEvent != null) {
      final dmSessionDetail = state.dmSessionDetails[detail.dmSession.pubkey];

      if (dmSessionDetail != null) {
        double now = DateTime.now().millisecondsSinceEpoch / 1000;
        final newInfo = detail.info.copyWith(
          readTime: now.toInt(),
        );

        final map = Map<String, DMSessionDetail>.from(
          state.dmSessionDetails,
        );

        infoMap[detail.info.id] = newInfo;
        map[detail.dmSession.pubkey] = detail.copyWith(info: newInfo);

        emit(
          state.copyWith(
            dmSessionDetails: map,
          ),
        );

        await CacheManagerDB.SetDmInfo(newInfo);

        final globalCounter =
            await AwesomeNotifications().getGlobalBadgeCounter();
        if (globalCounter > 0) {
          AwesomeNotifications().setGlobalBadgeCounter(globalCounter - 1);
        }
      }
    }
  }

  void sendEvent(
    String pubkey,
    String text,
    String? replayId,
    Function() onSuccessful,
  ) async {
    try {
      emit(
        state.copyWith(
          isSendingMessage: true,
        ),
      );

      late Event event;
      bool isSuccessful = true;

      if (state.isUsingNip44) {
        final pmEvent = Event.withoutSignature(
          kind: EventKind.PRIVATE_DIRECT_MESSAGE,
          tags: [
            if (replayId != null) ['e', replayId],
            [
              'p',
              pubkey,
            ],
          ],
          content: text,
          pubkey: nostrRepository.usm!.pubKey,
        );

        final receiverEvent = await Nip17.encode(
          pmEvent,
          pubkey,
          nostrRepository.usm!.pubKey,
          nostrRepository.usm!.privKey,
        );

        final senderEvent = await Nip17.encode(
          pmEvent,
          nostrRepository.usm!.pubKey,
          nostrRepository.usm!.pubKey,
          nostrRepository.usm!.privKey,
        );

        if (senderEvent == null || receiverEvent == null) {
          emit(
            state.copyWith(
              isSendingMessage: false,
            ),
          );
          BotToastUtils.showError('Error occured while signing the event');
          return;
        }

        final successList = await Future.wait(
          [
            NostrFunctionsRepository.sendEvent(
              event: receiverEvent,
              setProgress: false,
            ),
            NostrFunctionsRepository.sendEvent(
              event: senderEvent,
              setProgress: false,
            ),
          ],
        );

        isSuccessful = successList.first && successList.last;
        event = senderEvent;
      } else {
        final receivedEvent = await Nip4.encode(
          nostrRepository.usm!.pubKey,
          pubkey,
          text,
          replayId ?? '',
          nostrRepository.usm!.privKey,
        );

        if (receivedEvent == null) {
          emit(
            state.copyWith(
              isSendingMessage: false,
            ),
          );
          BotToastUtils.showError('Error occured while signing the event');
          return;
        }

        event = receivedEvent;
        isSuccessful = await NostrFunctionsRepository.sendEvent(
          event: event,
          setProgress: false,
        );
      }

      if (isSuccessful) {
        if (pubkey == yakihonneHex) {
          HttpFunctionsRepository.sendAction(PointsActions.DMSYAKI);
        } else {
          HttpFunctionsRepository.sendAction(PointsActions.DMS);
        }

        addEventAndUpdateReadedTime(pubkey, event);
        onSuccessful.call();
      } else {
        BotToastUtils.showError('Error occured while sending the event');
      }

      emit(
        state.copyWith(
          isSendingMessage: false,
        ),
      );
    } catch (_) {
      BotToastUtils.showError('error occured while sending the message');

      emit(
        state.copyWith(
          isSendingMessage: false,
        ),
      );
    }
  }

  void addEventAndUpdateReadedTime(String pubkey, Event event) {
    if (event.kind == EventKind.GIFT_WRAP) {
      handleGiftWraps(event);
    } else {
      onEvent(event);
    }

    updateReadedTime(pubkey);
  }

  void updateSessionsByFollowings(List<String> followings) {
    final dms = Map<String, DMSessionDetail>.from(state.dmSessionDetails);

    for (final dm in dms.entries) {
      if (followings.contains(dm.key)) {
        if (dm.value.dmsType != DmsType.followings) {
          dms[dm.key] = dm.value.copyWith(
            dmsType: DmsType.followings,
          );
        }
      } else {
        if (dm.value.dmsType == DmsType.followings) {
          if (dm.value.dmSession
              .doesEventExist(nostrRepository.usm?.pubKey ?? '')) {
            dms[dm.key] = dm.value.copyWith(
              dmsType: DmsType.known,
            );
          } else {
            dms[dm.key] = dm.value.copyWith(
              dmsType: DmsType.unknown,
            );
          }
        }
      }
    }

    emit(
      state.copyWith(
        dmSessionDetails: dms,
      ),
    );
  }

  void initDmSessions() async {
    _initSince = 0;

    emit(
      DmsState(
        dmSessionDetails: {},
        isUsingNip44: nostrRepository.isUsingNip44,
        index: 0,
        rebuild: true,
        mutes: nostrRepository.mutes.toList(),
        isSendingMessage: false,
      ),
    );

    final data = await Future.wait([
      CacheManagerDB.loadEvents(kinds: [
        EventKind.DIRECT_MESSAGE,
        EventKind.PRIVATE_DIRECT_MESSAGE,
        EventKind.GIFT_WRAP,
      ]),
      CacheManagerDB.getDmInfos(nostrRepository.usm!.pubKey),
    ]);

    List<Nip01EventData> dmsEvents = data[0] as List<Nip01EventData>;
    List<DmInfoData> dmInfos = data[1] as List<DmInfoData>;

    if (dmsEvents.isNotEmpty) {
      dmsEvents = dmsEvents
          .where((event) => event.currentUser == nostrRepository.usm?.pubKey)
          .toList();
    }

    List<Nip01EventData> localGiftWraps = dmsEvents
        .where((element) => element.kind == EventKind.GIFT_WRAP)
        .toList();

    dmsEvents.removeWhere((element) => element.kind == EventKind.GIFT_WRAP);

    if (localGiftWraps.isNotEmpty) {
      this.giftWraps = {
        for (var v in localGiftWraps) v.id: Event.fromNip01EventData(v)
      };
    }

    dmsEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (dmsEvents.isNotEmpty) {
      _initSince = dmsEvents.first.createdAt.toSecondsSinceEpoch();
    }

    Map<String, List<Event>> eventListMap = {};

    for (var event in dmsEvents) {
      var pubkey = getPubkeyNip01Event(event);
      if (StringUtil.isNotBlank(pubkey)) {
        var list = eventListMap[pubkey!];
        if (list == null) {
          list = [];
          eventListMap[pubkey] = list;
        }

        list.add(Event.fromNip01EventData(event));
      }
    }

    infoMap = {};

    if (dmInfos.isNotEmpty) {
      for (var item in dmInfos)
        infoMap[item.peerPubkey] = DMSessionInfo.fromDmInfoData(item);
    }

    Map<String, DMSessionDetail> _dmSessions = {};

    for (var entry in eventListMap.entries) {
      var pubkey = entry.key;
      var list = entry.value;

      var session = DMSession(box: EventMemBox(), pubkey: pubkey);
      session.addEvents(list);

      var info = infoMap[pubkey];
      final currentUser = nostrRepository.usm!.pubKey;

      var detail = DMSessionDetail(
        dmSession: session,
        dmsType: DmsType.unknown,
        info: info ??
            DMSessionInfo(
              id: '${currentUser}+${pubkey}',
              peerPubkey: pubkey,
              ownPubkey: currentUser,
              readTime: 0,
            ),
      );

      if (nostrRepository.followings.contains(pubkey)) {
        _dmSessions[detail.dmSession.pubkey] = detail.copyWith(
          dmsType: DmsType.followings,
        );
      } else {
        if (detail.dmSession.doesEventExist(currentUser)) {
          _dmSessions[detail.dmSession.pubkey] = detail.copyWith(
            dmsType: DmsType.known,
          );
        } else {
          _dmSessions[detail.dmSession.pubkey] = detail;
        }
      }
    }

    emit(
      state.copyWith(dmSessionDetails: _dmSessions),
    );

    query();
  }

  void setMuteStatus({
    required String pubkey,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    final result = await NostrFunctionsRepository.setMuteList(pubkey);
    _cancel();

    if (result) {
      final hasBeenMuted = nostrRepository.mutes.contains(pubkey);

      BotToastUtils.showSuccess(
        hasBeenMuted ? 'User has been muted' : 'User has been unmuted',
      );

      onSuccess.call();
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }
  }

  Future<void> query() async {
    if (dmsSubscriptionId != null) {
      NostrConnect.sharedInstance.closeRequests([dmsSubscriptionId!]);
    }

    dmsSubscriptionId = NostrFunctionsRepository.getUserDms(
      since: _initSince != 0 ? _initSince : null,
      since1059: giftWrapNewestDateTime,
      kind1059Events: (giftEvent) {
        if (this.giftWraps[giftEvent.id] == null) {
          handleGiftWraps(giftEvent);
        }
      },
      kind4Events: (dmEvent) {
        onEvent(dmEvent);
      },
    );
  }

  void handleGiftWraps(Event gwe) async {
    if (giftWraps[gwe.id] == null) {
      this.giftWraps[gwe.id] = gwe;
      onEvent(gwe);
      final event = await Nip17.decodeNip17Event(gwe);

      if (event != null && event.kind == EventKind.PRIVATE_DIRECT_MESSAGE) {
        onEvent(event);
        setGiftWrapOldestDateTime(event);
      }
    }
  }

  void setGiftWrapOldestDateTime(Event event) {
    if (giftWrapNewestDateTime == null ||
        event.createdAt > giftWrapNewestDateTime!) {
      giftWrapNewestDateTime = event.createdAt;
      localDatabaseRepository.setNewestGiftWrap(event.createdAt);
    }
  }

  bool isCurrentUserPartOfEvent(Nip01EventData event) {
    final currentUser = nostrRepository.usm!.pubKey;
    if (event.pubKey == currentUser) {
      return true;
    }

    final tags = jsonDecode(event.tags);

    for (var tag in tags) {
      if (tag[0] == "p" && tag[1] == currentUser) {
        return true;
      }
    }

    return false;
  }

  String? getPubkeyNip01Event(Nip01EventData event) {
    if (event.pubKey != nostrRepository.usm!.pubKey) {
      return event.pubKey;
    }

    final tags = jsonDecode(event.tags);

    for (var tag in tags) {
      if (tag[0] == "p") {
        return tag[1];
      }
    }

    return null;
  }

  String? getPubkeyRegularEvent(Event event) {
    if (event.pubkey != nostrRepository.usm!.pubKey) {
      return event.pubkey;
    }

    for (var tag in event.tags) {
      if (tag[0] == "p") {
        return tag[1];
      }
    }

    return null;
  }

  void onEvent(Event event) {
    later(event, eventLaterHandle, null);
  }

  void eventLaterHandle(List<Event> events, {bool updateUI = true}) {
    bool updated = false;
    List<Event> toSave = [];
    for (var event in events) {
      var addResult = _addEvent(event);

      if (addResult) {
        toSave.add(event);
        updated = true;
      }
    }

    if (updated) {
      toSave.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      sendNotification(toSave.first);

      for (final e in toSave) {
        updateCurrentMessagesReadTime(e.pubkey);
      }

      CacheManagerDB.addMultiEvents(toSave);
    }
  }

  void updateCurrentMessagesReadTime(String pubkey) {
    if (nostrRepository.usersMessageNotifications.contains(pubkey)) {
      updateReadedTime(pubkey);
    }
  }

  bool _addEvent(Event event) {
    if (event.kind == EventKind.GIFT_WRAP) {
      return true;
    }

    var pubkey = getPubkeyRegularEvent(event);

    if (StringUtil.isBlank(pubkey)) {
      return false;
    }

    var dmSessionDetail = state.dmSessionDetails[pubkey];

    bool addResult = false;
    final _dmSessions =
        Map<String, DMSessionDetail>.from(state.dmSessionDetails);

    if (dmSessionDetail == null) {
      dmSessionDetail = DMSessionDetail(
        dmSession: DMSession(box: EventMemBox(), pubkey: pubkey!),
        info: DMSessionInfo(
          id: '${nostrRepository.usm!.pubKey}+${pubkey}',
          peerPubkey: pubkey,
          ownPubkey: nostrRepository.usm!.pubKey,
          readTime: 0,
        ),
        dmsType: DmsType.unknown,
      );

      addResult = dmSessionDetail.dmSession.addEvent(event);
    } else {
      addResult = dmSessionDetail.dmSession.addEvent(event);
    }

    if (nostrRepository.followings.contains(pubkey)) {
      _dmSessions[dmSessionDetail.dmSession.pubkey] = dmSessionDetail.copyWith(
        dmsType: DmsType.followings,
      );
    } else {
      if (dmSessionDetail.dmSession
          .doesEventExist(nostrRepository.usm!.pubKey)) {
        _dmSessions[dmSessionDetail.dmSession.pubkey] =
            dmSessionDetail.copyWith(
          dmsType: DmsType.known,
        );
      } else {
        _dmSessions[dmSessionDetail.dmSession.pubkey] = dmSessionDetail;
      }
    }

    emit(
      state.copyWith(
        dmSessionDetails: _dmSessions,
        rebuild: !state.rebuild,
      ),
    );

    if (_initSince < event.createdAt) {
      _initSince = event.createdAt;
    }

    return addResult;
  }

  int howManyNewDMSessionsWithNewMessages(DmsType dmsType) {
    int count = 0;
    final list = state.dmSessionDetails.values
        .where((element) => element.dmsType == dmsType)
        .toList();

    for (var element in list) {
      if (element.hasNewMessage()) {
        count++;
      }
    }

    return count;
  }

  bool gotMessages() {
    final following = howManyNewDMSessionsWithNewMessages(DmsType.followings);
    if (following != 0) {
      return true;
    } else {
      final known = howManyNewDMSessionsWithNewMessages(DmsType.known);
      if (known != 0) {
        return true;
      } else {
        final unknown = howManyNewDMSessionsWithNewMessages(DmsType.unknown);
        return unknown != 0;
      }
    }
  }

  List<DMSessionDetail> getSessionDetailsByType(DmsType dmsType) {
    if (dmsType == DmsType.all) {
      return state.dmSessionDetails.values.toList();
    } else {
      final detailList = state.dmSessionDetails.values
          .where((element) => element.dmsType == dmsType)
          .toList();

      detailList.sort(
        (detail0, detail1) {
          return detail1.dmSession.newestEvent!.createdAt -
              detail0.dmSession.newestEvent!.createdAt;
        },
      );

      return detailList;
    }
  }

  void sendNotification(Event event) async {
    if (event.pubkey != nostrRepository.usm!.pubKey &&
        event.kind != EventKind.GIFT_WRAP &&
        !isDmsView &&
        !nostrRepository.usersMessageNotifications.contains(event.pubkey)) {
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

      title = '${name}';

      final data = await nostrRepository.getMessage(event);
      body = data.first.trim().isNotEmpty
          ? data.first.trim()
          : 'message could not be decrypted';

      final globalCounter =
          await AwesomeNotifications().getGlobalBadgeCounter();

      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: event.id.hashCode,
          channelKey: 'YakiHonne',
          largeIcon: user?.picture,
          title: title,
          body: body,
          payload: {'name': 'new notification'},
          badge: globalCounter + 1,
        ),
      );
    }
  }

  void clear() {
    if (dmsSubscriptionId != null) {
      NostrConnect.sharedInstance.closeRequests([dmsSubscriptionId!]);
      dmsSubscriptionId = null;
    }

    emit(
      DmsState(
        dmSessionDetails: {},
        isUsingNip44: nostrRepository.isUsingNip44,
        index: 0,
        rebuild: true,
        isSendingMessage: false,
        mutes: nostrRepository.mutes.toList(),
      ),
    );
  }

  @override
  Future<void> close() {
    userSubcription.cancel();
    followingsSubscription.cancel();
    muteListSubscription.cancel();
    return super.close();
  }
}
