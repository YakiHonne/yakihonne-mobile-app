import 'package:bot_toast/bot_toast.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/user_status_model.dart';
import 'package:yakihonne/utils/botToast_util.dart';
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
    bool? removeNostrEvent,
    List<List<String>>? extraTags,
    required Function(String) onZapped,
  }) async {
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
        removeNostrEvent: removeNostrEvent,
        aTag: aTag,
      );

      if (StringUtil.isBlank(invoiceCode)) {
        BotToast.showText(text: 'Error');
        return;
      }

      invoice = invoiceCode!;

      bool sendWithWallet = false;

      if (!sendWithWallet) {
        await LightningUtil.goToPay(invoiceCode, specifiedWallet!);
      }
    } finally {
      onZapped(invoice);
    }
  }

  static Future<void> handleExternalZap(
    String? invoiceCode, {
    String? specifiedWallet,
  }) async {
    if (StringUtil.isBlank(invoiceCode)) {
      BotToastUtils.showError('Empty invoice');
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
    bool? removeNostrEvent,
    List<List<String>>? extraTags,
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
        removeNostrEvent: removeNostrEvent,
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
    bool? removeNostrEvent,
  }) async {
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
      removeNostrEvent: removeNostrEvent,
    );
  }
}
