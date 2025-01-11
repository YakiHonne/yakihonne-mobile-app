import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/models/poll_model.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/mixins/later_function.dart';
import 'package:yakihonne/utils/utils.dart';

part 'single_event_state.dart';

class SingleEventCubit extends Cubit<SingleEventState> with LaterFunction {
  SingleEventCubit()
      : super(
          SingleEventState(
            events: {},
            sealedNotes: {},
            pollStats: {},
          ),
        );

  List<String> _needUpdateIds = [];
  List<String> _needUpdateDTags = [];
  List<Event> _pendingEvents = [];
  List<String> _sealedIds = [];
  Timer? searchOnStoppedTyping;

  Future<Event?> getEvenById({
    required String id,
    required bool isIdentifier,
    List<int>? kinds,
  }) async {
    final ev = state.events[id];

    if (ev != null) {
      return ev;
    }

    final newEv = await NostrFunctionsRepository.getEventById(
      eventId: id,
      isIdentifier: isIdentifier,
      kinds: kinds,
    );

    if (newEv != null) {
      _onEvent(newEv);
    }

    return newEv;
  }

  Event? getEvent(String id, bool r) {
    var event = state.events[id];

    if (event != null) {
      return event;
    }

    if (!_needUpdateIds.contains(id) && !r) {
      _needUpdateIds.add(id);
    }

    if (!_needUpdateDTags.contains(id) && r) {
      _needUpdateDTags.add(id);
    }

    later(_laterCallback, null);

    return null;
  }

  SealedNote? getSealedEventOverHttp(String id) {
    var event = state.sealedNotes[id];

    if (event != null) {
      return event;
    }

    if (!_sealedIds.contains(id)) {
      _sealedIds.add(id);
    }

    later(_laterSealedCallback, null);

    return null;
  }

  String? getDTag(Event event) {
    for (var tag in event.tags) {
      if (tag.first == 'd') {
        return tag[1];
      }
    }

    return null;
  }

  void _laterSealedCallback() {
    if (_sealedIds.isNotEmpty) {
      _laterSealedSearch();
    }
  }

  void _laterCallback() {
    if (_needUpdateIds.isNotEmpty || _needUpdateDTags.isNotEmpty) {
      _laterSearch();
    }

    if (_pendingEvents.isNotEmpty) {
      _handlePendingEvents();
    }
  }

  void _handlePendingEvents() {
    final currentEvents = Map<String, Event>.from(state.events);

    for (var event in _pendingEvents) {
      final dTag = getDTag(event);

      var oldEvent = currentEvents[dTag ?? event.id];
      if (oldEvent == null || oldEvent.createdAt < event.createdAt) {
        currentEvents[dTag ?? event.id] = event;
      }
    }

    emit(
      state.copyWith(
        events: currentEvents,
      ),
    );

    _pendingEvents.clear();
  }

  void _laterSearch() async {
    if (_needUpdateIds.isEmpty && _needUpdateDTags.isEmpty) {
      return;
    }

    NostrFunctionsRepository.getEvents(
      ids: _needUpdateIds,
      dTags: _needUpdateDTags,
    ).listen(
      (event) {
        _onEvent(event);
      },
      onDone: () {},
    );

    _needUpdateIds.clear();
    _needUpdateDTags.clear();
  }

  void _laterSealedSearch() async {
    if (_sealedIds.isEmpty) {
      return;
    }

    final currentSealedNotes = Map<String, SealedNote>.from(state.sealedNotes);
    final currentSealedIds = List<String>.from(_sealedIds);

    final fetchedSealedNotes =
        await HttpFunctionsRepository.getSealedNotesByIds(
      flashNewsIds: currentSealedIds,
    );

    if (fetchedSealedNotes.isNotEmpty) {
      currentSealedNotes.addAll(fetchedSealedNotes);

      emit(
        state.copyWith(
          sealedNotes: currentSealedNotes,
        ),
      );
    }

    _sealedIds.clear();
  }

  void zapPollSearch(String id, Function() onFinished) async {
    if (id.isEmpty) {
      return;
    }

    final _cancel = BotToast.showLoading();

    final currentZapPolls = Map<String, List<PollStat>>.from(state.pollStats);
    final zaps = <String, Event>{};

    NostrFunctionsRepository.getEvents(
      eTags: [id],
      kinds: [EventKind.ZAP],
    ).listen(
      (event) {
        zaps[event.id] = event;
      },
      onDone: () async {
        await Future.delayed(const Duration(seconds: 1));
        List<PollStat> pollStats = [];

        if (zaps.isNotEmpty) {
          for (final zap in zaps.values.toList()) {
            final stats = getZapByPollStats(zap);

            final createdAt =
                DateTime.fromMillisecondsSinceEpoch(zap.createdAt * 1000);

            pollStats.add(
              PollStat(
                pubkey: stats['pubkey'] ?? '',
                zapAmount: stats['amount'] ?? 0,
                createdAt: createdAt,
                index: stats['index'] ?? -1,
              ),
            );
          }

          currentZapPolls[id] = pollStats;

          emit(
            state.copyWith(
              pollStats: currentZapPolls,
            ),
          );
        } else {
          currentZapPolls[id] = [];
          emit(
            state.copyWith(
              pollStats: currentZapPolls,
            ),
          );
        }

        onFinished.call();
        _cancel.call();
      },
    );
  }

  void _onEvent(Event event) {
    _pendingEvents.add(event);

    later(_laterCallback, null);
  }

  @override
  Future<void> close() {
    disposeLater();
    return super.close();
  }
}
