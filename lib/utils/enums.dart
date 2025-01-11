enum AppTheme { purpleWhite, purpleDark }

enum CurrentRoute { onboarding, disclosure, main }

enum UpdatingState {
  idle,
  progress,
  failure,
  success,
  networkFailure,
  wrongCredentials
}

enum MainViews {
  home,
  curations,
  selfCurations,
  selfArticles,
  settings,
  properties,
  search,
  bookmarks,
  flashNews,
  notifications,
  selfFlashNews,
  uncensoredNotes,
  videosFeed,
  dms,
  selfVideos,
  buzzFeed,
  articles,
  notes,
  polls,
  wallet,
  selfNotes,
  smartWidgets,
  selfSmartWidgets,
}

enum FlashNewsType {
  userActive,
  userPending,
  public,
  display,
  publicWithoutSealed
}

enum AuthenticationViews {
  initial,
  login,
  generateKeys,
  pictureSelection,
  nameSelection
}

enum SearchResultsType { noSearch, content, loading }

enum NoteStatType { reaction, repost, quote }

enum PropertiesViews { main, banner, profilePicture, relays }

enum PicturesType { defaultPicture, localPicture, linkPicture }

enum PropertiesToggle { none, nip05, lightning, personal, comments, wallets }

enum AccountStatus { available, deleted, error }

enum ThreadsType { flash, article, curation, horizontalVideo, aiFeedDetails }

enum ContentType { flashNews, article, curation, video, buzzfeed, note }

enum ArticleFilter { All, Published, Drafts }

enum VideoFilter { All, horizontal, vertical }

enum ProfileStatus { available, notAvailable, loading }

enum CommentPrefixStatus { notUsed, used, notSet }

enum AddUncensoredNote { enabled, added, disabled }

enum ArticleCuration { curationsList, curationContent, zaps, relays }

enum WritingNoteStatus { disabled, alreadyWritten, canBeWritten }

enum RewardStatus { not_claimed, in_progress, claimed }

enum UrlType { image, video, text, audio }

enum VideosKinds { youtube, vimeo, regular }

enum DmsType { all, followings, known, unknown }

enum GiphyType { gifs, stickers }

enum ArticlePublishSteps { content, details, zaps, publish }

enum FlashNewsPublishSteps { content, relays, payment }

enum VideoPublishSteps { content, specifications, zaps, relays }

enum SmartWidgetPublishSteps { content, specifications }

enum CurationPublishSteps { content, zaps, relays }

enum FlashNewsKinds { plain, article, curation }

enum VideoSourceType { gallery, link, kind1063 }

enum MediaType { cameraImage, cameraVideo, image, video, gallery }

enum TagType { article, flashnews, video, notes }

enum TextContentType { flashnews, uncensoredNote, buzzFeed, note, smartWidget }

enum UserStatus { notConnected, UsingPubKey, UsingPrivKey }

enum AppClientExtensionType { web, ios, android, linux }

enum SmartWidgetButtonType {
  Regular,
  Nostr,
  Zap,
  Youtube,
  Telegram,
  Discord,
  X
}

enum TextSize { H1, H2, Regular, Small }

enum TextWeight { Bold, Regular }

enum InternalWalletTransactionOption { none, receive, send }

enum NotesType { trending, universal, followings, widgets }

enum SmartWidgetType { community, self }

enum ButtonStatus { disabled, active, inactive, loading }

enum PropertyStatus { valid, invalid, unknown }

enum PollStatsStatus { idle, visible, invisible }

enum ArticleNaddrTypes { article, curation, smart }
