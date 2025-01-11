// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/nostr/nostr.dart';

class EventRelation {
  late String id;

  late String pubkey;

  late int kind;

  late Event origin;

  List<String> tagPList = [];

  List<String> tagEList = [];

  String? rootId;

  String? rRootId;

  String? rootRelayAddr;

  String? replyId;

  String? replyRelayAddr;

  String? subject;

  bool warning = false;

  bool isFlashNews() {
    for (var tag in origin.tags) {
      var tagLength = tag.length;

      if (tagLength >= 2 &&
          tag[0] == FN_SEARCH_KEY &&
          tag[1] == FN_SEARCH_VALUE) {
        return true;
      }
    }

    return false;
  }

  bool isUncensoredNote() => origin.isUncensoredNote();

  EventRelation.fromEvent(Event event) {
    id = event.id;
    pubkey = event.pubkey;
    kind = event.kind;
    origin = event;

    Map<String, int> pMap = {};
    var length = event.tags.length;
    for (var i = 0; i < length; i++) {
      var tag = event.tags[i];

      var mentionStr = '#[$i]';

      if (event.content.contains(mentionStr)) {
        continue;
      }

      var tagLength = tag.length;
      if (tagLength > 1) {
        var tagKey = tag[0];
        var value = tag[1];
        if (tagKey == 'p') {
          var nip19Str = 'nostr:${Nip19.encodePubkey(value)}';
          if (event.content.contains(nip19Str)) {
            continue;
          }

          nip19Str = Nip19.encodeShareableEntity(
            'nprofile',
            event.pubkey,
            [],
            null,
            null,
          );

          if (event.content.contains(nip19Str)) {
            continue;
          }

          pMap[value] = 1;
        } else if (tagKey == 'e') {
          tagEList.add(value);

          if (tagLength > 3) {
            var marker = tag[3];
            if (marker == 'reply') {
              replyId = value;
              replyRelayAddr = tag[2];
            } else if (marker == 'root') {
              rootId = value;
              rootRelayAddr = tag[2];
            }
          } else {
            rootId = tag[1];
          }
        } else if (tagKey == 'a') {
          if (tagLength >= 2) {
            rRootId = value.split(':').last;
          }
        } else if (tagKey == 'subject') {
          subject = value;
        } else if (tagKey == 'content-warning') {
          warning = true;
        }
      }
    }

    var tagELength = tagEList.length;
    if (tagELength == 1 && rootId == null) {
      if (rRootId == null) rootId = tagEList[0];
    } else if (tagELength > 1) {
      if (rootId == null && replyId == null) {
        if (rRootId == null) rootId = tagEList.first;
        replyId = tagEList.last;
      } else if (rootId != null && replyId == null) {
        for (var i = tagELength - 1; i > -1; i--) {
          var id = tagEList[i];
          if (id != rootId) {
            replyId = id;
          }
        }
      } else if (rootId == null && replyId != null) {
        for (var i = 0; i < tagELength; i++) {
          var id = tagEList[i];
          if (id != replyId) {
            if (rRootId == null) rootId = id;
          }
        }
      } else {
        if (rRootId == null) rootId ??= tagEList.first;
        replyId ??= tagEList.last;
      }
    }

    if (rootId != null && replyId == rootId && rootRelayAddr == null) {
      rootRelayAddr = replyRelayAddr;
    }

    pMap.remove(event.pubkey);
    tagPList.addAll(pMap.keys);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'pubkey': pubkey,
      'kind': kind,
      'origin': origin,
      'tagPList': tagPList,
      'tagEList': tagEList,
      'rootId': rootId,
      'rRootId': rRootId,
      'rootRelayAddr': rootRelayAddr,
      'replyId': replyId,
      'replyRelayAddr': replyRelayAddr,
      'subject': subject,
      'warning': warning,
    };
  }
}
