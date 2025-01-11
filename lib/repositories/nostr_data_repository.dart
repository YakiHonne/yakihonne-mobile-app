// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/bookmark_list_model.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/models/chat_message.dart';
import 'package:yakihonne/models/curations_mem_box.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/topic.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/user_status_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/models/wallet_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

class NostrDataRepository {
  NostrDataRepository({
    required this.localDatabaseRepository,
  });

  final LocalDatabaseRepository localDatabaseRepository;
  late MainCubit mainCubit;
  CurationsMemBox curationsMemBox = CurationsMemBox();
  UserStatusModel? usm;
  Map<String, UserStatusModel> usmList = {};
  Map<String, Map<String, WalletModel>> globalWallets = {};
  Set<String> relays = {};
  List<String> followings = [];
  Map<String, BookmarkListModel> bookmarksLists = {};
  Map<String, Set<String>> loadingBookmarks = {};
  Map<String, Set<String>> usersFollowers = {};
  Map<String, VideoModel> videos = {};
  Map<String, String> nip04Dms = {};
  UserModel user = emptyUserModel;
  bool isUsingNip44 = true;
  bool isUsingExternalSigner = false;
  List<Topic> topics = [];
  List<String> userTopics = [];

  List<ChatMessage> gptMessages = [];
  List<PendingFlashNews> pendingFlashNews = [];
  List<MainFlashNews> flashnews = [];
  String usedUploadServer = UploadServers.NOSTR_BUILD;
  String yakihonneWallet = 'yakihonne_funds@getalby.com';
  num initNotePrice = 21;
  num initRatingPrice = 10;
  num sealedNotePrice = 100;
  num sealedRatingPrice = 90;
  num flashNewsPrice = 800;
  num importantTagPrice = 210;
  Set<String> usersMessageNotifications = {};
  Map<String, BuzzFeedSource> buzzFeedSources = {};
  Map<String, List<SmartWidgetTemplate>> SmartWidgetTemplates = {};

  //** Global wallets */
  void loadGlobalWallets() async {
    localDatabaseRepository.getWallets();
  }

  //** latest curations */
  final refreshSelfArticlesController = StreamController<bool>.broadcast();

  Stream<bool> get refreshSelfArticlesStream async* {
    yield* refreshSelfArticlesController.stream;
  }

  //** set main home view */
  final homeViewController = StreamController<bool>.broadcast();

  Stream<bool> get homeViewStream async* {
    yield* homeViewController.stream;
  }

  //** Topics */
  final userTopicsController = StreamController<List<String>>.broadcast();

  Stream<List<String>> get userTopicsStream async* {
    yield* userTopicsController.stream;
  }

  //** set user followings */
  final followingsController = StreamController<List<String>>.broadcast();

  Stream<List<String>> get followingsStream async* {
    yield* followingsController.stream;
  }

  //** loading bookmarks */
  final loadingBookmarksController =
      StreamController<Map<String, Set<String>>>.broadcast();

  Stream<Map<String, Set<String>>> get loadingBookmarksStream async* {
    yield* loadingBookmarksController.stream;
  }

  //** bookmarks */
  final bookmarksController =
      StreamController<Map<String, BookmarkListModel>>.broadcast();

  Stream<Map<String, BookmarkListModel>> get bookmarksStream async* {
    yield* bookmarksController.stream; //** user status model */
  }

  //** user status model */
  final userModelController = StreamController<UserStatusModel?>.broadcast();

  Stream<UserStatusModel?> get userModelStream async* {
    yield* userModelController.stream;
  }

  void setUserStatusModel(UserStatusModel? userStatusModel) {
    if (userStatusModel != null) {
      localDatabaseRepository.setUsm(userStatusModel);

      if (userStatusModel.isUsingPrivKey &&
          userStatusModel.privKey == 'signer') {
        localDatabaseRepository.setExternalSignerStatus();
        isUsingExternalSigner = true;
      }

      usmList[userStatusModel.pubKey] = userStatusModel;
      localDatabaseRepository.setUsmList(usmList);
    }

    this.usm = userStatusModel;
    userModelController.add(userStatusModel);
  }

  void updateConnectedUserProfile(String pubkey) async {
    final u = authorsCubit.getAuthor(pubkey);

    this.user = u ??
        user.copyWith(
          pubKey: pubkey,
          picturePlaceholder: getRandomPlaceholder(
            input: pubkey,
            isPfp: true,
          ),
        );

    userModelController.add(usm);
  }

  void setUserModel(UserModel user) {
    this.user = user;
    userModelController.add(this.usm);
  }

  //** Videos */
  List<VideoModel> getVideoSuggestions(String? currentIdentifier) {
    if (videos.isEmpty) {
      return [];
    }
    final filtered = videos.values
        .where((element) => element.identifier != currentIdentifier)
        .toList();

    return getRandomVideos(list: filtered);
  }

  List<VideoModel> getRandomVideos({required List<VideoModel> list}) {
    List<VideoModel> randomList = [];

    if (list.length >= 3) {
      list.shuffle();
      randomList = list.sublist(0, 3);
    }

    return randomList;
  }

  //** auto-save */
  String articleAutoSave = '';
  Map<String, SWAutoSaveModel> swAutoSave = {};

  setArticleAutoSave({
    required String content,
  }) {
    localDatabaseRepository.setAutoSaveContent(content, true);
  }

  setSWAutoSave({
    required SWAutoSaveModel swsm,
  }) {
    swAutoSave[swsm.id] = swsm;
    localDatabaseRepository.setAutoSaveContent(jsonEncode(swAutoSave), false);
  }

  deleteAutoSave(String id) {
    swAutoSave.remove(id);
    localDatabaseRepository.setAutoSaveContent(jsonEncode(swAutoSave), false);
  }

  //** user mutes */
  List<List<String>> muteListAdditionalData = [];
  Set<String> mutes = {};

  final mutesController = StreamController<Set<String>>.broadcast();

  Stream<Set<String>> get mutesStream async* {
    yield* mutesController.stream;
  }

  //** user relays */
  Set<String> userRelays = {};

  final relaysController = StreamController<Set<String>>.broadcast();

  Stream<Set<String>> get relaysStream async* {
    yield* relaysController.stream;
  }

  void setRelays(Set<String> currentRelays) {
    relays = currentRelays;

    NostrConnect.sharedInstance.connectRelays(relays.toList());

    relaysController.add(relays);
  }

  Future<List<String>> getOnlineRelays() async {
    try {
      final response = await HttpFunctionsRepository.get(relaysUrl);

      return List<String>.from(response!['data'] ?? []);
    } catch (e) {
      Logger().i(e);
      return [];
    }
  }

  //** Handle topics */

  Future<void> getTopics() async {
    try {
      final downloadedTopics = await yakiDioFormData.get(topicsUrl);

      final topicsList = topicsFromMaps(downloadedTopics.data);

      localDatabaseRepository.setTopics(
        topicsList,
      );

      topics = topicsList;
    } catch (_) {
      final stringifiedTopics = await localDatabaseRepository.getTopics();
      topics = topicsFromJson(stringifiedTopics);
    }
  }

  List<String> getFilteredTopics() {
    Set<String> suggestions = {};
    for (final topic in nostrRepository.topics) {
      suggestions.addAll([topic.topic, ...topic.subTopics]);
      suggestions.addAll(nostrRepository.userTopics);
    }

    return suggestions.where((element) => !element.contains(' ')).toList();
  }

  Future<void> setTopics(List<String> topics) async {
    userTopics = topics;
    userTopicsController.add(topics);
  }

  //** Handle curations cache */

  void fetchCurations() {
    Timer.periodic(
      const Duration(seconds: 60),
      (timer) {
        notificationsCubit.queryNotifications();
      },
    );
  }

  Future<void> getPricing() async {
    try {
      final result = await HttpFunctionsRepository.getRewardsPrices();

      for (var item in result) {
        if (item['kind'] == EventKind.REACTION) {
          initRatingPrice = item['amount'];
        } else if (item['kind'] == EventKind.TEXT_NOTE) {
          initNotePrice = item['uncensored_notes']['amount'];
          flashNewsPrice = item['flash_news']['amount'];
          importantTagPrice = item['flash_news_important_flag']['amount'];
        } else {
          sealedRatingPrice = item['is_rater']['amount'];
          sealedNotePrice = item['is_author']['amount'];
        }
      }
    } catch (e) {
      lg.i(e);
    }
  }

  //** user disconnection */
  void disconnect() {
    usm = null;
    setUserModelFollowing(emptyUserModel);
    bookmarksLists.clear();
    loadingBookmarks.clear();
    mutes.clear();
    mutes = localDatabaseRepository.getLocalMutes().toSet();
    muteListAdditionalData.clear();
    closeRelaysConnection();
    this.relays = constantRelays.toSet();
    localDatabaseRepository.removeUsm();
    localDatabaseRepository.deleteNwc();
    localDatabaseRepository.removeTopicsStatus();
    localDatabaseRepository.deleteAutoSaveContent(true);
    localDatabaseRepository.deleteAutoSaveContent(false);
    localDatabaseRepository.removeExternalSigner();
    localDatabaseRepository.clearPendingFlashNews();
    localDatabaseRepository.setUsmList({});
    pointsManagementCubit.logout();
    isUsingExternalSigner = false;
    relaysController.add(relays);
    pendingFlashNews.clear();
    bookmarksController.add({});
    mutesController.add(mutes);
    userModelController.add(null);
    userTopics.clear();
    gptMessages.clear();
    userTopicsController.add([]);
  }

  void closeRelaysConnection() {
    final toBeDisconnectedRelays =
        relays.where((relay) => !constantRelays.contains(relay)).toList();
    NostrConnect.sharedInstance.closeConnect(toBeDisconnectedRelays);
  }

  //** Pending flash news */
  void getAndFilterPendingFlashNews() {
    final stringifiedPendingFlashNews =
        localDatabaseRepository.getPendingFlashNews();

    List<PendingFlashNews> storedPendings = stringifiedPendingFlashNews
        .map((e) => PendingFlashNews.fromJson(e))
        .toList();

    storedPendings.removeWhere((element) {
      return element.isExpired();
    });

    final strigifiedPendingFlash =
        storedPendings.map((e) => e.toJson()).toList();

    localDatabaseRepository.setPendingFlashNews(strigifiedPendingFlash);

    if (usm != null && usm!.isUsingPrivKey) {
      pendingFlashNews = storedPendings;
    }
  }

  void setPendingFlashNews(PendingFlashNews newPending) {
    final index = pendingFlashNews.indexWhere(
      (element) => element.eventId == newPending.eventId,
    );

    if (index == -1) {
      pendingFlashNews.add(newPending);
    } else {
      pendingFlashNews[index] = newPending;
    }

    final strigifiedPendingFlash =
        pendingFlashNews.map((e) => e.toJson()).toList();

    localDatabaseRepository.setPendingFlashNews(strigifiedPendingFlash);
  }

  void deletePendingFlashNews(PendingFlashNews pending) {
    pendingFlashNews.removeWhere(
      (element) => element.eventId == pending.eventId || element.isExpired(),
    );

    final strigifiedPendingFlash =
        pendingFlashNews.map((e) => e.toJson()).toList();

    localDatabaseRepository.setPendingFlashNews(strigifiedPendingFlash);
  }

  void setUserModelFollowing(UserModel user) {
    this.user = user;
    followings = user.followings.map((e) => e.key).toList();
    followingsController.add(followings);
    userModelController.add(this.usm);
  }

  //** user meta data */

  void setActiveUser(UserStatusModel usm, bool isSwitch) {
    setUserStatusModel(usm);

    NostrFunctionsRepository.getCurrentUserMetadata(
      pubKey: usm.pubKey,
      isPrivKey: usm.isUsingPrivKey,
      userStatusModel: usm,
    );

    if (isSwitch) updateConnectedUserProfile(usm.pubKey);

    lightningZapsCubit.switchWallets();

    if (usm.isUsingPrivKey) {
      if (isSwitch) {
        pointsManagementCubit.logout();
        pointsManagementCubit.login(
          onSuccess: () {},
        );
      }

      notificationsCubit.since = null;
      notificationsCubit.queryNotifications();
      dmsCubit.initDmSessions();
      fetchBookmarks(usm.pubKey);
    }
  }

  void getUserMetaData({
    required String hex,
    required bool isPrivKey,
    bool? isExternalSigner,
  }) async {
    String pubKey = '';
    String privKey = '';

    mutes.clear();
    muteListAdditionalData.clear();

    if (isPrivKey) {
      privKey = isExternalSigner != null ? 'signer' : hex;
      pubKey = isExternalSigner != null
          ? Nip19.decodePubkey(hex)
          : Keychain.getPublicKey(hex);
      mutesController.add({});
    } else {
      pubKey = hex;
      mutes = localDatabaseRepository.getLocalMutes().toSet();
      mutesController.add(mutes);
    }

    final userStatusModel = UserStatusModel(
      isUsingPrivKey: isPrivKey,
      pubKey: pubKey,
      privKey: privKey,
    );

    setActiveUser(userStatusModel, false);
  }

  void fetchBookmarks(String pubkey) {
    bookmarksLists.clear();
    NostrFunctionsRepository.getEvents(
      pubkeys: [pubkey],
      kinds: [EventKind.CATEGORIZED_BOOKMARK],
    ).listen(
      (event) {
        if (event.kind == EventKind.CATEGORIZED_BOOKMARK) {
          final bookmark = BookmarkListModel.fromEvent(event);

          final canBeAdded = (bookmarksLists[bookmark.identifier] == null ||
              bookmarksLists[bookmark.identifier]!
                      .createAt
                      .toSecondsSinceEpoch()
                      .compareTo(bookmark.createAt.toSecondsSinceEpoch()) <
                  1);

          if (canBeAdded) {
            bookmarksLists[bookmark.identifier] = bookmark;
            bookmarksController.add(bookmarksLists);
          }
        }
      },
      onDone: () {},
    );
  }

  //** user bookmarks */

  void deleteBookmarkList(String bookmarkIdentifier) {
    bookmarksLists.removeWhere((key, value) => key == bookmarkIdentifier);
    bookmarksController.add(bookmarksLists);
  }

  void addBookmarkList(BookmarkListModel bookmarkListModel) {
    bookmarksLists[bookmarkListModel.identifier] = bookmarkListModel;
    bookmarksController.add(bookmarksLists);
  }

  String shareableLink({
    required isArticle,
    required String identifier,
    required pubkey,
  }) {
    List<int> charCodes = identifier.runes.toList();
    String hexString = charCodes.map((code) => code.toRadixString(16)).join('');

    final naddr = Nip19.encodeShareableEntity(
      'naddr',
      hexString,
      [],
      pubkey,
      isArticle ? EventKind.LONG_FORM : EventKind.CURATION_ARTICLES,
    );

    return '${baseUrl}${isArticle ? 'article' : 'curations'}/${naddr}';
  }

  Future<List<String>> getMessage(Event event) async {
    if (event.kind == EventKind.DIRECT_MESSAGE) {
      String? peerPubkey = getPubkeyRegularEvent(event);
      String replyId = '';

      for (final tag in event.tags) {
        if (tag[0] == 'e' && tag.length > 1) {
          replyId = tag[1];
        }
      }

      final decryptedMessage = nip04Dms[event.id] ??
          await Nip4.decryptContent(
            event.content,
            peerPubkey ?? '',
            nostrRepository.usm!.pubKey,
            nostrRepository.usm!.privKey,
          );

      nip04Dms[event.id] = decryptedMessage;

      return [decryptedMessage, replyId];
    } else if (event.kind == EventKind.PRIVATE_DIRECT_MESSAGE) {
      String replyId = '';
      for (final tag in event.tags) {
        if (tag[0] == 'e' && tag.length > 1) {
          replyId = tag[1];
        }
      }

      return [event.content.trim(), replyId];
    }

    return ['', ''];
  }

  String? getPubkeyRegularEvent(Event event) {
    if (event.pubkey != nostrRepository.usm!.pubKey) {
      return event.pubkey;
    }

    for (var tag in event.tags) {
      if (tag[0] == "p") {
        return tag[1];
      }
    }

    return null;
  }

  Future<File?> selectLocalMedia(MediaType mediaType) async {
    if (Platform.isIOS) {
      try {
        final XFile? media;
        if (mediaType == MediaType.gallery) {
          media = await ImagePicker().pickMedia();
        } else if (mediaType == MediaType.cameraImage) {
          media = await ImagePicker().pickImage(source: ImageSource.camera);
        } else if (mediaType == MediaType.cameraVideo) {
          media = await ImagePicker().pickVideo(source: ImageSource.camera);
        } else if (mediaType == MediaType.image) {
          media = await ImagePicker().pickImage(source: ImageSource.gallery);
        } else {
          media = await ImagePicker().pickVideo(source: ImageSource.gallery);
        }

        if (media != null) {
          final file = File(media.path);
          if (isFileSmallerThan10Mb(file)) {
            return file;
          } else {
            BotToastUtils.showError(
              'Media exceeds the maximum size which is 10 mb',
            );

            return null;
          }
        } else {
          return null;
        }
      } catch (_) {
        return null;
      }
    } else {
      bool storage = true;
      bool photos = true;
      bool videos = true;
      final deviceInfo = await DeviceInfoPlugin().androidInfo;

      if (deviceInfo.version.sdkInt >= 33) {
        photos = await _requestPermission(Permission.photos);
        videos = await _requestPermission(Permission.videos);
      } else {
        storage = await _requestPermission(Permission.storage);
      }

      if (storage && photos && videos) {
        final XFile? media;
        media = await ImagePicker().pickMedia();

        if (media != null) {
          final file = File(media.path);
          if (isFileSmallerThan10Mb(file)) {
            return file;
          } else {
            BotToastUtils.showError(
              'Media exceeds the maximum size which is 10 mb',
            );
            return null;
          }
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
  }

  bool isFileSmallerThan10Mb(File file) {
    int sizeInBytes = file.lengthSync();
    double sizeInMb = sizeInBytes / (1024 * 1024);
    return sizeInMb <= 10;
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

  Future<void> getBuzzFeed() async {
    try {
      final feed = await HttpFunctionsRepository.getBuzzFeedSources();
      final sources = {
        for (final s in feed) ...{s.name: s}
      };

      buzzFeedSources = sources;
    } catch (e) {
      lg.i(e);
    }
  }
}
