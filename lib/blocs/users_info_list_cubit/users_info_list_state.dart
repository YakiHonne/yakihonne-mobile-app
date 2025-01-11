// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'users_info_list_cubit.dart';

class UsersInfoListState extends Equatable {
  final Map<String, UserModel> zapAuthors;
  final bool isLoading;
  final bool isValidUser;
  final List<String> followings;
  final String currentUserPubKey;
  final Set<String> pendings;
  final List<String> mutes;

  UsersInfoListState({
    required this.zapAuthors,
    required this.isLoading,
    required this.isValidUser,
    required this.followings,
    required this.currentUserPubKey,
    required this.pendings,
    required this.mutes,
  });

  @override
  List<Object> get props => [
        zapAuthors,
        isLoading,
        isValidUser,
        followings,
        currentUserPubKey,
        pendings,
        mutes,
      ];

  UsersInfoListState copyWith({
    Map<String, UserModel>? zapAuthors,
    bool? isLoading,
    bool? isValidUser,
    List<String>? followings,
    String? currentUserPubKey,
    Set<String>? pendings,
    List<String>? mutes,
  }) {
    return UsersInfoListState(
      zapAuthors: zapAuthors ?? this.zapAuthors,
      isLoading: isLoading ?? this.isLoading,
      isValidUser: isValidUser ?? this.isValidUser,
      followings: followings ?? this.followings,
      currentUserPubKey: currentUserPubKey ?? this.currentUserPubKey,
      pendings: pendings ?? this.pendings,
      mutes: mutes ?? this.mutes,
    );
  }
}
