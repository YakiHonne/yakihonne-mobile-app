import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'self_curations_state.dart';

class SelfCurationsCubit extends Cubit<SelfCurationsState> {
  SelfCurationsCubit({required this.nostrRepository})
      : super(
          SelfCurationsState(
            isActualUser: nostrRepository.usm?.isUsingPrivKey ?? false,
            isUserConnected: nostrRepository.usm != null,
            curations: [],
            isCurationsLoading: true,
            chosenRelay: '',
            relays: nostrRepository.relays,
            curationAvailabilityToggle: true,
            isArticleCurations: true,
            relaysColors: {},
            onRefresh: false,
          ),
        ) {
    setRelaysColors();

    if (nostrRepository.usm != null) {
      getCurations(relay: '');
    }

    userSubcription = nostrRepository.userModelStream.listen(
      (user) {
        if (user == null) {
          if (!isClosed)
            emit(
              state.copyWith(
                isUserConnected: false,
                isActualUser: false,
                curations: [],
                isCurationsLoading: false,
              ),
            );
        } else {
          if (!isClosed)
            emit(
              state.copyWith(
                isUserConnected: true,
                isActualUser: user.isUsingPrivKey,
              ),
            );

          getCurations(relay: state.chosenRelay);
        }
      },
    );
  }

  final NostrDataRepository nostrRepository;
  late StreamSubscription userSubcription;
  Set<String> requests = {};
  Timer? curationsTimer;

  void setRelaysColors() {
    Map<String, int> colors = {};

    nostrRepository.relays.toList().forEach(
      (element) {
        colors[element] = randomColor().value;
      },
    );

    emit(
      state.copyWith(
        relaysColors: colors,
      ),
    );
  }

  void togglerCurationType() {
    emit(
      state.copyWith(
        isArticleCurations: !state.isArticleCurations,
      ),
    );
  }

  void getCurations({required String relay}) {
    curationsTimer?.cancel();

    if (!isClosed)
      emit(
        state.copyWith(
          curations: [],
          isCurationsLoading: true,
          chosenRelay: relay,
        ),
      );

    NostrFunctionsRepository.getCurationsByPubkeys(
      pubkeys: [nostrRepository.user.pubKey],
    ).listen(
      (curations) {
        emit(
          state.copyWith(
            curations: curations,
            isCurationsLoading: false,
          ),
        );
      },
      onDone: () {
        emit(
          state.copyWith(
            isCurationsLoading: false,
          ),
        );
      },
    );
  }

  Curation filterCuration({
    required Curation? oldCuration,
    required Curation newCuration,
  }) {
    if (oldCuration != null) {
      final isNew = oldCuration.createdAt.compareTo(newCuration.createdAt) < 1;
      if (isNew) {
        newCuration.relays.addAll(oldCuration.relays);
        return newCuration;
      } else {
        oldCuration.relays.addAll(newCuration.relays);
        return oldCuration;
      }
    } else {
      return newCuration;
    }
  }

  void deleteCuration(
    Curation curation,
    Function() onSuccess,
  ) async {
    final _cancel = BotToast.showLoading();

    final isSuccessful =
        await NostrFunctionsRepository.deleteEvent(eventId: curation.eventId);

    if (isSuccessful) {
      onSuccess.call();

      emit(
        state.copyWith(
          curations: state.curations
              .where((element) => element.eventId != curation.eventId)
              .toList(),
        ),
      );
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }

    _cancel.call();
  }

  @override
  Future<void> close() {
    NostrConnect.sharedInstance.closeRequests(requests.toList());
    userSubcription.cancel();
    return super.close();
  }
}
