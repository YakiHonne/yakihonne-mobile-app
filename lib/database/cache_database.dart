import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/database_tables.dart';
import 'package:yakihonne/models/dm_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/event.dart';
import 'package:yakihonne/utils/utils.dart';

part 'cache_database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(
    () async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(
        path.join(
          dbFolder.path,
          'yakihonne.sqlite',
        ),
      );

      if (Platform.isAndroid) {
        await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      }

      final cachebase = (await getTemporaryDirectory()).path;
      sqlite3.tempDirectory = cachebase;

      return NativeDatabase(file);
    },
  );
}

@DriftDatabase(tables: [Metadata, Nip01Event, DmInfo])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from == 1) {
          await Future.wait(
            [
              m.createTable(nip01Event),
              m.createTable(dmInfo),
            ],
          );
        }
      },
    );
  }

  // ** Metadata
  Future<void> getMetadata() async {
    try {
      final metadatas = await select(metadata).get();

      if (metadatas.isNotEmpty)
        authorsCubit.setAuthors(metadatas.map((e) => e).toList());
    } catch (e, stack) {
      lg.i(stack);
    }
  }

  Future<void> updateMetadata(UserModel user) async {
    try {
      final selectedMetadata = await (select(metadata)
            ..where(
              (tbl) => tbl.pubKey.equals(user.pubKey),
            ))
          .getSingleOrNull();

      if (selectedMetadata == null) {
        addMetadata(user);
      } else if (selectedMetadata.createdAt.isBefore(user.createdAt)) {
        await update(metadata).replace(
          MetadataData.fromJson(user.toLocalMetadata()),
        );
      }
    } catch (e, stack) {
      lg.i(stack);
    }
  }

  Future<void> addMetadata(UserModel user) async {
    try {
      await into(metadata).insert(
        MetadataData.fromJson(
          user.toLocalMetadata(),
        ),
      );
    } catch (e, stack) {
      lg.i(stack);
    }
  }

  Future<void> addMultiMetadata(List<UserModel> users) async {
    try {
      await batch((batch) {
        batch.insertAllOnConflictUpdate(
          metadata,
          users.map((e) => MetadataData.fromJson(e.toLocalMetadata())).toList(),
        );
      });

      getMetadata();
    } catch (e, stack) {
      lg.i(stack);
    }
  }

  // ** Events
  Future<List<Nip01EventData>> loadEvents({
    List<String>? pubKeys,
    List<int>? kinds,
    String? tag,
  }) async {
    try {
      final selectedNip01Events = await (select(nip01Event)
            ..where(
              (tbl) {
                return Expression.and(
                  [
                    if (pubKeys != null && pubKeys.isNotEmpty)
                      tbl.pubKey.isIn(pubKeys),
                    if (kinds != null && kinds.isNotEmpty) tbl.kind.isIn(kinds),
                    if (tag != null && tag.isNotEmpty) tbl.tags.contains(tag),
                  ],
                );
              },
            ))
          .get();

      return selectedNip01Events;
    } catch (e) {
      lg.i(e);
      return [];
    }
  }

  Future<void> addMultiEvents(List<Event> events) async {
    try {
      await batch((batch) {
        batch.insertAllOnConflictUpdate(
          nip01Event,
          events
              .map((e) => Nip01EventData.fromJson(e.toLocalNip01Event()))
              .toList(),
        );
      });
    } catch (e) {
      lg.i(e);
    }
  }

  // ** Dms info
  Future<List<DmInfoData>> getDmInfosByUser(String pubkey) async {
    try {
      final dmInfos = await (select(dmInfo)
            ..where(
              (tbl) => tbl.id.like('$pubkey%'),
            ))
          .get();

      return dmInfos;
    } catch (e) {
      lg.i(e);
      return [];
    }
  }

  Future<void> setDmInfo(DMSessionInfo dmSessionInfo) async {
    try {
      await into(dmInfo).insertOnConflictUpdate(
        DmInfoData.fromJson(dmSessionInfo.toLocalDmInfoData()),
      );
    } catch (e) {
      lg.i(e);
    }
  }

  // ** clear data
  Future<void> clearData() async {
    await Future.wait([
      delete(metadata).go(),
      delete(dmInfo).go(),
      delete(nip01Event).go(),
    ]);
  }
}
