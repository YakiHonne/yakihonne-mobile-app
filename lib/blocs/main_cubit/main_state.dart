// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'main_cubit.dart';

class MainState extends Equatable {
  final int selectedIndex;
  final MainViews mainView;
  final UserStatus userStatus;
  final String image;
  final String random;
  final String name;
  final String nip05;
  final String pubKey;
  final bool isMyContentShrinked;
  final bool isHorizontal;

  const MainState({
    required this.selectedIndex,
    required this.mainView,
    required this.userStatus,
    required this.image,
    required this.random,
    required this.name,
    required this.nip05,
    required this.pubKey,
    required this.isMyContentShrinked,
    required this.isHorizontal,
  });

  @override
  List<Object> get props => [
        selectedIndex,
        mainView,
        userStatus,
        random,
        image,
        name,
        nip05,
        pubKey,
        isMyContentShrinked,
        isHorizontal,
      ];

  MainState copyWith({
    int? selectedIndex,
    MainViews? mainView,
    UserStatus? userStatus,
    String? image,
    String? random,
    String? name,
    String? nip05,
    String? pubKey,
    bool? isMyContentShrinked,
    bool? isHorizontal,
  }) {
    return MainState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      mainView: mainView ?? this.mainView,
      userStatus: userStatus ?? this.userStatus,
      image: image ?? this.image,
      random: random ?? this.random,
      name: name ?? this.name,
      nip05: nip05 ?? this.nip05,
      pubKey: pubKey ?? this.pubKey,
      isMyContentShrinked: isMyContentShrinked ?? this.isMyContentShrinked,
      isHorizontal: isHorizontal ?? this.isHorizontal,
    );
  }
}
