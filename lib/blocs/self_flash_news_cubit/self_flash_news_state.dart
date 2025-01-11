// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'self_flash_news_cubit.dart';

class SelfFlashNewsState extends Equatable {
  final List<FlashNews> flashNews;
  final List<PendingFlashNews> pendingFlashNews;
  final bool isFlashNewsSelected;
  final bool isFlashLoading;
  final bool isImportant;
  final UserStatus userStatus;

  SelfFlashNewsState({
    required this.flashNews,
    required this.pendingFlashNews,
    required this.isFlashNewsSelected,
    required this.isFlashLoading,
    required this.isImportant,
    required this.userStatus,
  });

  @override
  List<Object> get props => [
        flashNews,
        isFlashLoading,
        isImportant,
        isFlashNewsSelected,
        pendingFlashNews,
        userStatus,
      ];

  SelfFlashNewsState copyWith({
    List<FlashNews>? flashNews,
    List<PendingFlashNews>? pendingFlashNews,
    bool? isFlashNewsSelected,
    bool? isFlashLoading,
    bool? isImportant,
    UserStatus? userStatus,
  }) {
    return SelfFlashNewsState(
      flashNews: flashNews ?? this.flashNews,
      pendingFlashNews: pendingFlashNews ?? this.pendingFlashNews,
      isFlashNewsSelected: isFlashNewsSelected ?? this.isFlashNewsSelected,
      isFlashLoading: isFlashLoading ?? this.isFlashLoading,
      isImportant: isImportant ?? this.isImportant,
      userStatus: userStatus ?? this.userStatus,
    );
  }
}
