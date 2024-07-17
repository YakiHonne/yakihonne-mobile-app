import 'dart:convert';

import 'package:yakihonne/nostr/message.dart';

class Nip20 {
  static OKEvent? getOk(String okPayload) {
    var ok = Message.deserialize(okPayload);
    if (ok.type == 'OK') {
      var object = jsonDecode(ok.message);
      return OKEvent(object[0], object[1], object[2]);
    }
    return null;
  }
}

class OKEvent {
  String eventId;
  bool status;
  String message;

  OKEvent(this.eventId, this.status, this.message);
}
