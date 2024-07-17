//Text Note References
import 'package:yakihonne/nostr/nips/nip_019.dart';
import 'package:yakihonne/nostr/nips/nip_021.dart';

class Nip27 {
  static List<ProfileMention> decodeProfileMention(String content) {
    RegExp regex = RegExp(r'nostr:.*?(?=\s|$)');
    Iterable<Match> matches = regex.allMatches(content);
    List<ProfileMention> mentions = [];
    for (Match match in matches) {
      String? group = match.group(0);
      if (group != null) {
        String? uri = Nip21.decode(group);
        if (uri != null) {
          Map<String, dynamic> map = Nip19.decodeShareableEntity(uri);
          if (map['prefix'] == 'nprofile') {
            String pubkey = map['special'];
            if (pubkey.isNotEmpty) {
              mentions.add(ProfileMention(
                  match.start, match.end, pubkey, map['relays']));
            }
          }
        }
      }
    }
    return mentions;
  }

  static String encodeProfileMention(
    List<ProfileMention> mentions,
    String content,
  ) {
    int offset = 0;
    for (ProfileMention mention in mentions) {
      String encodeProfile = Nip21.encode(
        Nip19.encodeShareableEntity(
          'nprofile',
          mention.pubkey,
          mention.relays,
          null,
          null,
        ),
      );
      String subString =
          content.substring(mention.start + offset, mention.end + offset);
      content = content.replaceFirst(
          subString, encodeProfile, mention.start + offset);
      int lengthDiff = encodeProfile.length - subString.length;
      offset += lengthDiff;
    }
    return content;
  }
}

class ProfileMention {
  int start;
  int end;
  String pubkey;
  List<String> relays;

  ProfileMention(this.start, this.end, this.pubkey, this.relays);
}
