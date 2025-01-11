class EventKind {
  static const int METADATA = 0;

  static const int TEXT_NOTE = 1;

  static const int RECOMMEND_SERVER = 2;

  static const int CONTACT_LIST = 3;

  static const int DIRECT_MESSAGE = 4;

  static const int EVENT_DELETION = 5;

  static const int REPOST = 6;

  static const int REACTION = 7;

  static const int BADGE_AWARD = 8;

  static const int SEALED_EVENT = 13;

  static const int PRIVATE_DIRECT_MESSAGE = 14;

  static const int GENERIC_REPOST = 16;

  static const int GIFT_WRAP = 1059;

  static const int FILE_METADATA = 1063;

  static const int REPORTING = 1984;

  static const int COMMUNITY_APPROVED = 4550;

  static const int POLL = 6969;

  static const int ZAP_REQUEST = 9734;

  static const int ZAP = 9735;

  static const int MUTE_LIST = 10000;

  static const int RELAY_LIST_METADATA = 10002;

  static const int NWC_INFO = 13194;

  static const int AUTHENTICATION = 22242;

  static const int NWC_REQUEST = 23194;

  static const int NWC_RESPONSE = 23195;

  static const int HTTP_AUTH = 27235;

  static const int CATEGORIZED_BOOKMARK = 30003;

  static const int CURATION_ARTICLES = 30004;

  static const int CURATION_VIDEOS = 30005;

  static const int BADGE_ACCEPT = 30008;

  static const int BADGE_DEFINITION = 30009;

  static const int LONG_FORM = 30023;

  static const int LONG_FORM_DRAFT = 30024;

  static const int SMART_WIDGET = 30031;

  static const int VIDEO_HORIZONTAL = 34235;

  static const int VIDEO_VERTICAL = 34236;

  static const int VIDEO_VIEW = 34237;

  static const int COMMUNITY_DEFINITION = 34550;

  static const int APP_CUSTOM = 30078;

  static const int APPLICATION_INFO = 31990;

  static const int APPLICATIONS_REFERENCE = 31989;
}

class PointsActions {
  static const NEW_ACCOUNT = 'new_account';

  static const USERNAME = 'username';

  static const BIO = 'bio';

  static const PROFILE_PICTURE = 'profile_picture';

  static const COVER = 'cover';

  static const NIP05 = 'nip05';

  static const LUDS = 'luds';

  static const RELAYS_SETUP = 'relays_setup';

  static const TOPICS_SETUP = 'topics_setup';

  static const FOLLOW_YAKI = 'follow_yaki';

  static const FLASHNEWS_DRAFT = 'flashnews_draft';

  static const FLASHNEWS_POST = 'flashnews_post';

  static const UN_WRITE = 'un_write';

  static const UN_RATE = 'un_rate';

  static const CURATION_POST = 'curation_post';

  static const ARTICLE_POST = 'article_post';

  static const ARTICLE_DRAFT = 'article_draft';

  static const VIDEO_POST = 'video_post';

  static const BOOKMARK = 'bookmark';

  static const ZAP1 = 'zap-1';

  static const ZAP20 = 'zap-20';

  static const ZAP60 = 'zap-60';

  static const ZAP100 = 'zap-100';

  static const DMS = 'dms-5';

  static const DMSYAKI = 'dms-10';

  static const reaction = 'reaction';

  static const COMMENT_POST = 'comment_post';
}

class Pastables {
  static const IMAGE_FORMAT_JPG = '.jpg';

  static const IMAGE_FORMAT_JPEG = '.jpeg';

  static const IMAGE_FORMAT_GIF = '.gif';

  static const IMAGE_FORMAT_PNG = '.png';

  static const IMAGE_FORMAT_WEBP = '.webp';

  static const NOSTR_SCHEME_NPROFILE = 'nprofile';

  static const NOSTR_SCHEME_NADDR = 'naddr';

  static const VIDEO_FORMAT_MP4 = '.mp4';
}

class UploadServers {
  static const YAKIHONNE = 'yakihonne';

  static const NOSTR_BUILD = 'nostr.build ';

  static String getUploadServer(String uploadServer) {
    if (uploadServer == YAKIHONNE || uploadServer == NOSTR_BUILD) {
      return uploadServer;
    } else {
      return NOSTR_BUILD;
    }
  }
}
