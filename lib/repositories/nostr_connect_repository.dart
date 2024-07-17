import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:yakihonne/nostr/close.dart';
import 'package:yakihonne/nostr/event.dart';
import 'package:yakihonne/nostr/filter.dart';
import 'package:yakihonne/nostr/message.dart';
import 'package:yakihonne/nostr/nips/nip_020.dart';
import 'package:yakihonne/nostr/request.dart';
import 'package:yakihonne/nostr/utils.dart';

/// notice callback
typedef NoticeCallBack = void Function(String notice, String relay);

/// send event callback
typedef OKCallBack = void Function(
    OKEvent ok, String relay, List<String> unCompletedRelays);

/// request callback
typedef EventCallBack = void Function(Event event, String relay);
typedef EOSECallBack = void Function(
    String requestId, OKEvent ok, String relay, List<String> unCompletedRelays);

/// connect callback
typedef ConnectStatusCallBack = void Function(String relay, int status);

class Sends {
  String sendsId;
  List<String> relays;
  int sendsTime;
  String eventId;
  OKCallBack? okCallBack;

  Sends(
      this.sendsId, this.relays, this.sendsTime, this.eventId, this.okCallBack);
}

class Requests {
  String requestId;
  List<String> relays;
  int requestTime;
  Map<String, String> subscriptions;
  EventCallBack? eventCallBack;
  EOSECallBack? eoseCallBack;

  Requests(this.requestId, this.relays, this.requestTime, this.subscriptions,
      this.eventCallBack, this.eoseCallBack);
}

class NostrConnect {
  NostrConnect._internal() {
    _startCheckTimeOut();
  }

  factory NostrConnect() => sharedInstance;
  static final NostrConnect sharedInstance = NostrConnect._internal();

  // 15 seconds time out
  static const int timeout = 15;

  NoticeCallBack? noticeCallBack;
  ConnectStatusCallBack? connectStatusCallBack;

  /// sockets
  Map<String, WebSocket?> webSockets = {};
  WebSocket? zapWebSocket;

  Set<String> closedRelays = {};

  /// connecting = 0;
  /// open = 1;
  /// closing = 2;
  /// closed = 3;
  Map<String, int> connectStatus = {};

  // subscriptionId+relay, Requests
  Map<String, Requests> requestsMap = {};
  // send event callback
  Map<String, Sends> sendsMap = {};
  // ConnectStatus listeners
  List<ConnectStatusCallBack> connectStatusListeners = [];
  // for timeout
  Timer? timer;

  void _startCheckTimeOut() {
    if (timer == null || timer!.isActive == false) {
      timer = Timer.periodic(
        const Duration(seconds: 5),
        (Timer t) {
          _checkTimeout();
          // relaysAutoReconnect();
        },
      );
    }
  }

  @pragma('vm:entry-point')
  void relaysAutoReconnect() {
    for (final webSocketKey in webSockets.keys) {
      if (webSockets[webSocketKey] == null) {
        connect(webSocketKey);
      }
    }
  }

  // // ignore: unused_element
  // void _stopCheckTimeOut() {
  //   if (timer != null && timer!.isActive) {
  //     timer!.cancel();
  //   }
  // }

  void _checkTimeout() {
    var now = DateTime.now().millisecondsSinceEpoch;
    Iterable<String> okMapKeys = List<String>.from(sendsMap.keys);
    for (var eventId in okMapKeys) {
      var start = sendsMap[eventId]!.sendsTime;
      if (now - start > timeout * 1000) {
        // timeout
        OKEvent ok = OKEvent(eventId, false, 'Time Out');
        if (sendsMap[eventId]!.okCallBack != null) {
          for (var relay in sendsMap[eventId]!.relays) {
            sendsMap[eventId]!.okCallBack!(ok, relay, []);
          }
          sendsMap.remove(eventId);
        }
      }
    }

    Iterable<String> requestMapKeys = List<String>.from(requestsMap.keys);
    for (var subscriptionId in requestMapKeys) {
      if (requestsMap[subscriptionId] != null) {
        var start = requestsMap[subscriptionId]!.requestTime;
        if (start > 0 && now - start > timeout * 1000) {
          // timeout
          EOSECallBack? callBack = requestsMap[subscriptionId]!.eoseCallBack;
          OKEvent ok = OKEvent(subscriptionId, false, 'Time Out');

          for (var relay in requestsMap[subscriptionId]!.relays) {
            if (callBack != null && requestsMap[subscriptionId] != null) {
              callBack(
                requestsMap[subscriptionId]!.subscriptions[relay]!,
                ok,
                relay,
                [],
              );
            }
          }
        }
      }
    }
  }

  void _setConnectStatus(String relay, int status) {
    connectStatus[relay] = status;
    connectStatusCallBack?.call(relay, status);
    for (var callBack in connectStatusListeners) {
      callBack(relay, status);
    }
  }

  void addConnectStatusListener(ConnectStatusCallBack callBack) {
    if (!connectStatusListeners.contains(callBack)) {
      connectStatusListeners.add(callBack);
    }
  }

  void removeConnectStatusListener(ConnectStatusCallBack callBack) {
    if (connectStatusListeners.contains(callBack)) {
      connectStatusListeners.remove(callBack);
    }
  }

  List<String> relays() {
    return webSockets.keys.toList();
  }

  List<String> activeRelays() {
    return webSockets.keys
        .where(
          (key) => webSockets[key] != null,
        )
        .toList();
  }

  Future connect(String relay, {bool? fromIdleState}) async {
    WebSocket? socket;

    if (fromIdleState == null) {
      if ((connectStatus[relay] == 0 && webSockets[relay] != null) ||
          connectStatus[relay] == 1 && webSockets[relay] != null) return;

      if (webSockets.containsKey(relay) && webSockets[relay] != null) {
        socket = webSockets[relay]!;
        _setConnectStatus(relay, socket.readyState);
        printLog('status =  ${connectStatus[relay]}');
        if (connectStatus[relay] != 3) {
          return;
        }
      }
    }

    closedRelays.remove(relay);
    webSockets[relay] = null;
    socket = await _connectWs(relay);

    if (socket != null) {
      socket.done.then((dynamic _) => _onDisconnected(relay));
      _listenEvent(socket, relay);
      webSockets[relay] = socket;
      printLog('$relay socket connection initialized');
      _setConnectStatus(relay, 1);
    } else {
      webSockets[relay] = socket;
    }
  }

  Future connectRelays(List<String> relays, {bool? fromIdleState}) async {
    List<String> toBeStopped = [];
    final nostrConnectRelays = this.relays();

    for (final relay in nostrConnectRelays) {
      if (!relays.contains(relay)) {
        toBeStopped.add(relay);
      }
    }

    if (toBeStopped.isNotEmpty) {
      closeConnect(toBeStopped);
    }

    Future.wait(
      relays.map((e) => connect(e, fromIdleState: fromIdleState)).toList(),
    );
  }

  // Future connectAndWaitRelays(List<String> relays,
  //     {bool? fromIdleState}) async {
  //   List<String> toBeStopped = [];
  //   final nostrConnectRelays = this.relays();

  //   for (final relay in nostrConnectRelays) {
  //     if (!relays.contains(relay)) {
  //       toBeStopped.add(relay);
  //     }
  //   }

  //   if (toBeStopped.isNotEmpty) {
  //     closeConnect(toBeStopped);
  //   }

  //   await Future.wait(
  //     relays.map((e) => connect(e, fromIdleState: fromIdleState)).toList(),
  //   );
  // }

  Future closeConnect(List<String> relays) async {
    for (final relay in relays) {
      if (webSockets.containsKey(relay)) {
        closedRelays.add(relay);
        final socket = webSockets.remove(relay);
        await socket?.close();
      }
    }
  }

  String addSubscription(
    List<Filter> filters,
    List<String> relays, {
    EventCallBack? eventCallBack,
    EOSECallBack? eoseCallBack,
  }) {
    Map<String, List<Filter>> result = {};
    final webSocketRelays = NostrConnect.sharedInstance.relays();
    for (var relay in webSocketRelays) {
      if (relays.isNotEmpty && relays.contains(relay) || relays.isEmpty) {
        if (webSockets[relay] != null) {
          result[relay] = filters;
        }
      }
    }

    return addSubscriptions(
      result,
      relays,
      eventCallBack: eventCallBack,
      eoseCallBack: eoseCallBack,
    );
  }

  String addSubscriptions(
    Map<String, List<Filter>> filters,
    List<String> relays, {
    EventCallBack? eventCallBack,
    EOSECallBack? eoseCallBack,
  }) {
    /// Create a subscription message request with one or many filters
    String requestsId = generate64RandomHexChars();
    Requests requests = Requests(
      requestsId,
      filters.keys.toList(),
      DateTime.now().millisecondsSinceEpoch,
      {},
      eventCallBack,
      eoseCallBack,
    );

    for (String relay in filters.keys) {
      Request requestWithFilter = Request(
        generate64RandomHexChars(),
        filters[relay]!,
      );

      String subscriptionString = requestWithFilter.serialize();

      /// add request to request map
      requests.subscriptions[relay] = requestWithFilter.subscriptionId;
      requestsMap[requestWithFilter.subscriptionId + relay] = requests;
      // log(subscriptionString);

      _send(subscriptionString, chosenRelays: [relay]);

      // if (relays.contains(relay) && relays.isNotEmpty || relays.isEmpty) {
      // }
    }

    return requestsId;
  }

  closeSubscriptions(String subscriptionId) {
    for (var relay in relays()) {
      if (subscriptionId.isNotEmpty) {
        _send(Close(subscriptionId).serialize(), chosenRelays: [relay]);
        requestsMap.remove(subscriptionId + relay);
        printLog('close ${subscriptionId}');
      }
    }
  }

  closeSubscription(String subscriptionId, String relay) {
    if (subscriptionId.isNotEmpty) {
      String close = Close(subscriptionId).serialize();
      _send(close, chosenRelays: [relay]);
      requestsMap.remove(subscriptionId + relay);
      printLog('close ${subscriptionId}');
    }
  }

  Future closeRequests(List<String> requestsIds) async {
    Iterable<String> requestsMapKeys = List<String>.from(requestsMap.keys);

    for (var key in requestsMapKeys) {
      var requests = requestsMap[key];

      if (requestsIds.contains(requests!.requestId)) {
        for (var relay in relays()) {
          if (requests.subscriptions[relay] != null) {
            closeSubscription(requests.subscriptions[relay]!, relay);
          }
        }

        return;
      }
    }
  }

  /// send an event to relay/relays
  void sendEvent(
    Event event,
    List<String> selectedRelays, {
    OKCallBack? sendCallBack,
  }) {
    Sends sends = Sends(
      generate64RandomHexChars(),
      selectedRelays.isNotEmpty ? selectedRelays : relays(),
      DateTime.now().millisecondsSinceEpoch,
      event.id,
      sendCallBack,
    );

    sendsMap[event.id] = sends;

    _send(
      event.serialize(),
      chosenRelays: selectedRelays.isNotEmpty ? selectedRelays : null,
    );
  }

  void _send(String data, {List<String>? chosenRelays}) {
    if (chosenRelays != null) {
      for (final relay in chosenRelays) {
        if (webSockets.containsKey(relay)) {
          var socket = webSockets[relay];
          if (connectStatus[relay] == 1 && socket != null) {
            socket.add(data);
          }
        }
      }
    } else {
      webSockets.forEach((url, socket) {
        if (connectStatus[url] == 1 && socket != null) {
          socket.add(data);
        }
      });
    }
  }

  void _handleMessage(String message, String relay) {
    try {
      var m = Message.deserialize(message);
      switch (m.type) {
        case 'EVENT':
          _handleEvent(m.message, relay);
          break;
        case 'EOSE':
          _handleEOSE(m.message, relay);
          break;
        case 'NOTICE':
          _handleNotice(m.message, relay);
          break;
        case 'OK':
          _handleOk(message, relay);
          break;
        default:
          printLog('Received message not supported: $message');
          break;
      }
    } catch (_) {
      printLog('Received message not supported: $message');
    }
  }

  void _handleEvent(Event event, String relay) {
    // printLog('Received event: ${event.serialize()}');
    String? subscriptionId = event.subscriptionId;
    if (subscriptionId != null) {
      String requestsMapKey = subscriptionId + relay;
      if (subscriptionId.isNotEmpty &&
          requestsMap.containsKey(requestsMapKey)) {
        EventCallBack? callBack = requestsMap[requestsMapKey]!.eventCallBack;
        if (callBack != null) callBack(event, relay);
      }
    }
  }

  void _handleEOSE(String eose, String relay) {
    printLog('receive EOSE: $eose in $relay');
    String subscriptionId = jsonDecode(eose)[0];
    String requestsMapKey = subscriptionId + relay;
    if (subscriptionId.isNotEmpty && requestsMap.containsKey(requestsMapKey)) {
      var relays = requestsMap[requestsMapKey]!.relays;
      relays.remove(relay);
      // all relays have EOSE
      EOSECallBack? callBack = requestsMap[requestsMapKey]!.eoseCallBack;
      OKEvent ok = OKEvent(subscriptionId, true, '');
      if (callBack != null) callBack(subscriptionId, ok, relay, relays);
    }
  }

  void _handleNotice(String notice, String relay) {
    printLog('receive notice: $notice');
    String n = jsonDecode(notice)[0];
    noticeCallBack?.call(n, relay);
  }

  void _handleOk(String message, String relay) {
    printLog('receive ok: $message');
    OKEvent? ok = Nip20.getOk(message);
    if (ok != null && sendsMap.containsKey(ok.eventId)) {
      if (sendsMap[ok.eventId]!.okCallBack != null) {
        List<String> relays = List.from(sendsMap[ok.eventId]!.relays)
          ..remove(relay);

        sendsMap[ok.eventId]!.relays = relays;
        sendsMap[ok.eventId]!.okCallBack!(ok, relay, relays);
        if (relays.isEmpty) sendsMap.remove(ok.eventId);
      }
    }
  }

  void _listenEvent(WebSocket socket, String relay) {
    socket.listen((message) {
      _handleMessage(message, relay);
    }, onDone: () {
      printLog('connect aborted');
      _setConnectStatus(relay, 3); // closed
      if (!closedRelays.contains(relay)) {
        connect(relay);
      }
    }, onError: (e) {
      printLog('Server error: $e');
      _setConnectStatus(relay, 3); // closed
      connect(relay);
    });
  }

  Future _connectWs(String relay) async {
    try {
      _setConnectStatus(relay, 0); // connecting
      return await WebSocket.connect(relay).timeout(
        Duration(seconds: 5),
      );
    } catch (e) {
      _setConnectStatus(relay, 3);
      printLog('Error! can not connect WS connectWs $e');
      // closed
      // _retryWs(relay);
      return null;
    }
  }

  // Future _retryWs(String relay) async {
  //   _setConnectStatus(relay, 3);
  //   Logger().i('message');
  //   await Future.delayed(const Duration(seconds: 10));
  //   return await _connectWs(relay);
  // }

  Future<void> _onDisconnected(String relay) async {
    printLog('_onDisconnected');
    _setConnectStatus(relay, 3);
    if (!closedRelays.contains(relay)) {
      await Future.delayed(const Duration(milliseconds: 1000));
      connect(relay);
    }
  }

  void printLog(String log) {
    if (kDebugMode) {
      print(log);
    }
  }
}
