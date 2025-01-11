// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:amberflutter/amberflutter.dart';
import 'package:bip340/bip340.dart' as bip340;
import 'package:convert/convert.dart';
import 'package:drift/drift.dart';
import 'package:pointycastle/export.dart';
import 'package:yakihonne/database/cache_database.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/nostr/utils.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

class Event {
  late String id;

  late String pubkey;

  late int createdAt;

  late int kind;

  late List<List<String>> tags;

  String content = '';

  late String sig;

  String? subscriptionId;

  Event(
    this.id,
    this.pubkey,
    this.createdAt,
    this.kind,
    this.tags,
    this.content,
    this.sig, {
    this.subscriptionId,
    bool verify = false,
  }) {
    pubkey = pubkey.toLowerCase();
  }

  Map<String, dynamic> toLocalNip01Event() {
    final serializer = driftRuntimeOptions.defaultSerializer;

    return <String, dynamic>{
      'pubKey': serializer.toJson<String>(pubkey),
      'content': serializer.toJson<String>(content),
      'id': serializer.toJson<String>(id),
      'sig': serializer.toJson<String>(sig),
      'tags': serializer.toJson<String>(jsonEncode(tags)),
      'kind': serializer.toJson<int>(kind),
      'currentUser':
          serializer.toJson<String>(nostrRepository.usm?.pubKey ?? '-1'),
      'createdAt': serializer.toJson<DateTime>(
        DateTime.fromMillisecondsSinceEpoch(createdAt * 1000),
      ),
    };
  }

  factory Event.fromNip01EventData(Nip01EventData nip01eventData) {
    final list = json
        .decode(nip01eventData.tags)
        .map<List<String>>((list) => List<String>.from(list))
        .toList();

    return Event(
      nip01eventData.id,
      nip01eventData.pubKey,
      nip01eventData.createdAt.toSecondsSinceEpoch(),
      nip01eventData.kind,
      list,
      nip01eventData.content,
      nip01eventData.sig,
    );
  }

  factory Event.partial({
    id = '',
    pubkey = '',
    createdAt = 0,
    kind = 1,
    tags = const <List<String>>[],
    content = '',
    sig = '',
    subscriptionId,
    bool verify = false,
  }) {
    return Event(
      id,
      pubkey,
      createdAt,
      kind,
      tags,
      content,
      sig,
      verify: verify,
    );
  }

  /// Instantiate Event object from the minimum available data
  ///
  /// ```dart
  ///Event event = Event.from(
  ///  kind: 1,
  ///  tags: [],
  ///  content: "",
  ///  privkey:
  ///      "5ee1c8000ab28edd64d74a7d951ac2dd559814887b1b9e1ac7c5f89e96125c12",
  ///);
  ///```
  factory Event.from({
    int createdAt = 0,
    required int kind,
    required List<List<String>> tags,
    required String content,
    required String privkey,
    String? subscriptionId,
    bool verify = false,
  }) {
    if (createdAt == 0) createdAt = currentUnixTimestampSeconds();
    final pubkey = bip340.getPublicKey(privkey).toLowerCase();

    final id = _processEventId(
      pubkey,
      createdAt,
      kind,
      tags,
      content,
    );

    final sig = privkey.isEmpty || privkey == 'signer'
        ? ''
        : _processSignature(
            privkey,
            id,
          );

    // Amberflutter().signEvent(currentUser: currentUser, eventJson: eventJson);

    return Event(
      id,
      pubkey,
      createdAt,
      kind,
      tags,
      content,
      sig,
      subscriptionId: subscriptionId,
      verify: verify,
    );
  }

  factory Event.withoutSignature({
    int createdAt = 0,
    required int kind,
    required List<List<String>> tags,
    required String content,
    required String pubkey,
    String? subscriptionId,
    bool verify = false,
  }) {
    if (createdAt == 0) createdAt = currentUnixTimestampSeconds();

    final id = _processEventId(
      pubkey,
      createdAt,
      kind,
      tags,
      content,
    );

    final sig = '';

    return Event(
      id,
      pubkey,
      createdAt,
      kind,
      tags,
      content,
      sig,
      subscriptionId: subscriptionId,
      verify: verify,
    );
  }

  /// Deserialize an event from a JSON
  ///
  /// verify: enable/disable events checks
  ///
  /// This option adds event checks such as id, signature, non-futuristic event: default=True
  ///
  /// Performances could be a reason to disable event checks
  factory Event.fromJson(Map<String, dynamic> json, {bool verify = true}) {
    var tags = (json['tags'] as List<dynamic>)
        .map((e) => (e as List<dynamic>).map((e) => e as String).toList())
        .toList();
    return Event(
      json['id'],
      json['pubkey'],
      json['created_at'],
      json['kind'],
      tags,
      json['content'],
      json['sig'],
      verify: verify,
    );
  }

  /// Serialize an event in JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'pubkey': pubkey,
        'created_at': createdAt,
        'kind': kind,
        'tags': tags,
        'content': content,
        'sig': sig
      };

  String toJsonString() => jsonEncode(
        {
          'id': id,
          'pubkey': pubkey,
          'created_at': createdAt,
          'kind': kind,
          'tags': tags,
          'content': content,
          'sig': sig
        },
      );

  /// Serialize to nostr event message
  /// - ["EVENT", event JSON as defined above]
  /// - ["EVENT", subscription_id, event JSON as defined above]
  String serialize() {
    if (subscriptionId != null) {
      return jsonEncode(['EVENT', subscriptionId, toJson()]);
    } else {
      return jsonEncode(['EVENT', toJson()]);
    }
  }

  factory Event.deserialize(input, {bool verify = true}) {
    Map<String, dynamic> json = {};
    String? subscriptionId;
    if (input.length == 2) {
      json = input[1] as Map<String, dynamic>;
    } else if (input.length == 3) {
      json = input[2] as Map<String, dynamic>;
      subscriptionId = input[1] as String;
    } else {
      throw Exception('invalid input');
    }

    var tags = (json['tags'] as List<dynamic>)
        .map((e) => (e as List<dynamic>)
            .map((e) => e.runtimeType == String ? e as String : '')
            .toList())
        .toList();

    return Event(
      json['id'],
      json['pubkey'],
      json['created_at'],
      json['kind'],
      tags,
      json['content'],
      json['sig'],
      subscriptionId: subscriptionId,
      verify: verify,
    );
  }

  static Event? fromString(String content) {
    try {
      return Event.fromJson(jsonDecode(content));
    } catch (_) {
      return null;
    }
  }

  String getEventId() {
    // Included for minimum breaking changes
    return _processEventId(
      pubkey,
      createdAt,
      kind,
      tags,
      content,
    );
  }

  // Support for [getEventId]
  static String _processEventId(
    String pubkey,
    int createdAt,
    int kind,
    List<List<String>> tags,
    String content,
  ) {
    List data = [0, pubkey.toLowerCase(), createdAt, kind, tags, content];
    String serializedEvent = json.encode(data);
    Uint8List hash = SHA256Digest()
        .process(Uint8List.fromList(utf8.encode(serializedEvent)));
    return hex.encode(hash);
  }

  /// Each user has a keypair. Signatures, public key, and encodings are done according to the Schnorr signatures standard for the curve secp256k1
  /// 64-bytes signature of the sha256 hash of the serialized event data, which is the same as the "id" field
  String getSignature(String privateKey) {
    return _processSignature(privateKey, id);
  }

  // Support for [getSignature]
  static String _processSignature(
    String privateKey,
    String id,
  ) {
    /// aux must be 32-bytes random bytes, generated at signature time.
    /// https://github.com/nbd-wtf/dart-bip340/blob/master/lib/src/bip340.dart#L10
    String aux = generate64RandomHexChars();
    return bip340.sign(privateKey, id, aux);
  }

  /// Verify if event checks such as id, signature, non-futuristic are valid
  /// Performances could be a reason to disable event checks
  bool isValid() {
    String verifyId = getEventId();
    if (createdAt.toString().length == 10 &&
        id == verifyId &&
        bip340.verify(pubkey, id, sig)) {
      return true;
    } else {
      return false;
    }
  }

  bool isFlashNews() {
    final createdAtDate = DateTime.fromMillisecondsSinceEpoch(
      createdAt * 1000,
    );

    String encryption = '';
    bool isFlashNews = false;

    for (var tag in tags) {
      var tagLength = tag.length;

      if (tagLength >= 2 &&
          tag[0] == FN_SEARCH_KEY &&
          tag[1] == FN_SEARCH_VALUE) {
        isFlashNews = true;
      }

      if (tag.first == FN_ENCRYPTION && tag.length > 1) {
        encryption = tag[1];
      }
    }

    if (!isFlashNews || encryption.isEmpty) {
      return false;
    }

    return checkAuthenticity(encryption, createdAtDate);
  }

  bool isBuzzFeed() {
    final createdAtDate = DateTime.fromMillisecondsSinceEpoch(
      createdAt * 1000,
    );

    String encryption = '';
    bool isAiFeed = false;

    for (var tag in tags) {
      var tagLength = tag.length;

      if (tagLength >= 2 &&
          tag[0] == AF_SEARCH_KEY &&
          tag[1] == AF_SEARCH_VALUE) {
        isAiFeed = true;
      }

      if (tag.first == AF_ENCRYPTION && tag.length > 1) {
        encryption = tag[1];
      }
    }

    if (!isAiFeed || encryption.isEmpty) {
      return false;
    }

    return checkAuthenticity(encryption, createdAtDate);
  }

  bool isUncensoredNote() {
    final createdAtDate = DateTime.fromMillisecondsSinceEpoch(
      createdAt * 1000,
    );

    String encryption = '';
    bool isUncensoredNote = false;

    for (var tag in tags) {
      var tagLength = tag.length;

      if (tagLength >= 2 &&
          tag[0] == FN_SEARCH_KEY &&
          tag[1] == UN_SEARCH_VALUE) {
        isUncensoredNote = true;
      }

      if (tag.first == FN_ENCRYPTION && tag.length > 1) {
        encryption = tag[1];
      }
    }

    if (!isUncensoredNote || encryption.isEmpty) {
      return false;
    }

    return checkAuthenticity(encryption, createdAtDate);
  }

  bool isSealedNote() {
    bool isSealed = false;

    for (var tag in tags) {
      var tagLength = tag.length;

      if (tagLength >= 2 &&
          tag[0] == FN_SEARCH_KEY &&
          tag[1] == "SEALED UNCENSORED NOTE") {
        isSealed = true;
      }
    }

    return pubkey == yakihonneHex && isSealed;
  }

  bool isSimpleNote() {
    return !isBuzzFeed() &&
        !isFlashNews() &&
        !isUncensoredNote() &&
        !isSealedNote();
  }

  bool isReply() {
    bool hasETag = false;

    for (final tag in tags) {
      if ((tag.first == 'e' && tag.length > 1) ||
          (tag.first == 'a' && tag.length > 1)) {
        hasETag = true;
      }
    }

    return isSimpleNote() && hasETag;
  }

  bool isUnRate() {
    bool hasEncryption = false;

    for (var tag in tags) {
      if (tag.first == FN_ENCRYPTION && tag.length > 1) {
        hasEncryption = true;
      }
    }

    return hasEncryption && kind == EventKind.REACTION;
  }

  bool isTopicEvent() {
    bool isTopicTag = false;

    for (var tag in tags) {
      if (tag.first == 'd' && tag.length > 1 && tag[1] == yakihonneTopicTag) {
        isTopicTag = true;
      }
    }

    return isTopicTag && kind == EventKind.APP_CUSTOM;
  }

  bool isFollowingYakihonne() {
    if (kind == EventKind.CONTACT_LIST) {
      bool isFollowingYakihonne = false;

      for (var tag in tags) {
        if (tag.first == 'p' && tag.length > 1 && tag[1] == yakihonneHex) {
          isFollowingYakihonne = true;
        }
      }

      return isFollowingYakihonne;
    } else {
      return false;
    }
  }

  bool isVideo() =>
      kind == EventKind.VIDEO_HORIZONTAL || kind == EventKind.VIDEO_VERTICAL;

  bool isCuration() =>
      kind == EventKind.CURATION_ARTICLES || kind == EventKind.CURATION_VIDEOS;

  bool isLongForm() => kind == EventKind.LONG_FORM;

  bool isLongFormDraft() => kind == EventKind.LONG_FORM_DRAFT;

  bool isRelaysList() => kind == EventKind.RELAY_LIST_METADATA;

  bool isUserTagged() {
    bool isTagged = false;

    for (var tag in tags) {
      if (tag.first == 'p' &&
          tag.length >= 2 &&
          tag[1] == nostrRepository.usm!.pubKey) {
        isTagged = true;
      }
    }

    return isTagged;
  }

  bool isQuote() {
    if (kind == EventKind.TEXT_NOTE) {
      for (final tag in tags) {
        if (tag.first == 'q' && tag.length >= 2) {
          return true;
        }
      }

      return false;
    } else {
      return false;
    }
  }

  String? getEventParent() {
    String? selectedTag;

    for (final tag in tags) {
      if (isQuote()) {
        if (tag.first == 'q' && tag.length > 1) {
          selectedTag = tag[1];
        }
      } else {
        if (tag.first == 'e' && tag.length > 1) {
          selectedTag = tag[1];
        }
      }
    }

    return selectedTag;
  }

  DateTime getPublishedAt() {
    DateTime publishedAt =
        DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);

    for (var tag in tags) {
      if (tag.first == 'published_at' && tag.length >= 2) {
        publishedAt = DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(tag[1]) ?? createdAt * 1000,
        );
      }
    }

    return publishedAt;
  }

  bool isAuthor() => pubkey == nostrRepository.usm!.pubKey;

  static Future<Event?> genEvent({
    int createdAt = 0,
    required int kind,
    required List<List<String>> tags,
    required String content,
    required String pubkey,
    required String privkey,
    String? subscriptionId,
    bool verify = false,
  }) async {
    try {
      if (getUserStatus() != UserStatus.UsingPrivKey) {
        BotToastUtils.showError('Error occured while signing the event');
        return null;
      }

      if (createdAt == 0) createdAt = currentUnixTimestampSeconds();

      final id = _processEventId(
        pubkey,
        createdAt,
        kind,
        tags,
        content,
      );

      final sig = privkey.isEmpty || privkey == 'signer'
          ? ''
          : _processSignature(
              privkey,
              id,
            );

      final ev = Event(
        id,
        pubkey,
        createdAt,
        kind,
        tags,
        content,
        sig,
        subscriptionId: subscriptionId,
        verify: verify,
      );

      if (!nostrRepository.isUsingExternalSigner) {
        return ev;
      } else {
        final result = await Amberflutter().signEvent(
          currentUser: pubkey,
          eventJson: jsonEncode(ev.toJson()),
          id: ev.id,
        );

        final signedEv = result['event'];

        if (result['event'] != null) {
          return Event.fromJson(jsonDecode(signedEv));
        } else {
          BotToastUtils.showError('Error occured while signing the event');
          return null;
        }
      }
    } catch (e) {
      BotToastUtils.showError('Error occured while signing the event');

      return null;
    }
  }
}
