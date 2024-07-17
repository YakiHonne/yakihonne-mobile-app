import 'dart:convert';

import 'package:bech32/bech32.dart';
import 'package:dio/dio.dart';
import 'package:yakihonne/nostr/lnurl_response.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/static_properties.dart';
import 'package:yakihonne/utils/string_utils.dart';

class Nip57 {
  static String decodeLud06Link(String lud06) {
    var decoder = Bech32Decoder();
    var bech32Result = decoder.convert(lud06, 2000);
    var data = convertBits(bech32Result.data, 5, 8, false);
    return utf8.decode(data);
  }

  static String? getLud16LinkFromLud16(String lud16) {
    var strs = lud16.split('@');
    if (strs.length < 2) {
      return null;
    }

    var username = strs[0];
    var domainname = strs[1];

    return 'https://$domainname/.well-known/lnurlp/$username';
  }

  static String? getLnurlFromLud16(String lud16) {
    var link = getLud16LinkFromLud16(lud16);
    List<int> data = utf8.encode(link!);
    data = convertBits(data, 8, 5, true);

    var encoder = Bech32Encoder();
    Bech32 input = Bech32('lnurl', data);
    var lnurl = encoder.convert(input, 2000);

    return lnurl.toUpperCase();
  }

  static Future<LnurlResponse?> getLnurlResponse(String link) async {
    var responseMap = await Dio().get(link) as Map<String, dynamic>;
    if (StringUtil.isNotBlank(responseMap['callback'])) {
      return LnurlResponse.fromJson(responseMap);
    }

    return null;
  }

  static ZapReceipt getZapReceipt(Event event) {
    if (event.kind == EventKind.ZAP) {
      String? bolt11, preimage, description, recipient, eventId;
      for (var tag in event.tags) {
        if (tag[0] == 'bolt11') bolt11 = tag[1];
        if (tag[0] == 'preimage') preimage = tag[1];
        if (tag[0] == 'description') description = tag[1];
        if (tag[0] == 'p') recipient = tag[1];
        if (tag[0] == 'e') eventId = tag[1];
      }

      ZapReceipt zapReceipt = ZapReceipt(
        event.createdAt,
        event.pubkey,
        bolt11 ?? '',
        preimage ?? '',
        description ?? '',
        recipient ?? '',
        eventId,
      );

      return zapReceipt;
    } else {
      throw Exception('${event.kind} is not nip57 compatible');
    }
  }

  static Event zapRequest(
    List<String> relays,
    String amount,
    String lnurl,
    String recipient,
    String privkey, {
    String? eventId,
    String? coordinate,
    String? content,
  }) {
    List<String> r = ['relays'];
    r.addAll(relays);
    List<List<String>> tags = [
      r,
      ['amount', amount],
      ['lnurl', lnurl],
      ['p', recipient]
    ];
    if (eventId != null) {
      tags.add(['e', eventId]);
    }
    if (coordinate != null) {
      tags.add(['a', coordinate]);
    }

    return Event.from(
      kind: 9734,
      tags: tags,
      content: content ?? '',
      privkey: privkey,
    );
  }
}

class ZapReceipt {
  int paidAt;
  String pubkey;
  String bolt11;
  String preimage;
  String description;
  String recipient;
  String? eventId;

  ZapReceipt(
    this.paidAt,
    this.pubkey,
    this.bolt11,
    this.preimage,
    this.description,
    this.recipient,
    this.eventId,
  );
}
