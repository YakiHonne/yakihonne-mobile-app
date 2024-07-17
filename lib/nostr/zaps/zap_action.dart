import 'package:bot_toast/bot_toast.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/user_status_model.dart';
import 'package:yakihonne/utils/string_utils.dart';

import '../../utils/lightning_util.dart';
import 'zap.dart';

class ZapAction {
  static Future<void> handleZap(
    num sats,
    UserModel user,
    UserStatusModel userStatusModel,
    List<String> relays, {
    String? eventId,
    String? aTag,
    String? pollOption,
    String? comment,
    String? specifiedWallet,
    required Function(String) onZapped,
  }) async {
    // var cancelFunc = BotToast.showLoading();
    String invoice = '';
    try {
      var invoiceCode = await _doGenInvoiceCode(
        sats,
        user,
        userStatusModel,
        relays,
        eventId: eventId,
        pollOption: pollOption,
        comment: comment,
      );

      if (StringUtil.isBlank(invoiceCode)) {
        BotToast.showText(text: 'Error');
        return;
      }

      invoice = invoiceCode!;

      bool sendWithWallet = false;

      // if (nwcProvider.isConnected) {
      //   int? balance = nwcProvider.getBalance;
      //   if (balance != null && balance > 10) {
      //     await nwcProvider.payInvoice(invoiceCode!, eventId, onZapped);
      //     sendWithWallet = true;
      //   }
      // }

      if (!sendWithWallet) {
        await LightningUtil.goToPay(invoiceCode, specifiedWallet!);
      }
    } finally {
      onZapped(invoice);
      // cancelFunc.call();
    }
  }

  static Future<void> handleExternalZap(
    String? invoiceCode, {
    String? specifiedWallet,
  }) async {
    if (StringUtil.isBlank(invoiceCode)) {
      BotToast.showText(text: 'Error');
      return;
    }

    bool sendWithWallet = false;

    if (!sendWithWallet) {
      await LightningUtil.goToPay(invoiceCode!, specifiedWallet!);
    }
  }

  static Future<String?> genInvoiceCode(
    num sats,
    UserModel user,
    UserStatusModel userStatusModel,
    List<String> relays, {
    String? eventId,
    String? aTag,
    String? pollOption,
    String? comment,
  }) async {
    // var cancelFunc = BotToast.showLoading();
    try {
      return await _doGenInvoiceCode(
        sats,
        user,
        userStatusModel,
        relays,
        eventId: eventId,
        aTag: aTag,
        pollOption: pollOption,
        comment: comment,
      );
    } finally {
      // cancelFunc.call();
    }
  }

  static Future<String?> _doGenInvoiceCode(
    num sats,
    UserModel user,
    UserStatusModel userStatusModel,
    List<String> relays, {
    String? eventId,
    String? aTag,
    String? pollOption,
    String? comment,
  }) async {
    // lud06 like: LNURL1DP68GURN8GHJ7MRW9E6XJURN9UH8WETVDSKKKMN0WAHZ7MRWW4EXCUP0XPURJCEKXVERVDEJXCMKYDFHV43KX2HK8GT
    // lud16 like: pavol@rusnak.io
    // but some people set lud16 to lud06

    String? lnurl = user.lud06;
    String? lud16Link;

    if (StringUtil.isBlank(lnurl) || !lnurl.toLowerCase().startsWith('lnurl')) {
      if (StringUtil.isNotBlank(user.lud16)) {
        lnurl = Zap.getLnurlFromLud16(user.lud16);
      } else {
        lnurl = '';
      }
    }

    if (StringUtil.isBlank(lnurl)) {
      BotToast.showText(text: 'Lnurl not found');
      return null;
    }

    if (lnurl!.contains('@')) {
      lnurl = Zap.getLnurlFromLud16(user.lud06);
    }

    if (StringUtil.isBlank(lud16Link)) {
      if (StringUtil.isNotBlank(user.lud16)) {
        lud16Link = Zap.getLud16LinkFromLud16(user.lud16);
      }
    }

    if (StringUtil.isBlank(lud16Link)) {
      if (StringUtil.isNotBlank(lnurl)) {
        lud16Link = Zap.decodeLud06Link(lnurl!);
      }
    }

    return await Zap.getInvoiceCode(
      lnurl: lnurl!,
      lud16Link: lud16Link!,
      sats: sats,
      recipientPubkey: user.pubKey,
      relays: relays,
      currentPrivkey: userStatusModel.privKey,
      currentPubkey: userStatusModel.pubKey,
      eventId: eventId,
      aTag: aTag,
      pollOption: pollOption,
      comment: comment,
    );
  }
}
