// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'profile_cubit.dart';

class ProfileState extends Equatable {
  final ProfileStatus profileStatus;
  final bool isArticlesLoading;
  final bool isFlashNewsLoading;
  final bool isVideoLoading;
  final bool isRelaysLoading;
  final bool isNotesLoading;
  final bool isNip05;
  final UpdatingState notesLoading;
  final List<Article> articles;
  final List<Curation> curations;
  final List<FlashNews> flashNews;
  final List<VideoModel> videos;
  final List<DetailedNoteModel> notes;
  final Set<String> bookmarks;
  final List<String> userRelays;
  final List<String> activeRelays;
  final List<String> ownRelays;
  final List<String> mutes;
  final Set<String> followers;
  final Set<String> followings;
  final int followersLength;
  final int followingsLength;
  final double sentZaps;
  final double receivedZaps;
  final UserModel user;
  final UserStatus userStatus;
  final bool isSameArticleAuthor;
  final bool isFollowingAuthor;
  final bool canBeZapped;

  final num writingImpact;
  final num positiveWritingImpact;
  final num negativeWritingImpact;
  final num ongoingWritingImpact;
  final num ratingImpact;
  final num positiveRatingImpactH;
  final num positiveRatingImpactNh;
  final num negativeRatingImpactH;
  final num negativeRatingImpactNh;
  final num ongoingRatingImpact;

  ProfileState({
    required this.profileStatus,
    required this.isArticlesLoading,
    required this.isFlashNewsLoading,
    required this.isVideoLoading,
    required this.isRelaysLoading,
    required this.isNotesLoading,
    required this.isNip05,
    required this.notesLoading,
    required this.articles,
    required this.curations,
    required this.flashNews,
    required this.videos,
    required this.notes,
    required this.bookmarks,
    required this.userRelays,
    required this.activeRelays,
    required this.ownRelays,
    required this.mutes,
    required this.followers,
    required this.followings,
    required this.followersLength,
    required this.followingsLength,
    required this.sentZaps,
    required this.receivedZaps,
    required this.user,
    required this.userStatus,
    required this.isSameArticleAuthor,
    required this.isFollowingAuthor,
    required this.canBeZapped,
    required this.writingImpact,
    required this.positiveWritingImpact,
    required this.negativeWritingImpact,
    required this.ongoingWritingImpact,
    required this.ratingImpact,
    required this.positiveRatingImpactH,
    required this.positiveRatingImpactNh,
    required this.negativeRatingImpactH,
    required this.negativeRatingImpactNh,
    required this.ongoingRatingImpact,
  });

  @override
  List<Object> get props => [
        profileStatus,
        isArticlesLoading,
        isFlashNewsLoading,
        isVideoLoading,
        isRelaysLoading,
        isNotesLoading,
        isNip05,
        notesLoading,
        articles,
        curations,
        flashNews,
        videos,
        notes,
        bookmarks,
        userRelays,
        activeRelays,
        ownRelays,
        mutes,
        followers,
        followings,
        followersLength,
        followingsLength,
        sentZaps,
        receivedZaps,
        user,
        userStatus,
        isSameArticleAuthor,
        isFollowingAuthor,
        canBeZapped,
        writingImpact,
        positiveWritingImpact,
        negativeWritingImpact,
        ongoingWritingImpact,
        ratingImpact,
        positiveRatingImpactH,
        positiveRatingImpactNh,
        negativeRatingImpactH,
        negativeRatingImpactNh,
        ongoingRatingImpact,
      ];

  ProfileState copyWith({
    ProfileStatus? profileStatus,
    bool? isArticlesLoading,
    bool? isFlashNewsLoading,
    bool? isVideoLoading,
    bool? isRelaysLoading,
    bool? isNotesLoading,
    bool? isNip05,
    UpdatingState? notesLoading,
    List<Article>? articles,
    List<Curation>? curations,
    List<FlashNews>? flashNews,
    List<VideoModel>? videos,
    List<DetailedNoteModel>? notes,
    Set<String>? bookmarks,
    List<String>? userRelays,
    List<String>? activeRelays,
    List<String>? ownRelays,
    List<String>? mutes,
    Set<String>? followers,
    Set<String>? followings,
    int? followersLength,
    int? followingsLength,
    double? sentZaps,
    double? receivedZaps,
    UserModel? user,
    UserStatus? userStatus,
    bool? isSameArticleAuthor,
    bool? isFollowingAuthor,
    bool? canBeZapped,
    num? writingImpact,
    num? positiveWritingImpact,
    num? negativeWritingImpact,
    num? ongoingWritingImpact,
    num? ratingImpact,
    num? positiveRatingImpactH,
    num? positiveRatingImpactNh,
    num? negativeRatingImpactH,
    num? negativeRatingImpactNh,
    num? ongoingRatingImpact,
  }) {
    return ProfileState(
      profileStatus: profileStatus ?? this.profileStatus,
      isArticlesLoading: isArticlesLoading ?? this.isArticlesLoading,
      isFlashNewsLoading: isFlashNewsLoading ?? this.isFlashNewsLoading,
      isVideoLoading: isVideoLoading ?? this.isVideoLoading,
      isRelaysLoading: isRelaysLoading ?? this.isRelaysLoading,
      isNotesLoading: isNotesLoading ?? this.isNotesLoading,
      isNip05: isNip05 ?? this.isNip05,
      notesLoading: notesLoading ?? this.notesLoading,
      articles: articles ?? this.articles,
      curations: curations ?? this.curations,
      flashNews: flashNews ?? this.flashNews,
      videos: videos ?? this.videos,
      notes: notes ?? this.notes,
      bookmarks: bookmarks ?? this.bookmarks,
      userRelays: userRelays ?? this.userRelays,
      activeRelays: activeRelays ?? this.activeRelays,
      ownRelays: ownRelays ?? this.ownRelays,
      mutes: mutes ?? this.mutes,
      followers: followers ?? this.followers,
      followings: followings ?? this.followings,
      followersLength: followersLength ?? this.followersLength,
      followingsLength: followingsLength ?? this.followingsLength,
      sentZaps: sentZaps ?? this.sentZaps,
      receivedZaps: receivedZaps ?? this.receivedZaps,
      user: user ?? this.user,
      userStatus: userStatus ?? this.userStatus,
      isSameArticleAuthor: isSameArticleAuthor ?? this.isSameArticleAuthor,
      isFollowingAuthor: isFollowingAuthor ?? this.isFollowingAuthor,
      canBeZapped: canBeZapped ?? this.canBeZapped,
      writingImpact: writingImpact ?? this.writingImpact,
      positiveWritingImpact:
          positiveWritingImpact ?? this.positiveWritingImpact,
      negativeWritingImpact:
          negativeWritingImpact ?? this.negativeWritingImpact,
      ongoingWritingImpact: ongoingWritingImpact ?? this.ongoingWritingImpact,
      ratingImpact: ratingImpact ?? this.ratingImpact,
      positiveRatingImpactH:
          positiveRatingImpactH ?? this.positiveRatingImpactH,
      positiveRatingImpactNh:
          positiveRatingImpactNh ?? this.positiveRatingImpactNh,
      negativeRatingImpactH:
          negativeRatingImpactH ?? this.negativeRatingImpactH,
      negativeRatingImpactNh:
          negativeRatingImpactNh ?? this.negativeRatingImpactNh,
      ongoingRatingImpact: ongoingRatingImpact ?? this.ongoingRatingImpact,
    );
  }
}
