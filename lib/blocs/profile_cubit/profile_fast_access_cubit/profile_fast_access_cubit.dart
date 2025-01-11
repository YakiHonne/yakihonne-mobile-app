import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';

part 'profile_fast_access_state.dart';

class ProfileFastAccessCubit extends Cubit<ProfileFastAccessState> {
  ProfileFastAccessCubit({required this.pubkey})
      : super(
          ProfileFastAccessState(
            commonPubkeys: (nostrRepository.usersFollowers[pubkey] ?? {})
                .where(
                    (element) => nostrRepository.followings.contains(element))
                .toSet(),
            followers: nostrRepository.usersFollowers[pubkey] ?? {},
            isFollowing: nostrRepository.followings.contains(pubkey),
          ),
        ) {
    getFollowers();

    followingsSubscription = nostrRepository.followingsStream.listen(
      (followings) {
        if (!isClosed)
          emit(
            state.copyWith(
              isFollowing: followings.contains(pubkey),
            ),
          );
      },
    );
  }

  late StreamSubscription followingsSubscription;
  late String pubkey;

  void getFollowers() {
    final oldCommonPubkeys = state.commonPubkeys;
    final oldFollowers = state.followers;

    NostrFunctionsRepository.getUserFollowers(
      pubkey: pubkey,
      onDone: (followers) {
        final commonPubkeys = nostrRepository.followings
            .where((element) => followers.contains(element))
            .toSet();

        if (commonPubkeys.isNotEmpty) {
          authorsCubit.getAuthors(commonPubkeys.toList());
        }

        if (!isClosed)
          emit(
            state.copyWith(
              followers: {...oldFollowers, ...followers},
              commonPubkeys: {...oldCommonPubkeys, ...commonPubkeys},
            ),
          );

        nostrRepository.usersFollowers[pubkey] = followers;
      },
      onFollowers: (followers) {
        if (!isClosed)
          emit(
            state.copyWith(
              followers: {...oldFollowers, ...followers},
            ),
          );
      },
    );
  }

  void setFollowingState() async {
    final _cancel = BotToast.showLoading();

    await NostrFunctionsRepository.setFollowingEvent(
      isFollowingAuthor: state.isFollowing,
      targetPubkey: pubkey,
    );

    _cancel.call();
  }
}
