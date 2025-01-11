import 'package:drift/drift.dart';

// ** Metadata table
class Metadata extends Table {
  TextColumn get pubKey => text()();
  TextColumn get name => text()();
  TextColumn get displayName => text()();
  TextColumn get about => text()();
  TextColumn get picture => text()();
  TextColumn get banner => text()();
  TextColumn get website => text()();
  TextColumn get nip05 => text()();
  TextColumn get lud16 => text()();
  TextColumn get lud06 => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isDeleted => boolean()();

  @override
  Set<Column> get primaryKey => {pubKey};
}

// ** Nip01 Event table
class Nip01Event extends Table {
  TextColumn get currentUser => text()();
  TextColumn get pubKey => text()();
  TextColumn get content => text()();
  TextColumn get id => text()();
  TextColumn get sig => text()();
  TextColumn get tags => text()();
  IntColumn get kind => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ** DMs Info Table
class DmInfo extends Table {
  TextColumn get id => text()();
  TextColumn get peerPubkey => text()();
  TextColumn get ownPubkey => text()();
  IntColumn get readTime => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
