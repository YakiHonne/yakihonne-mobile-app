import 'dart:convert';

import 'package:yakihonne/nostr/close.dart';
import 'package:yakihonne/nostr/event.dart';
import 'package:yakihonne/nostr/request.dart';

// Used to deserialize any kind of message that a nostr client or relay can transmit.
class Message {
  late String type;
  late dynamic message;

// nostr message deserializer
  Message.deserialize(String payload) {
    dynamic data = jsonDecode(payload);
    var messages = ['EVENT', 'REQ', 'CLOSE', 'NOTICE', 'EOSE', 'OK', 'AUTH'];
    assert(messages.contains(data[0]), 'Unsupported payload (or NIP)');

    type = data[0];
    switch (type) {
      case 'EVENT':
        message = Event.deserialize(data);
        break;
      case 'REQ':
        message = Request.deserialize(data);
        break;
      case 'CLOSE':
        message = Close.deserialize(data);
        break;
      default:
        message = jsonEncode(data.sublist(1));
        break;
    }
  }
}
