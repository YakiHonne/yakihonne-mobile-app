// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'flash_news_cubit.dart';

class FlashNewsState extends Equatable {
  final Map<String, List<MainFlashNews>> flashNews;
  final bool isFlashNewsLoading;
  final bool isImportant;
  final DateTime selectedDate;
  final bool isSpecificDateSelected;
  final List<String> mutes;
  final UpdatingState loadingFlashNews;
  final UserStatus userStatus;
  final String currentUserPubkey;
  final Map<String, Map<String, VoteModel>> votes;
  final Set<String> bookmarks;
  final bool refreshContent;

  FlashNewsState({
    required this.flashNews,
    required this.isFlashNewsLoading,
    required this.isImportant,
    required this.selectedDate,
    required this.isSpecificDateSelected,
    required this.mutes,
    required this.loadingFlashNews,
    required this.userStatus,
    required this.currentUserPubkey,
    required this.votes,
    required this.bookmarks,
    required this.refreshContent,
  });

  @override
  List<Object> get props => [
        flashNews,
        isFlashNewsLoading,
        isImportant,
        selectedDate,
        isSpecificDateSelected,
        mutes,
        loadingFlashNews,
        userStatus,
        currentUserPubkey,
        votes,
        bookmarks,
        refreshContent,
      ];

  FlashNewsState copyWith({
    Map<String, List<MainFlashNews>>? flashNews,
    bool? isFlashNewsLoading,
    bool? isImportant,
    DateTime? selectedDate,
    bool? isSpecificDateSelected,
    List<String>? mutes,
    UpdatingState? loadingFlashNews,
    UserStatus? userStatus,
    String? currentUserPubkey,
    Map<String, Map<String, VoteModel>>? votes,
    Set<String>? bookmarks,
    bool? refreshContent,
  }) {
    return FlashNewsState(
      flashNews: flashNews ?? this.flashNews,
      isFlashNewsLoading: isFlashNewsLoading ?? this.isFlashNewsLoading,
      isImportant: isImportant ?? this.isImportant,
      selectedDate: selectedDate ?? this.selectedDate,
      isSpecificDateSelected:
          isSpecificDateSelected ?? this.isSpecificDateSelected,
      mutes: mutes ?? this.mutes,
      loadingFlashNews: loadingFlashNews ?? this.loadingFlashNews,
      userStatus: userStatus ?? this.userStatus,
      currentUserPubkey: currentUserPubkey ?? this.currentUserPubkey,
      votes: votes ?? this.votes,
      bookmarks: bookmarks ?? this.bookmarks,
      refreshContent: refreshContent ?? this.refreshContent,
    );
  }
}
