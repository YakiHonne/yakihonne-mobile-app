// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'home_cubit.dart';

class HomeState extends Equatable {
  final List<dynamic> content;
  final List<MainFlashNews> flashNews;
  final List<dynamic> followingsContent;
  final Set<String> relays;
  final Map<String, UserModel> authors;
  final List<TopCuratorModel> topCurators;
  final List<TopCreatorModel> topCreators;
  final bool isFlashNewsLoading;
  final bool isRelaysLoading;
  final bool isFollowingsLoading;
  final bool rebuildCurations;
  final bool rebuildRelays;
  final bool rebuildFavorites;
  final UpdatingState relaysAddingData;
  final UpdatingState followingsAddingData;
  final UserStatus userStatus;
  final String chosenRelay;
  final List<String> followings;
  final Set<String> bookmarks;
  final Set<String> loadingBookmarks;
  final List<String> userTopics;
  final List<String> generalTopics;
  final List<String> selectedRelays;
  final List<String> mutes;
  final List<BuzzFeedSource> sources;

  HomeState({
    required this.content,
    required this.flashNews,
    required this.followingsContent,
    required this.relays,
    required this.authors,
    required this.topCurators,
    required this.topCreators,
    required this.isFlashNewsLoading,
    required this.isRelaysLoading,
    required this.isFollowingsLoading,
    required this.rebuildCurations,
    required this.rebuildRelays,
    required this.rebuildFavorites,
    required this.relaysAddingData,
    required this.followingsAddingData,
    required this.userStatus,
    required this.chosenRelay,
    required this.followings,
    required this.bookmarks,
    required this.loadingBookmarks,
    required this.userTopics,
    required this.generalTopics,
    required this.selectedRelays,
    required this.mutes,
    required this.sources,
  });

  @override
  List<Object> get props => [
        content,
        flashNews,
        mutes,
        followingsContent,
        authors,
        topCurators,
        topCreators,
        isFlashNewsLoading,
        relaysAddingData,
        isRelaysLoading,
        isFollowingsLoading,
        rebuildCurations,
        rebuildRelays,
        relays,
        userStatus,
        chosenRelay,
        followings,
        followingsAddingData,
        rebuildFavorites,
        bookmarks,
        loadingBookmarks,
        userTopics,
        generalTopics,
        selectedRelays,
        sources,
      ];

  HomeState copyWith({
    List<dynamic>? content,
    List<MainFlashNews>? flashNews,
    List<dynamic>? followingsContent,
    Set<String>? relays,
    Map<String, UserModel>? authors,
    List<TopCuratorModel>? topCurators,
    List<TopCreatorModel>? topCreators,
    bool? isFlashNewsLoading,
    bool? isRelaysLoading,
    bool? isFollowingsLoading,
    bool? rebuildCurations,
    bool? rebuildRelays,
    bool? rebuildFavorites,
    UpdatingState? relaysAddingData,
    UpdatingState? followingsAddingData,
    UserStatus? userStatus,
    String? chosenRelay,
    List<String>? followings,
    Set<String>? bookmarks,
    Set<String>? loadingBookmarks,
    List<String>? userTopics,
    List<String>? generalTopics,
    List<String>? selectedRelays,
    List<String>? mutes,
    List<BuzzFeedSource>? sources,
  }) {
    return HomeState(
      content: content ?? this.content,
      flashNews: flashNews ?? this.flashNews,
      followingsContent: followingsContent ?? this.followingsContent,
      relays: relays ?? this.relays,
      authors: authors ?? this.authors,
      topCurators: topCurators ?? this.topCurators,
      topCreators: topCreators ?? this.topCreators,
      isFlashNewsLoading: isFlashNewsLoading ?? this.isFlashNewsLoading,
      isRelaysLoading: isRelaysLoading ?? this.isRelaysLoading,
      isFollowingsLoading: isFollowingsLoading ?? this.isFollowingsLoading,
      rebuildCurations: rebuildCurations ?? this.rebuildCurations,
      rebuildRelays: rebuildRelays ?? this.rebuildRelays,
      rebuildFavorites: rebuildFavorites ?? this.rebuildFavorites,
      relaysAddingData: relaysAddingData ?? this.relaysAddingData,
      followingsAddingData: followingsAddingData ?? this.followingsAddingData,
      userStatus: userStatus ?? this.userStatus,
      chosenRelay: chosenRelay ?? this.chosenRelay,
      followings: followings ?? this.followings,
      bookmarks: bookmarks ?? this.bookmarks,
      loadingBookmarks: loadingBookmarks ?? this.loadingBookmarks,
      userTopics: userTopics ?? this.userTopics,
      generalTopics: generalTopics ?? this.generalTopics,
      selectedRelays: selectedRelays ?? this.selectedRelays,
      mutes: mutes ?? this.mutes,
      sources: sources ?? this.sources,
    );
  }
}
