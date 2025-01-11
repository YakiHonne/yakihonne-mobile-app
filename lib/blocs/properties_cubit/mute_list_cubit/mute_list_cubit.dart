// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';

part 'mute_list_state.dart';

class MuteListCubit extends Cubit<MuteListState> {
  MuteListCubit()
      : super(
          MuteListState(
            mutes: nostrRepository.mutes.toList(),
            isUsingPrivKey: nostrRepository.usm != null &&
                nostrRepository.usm!.isUsingPrivKey,
          ),
        ) {
    mutesListSubscription = nostrRepository.mutesStream.listen(
      (mutes) {
        if (!isClosed)
          emit(
            state.copyWith(
              mutes: mutes.toList(),
            ),
          );

        getAuthors();
      },
    );
  }

  late StreamSubscription mutesListSubscription;

  void getAuthors() {
    authorsCubit.getAuthors(state.mutes);
  }

  void setMuteStatus({
    required String pubkey,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    final result = await NostrFunctionsRepository.setMuteList(pubkey);

    _cancel();

    if (result) {
      final hasBeenMuted = nostrRepository.mutes.contains(pubkey);

      BotToastUtils.showSuccess(
          hasBeenMuted ? 'User has been muted' : 'User has been unmuted');
      onSuccess.call();
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }
  }

  @override
  Future<void> close() {
    mutesListSubscription.cancel();
    return super.close();
  }
}
