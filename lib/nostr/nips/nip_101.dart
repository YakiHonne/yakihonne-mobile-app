// /// nip 101 - alias exchange
// ///
// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:bip340/bip340.dart' as bip340;
// import 'package:convert/convert.dart';
// import 'package:kepler/kepler.dart';
// import 'package:pointycastle/digests/sha256.dart';
// import 'package:yakihonne/nostr/nostr.dart';

// class Nip101 {
//   static String generateId(List data) {
//     String serializedEvent = json.encode(data);
//     Uint8List hash = SHA256Digest()
//         .process(Uint8List.fromList(utf8.encode(serializedEvent)));
//     return hex.encode(hash);
//   }

//   static String getSig(List data, String privateKey) {
//     String aux = generate64RandomHexChars();
//     return bip340.sign(privateKey, generateId(data), aux);
//   }

//   static Uint8List getSharedSecret(String privateString, String publicString) {
//     List<List<int>> byteSecret =
//         Kepler.byteSecret(privateString, '02$publicString');
//     final secretIV = byteSecret;
//     return Uint8List.fromList(secretIV[0]);
//   }

//   static bool isValid(String verifyId, String pubkey, String sig) {
//     if (bip340.verify(pubkey, verifyId, sig)) {
//       return true;
//     } else {
//       return false;
//     }
//   }

//   static Future<String> encryptContent(
//     int createdAt,
//     String fromPubkey,
//     String fromPrivkey,
//     String fromAliasPrivkey,
//     String toPubkey,
//     String content,
//   ) async {
//     String sig = getSig([createdAt, fromPubkey, content], fromPrivkey);
//     Map<String, dynamic> map = {
//       'p': fromPubkey,
//       'content': content,
//       'sig': sig,
//     };
//     String encodeContent = jsonEncode(map);
//     String enContent = await Nip4.encryptContent(
//       encodeContent,
//       toPubkey,
//       fromPubkey,
//       fromAliasPrivkey,
//     );
//     return enContent;
//   }

//   static Future<Map<String, dynamic>> decryptContent(
//     int createdAt,
//     String enContent,
//     String privkey,
//     String sender,
//   ) async {
//     String content = await Nip4.decryptContent(
//       enContent,
//       sender,
//       Keychain.getPublicKey(privkey),
//       privkey,
//     );

//     Map map = jsonDecode(content);
//     String id = generateId([createdAt, map['p'], map['content']]);
//     if (isValid(id, map['p'], map['sig'])) {
//       return jsonDecode(content);
//     }
//     throw Exception('not valid sig in content!');
//   }

//   static String aliasPrivkey(String toPubkey, String privkey) {
//     final secretIV = Kepler.byteSecret(privkey, '02$toPubkey');
//     Uint8List tweak = Uint8List.fromList(secretIV[0]);
//     Uint8List aliasPrivateKey = tweakAdd(hexToBytes(privkey), tweak);
//     return bytesToHex(aliasPrivateKey);
//   }

//   /// encrypt share secret = (fromAliasPrivkey, toPubkey)
//   /// decrypt share secret = (fromPrivkey, toAliasPubkey)
//   /// send request then listen event: p = fromAliasPubkey
//   static Event request(
//       String fromPubkey,
//       String fromPrivkey,
//       String fromAliasPubkey,
//       String fromAliasPrivkey,
//       String toPubkey,
//       String requestContent) {
//     int createdAt = currentUnixTimestampSeconds();
//     return Event.from(
//       createdAt: createdAt,
//       kind: 10100,
//       tags: [
//         ['p', toPubkey]
//       ],
//       content: encryptContent(createdAt, fromPubkey, fromPrivkey,
//           fromAliasPrivkey, toPubkey, requestContent),
//       privkey: fromAliasPrivkey,
//     );
//   }

//   /// encrypt share secret = (fromAliasPrivkey, toAliasPubkey)
//   /// decrypt share secret = (fromAliasPrivkey, toAliasPubkey)
//   static Event accept(String fromPubkey, String fromPrivkey,
//       String fromAliasPubkey, String fromAliasPrivkey, String toAliasPubkey) {
//     int createdAt = currentUnixTimestampSeconds();
//     return Event.from(
//         createdAt: createdAt,
//         kind: 10101,
//         tags: [
//           ['p', toAliasPubkey]
//         ],
//         content: encryptContent(createdAt, fromPubkey, fromPrivkey,
//             fromAliasPrivkey, toAliasPubkey, 'accept'),
//         privkey: fromAliasPrivkey);
//   }

//   /// encrypt share secret = (fromAliasPrivkey, toAliasPubkey)
//   /// decrypt share secret = (fromAliasPrivkey, toAliasPubkey)
//   static Event reject(String fromPubkey, String fromPrivkey,
//       String fromAliasPubkey, String fromAliasPrivkey, String toAliasPubkey) {
//     int createdAt = currentUnixTimestampSeconds();
//     return Event.from(
//         createdAt: createdAt,
//         kind: 10102,
//         tags: [
//           ['p', toAliasPubkey]
//         ],
//         content: encryptContent(createdAt, fromPubkey, fromPrivkey,
//             fromAliasPrivkey, toAliasPubkey, 'reject'),
//         privkey: fromAliasPrivkey);
//   }

//   /// encrypt share secret = (fromAliasPrivkey, toAliasPubkey)
//   /// decrypt share secret = (fromAliasPrivkey, toAliasPubkey)
//   static Event remove(String fromPubkey, String fromPrivkey,
//       String fromAliasPubkey, String fromAliasPrivkey, String toAliasPubkey) {
//     int createdAt = currentUnixTimestampSeconds();
//     return Event.from(
//         createdAt: createdAt,
//         kind: 10103,
//         tags: [
//           ['p', toAliasPubkey]
//         ],
//         content: encryptContent(createdAt, fromPubkey, fromPrivkey,
//             fromAliasPrivkey, toAliasPubkey, 'remove'),
//         privkey: fromAliasPrivkey);
//   }

//   static String getP(Event event) {
//     if (event.tags[0].length > 1 && event.tags[0][0] == 'p') {
//       return event.tags[0][1];
//     }
//     return '';
//   }

//   static Alias getRequest(Event event, String pubkey, String privkey) {
//     Map<String, dynamic> map =
//         decryptContent(event.createdAt, event.content, privkey, event.pubkey);
//     return Alias(pubkey, '', map['p'], event.pubkey, map['content'], event.kind,
//         event.createdAt);
//   }

//   static Alias getAccept(
//       Event event, String pubkey, String aliasPubkey, String aliasPrikey) {
//     Map<String, dynamic> map = decryptContent(
//         event.createdAt, event.content, aliasPrikey, event.pubkey);
//     return Alias(pubkey, aliasPubkey, map['p'], event.pubkey, map['content'],
//         event.kind, event.createdAt);
//   }

//   static Alias getReject(
//       Event event, String pubkey, String aliasPubkey, String aliasPrikey) {
//     Map<String, dynamic> map = decryptContent(
//         event.createdAt, event.content, aliasPrikey, event.pubkey);
//     return Alias(pubkey, aliasPubkey, map['p'], event.pubkey, map['content'],
//         event.kind, event.createdAt);
//   }

//   static Alias getRemove(
//       Event event, String pubkey, String aliasPubkey, String aliasPrikey) {
//     Map<String, dynamic> map = decryptContent(
//         event.createdAt, event.content, aliasPrikey, event.pubkey);
//     return Alias(pubkey, aliasPubkey, map['p'], event.pubkey, map['content'],
//         event.kind, event.createdAt);
//   }
// }

// class Alias {
//   String fromPubkey;
//   String fromAliasPubkey;
//   String toPubkey;
//   String toAliasPubkey;

//   String content;
//   int kind;
//   int createTime;

//   Alias(this.fromPubkey, this.fromAliasPubkey, this.toPubkey,
//       this.toAliasPubkey, this.content, this.kind, this.createTime);
// }
