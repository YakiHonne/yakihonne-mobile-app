import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

class LightningUtil {
  static Future<void> goToPay(
    String invoiceCode,
    String specifiedWallet,
  ) async {
    var link = specifiedWallet + invoiceCode;
    if (Platform.isAndroid) {
      AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: link,
      );
      await intent.launch();
    } else if (Platform.isIOS) {
      var url = Uri.parse(link);

      await launchUrl(url);
    }
  }
}
