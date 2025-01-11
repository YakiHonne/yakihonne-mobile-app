import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/database/cache_database.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/nostr/zaps/zap.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';

class UserModel extends Equatable {
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
  final String picturePlaceholder;
  final String bannerPlaceholder;
  final List<Profile> followings;

  UserModel({
    required this.pubKey,
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
    required this.isDeleted,
    required this.followings,
    this.picturePlaceholder = '',
    this.bannerPlaceholder = '',
  }) : super();

  Map<String, dynamic> toMetadata() {
    return <String, dynamic>{
      'name': name,
      'display_name': displayName,
      'about': about,
      'picture': picture,
      'banner': banner,
      'website': website,
      'nip05': nip05,
      'lud16': lud16,
      'lud06': lud06,
      'deleted': isDeleted,
    };
  }

  Map<String, dynamic> toLocalMetadata() {
    final serializer = driftRuntimeOptions.defaultSerializer;

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

  Map<String, dynamic> toEmptyMap() {
    return <String, dynamic>{
      'name': 'unknown',
      'about': 'account deleted',
      'deleted': true,
    };
  }

  factory UserModel.fromMap(
    Map<String, dynamic> map, {
    String? pubKey,
    List<List<String>>? tags,
    int? createdAt,
  }) {
    final name = map['name'] as String? ?? '';
    final displayName = map['display_name'] as String? ?? '';

    final picturePlaceholder = getRandomPlaceholder(
      input: pubKey ?? 'default',
      isPfp: true,
    );

    final bannerPlaceholder = getRandomPlaceholder(
      input: pubKey ?? 'default',
      isPfp: false,
    );

    return UserModel(
      pubKey: pubKey ?? '',
      name: displayName.isNotEmpty ? displayName : name,
      displayName: displayName,
      about: map['about'] as String? ?? '',
      picture: map['picture'] as String? ?? '',
      banner: map['banner'] as String? ?? '',
      website: map['website'] as String? ?? '',
      nip05: map['nip05'] as String? ?? '',
      lud16: map['lud16'] as String? ?? '',
      lud06: map['lud06'] as String? ?? '',
      createdAt: createdAt != null
          ? DateTime.fromMillisecondsSinceEpoch(createdAt * 1000)
          : DateTime.now(),
      followings: Nip2.toProfiles(tags ?? []),
      isDeleted: map['deleted'] as bool? ?? false,
      picturePlaceholder: picturePlaceholder,
      bannerPlaceholder: bannerPlaceholder,
    );
  }

  factory UserModel.fromMetadata(MetadataData metadata) {
    final picturePlaceholder = getRandomPlaceholder(
      input: metadata.pubKey,
      isPfp: true,
    );

    final bannerPlaceholder = getRandomPlaceholder(
      input: metadata.pubKey,
      isPfp: false,
    );

    return UserModel(
      pubKey: metadata.pubKey,
      name: metadata.displayName.isNotEmpty
          ? metadata.displayName
          : metadata.name,
      displayName: metadata.displayName,
      about: metadata.about,
      picture: metadata.picture,
      banner: metadata.banner,
      website: metadata.website,
      nip05: metadata.nip05,
      lud16: metadata.lud16,
      lud06: metadata.lud06,
      createdAt: metadata.createdAt,
      followings: Nip2.toProfiles([]),
      isDeleted: metadata.isDeleted,
      picturePlaceholder: picturePlaceholder,
      bannerPlaceholder: bannerPlaceholder,
    );
  }

  bool canBeZapped() {
    String? lnurl = lud06;

    if (StringUtil.isBlank(lnurl) || !lnurl.toLowerCase().startsWith('lnurl')) {
      if (StringUtil.isNotBlank(lud16)) {
        lnurl = Zap.getLnurlFromLud16(lud16);
      } else {
        lnurl = '';
      }
    }

    if (StringUtil.isBlank(lnurl)) {
      BotToast.showText(text: 'Lnurl not found');
      return false;
    } else {
      return true;
    }
  }

  factory UserModel.fromDirectMap(
    Map<String, dynamic> map,
  ) {
    final name = map['name'] as String? ?? '';
    final displayName = map['display_name'] as String? ?? '';
    final userPubkey = map['pubkey'] as String? ?? '';

    final picturePlaceholder = getRandomPlaceholder(
      input: userPubkey,
      isPfp: true,
    );

    final bannerPlaceholder = getRandomPlaceholder(
      input: userPubkey,
      isPfp: false,
    );

    return UserModel(
      pubKey: userPubkey,
      name: displayName.isNotEmpty ? displayName : name,
      displayName: displayName,
      about: map['about'] as String? ?? '',
      picture: map['picture'] as String? ?? '',
      banner: map['banner'] as String? ?? '',
      website: map['website'] as String? ?? '',
      nip05: map['nip05'] as String? ?? '',
      lud16: map['lud16'] as String? ?? '',
      lud06: map['lud06'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['created_at'] as num).toInt() * 1000)
          : DateTime(2000),
      followings: [],
      isDeleted: map['deleted'] as bool? ?? false,
      picturePlaceholder: picturePlaceholder,
      bannerPlaceholder: bannerPlaceholder,
    );
  }

  String toJson() => json.encode(toMetadata());
  String toEmptyJson() => json.encode(toEmptyMap());

  factory UserModel.fromJson(
    String source,
    String? pubKey,
    List<List<String>>? tags,
    int? createdAt,
  ) {
    return UserModel.fromMap(
      json.decode(source) as Map<String, dynamic>,
      pubKey: pubKey,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
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
        isDeleted,
        picturePlaceholder,
        bannerPlaceholder,
      ];

  UserModel copyWith({
    String? pubKey,
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
    bool? isDeleted,
    List<Profile>? followings,
    String? picturePlaceholder,
    String? bannerPlaceholder,
  }) {
    return UserModel(
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
      followings: followings ?? this.followings,
      picturePlaceholder: picturePlaceholder ?? this.picturePlaceholder,
      bannerPlaceholder: bannerPlaceholder ?? this.bannerPlaceholder,
    );
  }
}
