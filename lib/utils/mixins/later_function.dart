import 'dart:async';

import 'package:yakihonne/nostr/event.dart';

mixin LaterFunction {
  int laterTimeMS = 300;

  bool latering = false;

  // bool _running = true;

  Timer? timer;

  void later(Function func, Function? completeFunc) {
    timer?.cancel();

    timer = Timer(Duration(milliseconds: laterTimeMS), () {
      func();

      if (completeFunc != null) {
        completeFunc();
      }
    });
  }

  void disposeLater() {
    // _running = false;
  }
}

mixin PendingEventsLaterFunction {
  int laterTimeMS = 200;

  bool latering = false;

  List<Event> pendingEvents = [];

  bool _running = true;

  void later(
    Event event,
    Function(List<Event>) func,
    Function? completeFunc,
  ) {
    pendingEvents.add(event);
    if (latering) {
      return;
    }

    latering = true;
    Future.delayed(Duration(milliseconds: laterTimeMS), () {
      if (!_running) {
        return;
      }

      latering = false;
      func(pendingEvents);
      pendingEvents.clear();
      if (completeFunc != null) {
        completeFunc();
      }
    });
  }

  void disposeLater() {
    _running = false;
  }
}
