import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'update_relays_state.dart';

class UpdateRelaysCubit extends Cubit<UpdateRelaysState> {
  UpdateRelaysCubit({
    required this.nostrRepository,
  }) : super(
          UpdateRelaysState(
            activeRelays: NostrConnect.sharedInstance.activeRelays(),
            relays: NostrConnect.sharedInstance.relays(),
            isSameRelays: true,
            onlineRelays: [],
            pendingRelays: [],
            userRelays: [],
          ),
        ) {
    currentRelays = NostrConnect.sharedInstance.relays();

    setRelaysStatus();
  }

  final NostrDataRepository nostrRepository;
  late Timer timer;
  List<String> currentRelays = [];
  // List<String> userRelays = [];

  void setRelaysStatus() {
    timer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {
        final activeRelays = NostrConnect.sharedInstance.activeRelays();

        if (!isClosed)
          emit(
            state.copyWith(
              activeRelays: activeRelays,
            ),
          );
      },
    );
  }

  Future<void> updateRelays({
    required Function(String) onFailure,
    required Function(String) onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    try {
      final kind10002Event = await Event.genEvent(
        content: '',
        kind: EventKind.RELAY_LIST_METADATA,
        pubkey: nostrRepository.usm!.pubKey,
        privkey: nostrRepository.usm!.privKey,
        tags: state.relays.map((relay) => ['r', relay]).toList(),
      );

      if (kind10002Event == null) {
        _cancel.call();
        return;
      }

      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: kind10002Event,
        setProgress: false,
      );

      if (isSuccessful) {
        currentRelays = state.relays;

        if (!isClosed)
          emit(
            state.copyWith(
              isSameRelays: true,
              pendingRelays: [],
            ),
          );

        onSuccess.call('Relays list has been updated.');
        nostrRepository.setRelays(state.relays.toSet());
      } else {
        if (!isClosed) emit(state.copyWith(isSameRelays: true));
        onFailure.call("Couldn't update relays' list.");
      }

      _cancel.call();
    } catch (e) {
      _cancel.call();
      onFailure.call(
        "An error occured while updating the relays' list",
      );
    }
  }

  void setRelay(String addedRelay, {bool? textfield, Function()? onSuccess}) {
    String relay = '';

    if (textfield != null) {
      relay = addedRelay.removeLastBackSlashes();
      if (state.activeRelays.contains(relay)) {
        BotToastUtils.showError('Relay already in use');
        return;
      }
    } else {
      relay = addedRelay;
    }

    if (!relay.contains(relayRegExp)) {
      BotToastUtils.showError('Invalid relay');
      return;
    }

    if (state.relays.contains(relay)) {
      final relays = List<String>.from(state.relays)..remove(relay);
      final pending = List<String>.from(state.pendingRelays)..remove(relay);

      final relaysSet = relays.toSet();
      final currentRelaysSet = currentRelays.toSet();

      if (!isClosed)
        emit(
          state.copyWith(
            relays: relays,
            pendingRelays: pending,
            isSameRelays: relaysSet.containsAll(currentRelaysSet) &&
                currentRelays.length == relaysSet.length,
          ),
        );
    } else {
      final relays = List<String>.from(state.relays)..add(relay);
      final pending = List<String>.from(state.pendingRelays)..add(relay);

      final relaysSet = relays.toSet();
      final pendingsSet = pending.toSet();

      if (!isClosed)
        emit(
          state.copyWith(
            relays: relays,
            pendingRelays: pending,
            isSameRelays: relaysSet.containsAll(pendingsSet) &&
                pendingsSet.length == relaysSet.length,
          ),
        );
    }
  }

  Future<void> setOnlineRelays() async {
    try {
      if (state.onlineRelays.isEmpty) {
        final onlineRelays = await nostrRepository.getOnlineRelays();

        if (!isClosed)
          emit(
            state.copyWith(
              onlineRelays: onlineRelays,
            ),
          );
      }
    } catch (e) {
      if (!isClosed)
        emit(
          state.copyWith(
            onlineRelays: [],
          ),
        );
    }
  }

  @override
  Future<void> close() {
    timer.cancel();
    return super.close();
  }
}
