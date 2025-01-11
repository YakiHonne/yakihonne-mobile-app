import 'dart:math';

import 'package:flutter/material.dart';

extension StringExtension on String {
  String nineCharacters() {
    return this.length >= 10 ? this.substring(0, 9) : this;
  }

  String capitalize() {
    return this.isNotEmpty
        ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}'
        : '';
  }

  String removeFirstCharacter() {
    return this.isNotEmpty ? '${substring(1)}' : '';
  }

  String lowerize() {
    return this.isNotEmpty ? '${this[0].toLowerCase()}${substring(1)}' : '';
  }

  String hexToAscii() {
    return List.generate(
      this.length ~/ 2,
      (i) => String.fromCharCode(
          int.parse(this.substring(i * 2, (i * 2) + 2), radix: 16)),
    ).join();
  }

  String removeLastBackSlashes() {
    if (this.isEmpty) {
      return this;
    }

    List<String> result = this.characters.toList();

    for (int i = this.length - 1; i >= 0; i--) {
      if (result[i] == '/') {
        result.removeAt(i);
      } else {
        return result.join();
      }
    }

    return result.join();
  }

  double getAspectRatio() {
    List<String> parts = this.split(RegExp(r'[:/]'));

    if (parts.length == 2) {
      int width = int.parse(parts[0]);
      int height = int.parse(parts[1]);

      return width / height;
    } else {
      return 1;
    }
  }
}

extension colorExtension on Color {
  String toHex() {
    final res =
        '#${this.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    return res.replaceFirst('FF', '');
  }
}

extension integersParsing on int {
  String formattedSeconds() {
    int sec = this % 60;
    int min = (this / 60).floor();
    String minute = min.toString().length <= 1 ? '0$min' : '$min';
    String second = sec.toString().length <= 1 ? '0$sec' : '$sec';
    return '$minute : $second';
  }
}

extension LowerCaseList on List<String> {
  void toLowerCase() {
    for (int i = 0; i < length; i++) {
      this[i] = this[i].toLowerCase();
    }
  }

  List<String> toLowerCaseTrim() {
    for (int i = 0; i < length; i++) {
      this[i] = this[i].toLowerCase();
      this[i].trim();
    }

    return this;
  }
}

extension UppderCaseList on List<String> {
  void toUpperCase() {
    for (int i = 0; i < length; i++) {
      this[i] = this[i].capitalize();
    }
  }
}

extension DurationExtensions on Duration {
  num toYearsMonthsDaysString() {
    final months = (inDays ~/ 365) ~/ 30;

    return months;
  }
}

extension DateTimeExtensions on DateTime {
  int toSecondsSinceEpoch() {
    return this.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
  }

  bool isSameDate(DateTime other) {
    return day == other.day && year == other.year && month == other.month;
  }

  bool differenceInHours(DateTime other) {
    return this.difference(other).inMinutes > 180;
  }

  DateTime basicDate() {
    return DateTime(year, month, day);
  }

  String toHourMinutes() {
    final totalSeconds = this.hour * 3600 + this.minute * 60;
    return durationToString(totalSeconds);
  }
}

String durationToString(int seconds) {
  var d = Duration(seconds: seconds);
  List<String> parts = d.toString().split(':');
  return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
}

extension GetByKeyIndex on Map {
  elementAt(int index) => this.values.elementAt(index);
}

Random _random = Random();

String randomHexString(int length) {
  StringBuffer sb = StringBuffer();
  for (var i = 0; i < length; i++) {
    sb.write(_random.nextInt(16).toRadixString(16));
  }
  return sb.toString();
}

final relayRegExp = RegExp(
  r'^(wss?:\/\/)([0-9]{1,3}(?:\.[0-9]{1,3}){3}|[^:]+):?([0-9]{1,5})?$',
);

final hashtagsRegExp = RegExp(r'\B#\w\w+');

final urlRegExp = RegExp(
  r'((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?',
);

final youtubeRegExp = RegExp(
  r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:watch\?v=|embed\/|v\/|shorts\/|playlist\?list=)|youtu\.be\/)([\w-]{11,})',
);

final discordRegExp = RegExp(
  r'(?:https?:\/\/)?(?:www\.)?(?:discord\.gg\/|discord(?:app)?\.com\/invite\/)([\w-]+)',
);

final telegramRegExp = RegExp(
  r'(?:https?:\/\/)?(?:www\.)?(?:t\.me\/|telegram\.me\/)([\w-]+)',
);

final xRegExp = RegExp(
  r'(?:https?:\/\/)?(?:www\.)?(?:x\.com|twitter\.com)\/(?:#!\/)?(\w+)(?:\/status\/(\d+))?',
);

final emailRegExp = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

final hexRegExp = RegExp(
  r'^#[0-9a-fA-F]{6}',
);
