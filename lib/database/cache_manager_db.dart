import 'package:yakihonne/database/cache_database.dart';
import 'package:yakihonne/models/dm_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nostr.dart';

class CacheManagerDB {
  static late AppDatabase appDatabase;

  // ** initialize database
  static Future<void> initialize() async {
    appDatabase = AppDatabase();
  }

  // ** add metadata
  static Future<void> addMetadata(UserModel user) async {
    await appDatabase.addMetadata(user);
  }

  // ** add multi metadata
  static Future<void> addMultiMetadata(List<UserModel> users) async {
    await appDatabase.addMultiMetadata(users);
  }

  // ** add metadata
  static Future<void> fetchMetadata() async {
    await appDatabase.getMetadata();
  }

  // ** update metadata
  static Future<void> updateMetadata(UserModel user) async {
    await appDatabase.updateMetadata(user);
  }

  // ** load events
  static Future<List<Nip01EventData>> loadEvents({
    List<String>? pubKeys,
    List<int>? kinds,
    String? pTag,
  }) async {
    return await appDatabase.loadEvents(
      kinds: kinds,
      tag: pTag,
      pubKeys: pubKeys,
    );
  }

  // ** add multi events
  static Future<void> addMultiEvents(List<Event> events) async {
    await appDatabase.addMultiEvents(events);
  }

  // ** Get Dm infos
  static Future<List<DmInfoData>> getDmInfos(String pubkey) async {
    return await appDatabase.getDmInfosByUser(pubkey);
  }

  // ** Set Dm info
  static Future<void> SetDmInfo(DMSessionInfo dmSessionInfo) async {
    await appDatabase.setDmInfo(dmSessionInfo);
  }

  // ** clear all metadata
  static Future<void> clearData() async {
    await appDatabase.clearData();
  }
}
