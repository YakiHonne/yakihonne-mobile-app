import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:yakihonne/utils/utils.dart';

// ** App version
const String appVersion = 'YakiHonne v1.3.4+78';

//** network
const uploadUrl = 'api/v1/file-upload';
const baseUrl = 'https://yakihonne.com/';
const cacheUrl = 'https://cache-v2.yakihonne.com/api/v1/';
const pointsUrl = 'https://www.yakihonne.com/api/v1/';
const nostrBandURl = 'https://api.nostr.band/v0/';
const relaysUrl = 'https://api.nostr.watch/v1/online';
const searchUrl = 'https://api.nostr.band/nostr?method=search&count=10&q=';
const topicsUrl = 'https://yakihonne.com/api/v1/yakihonne-topics';
const pointsSystemUrl = 'https://www.yakihonne.com/points-system';

final lg = Logger(printer: PrettyPrinter());

//** Colors
const kBlack = Colors.black;
const kWhite = Colors.white;
const kTransparent = Colors.transparent;

const kPurple = Color(0xFF86318C);
const kLightPurple = Colors.purpleAccent;
const kDarkGrey = Color(0xff1C1B1F);
const kDimBgGrey = Color(0xff252429);
const kDimGrey2 = Color(0xff343434);
const kLightBgGrey = Color(0xfff7f7f7);
const kDimGrey = Color(0xffB3B3B3);
const kPaleGrey = Color(0xffE5E5E5);
const kLightGrey = Color(0xffF2F2F2);
const kDimPurple = Color(0xff220038);
const kRed = Color(0xffFF4A4A);
const kRedSide = Color(0xfffff6f6);
const kYellow = Color(0xffFFE604);
const kGreen = Color(0xff00C04D);
const kGreenSide = Color(0xffF2FDF6);
const kBlue = Color(0xff504DFF);
const kBlueSide = Color(0xffF6F6FF);
const kOrange = Color(0xffFF9C08);
const kOrangeContrasted = Color(0xffEE7700);
const kOrangeSide = Color(0xffFFFAF3);

const kElPerPage = 20;
const kElPerPage2 = 10;

//**  paddings
const kDefaultPadding = 20.0;

//** containers
final containerBorder = OutlineInputBorder(
  borderSide: BorderSide(
    color: kDimGrey,
    width: 0.5,
  ),
  borderRadius: BorderRadius.circular(
    kDefaultPadding / 1.5,
  ),
);

//** cacheManager
final cacheManager = CacheManager(
  Config(
    'yakihonneCacheKey',
    stalePeriod: const Duration(days: 3),
    //one week cache period
  ),
);

//** date format
final dateFormat = DateFormat('dd/MM/yyyy');
final dateFormat2 = DateFormat('MMM dd, yyyy');
final dateFormat3 = DateFormat('MMM dd yyyy, h:mma');
final dateFormat4 = DateFormat('MMM dd, yyyy HH:mm');
final dateformat5 = DateFormat('MMM y');
final dateFormat6 = DateFormat('MMM dd');
final dateFormat7 = DateFormat('HH:mm');

// ** events constants
const bookmarkTag = 'bookmark';
const yakihonneTopicTag = 'MyFavoriteTopicsInYakihonne';
const yakihonneArticlesBookmarksTag = "YakiHonne's articles";
const yakihonneCurationsBookmarksTag = "YakiHonne's curation";
const yakihonneFlashNewsBookmarksTag = "YakiHonne's flash news";

const yakihonneHex =
    '20986fb83e775d96d188ca5c9df10ce6d613e0eb7e5768a0f0b12b37cdac21b3';

const readers =
    'Readers shared extra details they thought people might find relevant.';

const albyRedirectUri = 'https://yakihonne.com/wallet/alby';

const timerTicks = 10;
const FN_MAX_LENGTH = 1000;
const INIT_RATING_REWARD = 21;
const INIT_UN_REWARD = 21;
const FINAL_SEALED_REWARD = 100;

const lorem =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';

final fieldValidator = MultiValidator(
  [
    RequiredValidator(
      errorText: 'Requierd field',
    ),
  ],
);

const randomCovers = [
  RandomCovers.randomCover1,
  RandomCovers.randomCover2,
  RandomCovers.randomCover3,
  RandomCovers.randomCover4,
  RandomCovers.randomCover5,
  RandomCovers.randomCover6,
  RandomCovers.randomCover7,
  RandomCovers.randomCover8,
  RandomCovers.randomCover9,
  RandomCovers.randomCover10,
];

String getRandomPlaceholder({
  required String input,
  required bool isPfp,
}) {
  String inputToBeHashed = input;

  if (inputToBeHashed.isEmpty) {
    inputToBeHashed = 'default';
  }

  int hash = 0;

  for (int i = 0; i < inputToBeHashed.length; i++) {
    hash = (hash * 31) + inputToBeHashed.codeUnitAt(i);
  }

  // Ensure the hash is non-negative
  hash = hash.abs();
  int oneDigitNumber = hash % 10;

  return isPfp ? randomPfps[oneDigitNumber] : randomCovers[oneDigitNumber];
}

const randomPfps = [
  RandomPfps.randomPfp1,
  RandomPfps.randomPfp2,
  RandomPfps.randomPfp3,
  RandomPfps.randomPfp4,
  RandomPfps.randomPfp5,
  RandomPfps.randomPfp6,
  RandomPfps.randomPfp7,
  RandomPfps.randomPfp8,
  RandomPfps.randomPfp9,
  RandomPfps.randomPfp10,
];

const profileImages = [
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_0.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_1.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_3.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_4.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_5.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_6.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_7.png',
  'https://yakihonne.s3.ap-east-1.amazonaws.com/profilePicPlaceholder/grid_8.png',
];

const helpfulRatingPoints = [
  'Cites high-quality sources',
  'Easy to understand',
  "Directly addresses the post's claim",
  'Provides important context',
  'Other',
];

const notHelpfulRatingPoints = [
  'Sources not included or unreliable',
  'Sources do not support note',
  'Incorrect information',
  'Opinion or speculation',
  'Typos or unclear language',
  'Misses key points or irrelevant',
  'Argumentative or biased language',
  'Harassment or abuse',
  'Other',
];

const bookmarksTypes = [
  'All',
  'Articles',
  'Curations',
  'Flash news',
  'Notes',
  'Videos',
  'Buzz feed'
];

const mandatoryRelays = [
  'wss://nostr-01.yakihonne.com',
  'wss://nostr-02.yakihonne.com',
  'wss://nostr-03.dorafactory.org',
];

const constantRelays = [
  'wss://nostr-01.yakihonne.com',
  'wss://nostr-02.yakihonne.com',
  'wss://nostr-03.dorafactory.org',
  'wss://nostr-02.dorafactory.org',
  'wss://relay.damus.io',
];

const wallets = {
  '': {
    'name': 'Select wallet',
    'icon': WalletsLogos.local,
  },
  'bluewallet': {
    'name': 'Blue Wallet',
    'icon': WalletsLogos.bluetwallet,
    'deeplink': 'bluewallet:lightning:',
  },
  'satoshi': {
    'name': 'Wallet of Satoshi',
    'icon': WalletsLogos.satoshi,
    'deeplink': 'walletofsatoshi:',
  },
  'muun': {
    'name': 'Muun',
    'icon': WalletsLogos.muun,
    'deeplink': 'muun:',
  },
  'breez': {
    'name': 'Breez',
    'icon': WalletsLogos.breez,
    'deeplink': 'breez:lightning:',
  },
  'zebedee': {
    'name': 'Zebedee',
    'icon': WalletsLogos.zebedee,
    'deeplink': 'zbd:lightning:',
  },
  'zeusln': {
    'name': 'Zeus LN',
    'icon': WalletsLogos.zeusln,
    'deeplink': 'zeusln:',
  },
};

const defaultZaps = {
  '0': {
    'value': '20',
    'icon': ReactionsIcons.reaction1,
  },
  '1': {
    'value': '100',
    'icon': ReactionsIcons.reaction2,
  },
  '2': {
    'value': '500',
    'icon': ReactionsIcons.reaction3,
  },
  '3': {
    'value': '1000',
    'icon': ReactionsIcons.reaction4,
  },
  '4': {
    'value': '5000',
    'icon': ReactionsIcons.reaction5,
  },
  '5': {
    'value': '10000',
    'icon': ReactionsIcons.reaction6,
  },
  '6': {
    'value': '50000',
    'icon': ReactionsIcons.reaction7,
  },
  '7': {
    'value': '100000',
    'icon': ReactionsIcons.reaction8,
  },
};

const aspectRatios = ['16:9', '1:1'];

const eulaContent = {
  'Prohibited Content and Activities': {
    'Prohibited Content':
        'Users are strictly prohibited from uploading, sharing, or promoting content that is illegal, offensive, discriminatory, or violates the rights of others, including intellectual property rights.',
    'Security Compromise':
        'Users shall not engage in activities that compromise the security of the App, its users, or any associated networks.',
    'Spamming':
        'The App prohibits spamming activities, including but not limited to unsolicited messages, advertisements, or any form of intrusive communication.',
  },
  'Misrepresentation and Illegal Activities': {
    'Misrepresentation':
        'Users shall not engage in any form of misrepresentation, impersonation, or fraudulent activities within the App.',
    'Illegal Activities':
        'The App must not be used for any illegal activities, and users are responsible for complying with all applicable laws and regulations.',
  },
  'User Content Responsibility': {
    'User Content':
        'Users are solely responsible for the content they upload, share, or distribute through the App. YakiHonne disclaims any liability for user-generated content.',
    'Moderation':
        'YakiHonne reserves the right to moderate, remove, or disable content that violates this EULA or is deemed inappropriate without prior notice.',
  },
  'Intellectual Property': {
    'Ownership':
        "YakiHonne retains all rights, title, and interest in and to the App, including its intellectual property. This EULA does not grant users any rights to use YakiHonne's trade names, trademarks, service marks, logos, domain names, or other distinctive brand features."
  },
  'Governing Law': {
    'Applicable Law':
        'This EULA is governed by and construed in accordance with the laws of Singapore, without regard to its conflict of law principles.',
  },
  'Disclaimer of Warranty': {
    'As-Is Basis':
        'The App is provided "as is" without any warranty, express or implied, including but not limited to the implied warranties of fitness for a particular purpose, or non-infringement.',
    'No Warranty of Security':
        'YakiHonne does not warrant that the App will be error-free or uninterrupted, and YakiHonne does not make any warranty regarding the quality, accuracy, reliability, or suitability of our app for any particular purpose.',
  },
};
