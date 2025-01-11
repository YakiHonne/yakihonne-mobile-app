import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:yakihonne/utils/utils.dart';

class BotToastUtils {
  static int toastDuration = 3;

  static showUnreachableRelaysError() {
    BotToast.showText(
      text: "Relays couldn't be reached",
      contentColor: kRed,
      textStyle: TextStyle(
        color: kWhite,
        fontSize: 12,
      ),
    );
  }

  static showError(String message) {
    BotToast.showText(
      duration: Duration(seconds: toastDuration),
      text: message,
      contentColor: kRed,
      textStyle: TextStyle(
        color: kWhite,
        fontSize: 12,
      ),
    );
  }

  static showInformation(String message) {
    BotToast.showText(
      duration: Duration(seconds: toastDuration),
      text: message,
      contentColor: kBlue,
      textStyle: TextStyle(
        color: kWhite,
        fontSize: 12,
      ),
    );
  }

  static showSuccess(String message) {
    BotToast.showText(
      text: message,
      duration: Duration(seconds: toastDuration),
      contentColor: kGreen,
      textStyle: TextStyle(
        color: kWhite,
        fontSize: 12,
      ),
    );
  }

  static showWarning(String message) {
    BotToast.showText(
      text: message,
      duration: Duration(seconds: toastDuration),
      contentColor: kOrange,
      textStyle: TextStyle(
        color: kWhite,
        fontSize: 12,
      ),
    );
  }
}
