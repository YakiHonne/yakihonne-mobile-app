import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:amberflutter/amberflutter.dart';
import 'package:convert/convert.dart';
import 'package:pointycastle/export.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/utils.dart';

/// Encrypted Direct Message
class Nip4 {
  static var secp256k1 = ECDomainParameters('secp256k1');

  static ECDHBasicAgreement getAgreement(String sk) {
    var skD0 = BigInt.parse(sk, radix: 16);
    var privateKey = ECPrivateKey(skD0, secp256k1);

    var agreement = ECDHBasicAgreement();
    agreement.init(privateKey);

    return agreement;
  }

  static String encryptData(
    String message,
    ECDHBasicAgreement agreement,
    String pk,
  ) {
    var pubKey = getPubKey(pk);
    var agreementD0 = agreement.calculateAgreement(pubKey);
    var encryptKey = agreementD0.toRadixString(16).padLeft(64, '0');

    final random = Random.secure();

    var ivData =
        Uint8List.fromList(List<int>.generate(16, (i) => random.nextInt(256)));
    // var iv = "UeAMaJl5Hj6IZcot7zLfmQ==";
    // var ivData = base64.decode(iv);

    final cipherCbc =
        PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()));

    final paramsCbc = PaddedBlockCipherParameters(
      ParametersWithIV(
        KeyParameter(
          Uint8List.fromList(
            hex.decode(encryptKey),
          ),
        ),
        ivData,
      ),
      null,
    );

    cipherCbc.init(true, paramsCbc);

    // print(cipherCbc.algorithmName);

    var result = cipherCbc.process(Uint8List.fromList(utf8.encode(message)));

    return base64.encode(result) + '?iv=' + base64.encode(ivData);
  }

  static String decryptData(
    String message,
    ECDHBasicAgreement agreement,
    String pk,
  ) {
    var strs = message.split('?iv=');
    if (strs.length != 2) {
      return '';
    }
    message = strs[0];
    var iv = strs[1];
    var ivData = base64.decode(iv);

    var pubKey = getPubKey(pk);
    var agreementD0 = agreement.calculateAgreement(pubKey);
    var encryptKey = agreementD0.toRadixString(16).padLeft(64, '0');

    // var encrypter = Encrypter(AES(
    //     Key(Uint8List.fromList(hex.decode(encryptKey))),
    //     mode: AESMode.cbc));
    // return encrypter.decrypt(Encrypted.from64(message), iv: IV.fromBase64(iv));

    final cipherCbc =
        PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()));
    final paramsCbc = PaddedBlockCipherParameters(
        ParametersWithIV(
            KeyParameter(Uint8List.fromList(hex.decode(encryptKey))), ivData),
        null);
    cipherCbc.init(false, paramsCbc);

    var result = cipherCbc.process(base64.decode(message));

    return utf8.decode(result);
  }

  static ECPublicKey getPubKey(String pk) {
    // BigInt x = BigInt.parse(pk, radix: 16);
    BigInt x =
        BigInt.parse(hex.encode(hex.decode(pk.padLeft(64, '0'))), radix: 16);
    BigInt? y;
    try {
      y = liftX(x);
    } on Error {
      print('error in handle pubKey');
    }
    ECPoint endPoint = secp256k1.curve.createPoint(x, y!);
    return ECPublicKey(endPoint, secp256k1);
  }

  static var curveP = BigInt.parse(
    'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F',
    radix: 16,
  );

  // helper methods:
  // liftX returns Y for this X
  static BigInt liftX(BigInt x) {
    if (x >= curveP) {
      throw new Error();
    }
    var ySq = (x.modPow(BigInt.from(3), curveP) + BigInt.from(7)) % curveP;
    var y = ySq.modPow((curveP + BigInt.one) ~/ BigInt.from(4), curveP);
    if (y.modPow(BigInt.two, curveP) != ySq) {
      throw new Error();
    }
    return y % BigInt.two == BigInt.zero /* even */ ? y : curveP - y;
  }

  static String generate16RandomHexChars() {
    final random = Random.secure();
    final randomBytes = List<int>.generate(16, (i) => random.nextInt(256));
    return hex.encode(randomBytes);
  }

  static Future<EDMessage?> decode(
      Event event, String myPubkey, String privkey) async {
    if (event.kind == 4) {
      return await _toEDMessage(event, myPubkey, privkey);
    }
    return null;
  }

  /// Returns EDMessage from event
  static Future<EDMessage> _toEDMessage(
      Event event, String myPubkey, String privkey) async {
    String sender = event.pubkey;
    int createdAt = event.createdAt;
    String receiver = "";
    String replyId = "";
    String content = "";
    String subContent = event.content;
    String? expiration;
    for (var tag in event.tags) {
      if (tag[0] == "p") receiver = tag[1];
      if (tag[0] == "e") replyId = tag[1];
      if (tag[0] == "subContent") subContent = tag[1];
      if (tag[0] == "expiration") expiration = tag[1];
    }
    if (receiver.compareTo(myPubkey) == 0) {
      content = await decryptContent(subContent, sender, myPubkey, privkey);
    } else if (sender.compareTo(myPubkey) == 0) {
      content = await decryptContent(subContent, receiver, myPubkey, privkey);
    } else {
      throw Exception("not correct receiver, is not nip4 compatible");
    }

    return EDMessage(sender, receiver, createdAt, content, replyId, expiration);
  }

  static Future<String> decryptContent(
    String content,
    String peerPubkey,
    String myPubkey,
    String privkey,
  ) async {
    int ivIndex = content.indexOf("?iv=");
    if (ivIndex <= 0) {
      print("Invalid content for dm, could not get ivIndex: $content");
      return "";
    }
    String iv = content.substring(ivIndex + "?iv=".length, content.length);
    String encString = content.substring(0, ivIndex);
    try {
      if (nostrRepository.isUsingExternalSigner) {
        final result = await Amberflutter().nip04Decrypt(
          ciphertext: content,
          currentUser: myPubkey,
          pubKey: peerPubkey,
        );
        return result['event'];
      } else {
        return decrypt(privkey, '02$peerPubkey', encString, iv);
      }
    } catch (e) {
      lg.i(e);
      return "";
    }
  }

  static Future<Event?> encode(
    String sender,
    String receiver,
    String content,
    String replyId,
    String privkey, {
    String? subContent,
    int? expiration,
  }) async {
    String enContent = await encryptContent(content, receiver, sender, privkey);
    List<List<String>> tags = toTags(receiver, replyId, expiration);
    if (subContent != null && subContent.isNotEmpty) {
      String enSubContent = await encryptContent(
        subContent,
        receiver,
        sender,
        privkey,
      );

      tags.add(['subContent', enSubContent]);
    }

    Event? event = await Event.genEvent(
      kind: 4,
      tags: tags,
      content: enContent,
      privkey: privkey,
      pubkey: sender,
    );

    return event;
  }

  static Future<String> encryptContent(
    String plainText,
    String peerPubkey,
    String myPubkey,
    String privkey,
  ) async {
    if (nostrRepository.isUsingExternalSigner) {
      final result = await Amberflutter().nip04Encrypt(
        plaintext: plainText,
        currentUser: myPubkey,
        pubKey: peerPubkey,
      );

      return result['event'];
    } else {
      return encrypt(privkey, '02$peerPubkey', plainText);
    }
  }

  static List<List<String>> toTags(String p, String e, int? expiration) {
    List<List<String>> result = [];
    result.add(["p", p]);
    if (e.isNotEmpty) result.add(["e", e, '', 'reply']);
    if (expiration != null) result.add(['expiration', expiration.toString()]);
    return result;
  }
}

/// ```
class EDMessage {
  String sender;

  String receiver;

  int createdAt;

  String content;

  String replyId;

  String? expiration;

  /// Default constructor
  EDMessage(this.sender, this.receiver, this.createdAt, this.content,
      this.replyId, this.expiration);
}
