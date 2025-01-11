import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/poll_model.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/utils.dart';

part 'polls_state.dart';

class PollsCubit extends Cubit<PollsState> {
  PollsCubit()
      : super(
          PollsState(
            isLoading: true,
            loadingState: UpdatingState.success,
            mutes: nostrRepository.mutes.toList(),
            polls: [],
          ),
        ) {
    getPolls(isAdd: false, isSelf: false);

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

  late StreamSubscription muteListSubscription;
  bool isSelfVal = false;

  void getPolls({required bool isAdd, required bool isSelf}) {
    final oldPolls = List<PollModel>.from(state.polls);

    if (isAdd) {
      emit(
        state.copyWith(
          loadingState: UpdatingState.progress,
        ),
      );
    } else {
      isSelfVal = isSelf;
      emit(
        state.copyWith(
          polls: [],
          isLoading: true,
        ),
      );
    }

    List<PollModel> addedPolls = [];

    NostrFunctionsRepository.getZapPolls(
      limit: 30,
      pubkeys: isSelfVal ? [nostrRepository.usm!.pubKey] : null,
      until:
          isAdd ? state.polls.last.createdAt.toSecondsSinceEpoch() - 1 : null,
      onPollsFunc: (polls) {
        if (isAdd) {
          addedPolls = polls;

          emit(
            state.copyWith(
              polls: [...oldPolls, ...polls],
              loadingState: UpdatingState.success,
            ),
          );
        } else {
          emit(
            state.copyWith(
              polls: polls,
              isLoading: false,
            ),
          );
        }
      },
      onDone: () {
        emit(
          state.copyWith(
            isLoading: false,
            loadingState:
                isAdd && addedPolls.isEmpty ? UpdatingState.idle : null,
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    muteListSubscription.cancel();
    return super.close();
  }
}
