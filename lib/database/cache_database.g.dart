// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_database.dart';

// ignore_for_file: type=lint
class $MetadataTable extends Metadata
    with TableInfo<$MetadataTable, MetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pubKeyMeta = const VerificationMeta('pubKey');
  @override
  late final GeneratedColumn<String> pubKey = GeneratedColumn<String>(
      'pub_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _aboutMeta = const VerificationMeta('about');
  @override
  late final GeneratedColumn<String> about = GeneratedColumn<String>(
      'about', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pictureMeta =
      const VerificationMeta('picture');
  @override
  late final GeneratedColumn<String> picture = GeneratedColumn<String>(
      'picture', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bannerMeta = const VerificationMeta('banner');
  @override
  late final GeneratedColumn<String> banner = GeneratedColumn<String>(
      'banner', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _websiteMeta =
      const VerificationMeta('website');
  @override
  late final GeneratedColumn<String> website = GeneratedColumn<String>(
      'website', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nip05Meta = const VerificationMeta('nip05');
  @override
  late final GeneratedColumn<String> nip05 = GeneratedColumn<String>(
      'nip05', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lud16Meta = const VerificationMeta('lud16');
  @override
  late final GeneratedColumn<String> lud16 = GeneratedColumn<String>(
      'lud16', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lud06Meta = const VerificationMeta('lud06');
  @override
  late final GeneratedColumn<String> lud06 = GeneratedColumn<String>(
      'lud06', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [
        pubKey,
        name,
        displayName,
        about,
        picture,
        banner,
        website,
        nip05,
        lud16,
        lud06,
        createdAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metadata';
  @override
  VerificationContext validateIntegrity(Insertable<MetadataData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pub_key')) {
      context.handle(_pubKeyMeta,
          pubKey.isAcceptableOrUnknown(data['pub_key']!, _pubKeyMeta));
    } else if (isInserting) {
      context.missing(_pubKeyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('about')) {
      context.handle(
          _aboutMeta, about.isAcceptableOrUnknown(data['about']!, _aboutMeta));
    } else if (isInserting) {
      context.missing(_aboutMeta);
    }
    if (data.containsKey('picture')) {
      context.handle(_pictureMeta,
          picture.isAcceptableOrUnknown(data['picture']!, _pictureMeta));
    } else if (isInserting) {
      context.missing(_pictureMeta);
    }
    if (data.containsKey('banner')) {
      context.handle(_bannerMeta,
          banner.isAcceptableOrUnknown(data['banner']!, _bannerMeta));
    } else if (isInserting) {
      context.missing(_bannerMeta);
    }
    if (data.containsKey('website')) {
      context.handle(_websiteMeta,
          website.isAcceptableOrUnknown(data['website']!, _websiteMeta));
    } else if (isInserting) {
      context.missing(_websiteMeta);
    }
    if (data.containsKey('nip05')) {
      context.handle(
          _nip05Meta, nip05.isAcceptableOrUnknown(data['nip05']!, _nip05Meta));
    } else if (isInserting) {
      context.missing(_nip05Meta);
    }
    if (data.containsKey('lud16')) {
      context.handle(
          _lud16Meta, lud16.isAcceptableOrUnknown(data['lud16']!, _lud16Meta));
    } else if (isInserting) {
      context.missing(_lud16Meta);
    }
    if (data.containsKey('lud06')) {
      context.handle(
          _lud06Meta, lud06.isAcceptableOrUnknown(data['lud06']!, _lud06Meta));
    } else if (isInserting) {
      context.missing(_lud06Meta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    } else if (isInserting) {
      context.missing(_isDeletedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pubKey};
  @override
  MetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetadataData(
      pubKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pub_key'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      about: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}about'])!,
      picture: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}picture'])!,
      banner: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}banner'])!,
      website: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}website'])!,
      nip05: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nip05'])!,
      lud16: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lud16'])!,
      lud06: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lud06'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $MetadataTable createAlias(String alias) {
    return $MetadataTable(attachedDatabase, alias);
  }
}

class MetadataData extends DataClass implements Insertable<MetadataData> {
  final String pubKey;
  final String name;
  final String displayName;
  final String about;
  final String picture;
  final String banner;
  final String website;
  final String nip05;
  final String lud16;
  final String lud06;
  final DateTime createdAt;
  final bool isDeleted;
  const MetadataData(
      {required this.pubKey,
      required this.name,
      required this.displayName,
      required this.about,
      required this.picture,
      required this.banner,
      required this.website,
      required this.nip05,
      required this.lud16,
      required this.lud06,
      required this.createdAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pub_key'] = Variable<String>(pubKey);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    map['about'] = Variable<String>(about);
    map['picture'] = Variable<String>(picture);
    map['banner'] = Variable<String>(banner);
    map['website'] = Variable<String>(website);
    map['nip05'] = Variable<String>(nip05);
    map['lud16'] = Variable<String>(lud16);
    map['lud06'] = Variable<String>(lud06);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  MetadataCompanion toCompanion(bool nullToAbsent) {
    return MetadataCompanion(
      pubKey: Value(pubKey),
      name: Value(name),
      displayName: Value(displayName),
      about: Value(about),
      picture: Value(picture),
      banner: Value(banner),
      website: Value(website),
      nip05: Value(nip05),
      lud16: Value(lud16),
      lud06: Value(lud06),
      createdAt: Value(createdAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory MetadataData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetadataData(
      pubKey: serializer.fromJson<String>(json['pubKey']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      about: serializer.fromJson<String>(json['about']),
      picture: serializer.fromJson<String>(json['picture']),
      banner: serializer.fromJson<String>(json['banner']),
      website: serializer.fromJson<String>(json['website']),
      nip05: serializer.fromJson<String>(json['nip05']),
      lud16: serializer.fromJson<String>(json['lud16']),
      lud06: serializer.fromJson<String>(json['lud06']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pubKey': serializer.toJson<String>(pubKey),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'about': serializer.toJson<String>(about),
      'picture': serializer.toJson<String>(picture),
      'banner': serializer.toJson<String>(banner),
      'website': serializer.toJson<String>(website),
      'nip05': serializer.toJson<String>(nip05),
      'lud16': serializer.toJson<String>(lud16),
      'lud06': serializer.toJson<String>(lud06),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  MetadataData copyWith(
          {String? pubKey,
          String? name,
          String? displayName,
          String? about,
          String? picture,
          String? banner,
          String? website,
          String? nip05,
          String? lud16,
          String? lud06,
          DateTime? createdAt,
          bool? isDeleted}) =>
      MetadataData(
        pubKey: pubKey ?? this.pubKey,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        about: about ?? this.about,
        picture: picture ?? this.picture,
        banner: banner ?? this.banner,
        website: website ?? this.website,
        nip05: nip05 ?? this.nip05,
        lud16: lud16 ?? this.lud16,
        lud06: lud06 ?? this.lud06,
        createdAt: createdAt ?? this.createdAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  @override
  String toString() {
    return (StringBuffer('MetadataData(')
          ..write('pubKey: $pubKey, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('about: $about, ')
          ..write('picture: $picture, ')
          ..write('banner: $banner, ')
          ..write('website: $website, ')
          ..write('nip05: $nip05, ')
          ..write('lud16: $lud16, ')
          ..write('lud06: $lud06, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(pubKey, name, displayName, about, picture,
      banner, website, nip05, lud16, lud06, createdAt, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetadataData &&
          other.pubKey == this.pubKey &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.about == this.about &&
          other.picture == this.picture &&
          other.banner == this.banner &&
          other.website == this.website &&
          other.nip05 == this.nip05 &&
          other.lud16 == this.lud16 &&
          other.lud06 == this.lud06 &&
          other.createdAt == this.createdAt &&
          other.isDeleted == this.isDeleted);
}

class MetadataCompanion extends UpdateCompanion<MetadataData> {
  final Value<String> pubKey;
  final Value<String> name;
  final Value<String> displayName;
  final Value<String> about;
  final Value<String> picture;
  final Value<String> banner;
  final Value<String> website;
  final Value<String> nip05;
  final Value<String> lud16;
  final Value<String> lud06;
  final Value<DateTime> createdAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const MetadataCompanion({
    this.pubKey = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.about = const Value.absent(),
    this.picture = const Value.absent(),
    this.banner = const Value.absent(),
    this.website = const Value.absent(),
    this.nip05 = const Value.absent(),
    this.lud16 = const Value.absent(),
    this.lud06 = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetadataCompanion.insert({
    required String pubKey,
    required String name,
    required String displayName,
    required String about,
    required String picture,
    required String banner,
    required String website,
    required String nip05,
    required String lud16,
    required String lud06,
    required DateTime createdAt,
    required bool isDeleted,
    this.rowid = const Value.absent(),
  })  : pubKey = Value(pubKey),
        name = Value(name),
        displayName = Value(displayName),
        about = Value(about),
        picture = Value(picture),
        banner = Value(banner),
        website = Value(website),
        nip05 = Value(nip05),
        lud16 = Value(lud16),
        lud06 = Value(lud06),
        createdAt = Value(createdAt),
        isDeleted = Value(isDeleted);
  static Insertable<MetadataData> custom({
    Expression<String>? pubKey,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? about,
    Expression<String>? picture,
    Expression<String>? banner,
    Expression<String>? website,
    Expression<String>? nip05,
    Expression<String>? lud16,
    Expression<String>? lud06,
    Expression<DateTime>? createdAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pubKey != null) 'pub_key': pubKey,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (about != null) 'about': about,
      if (picture != null) 'picture': picture,
      if (banner != null) 'banner': banner,
      if (website != null) 'website': website,
      if (nip05 != null) 'nip05': nip05,
      if (lud16 != null) 'lud16': lud16,
      if (lud06 != null) 'lud06': lud06,
      if (createdAt != null) 'created_at': createdAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetadataCompanion copyWith(
      {Value<String>? pubKey,
      Value<String>? name,
      Value<String>? displayName,
      Value<String>? about,
      Value<String>? picture,
      Value<String>? banner,
      Value<String>? website,
      Value<String>? nip05,
      Value<String>? lud16,
      Value<String>? lud06,
      Value<DateTime>? createdAt,
      Value<bool>? isDeleted,
      Value<int>? rowid}) {
    return MetadataCompanion(
      pubKey: pubKey ?? this.pubKey,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      about: about ?? this.about,
      picture: picture ?? this.picture,
      banner: banner ?? this.banner,
      website: website ?? this.website,
      nip05: nip05 ?? this.nip05,
      lud16: lud16 ?? this.lud16,
      lud06: lud06 ?? this.lud06,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pubKey.present) {
      map['pub_key'] = Variable<String>(pubKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (about.present) {
      map['about'] = Variable<String>(about.value);
    }
    if (picture.present) {
      map['picture'] = Variable<String>(picture.value);
    }
    if (banner.present) {
      map['banner'] = Variable<String>(banner.value);
    }
    if (website.present) {
      map['website'] = Variable<String>(website.value);
    }
    if (nip05.present) {
      map['nip05'] = Variable<String>(nip05.value);
    }
    if (lud16.present) {
      map['lud16'] = Variable<String>(lud16.value);
    }
    if (lud06.present) {
      map['lud06'] = Variable<String>(lud06.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetadataCompanion(')
          ..write('pubKey: $pubKey, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('about: $about, ')
          ..write('picture: $picture, ')
          ..write('banner: $banner, ')
          ..write('website: $website, ')
          ..write('nip05: $nip05, ')
          ..write('lud16: $lud16, ')
          ..write('lud06: $lud06, ')
          ..write('createdAt: $createdAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $Nip01EventTable extends Nip01Event
    with TableInfo<$Nip01EventTable, Nip01EventData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $Nip01EventTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _currentUserMeta =
      const VerificationMeta('currentUser');
  @override
  late final GeneratedColumn<String> currentUser = GeneratedColumn<String>(
      'current_user', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pubKeyMeta = const VerificationMeta('pubKey');
  @override
  late final GeneratedColumn<String> pubKey = GeneratedColumn<String>(
      'pub_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sigMeta = const VerificationMeta('sig');
  @override
  late final GeneratedColumn<String> sig = GeneratedColumn<String>(
      'sig', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
      'kind', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [currentUser, pubKey, content, id, sig, tags, kind, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nip01_event';
  @override
  VerificationContext validateIntegrity(Insertable<Nip01EventData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('current_user')) {
      context.handle(
          _currentUserMeta,
          currentUser.isAcceptableOrUnknown(
              data['current_user']!, _currentUserMeta));
    } else if (isInserting) {
      context.missing(_currentUserMeta);
    }
    if (data.containsKey('pub_key')) {
      context.handle(_pubKeyMeta,
          pubKey.isAcceptableOrUnknown(data['pub_key']!, _pubKeyMeta));
    } else if (isInserting) {
      context.missing(_pubKeyMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sig')) {
      context.handle(
          _sigMeta, sig.isAcceptableOrUnknown(data['sig']!, _sigMeta));
    } else if (isInserting) {
      context.missing(_sigMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    } else if (isInserting) {
      context.missing(_tagsMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Nip01EventData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Nip01EventData(
      currentUser: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}current_user'])!,
      pubKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pub_key'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sig: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sig'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}kind'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $Nip01EventTable createAlias(String alias) {
    return $Nip01EventTable(attachedDatabase, alias);
  }
}

class Nip01EventData extends DataClass implements Insertable<Nip01EventData> {
  final String currentUser;
  final String pubKey;
  final String content;
  final String id;
  final String sig;
  final String tags;
  final int kind;
  final DateTime createdAt;
  const Nip01EventData(
      {required this.currentUser,
      required this.pubKey,
      required this.content,
      required this.id,
      required this.sig,
      required this.tags,
      required this.kind,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['current_user'] = Variable<String>(currentUser);
    map['pub_key'] = Variable<String>(pubKey);
    map['content'] = Variable<String>(content);
    map['id'] = Variable<String>(id);
    map['sig'] = Variable<String>(sig);
    map['tags'] = Variable<String>(tags);
    map['kind'] = Variable<int>(kind);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  Nip01EventCompanion toCompanion(bool nullToAbsent) {
    return Nip01EventCompanion(
      currentUser: Value(currentUser),
      pubKey: Value(pubKey),
      content: Value(content),
      id: Value(id),
      sig: Value(sig),
      tags: Value(tags),
      kind: Value(kind),
      createdAt: Value(createdAt),
    );
  }

  factory Nip01EventData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Nip01EventData(
      currentUser: serializer.fromJson<String>(json['currentUser']),
      pubKey: serializer.fromJson<String>(json['pubKey']),
      content: serializer.fromJson<String>(json['content']),
      id: serializer.fromJson<String>(json['id']),
      sig: serializer.fromJson<String>(json['sig']),
      tags: serializer.fromJson<String>(json['tags']),
      kind: serializer.fromJson<int>(json['kind']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'currentUser': serializer.toJson<String>(currentUser),
      'pubKey': serializer.toJson<String>(pubKey),
      'content': serializer.toJson<String>(content),
      'id': serializer.toJson<String>(id),
      'sig': serializer.toJson<String>(sig),
      'tags': serializer.toJson<String>(tags),
      'kind': serializer.toJson<int>(kind),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Nip01EventData copyWith(
          {String? currentUser,
          String? pubKey,
          String? content,
          String? id,
          String? sig,
          String? tags,
          int? kind,
          DateTime? createdAt}) =>
      Nip01EventData(
        currentUser: currentUser ?? this.currentUser,
        pubKey: pubKey ?? this.pubKey,
        content: content ?? this.content,
        id: id ?? this.id,
        sig: sig ?? this.sig,
        tags: tags ?? this.tags,
        kind: kind ?? this.kind,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('Nip01EventData(')
          ..write('currentUser: $currentUser, ')
          ..write('pubKey: $pubKey, ')
          ..write('content: $content, ')
          ..write('id: $id, ')
          ..write('sig: $sig, ')
          ..write('tags: $tags, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(currentUser, pubKey, content, id, sig, tags, kind, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Nip01EventData &&
          other.currentUser == this.currentUser &&
          other.pubKey == this.pubKey &&
          other.content == this.content &&
          other.id == this.id &&
          other.sig == this.sig &&
          other.tags == this.tags &&
          other.kind == this.kind &&
          other.createdAt == this.createdAt);
}

class Nip01EventCompanion extends UpdateCompanion<Nip01EventData> {
  final Value<String> currentUser;
  final Value<String> pubKey;
  final Value<String> content;
  final Value<String> id;
  final Value<String> sig;
  final Value<String> tags;
  final Value<int> kind;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const Nip01EventCompanion({
    this.currentUser = const Value.absent(),
    this.pubKey = const Value.absent(),
    this.content = const Value.absent(),
    this.id = const Value.absent(),
    this.sig = const Value.absent(),
    this.tags = const Value.absent(),
    this.kind = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  Nip01EventCompanion.insert({
    required String currentUser,
    required String pubKey,
    required String content,
    required String id,
    required String sig,
    required String tags,
    required int kind,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : currentUser = Value(currentUser),
        pubKey = Value(pubKey),
        content = Value(content),
        id = Value(id),
        sig = Value(sig),
        tags = Value(tags),
        kind = Value(kind),
        createdAt = Value(createdAt);
  static Insertable<Nip01EventData> custom({
    Expression<String>? currentUser,
    Expression<String>? pubKey,
    Expression<String>? content,
    Expression<String>? id,
    Expression<String>? sig,
    Expression<String>? tags,
    Expression<int>? kind,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (currentUser != null) 'current_user': currentUser,
      if (pubKey != null) 'pub_key': pubKey,
      if (content != null) 'content': content,
      if (id != null) 'id': id,
      if (sig != null) 'sig': sig,
      if (tags != null) 'tags': tags,
      if (kind != null) 'kind': kind,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  Nip01EventCompanion copyWith(
      {Value<String>? currentUser,
      Value<String>? pubKey,
      Value<String>? content,
      Value<String>? id,
      Value<String>? sig,
      Value<String>? tags,
      Value<int>? kind,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return Nip01EventCompanion(
      currentUser: currentUser ?? this.currentUser,
      pubKey: pubKey ?? this.pubKey,
      content: content ?? this.content,
      id: id ?? this.id,
      sig: sig ?? this.sig,
      tags: tags ?? this.tags,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (currentUser.present) {
      map['current_user'] = Variable<String>(currentUser.value);
    }
    if (pubKey.present) {
      map['pub_key'] = Variable<String>(pubKey.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sig.present) {
      map['sig'] = Variable<String>(sig.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('Nip01EventCompanion(')
          ..write('currentUser: $currentUser, ')
          ..write('pubKey: $pubKey, ')
          ..write('content: $content, ')
          ..write('id: $id, ')
          ..write('sig: $sig, ')
          ..write('tags: $tags, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DmInfoTable extends DmInfo with TableInfo<$DmInfoTable, DmInfoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DmInfoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _peerPubkeyMeta =
      const VerificationMeta('peerPubkey');
  @override
  late final GeneratedColumn<String> peerPubkey = GeneratedColumn<String>(
      'peer_pubkey', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ownPubkeyMeta =
      const VerificationMeta('ownPubkey');
  @override
  late final GeneratedColumn<String> ownPubkey = GeneratedColumn<String>(
      'own_pubkey', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _readTimeMeta =
      const VerificationMeta('readTime');
  @override
  late final GeneratedColumn<int> readTime = GeneratedColumn<int>(
      'read_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, peerPubkey, ownPubkey, readTime];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dm_info';
  @override
  VerificationContext validateIntegrity(Insertable<DmInfoData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('peer_pubkey')) {
      context.handle(
          _peerPubkeyMeta,
          peerPubkey.isAcceptableOrUnknown(
              data['peer_pubkey']!, _peerPubkeyMeta));
    } else if (isInserting) {
      context.missing(_peerPubkeyMeta);
    }
    if (data.containsKey('own_pubkey')) {
      context.handle(_ownPubkeyMeta,
          ownPubkey.isAcceptableOrUnknown(data['own_pubkey']!, _ownPubkeyMeta));
    } else if (isInserting) {
      context.missing(_ownPubkeyMeta);
    }
    if (data.containsKey('read_time')) {
      context.handle(_readTimeMeta,
          readTime.isAcceptableOrUnknown(data['read_time']!, _readTimeMeta));
    } else if (isInserting) {
      context.missing(_readTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DmInfoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DmInfoData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      peerPubkey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}peer_pubkey'])!,
      ownPubkey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}own_pubkey'])!,
      readTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}read_time'])!,
    );
  }

  @override
  $DmInfoTable createAlias(String alias) {
    return $DmInfoTable(attachedDatabase, alias);
  }
}

class DmInfoData extends DataClass implements Insertable<DmInfoData> {
  final String id;
  final String peerPubkey;
  final String ownPubkey;
  final int readTime;
  const DmInfoData(
      {required this.id,
      required this.peerPubkey,
      required this.ownPubkey,
      required this.readTime});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['peer_pubkey'] = Variable<String>(peerPubkey);
    map['own_pubkey'] = Variable<String>(ownPubkey);
    map['read_time'] = Variable<int>(readTime);
    return map;
  }

  DmInfoCompanion toCompanion(bool nullToAbsent) {
    return DmInfoCompanion(
      id: Value(id),
      peerPubkey: Value(peerPubkey),
      ownPubkey: Value(ownPubkey),
      readTime: Value(readTime),
    );
  }

  factory DmInfoData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DmInfoData(
      id: serializer.fromJson<String>(json['id']),
      peerPubkey: serializer.fromJson<String>(json['peerPubkey']),
      ownPubkey: serializer.fromJson<String>(json['ownPubkey']),
      readTime: serializer.fromJson<int>(json['readTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'peerPubkey': serializer.toJson<String>(peerPubkey),
      'ownPubkey': serializer.toJson<String>(ownPubkey),
      'readTime': serializer.toJson<int>(readTime),
    };
  }

  DmInfoData copyWith(
          {String? id, String? peerPubkey, String? ownPubkey, int? readTime}) =>
      DmInfoData(
        id: id ?? this.id,
        peerPubkey: peerPubkey ?? this.peerPubkey,
        ownPubkey: ownPubkey ?? this.ownPubkey,
        readTime: readTime ?? this.readTime,
      );
  @override
  String toString() {
    return (StringBuffer('DmInfoData(')
          ..write('id: $id, ')
          ..write('peerPubkey: $peerPubkey, ')
          ..write('ownPubkey: $ownPubkey, ')
          ..write('readTime: $readTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, peerPubkey, ownPubkey, readTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DmInfoData &&
          other.id == this.id &&
          other.peerPubkey == this.peerPubkey &&
          other.ownPubkey == this.ownPubkey &&
          other.readTime == this.readTime);
}

class DmInfoCompanion extends UpdateCompanion<DmInfoData> {
  final Value<String> id;
  final Value<String> peerPubkey;
  final Value<String> ownPubkey;
  final Value<int> readTime;
  final Value<int> rowid;
  const DmInfoCompanion({
    this.id = const Value.absent(),
    this.peerPubkey = const Value.absent(),
    this.ownPubkey = const Value.absent(),
    this.readTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DmInfoCompanion.insert({
    required String id,
    required String peerPubkey,
    required String ownPubkey,
    required int readTime,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        peerPubkey = Value(peerPubkey),
        ownPubkey = Value(ownPubkey),
        readTime = Value(readTime);
  static Insertable<DmInfoData> custom({
    Expression<String>? id,
    Expression<String>? peerPubkey,
    Expression<String>? ownPubkey,
    Expression<int>? readTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (peerPubkey != null) 'peer_pubkey': peerPubkey,
      if (ownPubkey != null) 'own_pubkey': ownPubkey,
      if (readTime != null) 'read_time': readTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DmInfoCompanion copyWith(
      {Value<String>? id,
      Value<String>? peerPubkey,
      Value<String>? ownPubkey,
      Value<int>? readTime,
      Value<int>? rowid}) {
    return DmInfoCompanion(
      id: id ?? this.id,
      peerPubkey: peerPubkey ?? this.peerPubkey,
      ownPubkey: ownPubkey ?? this.ownPubkey,
      readTime: readTime ?? this.readTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (peerPubkey.present) {
      map['peer_pubkey'] = Variable<String>(peerPubkey.value);
    }
    if (ownPubkey.present) {
      map['own_pubkey'] = Variable<String>(ownPubkey.value);
    }
    if (readTime.present) {
      map['read_time'] = Variable<int>(readTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DmInfoCompanion(')
          ..write('id: $id, ')
          ..write('peerPubkey: $peerPubkey, ')
          ..write('ownPubkey: $ownPubkey, ')
          ..write('readTime: $readTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $MetadataTable metadata = $MetadataTable(this);
  late final $Nip01EventTable nip01Event = $Nip01EventTable(this);
  late final $DmInfoTable dmInfo = $DmInfoTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [metadata, nip01Event, dmInfo];
}
