// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/database/cache_database.dart';
import 'package:yakihonne/models/event_mem_box.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/enums.dart';

class DMSessionDetail extends Equatable {
  final DMSession dmSession;
  final DMSessionInfo info;
  final DmsType dmsType;

  DMSessionDetail({
    required this.dmSession,
    required this.info,
    required this.dmsType,
  });

  bool hasNewMessage() {
    return dmSession.newestEvent != null &&
        dmSession.newestEvent!.pubkey == info.peerPubkey &&
        (info.readTime == 0 ||
            info.readTime < dmSession.newestEvent!.createdAt);
  }

  @override
  List<Object?> get props => [dmSession, info, dmsType];

  DMSessionDetail copyWith({
    DMSession? dmSession,
    DMSessionInfo? info,
    DmsType? dmsType,
  }) {
    return DMSessionDetail(
      dmSession: dmSession ?? this.dmSession,
      info: info ?? this.info,
      dmsType: dmsType ?? this.dmsType,
    );
  }

  DMSessionDetail clone() {
    return DMSessionDetail(dmSession: dmSession, info: info, dmsType: dmsType);
  }
}

class DMSession extends Equatable {
  final String pubkey;
  final EventMemBox box;

  DMSession({
    required this.box,
    required this.pubkey,
  });

  DMSession clone() {
    return DMSession(
      box: box,
      pubkey: pubkey,
    );
  }

  bool addEvent(Event event) {
    return box.add(event, returnTrueOnNewSources: false);
  }

  void addEvents(List<Event> events) {
    box.addList(events);
  }

  bool doesEventExist(String pubkey) {
    return box.doesEventExist(pubkey);
  }

  Event? get newestEvent {
    return box.newestEvent;
  }

  int length() {
    return box.length();
  }

  List<Event> getAll() {
    return box.getAll();
  }

  int getIndexById(String id) {
    return box.getIndexById(id);
  }

  Event? getByIndex(int index) {
    if (box.length() <= index) {
      return null;
    }

    return box.getByIndex(index);
  }

  Event? getById(String id) {
    return box.getById(id);
  }

  int lastTime() {
    return box.newestEvent!.createdAt;
  }

  @override
  List<Object?> get props => [box, pubkey];

  DMSession copyWith({
    String? pubkey,
    EventMemBox? box,
  }) {
    return DMSession(
      pubkey: pubkey ?? this.pubkey,
      box: box ?? this.box,
    );
  }
}

class DMSessionInfo extends Equatable {
  final String id;
  final String peerPubkey;
  final String ownPubkey;
  final int readTime;

  DMSessionInfo({
    required this.id,
    required this.peerPubkey,
    required this.ownPubkey,
    required this.readTime,
  });

  Map<String, dynamic> toLocalDmInfoData() {
    final serializer = driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'peerPubkey': serializer.toJson<String>(peerPubkey),
      'ownPubkey': serializer.toJson<String>(ownPubkey),
      'readTime': serializer.toJson<int>(readTime),
    };
  }

  factory DMSessionInfo.fromDmInfoData(DmInfoData dmInfoData) {
    return DMSessionInfo(
      id: dmInfoData.id,
      ownPubkey: dmInfoData.ownPubkey,
      peerPubkey: dmInfoData.peerPubkey,
      readTime: dmInfoData.readTime,
    );
  }

  DMSessionInfo copyWith({
    String? id,
    String? peerPubkey,
    String? ownPubkey,
    bool? known,
    int? readTime,
  }) {
    return DMSessionInfo(
      id: id ?? this.id,
      peerPubkey: peerPubkey ?? this.peerPubkey,
      ownPubkey: ownPubkey ?? this.ownPubkey,
      readTime: readTime ?? this.readTime,
    );
  }

  @override
  List<Object?> get props => [
        id,
        peerPubkey,
        ownPubkey,
        readTime,
      ];
}
