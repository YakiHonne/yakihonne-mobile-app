import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';

part 'profile_follow_authors_state.dart';

class ProfileFollowAuthorsCubit extends Cubit<ProfileFollowAuthorsState> {
  ProfileFollowAuthorsCubit({
    required this.nostrRepository,
  }) : super(
          ProfileFollowAuthorsState(
            followers: {},
            followings: {},
            isFollowersLoading: true,
            isFollowingLoading: true,
            isFollowers: true,
            isValidUser: nostrRepository.usm != null &&
                nostrRepository.usm!.isUsingPrivKey,
            currentUserPubKey: nostrRepository.user.pubKey,
            ownFollowings: nostrRepository.followings,
            pendings: {},
          ),
        ) {
    followingsSubscription = nostrRepository.followingsStream.listen(
      (followings) {
        if (!isClosed)
          emit(
            state.copyWith(
              ownFollowings: followings,
            ),
          );
      },
    );
  }

  late StreamSubscription followingsSubscription;
  final NostrDataRepository nostrRepository;
  Set<String> requests = {};
  Timer? addFollowingOnStop;

  void toggleFollowers() {
    if (!isClosed)
      emit(
        state.copyWith(
          isFollowers: !state.isFollowers,
        ),
      );
  }

  void initView({
    required List<String> followings,
    required List<String> followers,
  }) {
    getAuthors(
      followers,
      true,
    );

    getAuthors(
      followings,
      false,
    );
  }

  void getAuthors(
    List<String> authors,
    bool isFollowers,
  ) {
    if (authors.isEmpty) {
      if (!isClosed)
        emit(
          state.copyWith(
            isFollowersLoading: isFollowers ? false : null,
            isFollowingLoading: !isFollowers ? false : null,
          ),
        );

      return;
    }

    final availableAuthors = List.from(
      isFollowers ? state.followers.keys : state.followings.keys,
    );

    authors.removeWhere(
      (author) => availableAuthors.contains(author),
    );

    NostrFunctionsRepository.getAuthorsByPubkeys(authors: authors).listen(
      (authorsToBeEmitted) {
        Map<String, UserModel> authors =
            Map.from(isFollowers ? state.followers : state.followings);

        for (var author in authorsToBeEmitted.entries) {
          authors[author.key] = author.value;
        }

        if (!isClosed)
          emit(
            state.copyWith(
              followers: isFollowers ? authors : null,
              isFollowersLoading: isFollowers ? false : null,
              followings: !isFollowers ? authors : null,
              isFollowingLoading: !isFollowers ? false : null,
            ),
          );
      },
      onDone: () {
        if (!isClosed)
          emit(
            state.copyWith(
              isFollowersLoading: isFollowers ? false : null,
              isFollowingLoading: !isFollowers ? false : null,
            ),
          );
      },
    );
  }

  void setFollowingOnStop(String desiredAuthor) {
    addFollowingOnStop?.cancel();

    emit(
      state.copyWith(
        pendings: Set.from(state.pendings)..add(desiredAuthor),
      ),
    );

    addFollowingOnStop = Timer(
      const Duration(milliseconds: 800),
      () {
        setFollowingState();
      },
    );
  }

  void setFollowingState() async {
    if (state.isValidUser) {
      List<Profile> profiles = nostrRepository.user.followings;

      state.pendings.forEach(
        (desiredAuthor) {
          final status = state.ownFollowings.contains(desiredAuthor);

          if (status) {
            profiles.removeWhere((profile) => profile.key == desiredAuthor);
          } else {
            profiles.add(Profile(desiredAuthor, '', ''));
          }
        },
      );

      final _cancel = BotToast.showLoading();

      final event = await Event.genEvent(
        kind: 3,
        content: '',
        privkey: nostrRepository.usm!.privKey,
        pubkey: nostrRepository.usm!.pubKey,
        verify: true,
        tags: Nip2.toTags(profiles),
      );

      if (event == null) {
        _cancel.call();
        return;
      }

      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: true,
      );

      emit(
        state.copyWith(
          pendings: {},
        ),
      );

      _cancel.call();

      if (isSuccessful) {
        emit(
          state.copyWith(
            pendings: {},
          ),
        );

        nostrRepository.setUserModelFollowing(
          nostrRepository.user.copyWith(
            followings: profiles,
          ),
        );
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }
    }
  }

  @override
  Future<void> close() {
    NostrConnect.sharedInstance.closeRequests(requests.toList());
    followingsSubscription.cancel();
    return super.close();
  }
}
