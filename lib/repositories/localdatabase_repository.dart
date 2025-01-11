import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakihonne/models/relays_list.dart';
import 'package:yakihonne/models/topic.dart';
import 'package:yakihonne/models/user_status_model.dart';
import 'package:yakihonne/utils/topics.dart';
import 'package:yakihonne/utils/utils.dart';

late SharedPreferences prefs;

class LocalDatabaseRepository {
  final String ZAPS = 'zaps';
  final String USER_STATUS_MODEL = 'userStatusModel';
  final String USM_LIST = 'usm_list';
  final String IS_LIGHT_THEME = 'isLightTheme';
  final String ONBOARDING = 'onBoarding';
  final String APP_WALLETS = 'global_app_wallets';
  final String SELECTED_WALLET_ID = 'selected_wallet_id';
  final String NWC_URI = 'nwc_uri';
  final String NWC_SECRET = 'nwc_secret';
  final String NWC_LUD16 = 'nwc_lud16';
  final String NWC_PERMISSIONS = 'nwc_permissions';
  final String NWC_RELAY = 'nwc_relay';
  final String NWC_PUBKEY = 'nwc_pubkey';
  final String RELAYS = 'relays';
  final String DEFAULT_WALLET = 'default_wallet';
  final String USE_PREFIX = 'use_prefix';
  final String IMAGES_LINKS = 'images_links';
  final String COLLECT_DATA = 'collect_data';
  final String SHOW_DISCLOSURE = 'show_disclosure';
  final String TOPICS = 'topics';
  final String TOPICS_STATUS = 'topics_status';
  final String ARTICLE_CONTENT = 'article_content';
  final String SW_CONTENT = 'sw_content';
  final String MIGRATION = 'migration';
  final String LOCAL_MUTE = 'local_mute';
  final String PENDING_FLASH_NEWS = 'pending_flash_news';
  final String NEW_NOTIFICATIONS = 'new_notifications';
  final String REGISTRED_NOTIFICATIONS = 'registred_notifications';
  final String EXTERNAL_SIGNER = 'EXTERNAL_SIGNER';
  final String MESSAGING_NIP = 'messaging_nip';
  final String UPLOAD_SERVERS = 'upload_servers';
  final String NOTIFICATION_PROMPTER = 'notification_prompter';
  final String GIFT_WRAP_NEWEST_DATE_TIME = 'gift_wrap_newest_date_time';
  final String VERSION_NEWS = 'version_news';
  final String POINTS_SYSTEM = 'points_system';
  final String TEXT_SCALE_FACTOR = 'text_scale_factor';

  late FlutterSecureStorage secureStorage;

  IOSOptions _getIOSOptions() => const IOSOptions(
        accountName: 'yakihonne',
        accessibility: KeychainAccessibility.first_unlock,
      );

  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  LocalDatabaseRepository() {
    secureStorage = FlutterSecureStorage(
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );
  }

  //** text scale factor
  double getTextScaleFactor() {
    final textScaleFactor = prefs.getDouble(TEXT_SCALE_FACTOR);
    if (textScaleFactor != null) {
      return textScaleFactor;
    } else {
      prefs.setDouble(TEXT_SCALE_FACTOR, 1.0);
      return 1.0;
    }
  }

  void setTextScaleFactor(double textScaleFactor) {
    prefs.setDouble(TEXT_SCALE_FACTOR, textScaleFactor);
  }

  //** topics status
  Future<bool> getTopicsStatus() async {
    final isAvailable = prefs.get(TOPICS_STATUS);
    if (isAvailable != null) {
      return false;
    } else {
      prefs.setBool(TOPICS_STATUS, true);
      return true;
    }
  }

  Future<void> removeTopicsStatus() async {
    prefs.remove(TOPICS_STATUS);
  }

  //** version news
  bool canDisplayVersionNews(String version) {
    final currentVersion = prefs.getString(VERSION_NEWS);
    prefs.setString(VERSION_NEWS, version);

    return version != currentVersion;
  }

  //** notification prompter
  bool? getNotificationPrompter() {
    final isAvailable = prefs.getBool(NOTIFICATION_PROMPTER);
    if (isAvailable != null) {
      return isAvailable;
    } else {
      prefs.setBool(NOTIFICATION_PROMPTER, true);
      return null;
    }
  }

  Future<void> removeNotificationPrompter() async {
    prefs.remove(NOTIFICATION_PROMPTER);
  }

  //** external signer status
  Future<void> setExternalSignerStatus() async {
    prefs.setBool(EXTERNAL_SIGNER, true);
  }

  Future<bool> getExternalSignerStatus() async {
    final isAvailable = prefs.getBool(EXTERNAL_SIGNER);
    if (isAvailable != null) {
      return isAvailable;
    } else {
      prefs.setBool(EXTERNAL_SIGNER, false);
      return false;
    }
  }

  Future<void> removeExternalSigner() async {
    prefs.remove(EXTERNAL_SIGNER);
  }

  //** onboarding
  Future<bool> getOnboardingStatus() async {
    final isAvailable = prefs.get(ONBOARDING);
    if (isAvailable != null) {
      return false;
    } else {
      prefs.setBool(ONBOARDING, true);
      return true;
    }
  }

  //** points system
  bool getPointsSystemStatus() {
    final isAvailable = prefs.get(POINTS_SYSTEM);
    if (isAvailable != null) {
      return false;
    } else {
      prefs.setBool(POINTS_SYSTEM, true);
      return true;
    }
  }

  //** Messaging used nip
  Future<bool> isUsingNip44() async {
    final isAvailable = prefs.getBool(MESSAGING_NIP);

    if (isAvailable != null) {
      return isAvailable;
    } else {
      prefs.setBool(MESSAGING_NIP, false);
      return false;
    }
  }

  Future<void> setUsedNip(bool isUsingNip44) async {
    prefs.setBool(MESSAGING_NIP, isUsingNip44);
  }

  //** Upload servers
  Future<String> getUploadServer() async {
    final uploadServer = prefs.getString(UPLOAD_SERVERS);

    if (uploadServer != null) {
      return UploadServers.getUploadServer(uploadServer);
    } else {
      prefs.setString(UPLOAD_SERVERS, UploadServers.NOSTR_BUILD);
      return UploadServers.NOSTR_BUILD;
    }
  }

  Future<void> setUploadServer(String uploadServer) async {
    prefs.setString(UPLOAD_SERVERS, uploadServer);
  }

  //** zaps configuration
  Future<Map<String, Map<String, dynamic>>> getZapsConfiguration() async {
    final zaps = prefs.getString(ZAPS);

    if (zaps != null) {
      return Map<String, Map<String, dynamic>>.from(jsonDecode(zaps));
    } else {
      await prefs.setString(ZAPS, json.encode(defaultZaps));
      return defaultZaps;
    }
  }

  Future<void> setZaps(
    Map<String, Map<String, dynamic>> zaps,
  ) async {
    prefs.setString(ZAPS, jsonEncode(zaps));
  }

  //** oldest giftwrap date time
  int? getNewestGiftWrap() {
    return prefs.getInt(GIFT_WRAP_NEWEST_DATE_TIME);
  }

  Future<void> setNewestGiftWrap(int dateTime) async {
    await prefs.setInt(GIFT_WRAP_NEWEST_DATE_TIME, dateTime);
  }

  Future<void> deleteNewestGiftWrap() async {
    await prefs.remove(GIFT_WRAP_NEWEST_DATE_TIME);
  }

  //** Notifications
  Map<String, List<String>> getNotifications(bool isRegistred) {
    final registredNotifications = prefs.getString(
      isRegistred ? REGISTRED_NOTIFICATIONS : NEW_NOTIFICATIONS,
    );

    if (registredNotifications != null) {
      final map =
          Map<String, List<dynamic>>.from(jsonDecode(registredNotifications));
      Map<String, List<String>> newMap = {};

      map.forEach((key, value) {
        newMap[key] = value.cast<String>();
      });

      return newMap;
    } else {
      prefs.setString(
        isRegistred ? REGISTRED_NOTIFICATIONS : NEW_NOTIFICATIONS,
        json.encode({}),
      );

      return {};
    }
  }

  Future<void> setNotifications(
    Map<String, List<String>> registredNotifications,
    bool isRegistred,
  ) async {
    prefs.setString(
      isRegistred ? REGISTRED_NOTIFICATIONS : NEW_NOTIFICATIONS,
      jsonEncode(registredNotifications),
    );
  }

  Future<void> clearNotifications() async {
    prefs.remove(REGISTRED_NOTIFICATIONS);
  }

  //** wallet configuration
  Future<void> setUserWallets(String wallets) async {
    await secureStorage.write(key: APP_WALLETS, value: wallets);
  }

  Future<String> getWallets() async {
    return await secureStorage.read(key: APP_WALLETS) ?? '';
  }

  void setSelectedWalletId(String walletId) async {
    await prefs.setString(SELECTED_WALLET_ID, walletId);
  }

  String getSelectedWalletId() {
    return prefs.getString(SELECTED_WALLET_ID) ?? '';
  }

  Future<void> deleteNwc() async {
    await Future.wait(
      [
        prefs.remove(NWC_PERMISSIONS),
        prefs.remove(NWC_PUBKEY),
        prefs.remove(NWC_LUD16),
        prefs.remove(NWC_RELAY),
        prefs.remove(USE_PREFIX),
        secureStorage.delete(key: NWC_SECRET),
        secureStorage.delete(key: NWC_URI),
      ],
    );
  }

  //** default wallet
  void setDefaultWallet(String wallet) async {
    await prefs.setString(DEFAULT_WALLET, wallet);
  }

  Future<String> getDefaultWallet() async {
    final wallet = prefs.getString(DEFAULT_WALLET);
    if (wallet == null) {
      setDefaultWallet('');
      return '';
    } else {
      return wallet;
    }
  }

  //** themes
  Future<bool> isLightTheme() async {
    final isLightTheme = prefs.getBool(IS_LIGHT_THEME);

    if (isLightTheme != null) {
      return isLightTheme;
    } else {
      await prefs.setBool(IS_LIGHT_THEME, false);
      return false;
    }
  }

  void setTheme(bool isLightTheme) async {
    await prefs.setBool(IS_LIGHT_THEME, isLightTheme);
  }

  //** Pending flash news
  List<String> getPendingFlashNews() {
    final pendingFlashNews = prefs.getStringList(PENDING_FLASH_NEWS);
    return pendingFlashNews ?? <String>[];
  }

  void setPendingFlashNews(List<String> pendingFlashNews) async {
    await prefs.setStringList(PENDING_FLASH_NEWS, pendingFlashNews);
  }

  void clearPendingFlashNews() async {
    await prefs.remove(PENDING_FLASH_NEWS);
  }

  //** Comments prefix
  bool? getPrefix() {
    return prefs.getBool(USE_PREFIX);
  }

  Future<bool?> setPrefix(bool usePrefix) async {
    return prefs.setBool(USE_PREFIX, usePrefix);
  }

  //** local images links
  Future<List<String>> getImagesLinks(String pubkey) async {
    return prefs.getStringList(pubkey) ?? <String>[];
  }

  Future<void> setImagesLinks(String pubKey, List<String> imagesLinks) async {
    await prefs.setStringList(pubKey, imagesLinks);
  }

  //** user checkup
  void setUsm(UserStatusModel userStatusModel) {
    secureStorage.write(
      key: USER_STATUS_MODEL,
      value: userStatusModel.toJson(),
    );
  }

  void removeUsm() async {
    await secureStorage.delete(key: USER_STATUS_MODEL);
  }

  Future<UserStatusModel?> getCurrentUsm() async {
    final userModel = await secureStorage.read(key: USER_STATUS_MODEL);
    if (userModel != null) {
      return UserStatusModel.fromJson(userModel);
    }

    return null;
  }

  //** connected users
  void setUsmList(Map<String, UserStatusModel> users) {
    final map = <String, String>{};
    for (final item in users.entries) {
      map[item.key] = item.value.toJson();
    }

    secureStorage.write(
      key: USM_LIST,
      value: map.isEmpty ? '' : jsonEncode(map),
    );
  }

  Future<Map<String, UserStatusModel>> getUsmList() async {
    try {
      final users = await secureStorage.read(key: USM_LIST);
      if (users != null) {
        final map = jsonDecode(users) as Map<String, dynamic>;
        final usersMap = <String, UserStatusModel>{};

        for (final item in map.entries) {
          usersMap[item.key] = UserStatusModel.fromJson(item.value);
        }

        return usersMap;
      } else {
        setUsmList({});
        return <String, UserStatusModel>{};
      }
    } catch (e) {
      return <String, UserStatusModel>{};
    }
  }

  //** topics
  Future<String> getTopics() async {
    final topics = prefs.getString(TOPICS);

    if (topics != null) {
      return topics;
    } else {
      final topicsList = topicsToJson(topicsFromMaps(topicsDefaultList));

      prefs.setString(TOPICS, topicsList);
      return topicsList;
    }
  }

  Future<void> setTopics(List<Topic> topics) async {
    prefs.setString(TOPICS, topicsToJson(topics));
  }

  //** show disclosure view
  Future<bool> getDisclosureStatus() async {
    final isAvailable = prefs.get(SHOW_DISCLOSURE);
    if (isAvailable != null) {
      return false;
    } else {
      prefs.setBool(SHOW_DISCLOSURE, true);
      return true;
    }
  }

  //** local mutes
  void setLocalMutes(List<String> localMutes) {
    prefs.setStringList(LOCAL_MUTE, localMutes);
  }

  List<String> getLocalMutes() {
    final localMutes = prefs.getStringList(LOCAL_MUTE);

    return localMutes ?? <String>[];
  }

  //** analytics data collection
  bool getAnalyticsDataCollection() {
    final isAvailable = prefs.get(COLLECT_DATA);
    if (isAvailable != null) {
      return isAvailable as bool;
    } else {
      prefs.setBool(COLLECT_DATA, true);
      return true;
    }
  }

  void setAnalyticsDataCollection(bool analytics) {
    prefs.setBool(COLLECT_DATA, analytics);
  }

  //** Auto-save
  void setAutoSaveContent(String content, bool isArticle) {
    prefs.setString(
      isArticle ? ARTICLE_CONTENT : SW_CONTENT,
      content,
    );
  }

  Future<String> getAutoSaveContent(bool isArticle) async {
    final autoSaveContent = prefs.get(isArticle ? ARTICLE_CONTENT : SW_CONTENT);

    if (autoSaveContent != null) {
      return autoSaveContent as String;
    } else {
      prefs.setString(isArticle ? ARTICLE_CONTENT : SW_CONTENT, '');
      return '';
    }
  }

  void deleteAutoSaveContent(bool isArticle) async {
    prefs.remove(
      isArticle ? ARTICLE_CONTENT : SW_CONTENT,
    );
  }

  //** relays list
  void registerRelays(Relays relays) {
    prefs.setStringList(
      '${RELAYS}-${relays.pubKey}',
      relays.relays,
    );
  }

  Future<List<String>?> getRelays(String pubkey) async {
    return prefs.getStringList('${RELAYS}-${pubkey}');
  }
}
