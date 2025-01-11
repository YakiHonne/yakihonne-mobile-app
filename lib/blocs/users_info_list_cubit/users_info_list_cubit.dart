import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'users_info_list_state.dart';

class UsersInfoListCubit extends Cubit<UsersInfoListState> {
  UsersInfoListCubit({required this.nostrRepository})
      : super(
          UsersInfoListState(
            isLoading: true,
            zapAuthors: {},
            mutes: nostrRepository.mutes.toList(),
            isValidUser: nostrRepository.usm != null &&
                nostrRepository.usm!.isUsingPrivKey,
            currentUserPubKey: nostrRepository.user.pubKey,
            followings: nostrRepository.followings,
            pendings: {},
          ),
        ) {
    followingsSubscription = nostrRepository.followingsStream.listen(
      (followings) {
        if (!isClosed)
          emit(
            state.copyWith(
              followings: followings,
            ),
          );
      },
    );

    muteListSubscription = nostrRepository.mutesStream.listen(
      (mutes) {
        if (!isClosed)
          emit(
            state.copyWith(
              mutes: mutes.toList(),
            ),
          );
      },
    );
  }

  late StreamSubscription followingsSubscription;
  late StreamSubscription muteListSubscription;
  final NostrDataRepository nostrRepository;
  Set<String> requests = {};
  Set<String> pubkeys = {};
  Timer? addFollowingOnStop;

  void getAuthor(List<String> authors) {
    if (authors.isEmpty) {
      if (!isClosed)
        emit(
          state.copyWith(
            isLoading: false,
          ),
        );

      return;
    }

    final availableAuthors = authorsCubit.getAuthorsByPubkeys(authors);

    authors.removeWhere(
      (author) => availableAuthors.keys.contains(author),
    );

    Map<String, UserModel> authorsToBeEmitted = {};

    for (final e in authors) {
      authorsToBeEmitted[e] = UserModel.fromJson(
        '{}',
        e,
        [],
        DateTime(2000).toSecondsSinceEpoch(),
      );
    }

    emit(
      state.copyWith(
        zapAuthors: {
          ...availableAuthors,
          ...authorsToBeEmitted,
        },
        isLoading: availableAuthors.isEmpty,
      ),
    );

    final updateAuthors = state.zapAuthors;

    if (authors.isNotEmpty) {
      NostrFunctionsRepository.getAuthorsByPubkeys(authors: authors).listen(
        (authors) {
          emit(
            state.copyWith(
              zapAuthors: Map.from(updateAuthors)..addAll(authors),
              isLoading: false,
            ),
          );
        },
        onDone: () {
          emit(
            state.copyWith(
              isLoading: false,
            ),
          );
        },
      );
    } else {
      emit(
        state.copyWith(
          isLoading: false,
        ),
      );
    }
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
          final status = state.followings.contains(desiredAuthor);

          if (status) {
            profiles.removeWhere((profile) => profile.key == desiredAuthor);
          } else {
            profiles.add(Profile(desiredAuthor, '', ''));
          }
        },
      );

      final event = await Event.genEvent(
        kind: 3,
        content: '',
        privkey: nostrRepository.usm!.privKey,
        pubkey: nostrRepository.usm!.pubKey,
        verify: true,
        tags: Nip2.toTags(profiles),
      );

      if (event == null) {
        return;
      }

      final _cancel = BotToast.showLoading();

      final isSuccessful =
          await NostrFunctionsRepository.addEvent(event: event);

      if (isSuccessful) {
        emit(state.copyWith(pendings: {}));

        nostrRepository.setUserModelFollowing(
          nostrRepository.user.copyWith(
            followings: profiles,
          ),
        );
      } else {
        emit(state.copyWith(pendings: {}));
        BotToastUtils.showUnreachableRelaysError();
      }

      _cancel.call();
    }
  }

  @override
  Future<void> close() {
    NostrConnect.sharedInstance.closeRequests(requests.toList());
    followingsSubscription.cancel();
    muteListSubscription.cancel();
    return super.close();
  }
}
