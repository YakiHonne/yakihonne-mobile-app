import 'dart:convert';
import 'dart:developer';

import 'package:bech32/bech32.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';

import '../nostr.dart';
import 'lnurl_response.dart';

class Zap {
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
    if (StringUtil.isBlank(lud16)) {
      return null;
    } else {
      try {
        var link = getLud16LinkFromLud16(lud16);
        List<int> data = utf8.encode(link!);
        data = convertBits(data, 8, 5, true);

        var encoder = Bech32Encoder();
        Bech32 input = Bech32('lnurl', data);
        var lnurl = encoder.convert(input, 2000);

        return lnurl.toUpperCase();
      } catch (_) {
        return null;
      }
    }
  }

  static Future<LnurlResponse?> getLnurlResponse(String link) async {
    try {
      var responseMap = await HttpFunctionsRepository.get(link);

      if (responseMap != null &&
          StringUtil.isNotBlank(responseMap['callback'])) {
        return LnurlResponse.fromJson(responseMap);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getInvoiceCode({
    required String lnurl,
    required String lud16Link,
    required num sats,
    required String recipientPubkey,
    String? eventId,
    String? aTag,
    required currentPubkey,
    required currentPrivkey,
    required List<String> relays,
    String? pollOption,
    String? comment,
  }) async {
    var lnurlResponse = await getLnurlResponse(lud16Link);

    if (lnurlResponse == null) {
      return null;
    }

    var callback = lnurlResponse.callback!;
    if (callback.contains('?')) {
      callback += '&';
    } else {
      callback += '?';
    }

    var amount = sats * 1000;
    callback += 'amount=$amount';

    String eventContent = '';

    if (StringUtil.isNotBlank(comment)) {
      var commentNum = lnurlResponse.commentAllowed;
      if (commentNum != null) {
        if (commentNum < comment!.length) {
          comment = comment.substring(0, commentNum);
        }
        callback += '&comment=${Uri.encodeQueryComponent(comment)}';
        eventContent = comment;
      }
    }

    var tags = [
      ['relays', ...relays],
      ['amount', amount.toString()],
      ['lnurl', lnurl],
      ['p', recipientPubkey],
    ];

    if (StringUtil.isNotBlank(eventId)) {
      tags.add(['e', eventId!]);
    }

    if (StringUtil.isNotBlank(aTag)) {
      tags.add(['a', aTag!]);
    }

    if (StringUtil.isNotBlank(pollOption)) {
      tags.add(['poll_option', pollOption!]);
    }

    var event = Event.from(
      kind: EventKind.ZAP_REQUEST,
      tags: tags,
      content: eventContent,
      privkey: currentPrivkey,
    );

    var eventStr = Uri.encodeQueryComponent(jsonEncode(event));
    callback += '&nostr=$eventStr';
    callback += '&lnurl=$lnurl';

    log('getInvoice callback $callback');

    Map<String, dynamic>? responseMap =
        await HttpFunctionsRepository.get(callback);

    if (responseMap != null && StringUtil.isNotBlank(responseMap['pr'])) {
      return responseMap['pr'];
    }

    return null;
  }
}
