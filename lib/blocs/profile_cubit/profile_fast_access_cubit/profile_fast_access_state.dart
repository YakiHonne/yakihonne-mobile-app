// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'profile_fast_access_cubit.dart';

class ProfileFastAccessState extends Equatable {
  final Set<String> commonPubkeys;
  final bool isFollowing;
  final Set<String> followers;

  ProfileFastAccessState({
    required this.commonPubkeys,
    required this.isFollowing,
    required this.followers,
  });

  @override
  List<Object> get props => [
        commonPubkeys,
        isFollowing,
        followers,
      ];

  ProfileFastAccessState copyWith({
    Set<String>? commonPubkeys,
    bool? isFollowing,
    Set<String>? followers,
  }) {
    return ProfileFastAccessState(
      commonPubkeys: commonPubkeys ?? this.commonPubkeys,
      isFollowing: isFollowing ?? this.isFollowing,
      followers: followers ?? this.followers,
    );
  }
}
