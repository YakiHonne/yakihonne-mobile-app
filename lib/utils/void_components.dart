// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:aescryptojs/aescryptojs.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_url_validator/video_url_validator.dart';
import 'package:yakihonne/blocs/app_clients_cubit/app_clients_cubit.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/dms_cubit/dms_cubit.dart';
import 'package:yakihonne/blocs/lightning_zaps_cubit/lightning_zaps_cubit.dart';
import 'package:yakihonne/blocs/notes_events_cubit/notes_events_cubit.dart';
import 'package:yakihonne/blocs/notifications_cubit/notifications_cubit.dart';
import 'package:yakihonne/blocs/points_management_cubit/points_management_cubit.dart';
import 'package:yakihonne/blocs/relays_progress_cubit/relays_progress_cubit.dart';
import 'package:yakihonne/blocs/single_event_cubit/single_event_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/database/cache_manager_db.dart';
import 'package:yakihonne/firebase_options.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/bookmark_list_model.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/spider_util.dart';
import 'package:yakihonne/utils/string_inlineSpan.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/article_view/article_view.dart';
import 'package:yakihonne/views/curation_view/curation_view.dart';
import 'package:yakihonne/views/note_view/note_view.dart';
import 'package:yakihonne/views/profile_view/profile_view.dart';
import 'package:yakihonne/views/profile_view/widgets/profile_fast_access.dart';
import 'package:yakihonne/views/smart_widget_display/smart_widget_display.dart';
import 'package:yakihonne/views/tag_view/tag_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/vertical_video_view.dart';
import 'package:yakihonne/views/widgets/modal_with_blur.dart';
import 'package:yakihonne/views/widgets/scroll_to_top.dart';

Future<void> iniApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  loadCubits();

  await Future.wait([
    dotenv.load(fileName: '.env'),
    initDatabaseInstance(),
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    )
  ]);

  notificationsCubit.loadNotifications();

  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );

  final isAnalyticsEnabled =
      localDatabaseRepository.getAnalyticsDataCollection();

  FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(isAnalyticsEnabled);
  FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(isAnalyticsEnabled);

  if (isAnalyticsEnabled && !kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordFlutterFatalError;
      return true;
    };
  }

  initNotifications();
  onStart();
  // Bloc.observer = MyBlocObserver();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

void loadCubits() async {
  localDatabaseRepository = LocalDatabaseRepository();
  nostrRepository =
      NostrDataRepository(localDatabaseRepository: localDatabaseRepository);
  authorsCubit = AuthorsCubit();
  appClientsCubit = AppClientsCubit(
    nostrRepository: nostrRepository,
  );
  themeCubit = ThemeCubit(localDatabaseRepository: localDatabaseRepository)
    ..initTheme();
  singleEventCubit = SingleEventCubit();
  notesEventsCubit = NotesEventsCubit();
  notificationsCubit = NotificationsCubit();
  dmsCubit = DmsCubit();
  lightningZapsCubit = LightningZapsCubit(
    nostrRepository: nostrRepository,
    localDatabaseRepository: localDatabaseRepository,
  );
  pointsManagementCubit = PointsManagementCubit();
  relaysProgressCubit = RelaysProgressCubit();
}

Future<void> initDatabaseInstance() async {
  await CacheManagerDB.initialize();
  await CacheManagerDB.fetchMetadata();
}

@pragma('vm:entry-point')
void onStart() async {
  Timer.periodic(
    const Duration(seconds: 5),
    (Timer t) {
      NostrConnect.sharedInstance.relaysAutoReconnect();
    },
  );
}

void initNotifications() {
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) async {
    if (!isAllowed &&
        localDatabaseRepository.getNotificationPrompter() == null) {
      await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [
          NotificationPermission.Vibration,
          NotificationPermission.Badge,
          NotificationPermission.Light,
          NotificationPermission.Sound,
          NotificationPermission.PreciseAlarms,
        ],
      );
    }
  });

  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelGroupKey: 'YakiHonne',
        channelKey: 'YakiHonne',
        channelShowBadge: true,
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
      ),
    ],
  );

  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationsCubit.onActionReceivedMethod,
  );
}

Future<void> onScrollsToTop(
  ScrollsToTopEvent event,
  ScrollController controller,
) async {
  controller.animateTo(
    0,
    duration: const Duration(milliseconds: 1000),
    curve: Curves.easeOut,
  );
}

List<String> getBookmarkIds(
  Map<String, BookmarkListModel> bookmarks,
) {
  final bookmarksList = <String>{};

  bookmarks.values.forEach(
    (bookmarkList) {
      bookmarksList.addAll(
        bookmarkList.bookmarkedReplaceableEvents.map((e) => e.identifier),
      );
      bookmarksList.addAll(
        bookmarkList.bookmarkedEvents,
      );
    },
  );

  return bookmarksList.toSet().toList();
}

List<String> getLoadingBookmarkIds(
  Map<String, Set<String>> bookmarks,
) {
  final bookmarksList = <String>{};

  bookmarks.values.forEach((bookmarkList) {
    bookmarksList.addAll(
      bookmarkList,
    );
  });

  return bookmarksList.toSet().toList();
}

List<String> getZapPubkey(List<List<String>> tags) {
  String? zapRequestEventStr;
  String senderPubkey = '';
  String content = '';

  for (var tag in tags) {
    if (tag.length > 1) {
      var key = tag[0];
      if (key == 'description') {
        zapRequestEventStr = tag[1];
      }
    }
  }

  if (StringUtil.isNotBlank(zapRequestEventStr)) {
    try {
      var eventJson = jsonDecode(zapRequestEventStr!);
      var zapRequestEvent = Event.fromJson(eventJson);
      senderPubkey = zapRequestEvent.pubkey;
      content = zapRequestEvent.content;
    } catch (e) {
      senderPubkey =
          SpiderUtil.subUntil(zapRequestEventStr!, 'pubkey\":\"', '\"');
    }
  }

  return [senderPubkey, content];
}

Map<String, dynamic> getZapByPollStats(Event event) {
  String? zapRequestEventStr;
  final map = <String, dynamic>{};

  for (var tag in event.tags) {
    if (tag.length > 1) {
      var key = tag[0];
      if (key == 'description') {
        zapRequestEventStr = tag[1];
      }
    }
  }

  if (StringUtil.isNotBlank(zapRequestEventStr)) {
    try {
      var eventJson = jsonDecode(zapRequestEventStr!);
      var zapRequestEvent = Event.fromJson(eventJson);
      map['pubkey'] = zapRequestEvent.pubkey;
      map['index'] = -1;
      for (final tag in zapRequestEvent.tags) {
        if (tag.first == 'poll_option' && tag.length > 1) {
          map['index'] = int.tryParse(tag[1]) ?? -1;
        }
      }
      map['amount'] = getZapValue(event);
    } catch (e) {
      map['pubkey'] =
          SpiderUtil.subUntil(zapRequestEventStr!, 'pubkey\":\"', '\"');
    }
  }

  return map;
}

double getZapValue(Event event) {
  final receipt = Nip57.getZapReceipt(event);
  if (receipt.bolt11.isNotEmpty) {
    final req = Bolt11PaymentRequest(receipt.bolt11);

    return (req.amount.toDouble() * 100000000).round().toDouble();
  } else {
    return 0;
  }
}

bool rootComments({
  required List<Comment> comments,
}) {
  final rootComments = comments.where((comment) => comment.isRoot).toList();

  return rootComments.isEmpty;
}

void openWebPage({required String url, bool? inAppWebView}) async {
  try {
    String toAddUrl = url;
    if (!url.startsWith('http')) {
      toAddUrl = 'https://${toAddUrl}';
    }

    final uri = Uri.parse(toAddUrl);
    await launchUrl(
      uri,
      mode: inAppWebView != null
          ? LaunchMode.inAppWebView
          : LaunchMode.platformDefault,
    );
  } catch (_) {
    BotToastUtils.showError('Inaccessible link');
  }
}

int getCommentsCount(List<Comment> comments) {
  final rootComments = comments.where((comment) => comment.isRoot).toList();

  int count = rootComments.length;

  if (rootComments.isNotEmpty) {
    for (int i = 0; i < rootComments.length; i++) {
      int subsCount = getSubComments(
        comments: comments,
        commentId: rootComments[i].id,
      ).length;

      count += subsCount;
    }
  }

  return count;
}

void shareLink({
  required RenderBox? renderBox,
  required String pubkey,
  required String id,
  required int kind,
  TextContentType? textContentType,
}) {
  Share.share(
    externalShearableLink(
      kind: kind,
      pubkey: pubkey,
      id: id,
      textContentType: textContentType,
    ),
    subject: 'Check out www.yakihonne.com for more',
    sharePositionOrigin: renderBox != null
        ? renderBox.localToGlobal(Offset.zero) & renderBox.size
        : null,
  );
}

bool isReplaceable(int? kind) {
  return kind == EventKind.LONG_FORM ||
      kind == EventKind.CURATION_ARTICLES ||
      kind == EventKind.CURATION_VIDEOS ||
      kind == EventKind.VIDEO_HORIZONTAL ||
      kind == EventKind.VIDEO_VERTICAL ||
      kind == EventKind.SMART_WIDGET;
}

String externalShearableLink({
  required int kind,
  required String pubkey,
  required String id,
  TextContentType? textContentType,
}) {
  final naddr = createShareableLink(
    kind,
    pubkey,
    id,
  );

  final page = kind == EventKind.LONG_FORM
      ? 'article'
      : (kind == EventKind.CURATION_ARTICLES ||
              kind == EventKind.CURATION_VIDEOS)
          ? 'curations'
          : kind == EventKind.METADATA
              ? 'users'
              : kind == EventKind.SMART_WIDGET
                  ? 'smart-widget-checker'
                  : (kind == EventKind.VIDEO_HORIZONTAL ||
                          kind == EventKind.VIDEO_VERTICAL)
                      ? 'videos'
                      : textContentType == TextContentType.flashnews
                          ? 'flash-news'
                          : textContentType == TextContentType.note
                              ? 'notes'
                              : textContentType ==
                                      TextContentType.uncensoredNote
                                  ? 'uncensored-notes'
                                  : 'buzz-feed';

  final link = kind == EventKind.SMART_WIDGET
      ? '${baseUrl}$page?naddr=$naddr'
      : '${baseUrl}$page/${naddr}';

  return link;
}

List<dynamic> getVotes({
  required Map<String, VoteModel>? votes,
  required String? pubkey,
}) {
  int calculatedUpvotes = 0;
  int calculatedDownvotes = 0;
  bool userUpvote = false;
  bool userDownvote = false;

  if (votes == null) {
    return [
      calculatedUpvotes,
      userUpvote,
      calculatedDownvotes,
      userDownvote,
    ];
  }

  votes.forEach(
    (key, value) {
      if (value.vote) {
        calculatedUpvotes++;
        if (pubkey != null && key == pubkey) {
          userUpvote = true;
        }
      } else {
        calculatedDownvotes++;
        if (pubkey != null && key == pubkey) {
          userDownvote = true;
        }
      }
    },
  );

  return [
    calculatedUpvotes,
    userUpvote,
    calculatedDownvotes,
    userDownvote,
  ];
}

int getTextLengthWithoutParsables(String text) {
  int nostrLength = 0;
  int linksLength = 0;

  Iterable<RegExpMatch> nostrMatches = Nip19.nip19regex.allMatches(text);
  Iterable<RegExpMatch> linkMatches = urlRegExp.allMatches(text);

  if (nostrMatches.isNotEmpty) {
    for (final match in nostrMatches) {
      nostrLength += match.group(0)?.length ?? 0;
    }
  }

  if (linkMatches.isNotEmpty) {
    for (final match in linkMatches) {
      linksLength += match.group(0)?.length ?? 0;
    }
  }

  return text.length - nostrLength - linksLength;
}

String commentShearableLink({
  required bool? status,
  required int kind,
  required String comment,
  required String pubkey,
  required String id,
}) {
  if (status == null || !status) {
    return comment;
  } else {
    final naddr = createShareableLink(
      kind,
      pubkey,
      id,
    );

    final page = kind == EventKind.LONG_FORM
        ? 'article'
        : kind == EventKind.CURATION_ARTICLES
            ? 'curations'
            : kind == EventKind.VIDEO_HORIZONTAL ||
                    kind == EventKind.VIDEO_VERTICAL
                ? 'videos'
                : 'flash-news';

    return '$comment — This is a comment on: ${baseUrl}$page/${naddr}';
  }
}

String createShareableLink(int kind, String pubkey, String id) {
  String hexString = '';
  if (kind == EventKind.TEXT_NOTE) {
    hexString = id;
  } else if (kind == EventKind.METADATA) {
    hexString = id;
  } else {
    List<int> charCodes = id.runes.toList();
    hexString = charCodes.map((code) => code.toRadixString(16)).join('');
  }

  final chosenKind = kind == EventKind.LONG_FORM ||
          kind == EventKind.CURATION_ARTICLES ||
          kind == EventKind.VIDEO_HORIZONTAL ||
          kind == EventKind.VIDEO_VERTICAL ||
          kind == EventKind.SMART_WIDGET
      ? 'naddr'
      : kind == EventKind.METADATA
          ? 'nprofile'
          : 'nevent';

  final res = Nip19.encodeShareableEntity(
    chosenKind,
    hexString,
    [],
    pubkey,
    kind,
  );

  return res;
}

List<String> getSubComments({
  required List<Comment> comments,
  required String commentId,
}) {
  Set<String> subCommentsIds = {};

  for (final subComment in comments) {
    if (!subComment.isRoot && !subCommentsIds.contains(subComment.id)) {
      if (commentId == subComment.replyTo) {
        subCommentsIds.add(subComment.id);

        final list = getSubComments(
          comments: comments,
          commentId: subComment.id,
        );

        subCommentsIds.addAll(list);
      }
    }
  }

  return subCommentsIds.toList();
}

Widget linkifiedText({
  required BuildContext context,
  required String text,
  Function()? onClicked,
  Color? color,
  TextStyle? style,
  bool? isScreenshot,
  bool? disableVisualParsing,
  bool? inverseNoteColor,
  bool? isKeepAlive,
}) {
  try {
    return BlocBuilder<AuthorsCubit, AuthorsState>(
      builder: (context, state) {
        return BlocBuilder<SingleEventCubit, SingleEventState>(
          builder: (context, state) {
            return SelectionArea(
              child: Linkify(
                text: text,
                onClicked: onClicked,
                disableNoteParsing: disableVisualParsing,
                isScreenshot: isScreenshot,
                inverseNoteColor: inverseNoteColor,
                style: style ??
                    Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: color ?? null,
                        ),
                linkStyle: style?.copyWith(color: kOrange) ??
                    Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: kOrange,
                        ),
                linkifiers: [
                  UrlLinkifier(),
                  TagLinkifier(),
                  NostrSchemeLinkifier(),
                ],
                onOpen: (link) {
                  if (link.toString().startsWith('user:')) {
                    Navigator.pushNamed(
                      context,
                      ProfileView.routeName,
                      arguments: link.url,
                    );
                  }

                  if (link.toString().startsWith('article:')) {
                    if (link.url.isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        ArticleView.routeName,
                        arguments: Article.fromJson(link.url),
                      );
                    }
                  }

                  if (link.toString().startsWith('curation:')) {
                    if (link.url.isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        CurationView.routeName,
                        arguments: Curation.Curation(link.url),
                      );
                    }
                  }

                  if (link.toString().startsWith('video:')) {
                    if (link.url.isNotEmpty) {
                      final video = VideoModel.fromJson(link.url);
                      Navigator.pushNamed(
                        context,
                        video.kind == EventKind.VIDEO_HORIZONTAL
                            ? HorizontalVideoView.routeName
                            : VerticalVideoView.routeName,
                        arguments: [video],
                      );
                    }
                  }

                  if (link.toString().startsWith('smartWidget:')) {
                    if (link.url.isNotEmpty) {
                      final swc = SmartWidgetModel.fromJson(link.url);

                      showBlurredModal(
                        context: context,
                        view: SmartWidgetDisplay(
                          smartWidgetModel: swc,
                        ),
                      );
                    }
                  }

                  if (link.toString().startsWith('note:')) {
                    if (link.url.isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        NoteView.routeName,
                        arguments: DetailedNoteModel.fromJson(link.url),
                      );
                    }
                  }

                  if (link.toString().startsWith('tag:')) {
                    if (link.url.isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        TagView.routeName,
                        arguments: link.url.split('#')[1],
                      );
                    }
                  }

                  if (link.toString().startsWith('LinkElement:')) {
                    openWebPage.call(url: link.url);
                  }
                },
              ),
            );
          },
        );
      },
    );
  } catch (e, stack) {
    lg.i(stack);
    return SizedBox();
  }
}

void moveUp(List list, int index) {
  if (index > 0 && index < list.length) {
    var temp = list[index];
    list[index] = list[index - 1];
    list[index - 1] = temp;
  }
}

void moveDown(List list, int index) {
  if (index >= 0 && index < list.length - 1) {
    var temp = list[index];
    list[index] = list[index + 1];
    list[index + 1] = temp;
  }
}

Color? getColorFromHex(String hexColor) {
  try {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor; // add alpha if not provided
    }

    return Color(int.parse(hexColor, radix: 16));
  } catch (e) {
    return null;
  }
}

bool canAddNote(List<String> tag, String noteId) {
  return (tag.first == 'e' &&
          tag.length > 3 &&
          tag[3] == 'root' &&
          tag[1] == noteId) ||
      tag.first == 'e' && tag.length > 1 && tag[1] == noteId;
}

String getCommentWithoutPrefix(String comment) {
  return comment.split(' — This is a comment on: https').first.trim();
}

Color randomColor() {
  return Color((Random().nextDouble() * 0xFFFFFF).toInt())
      .withValues(alpha: 1.0);
}

String getAuthorName(UserModel author) {
  if (author.name.trim().isEmpty) {
    return Nip19.encodePubkey(author.pubKey).substring(0, 10);
  } else {
    return author.name.trim();
  }
}

String getAuthorDisplayName(UserModel author) {
  if (author.displayName.trim().isEmpty) {
    return getAuthorName(author);
  } else {
    return author.displayName.trim();
  }
}

bool checkAuthenticity(
  String encryption,
  DateTime createdAt,
) {
  try {
    final decryptedDate = decryptAESCryptoJS(
      encryption,
      dotenv.env['FN_KEY']!,
    );

    final parsedDate = int.tryParse(decryptedDate);

    if (parsedDate != null) {
      final newDate = DateTime.fromMillisecondsSinceEpoch(parsedDate * 1000);
      return newDate.isAtSameMomentAs(createdAt);
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}

Future<bool> _requestPermission(Permission permission) async {
  if (await permission.isGranted) {
    return true;
  } else {
    var result = await permission.request();
    if (result == PermissionStatus.granted) {
      return true;
    }
  }
  return false;
}

Future<File?> selectGalleryImage() async {
  if (Platform.isIOS) {
    try {
      final XFile? image;
      image = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (image != null) {
        return File(image.path);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  } else {
    bool storage = true;
    bool photos = true;

    final deviceInfo = await DeviceInfoPlugin().androidInfo;

    if (deviceInfo.version.sdkInt >= 33) {
      photos = await _requestPermission(Permission.photos);
    } else {
      storage = await _requestPermission(Permission.storage);
    }

    if (storage && photos) {
      final XFile? image;
      image = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (image != null) {
        return File(image.path);
      } else {
        return null;
      }
    } else {
      return null;
    }
  }
}

bool isImageExtension(String extension) {
  return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
      .contains(extension.toLowerCase());
}

bool isAudioExtension(String extension) {
  return ['m4a', 'mp3', 'wav', 'wma', 'aac'].contains(extension.toLowerCase());
}

bool isVideoExtension(String extension) {
  return ['mp4', 'avi', 'mkv', 'mov', 'flv'].contains(extension.toLowerCase());
}

final emptyUserModel = UserModel(
  picture: '',
  name: '',
  about: '',
  pubKey: '',
  banner: '',
  displayName: '',
  lud16: '',
  nip05: '',
  lud06: '',
  website: '',
  isDeleted: false,
  followings: [],
  createdAt: DateTime(2000),
);

final emptyComment = Comment(
  id: '',
  pubKey: '',
  content: '',
  createdAt: DateTime.now(),
  isRoot: false,
  replyTo: '',
);

UserStatus getUserStatus() {
  return nostrRepository.usm == null
      ? UserStatus.notConnected
      : nostrRepository.usm!.isUsingPrivKey
          ? UserStatus.UsingPrivKey
          : UserStatus.UsingPubKey;
}

bool isUsingPrivatekey() {
  return nostrRepository.usm != null && nostrRepository.usm!.isUsingPrivKey;
}

final videoUrlValidator = VideoURLValidator();

int getUnixTimestampWithinOneWeek() {
  final now = DateTime.now();
  final weekBefore = now.subtract(
    const Duration(days: 7),
  );

  final _random = new Random();

  return weekBefore.toSecondsSinceEpoch() +
      _random.nextInt(
          now.toSecondsSinceEpoch() - weekBefore.toSecondsSinceEpoch());
}

int getRemainingXp(int nextLevel) {
  if (nextLevel == 1)
    return 0;
  else
    return getRemainingXp(nextLevel - 1) + (nextLevel - 1) * 50;
}

int getCurrentLevel(int xp) {
  return ((1 + sqrt(1 + (8 * xp) / 50)) / 2).floor();
}

formattedTime({required int timeInSecond}) {
  int sec = timeInSecond % 60;
  int min = (timeInSecond / 60).floor();
  String minute = min.toString().length <= 1 ? "0$min" : "$min";
  String second = sec.toString().length <= 1 ? "0$sec" : "$sec";
  return "$minute:$second";
}

Color getPercentageColor(double percentage) {
  if (percentage >= 0 && percentage <= 25) {
    return kRed;
  } else if (percentage >= 26 && percentage <= 50) {
    return kOrange;
  } else if (percentage >= 51 && percentage <= 75) {
    return kYellow;
  } else {
    return kGreen;
  }
}

PageRouteBuilder createViewFromBottom(Widget widget) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => widget,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset(0.0, 0.0);
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

PageRouteBuilder createViewFromRight(Widget widget) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => widget,
    opaque: false,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset(0.0, 0.0);
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

Future<bool> colorPickerDialog({
  required BuildContext context,
  required Color selectedColor,
  required Function(Color) onColorChanged,
}) async {
  return ColorPicker(
    color: selectedColor,
    onColorChanged: onColorChanged,
    width: 40,
    height: 40,
    borderRadius: 3,
    spacing: 5,
    runSpacing: 5,
    wheelDiameter: 180,
    heading: Text(
      'Select color',
      style: Theme.of(context).textTheme.titleSmall,
    ),
    subheading: Text(
      'Select color shade',
      style: Theme.of(context).textTheme.titleSmall,
    ),
    wheelSubheading: Text(
      'Selected color and its shades',
      style: Theme.of(context).textTheme.titleSmall,
    ),
    showMaterialName: true,
    showColorName: true,
    showColorCode: true,
    copyPasteBehavior: const ColorPickerCopyPasteBehavior(
      longPressMenu: true,
    ),
    materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
    colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
    colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
    pickersEnabled: const <ColorPickerType, bool>{
      ColorPickerType.both: false,
      ColorPickerType.primary: true,
      ColorPickerType.accent: true,
      ColorPickerType.bw: false,
      ColorPickerType.custom: true,
      ColorPickerType.wheel: true,
    },
  ).showPickerDialog(
    context,
    // New in version 3.0.0 custom transitions support.
    transitionBuilder: (BuildContext context, Animation<double> a1,
        Animation<double> a2, Widget widget) {
      final double curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
      return Transform(
        transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
        child: Opacity(
          opacity: a1.value,
          child: widget,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),

    constraints:
        const BoxConstraints(minHeight: 460, minWidth: 300, maxWidth: 320),
  );
}

void useInterval(VoidCallback callback, Duration delay) {
  final savedCallback = useRef(callback);
  savedCallback.value = callback;

  useEffect(() {
    final timer = Timer.periodic(delay, (_) => savedCallback.value());
    return timer.cancel;
  }, [delay]);
}

bool canUserBeZapped(UserModel user) {
  return isUsingPrivatekey() &&
      (user.lud16.isNotEmpty || user.lud06.isNotEmpty) &&
      user.pubKey != nostrRepository.usm!.pubKey;
}

bool canUserBeFollowed(UserModel user) {
  return isUsingPrivatekey() && user.pubKey != nostrRepository.usm!.pubKey;
}

void openProfileFastAccess({
  required BuildContext context,
  required String pubkey,
}) {
  showModalBottomSheet(
    context: context,
    elevation: 0,
    builder: (_) {
      return ProfileFastAccess(
        pubkey: pubkey,
      );
    },
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  );
}

void moveItem(List<dynamic> list, int fromIndex, int toIndex) {
  if (fromIndex < 0 ||
      fromIndex >= list.length ||
      toIndex < 0 ||
      toIndex >= list.length) {
    return;
  }

  // Remove the item from the original position
  final item = list.removeAt(fromIndex);

  // Insert the item into the new position
  list.insert(toIndex, item);
}

double getTextSize(TextSize textSize, BuildContext context) {
  if (textSize == TextSize.H1) {
    return Theme.of(context).textTheme.titleMedium!.fontSize!;
  } else if (textSize == TextSize.H2) {
    return Theme.of(context).textTheme.titleSmall!.fontSize!;
  } else if (textSize == TextSize.Regular) {
    return Theme.of(context).textTheme.bodyMedium!.fontSize!;
  } else {
    return Theme.of(context).textTheme.labelMedium!.fontSize!;
  }
}

Map<String, dynamic> getSmartWidgetButtonProps(SmartWidgetButtonType action) {
  if (action == SmartWidgetButtonType.Youtube) {
    return {
      'color': '#FF0000',
      'icon': FeatureIcons.youtube,
    };
  } else if (action == SmartWidgetButtonType.Telegram) {
    return {
      'color': '#24A1DE',
      'icon': FeatureIcons.telegram,
    };
  } else if (action == SmartWidgetButtonType.Discord) {
    return {
      'color': '#7785cc',
      'icon': FeatureIcons.discord,
    };
  } else if (action == SmartWidgetButtonType.X) {
    return {
      'color': kBlack.toHex(),
      'icon': FeatureIcons.x,
    };
  } else if (action == SmartWidgetButtonType.Nostr) {
    return {
      'color': kPurple.toHex(),
      'icon': FeatureIcons.nostr,
    };
  } else {
    return {};
  }
}

bool isListOfMaps(List<dynamic> list) {
  for (var item in list) {
    if (item is! Map) {
      return false;
    }
  }
  return true;
}

PropertyStatus getPropertyStatus(
  MapEntry<String, dynamic> mapEntry,
  String type,
  dynamic extra,
) {
  final key = mapEntry.key;
  final val = mapEntry.value;

  if (type == 'container') {
    if (key == 'background_color' ||
        key == 'border_color' ||
        key == 'components') {
      if (key == 'components' && val is! List) {
        return PropertyStatus.invalid;
      } else if (key == 'background_color' &&
          (val is! String || (val.isNotEmpty && !hexRegExp.hasMatch(val)))) {
        return PropertyStatus.invalid;
      } else if (key == 'border_color' &&
          (val is! String || (val.isNotEmpty && !hexRegExp.hasMatch(val)))) {
        return PropertyStatus.invalid;
      }

      return PropertyStatus.valid;
    } else {
      return PropertyStatus.unknown;
    }
  } else if (type == 'grid') {
    if (key == 'division' ||
        key == 'layout' ||
        key == 'left_side' ||
        key == 'right_side') {
      if (key == 'left_side' && val is! List) {
        return PropertyStatus.invalid;
      } else if (key == 'right_side' &&
          (extra == 2 ? val is! List : val is! List?)) {
        return PropertyStatus.invalid;
      } else if (key == 'division' &&
          (val is! String || (val != '1:1' && val != '2:1' && val != '1:2'))) {
        return PropertyStatus.invalid;
      } else if (key == 'layout' && (val is! int || val < 1 || val > 2)) {
        return PropertyStatus.invalid;
      }

      return PropertyStatus.valid;
    } else {
      return PropertyStatus.unknown;
    }
  } else if (type == 'video') {
    if (key == 'url') {
      if (val is! String || !urlRegExp.hasMatch(val)) {
        return PropertyStatus.invalid;
      }

      return PropertyStatus.valid;
    } else {
      return PropertyStatus.unknown;
    }
  } else if (type == 'image') {
    if (key == 'url' || key == 'aspect_ratio') {
      if (key == 'url' &&
          (val is! String || (val.isNotEmpty && !urlRegExp.hasMatch(val)))) {
        return PropertyStatus.invalid;
      } else if (key == 'aspect_ratio' && (val is! String || val.isEmpty)) {
        return PropertyStatus.invalid;
      }

      return PropertyStatus.valid;
    } else {
      return PropertyStatus.unknown;
    }
  } else if (type == 'text') {
    if (key == 'content' ||
        key == 'text_color' ||
        key == 'weight' ||
        key == 'size') {
      if (key == 'size') {
        if (val is! String ||
            val.isEmpty ||
            TextSize.values
                .where((element) =>
                    element.name.toLowerCase() == val.toLowerCase())
                .isEmpty) {
          return PropertyStatus.invalid;
        }
      } else if (key == 'weight') {
        if (val is! String ||
            (val.isNotEmpty &&
                TextWeight.values
                    .where((element) =>
                        element.name.toLowerCase() == val.toLowerCase())
                    .isEmpty)) {
          return PropertyStatus.invalid;
        }
      } else if (key == 'content' && (val is! String || val.isEmpty)) {
        return PropertyStatus.invalid;
      } else if (key == 'text_color' &&
          (val is! String || (val.isNotEmpty && !hexRegExp.hasMatch(val)))) {
        return PropertyStatus.invalid;
      }

      return PropertyStatus.valid;
    } else {
      return PropertyStatus.unknown;
    }
  } else if (type == 'button') {
    if (key == 'content' ||
        key == 'text_color' ||
        key == 'url' ||
        key == 'background_color' ||
        key == 'type') {
      if (key == 'type' &&
          (val is! String ||
              val.isEmpty ||
              SmartWidgetButtonType.values
                  .where((element) =>
                      element.name.toLowerCase() == val.toLowerCase())
                  .isEmpty)) {
        return PropertyStatus.invalid;
      } else if (key == 'content' && (val is! String || val.isEmpty)) {
        return PropertyStatus.invalid;
      } else if (key == 'url') {
        final type = extra.toString().toLowerCase();

        if (val is! String ||
            val.isEmpty ||
            (type == 'regular' && !urlRegExp.hasMatch(val)) ||
            (type == 'x' && !xRegExp.hasMatch(val)) ||
            (type == 'youtube' && !youtubeRegExp.hasMatch(val)) ||
            (type == 'discord' && !discordRegExp.hasMatch(val)) ||
            (type == 'nostr' && !Nip19.nip19regex.hasMatch(val)) ||
            (type == 'telegram' && !telegramRegExp.hasMatch(val))) {
          return PropertyStatus.invalid;
        } else {}
      } else if (key == 'text_color' &&
          (val is! String || (val.isNotEmpty && !hexRegExp.hasMatch(val)))) {
        return PropertyStatus.invalid;
      } else if (key == 'background_color' &&
          (val is! String || (val.isNotEmpty && !hexRegExp.hasMatch(val)))) {
        return PropertyStatus.invalid;
      }

      return PropertyStatus.valid;
    } else {
      return PropertyStatus.unknown;
    }
  } else if (type == 'zap-poll') {
    if (key == 'content' ||
        key == 'content_text_color' ||
        key == 'options_text_color' ||
        key == 'options_background_color' ||
        key == 'options_foreground_color') {
      if (key == 'content' && (val is! String || val.isEmpty)) {
        return PropertyStatus.invalid;
      } else if (key == 'content_text_color' &&
          (val is! String && (val.isNotEmpty && !hexRegExp.hasMatch(val)))) {
        return PropertyStatus.invalid;
      } else if (key == 'options_text_color' &&
          (val is! String && (val.isNotEmpty && !hexRegExp.hasMatch(val)))) {
        return PropertyStatus.invalid;
      } else if (key == 'options_background_color' &&
          (val is! String && (val.isNotEmpty && !hexRegExp.hasMatch(val)))) {
        return PropertyStatus.invalid;
      } else if (key == 'options_foreground_color' &&
          (val is! String && (val.isNotEmpty && !hexRegExp.hasMatch(val)))) {
        return PropertyStatus.invalid;
      }

      return PropertyStatus.valid;
    } else {
      return PropertyStatus.unknown;
    }
  } else if (type == 'component') {
    if (key == 'type' || key == 'metadata') {
      if (key == 'type' &&
          (val is! String ||
              (val != 'video' &&
                  val != 'text' &&
                  val != 'image' &&
                  val != 'button' &&
                  val != 'zap-poll'))) {
        return PropertyStatus.invalid;
      } else if (key == 'metadata' && (val is! Map || val.isEmpty)) {
        return PropertyStatus.invalid;
      }
      return PropertyStatus.valid;
    } else {
      return PropertyStatus.unknown;
    }
  } else {
    return PropertyStatus.unknown;
  }
}
