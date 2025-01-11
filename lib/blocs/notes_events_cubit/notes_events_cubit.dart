import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/mixins/later_function.dart';
import 'package:yakihonne/utils/utils.dart';

part 'notes_events_state.dart';

class NotesEventsCubit extends Cubit<NotesEventsState> with LaterFunction {
  NotesEventsCubit()
      : super(
          NotesEventsState(
            notesStats: {},
            refresher: false,
            previousNotes: {},
            events: {},
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            mutes: nostrRepository.mutes.toList(),
          ),
        ) {
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

    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        if (!isClosed)
          emit(
            state.copyWith(
              bookmarks: getBookmarkIds(bookmarks).toSet(),
            ),
          );
      },
    );
  }

  late StreamSubscription muteListSubscription;
  late StreamSubscription bookmarksSubscription;
  Map<String, Map<String, double>> zaps = {};
  List<String> alreadySearchedNotes = [];
  List<String> _notesIds = [];
  List<Event> _pendingNotesEvents = [];

  void addNoteEvent(DetailedNoteModel note) {
    final map = Map<String, DetailedNoteModel>.from(state.events);
    map[note.id] = note;

    emit(
      state.copyWith(events: map),
    );
  }

  void addNoteMultipleEvents(List<DetailedNoteModel> notes) {
    final map = Map<String, DetailedNoteModel>.from(state.events);
    for (final note in notes) {
      map[note.id] = note;
    }

    emit(state.copyWith(
      events: map,
    ));
  }

  void getNoteStats(String noteId, bool selfStats) {
    if (!alreadySearchedNotes.contains(noteId) || !selfStats) {
      alreadySearchedNotes.add(noteId);

      if (!_notesIds.contains(noteId)) {
        _notesIds.add(noteId);
      }

      later(
        () {
          _laterNotesSearch(selfStats);
        },
        null,
      );
    }
  }

  void _handleNotePendingEvents() {
    final currentEvents =
        Map<String, Map<String, Event>>.from(state.notesStats);

    for (var event in _pendingNotesEvents) {
      final id = event.getEventParent();

      if (id != null) {
        var oldEvent = currentEvents[id]?[event.id];
        if (oldEvent == null || oldEvent.createdAt < event.createdAt) {
          if (currentEvents[id] == null) {
            currentEvents[id] = {event.id: event};
          } else {
            currentEvents[id]![event.id] = event;
          }
        }
      }
    }

    emit(
      state.copyWith(
        notesStats: currentEvents,
        refresher: !state.refresher,
      ),
    );

    _pendingNotesEvents.clear();
  }

  Future<void> getNotePrevious(
    DetailedNoteModel note,
    bool isCurrentlyLoading,
    Function(bool) setLoading,
  ) async {
    if (!isCurrentlyLoading) {
      setLoading.call(true);

      final completer = Completer<void>();

      if (!note.isRoot) {
        Event? noteEvent;

        Map<String, List<DetailedNoteModel>> map =
            Map<String, List<DetailedNoteModel>>.from(state.previousNotes);

        final previousNotes = state.previousNotes[note.id];

        if (previousNotes != null) {
          final lastNote = previousNotes.first;

          if (!lastNote.isRoot) {
            final previousEventId = lastNote.replyTo.isNotEmpty
                ? lastNote.replyTo
                : lastNote.originId ?? '';

            if (previousEventId.isNotEmpty) {
              if (state.events[previousEventId] != null) {
                map[note.id] = previousNotes
                  ..insert(0, state.events[previousEventId]!);

                emit(
                  state.copyWith(
                    previousNotes: map,
                    refresher: !state.refresher,
                  ),
                );

                setLoading.call(false);

                completer.complete();
              } else {
                NostrFunctionsRepository.getEvents(
                  ids: [previousEventId],
                ).listen(
                  (event) {
                    if ((noteEvent?.createdAt ?? 0) < event.createdAt) {
                      noteEvent = event;
                    }
                  },
                ).onDone(
                  () {
                    if (noteEvent != null) {
                      map[note.id] = previousNotes
                        ..insert(0, DetailedNoteModel.fromEvent(noteEvent!));

                      emit(
                        state.copyWith(
                          previousNotes: map,
                          refresher: !state.refresher,
                        ),
                      );

                      setLoading.call(false);
                    }

                    completer.complete();
                  },
                );
              }
            }
          } else {
            setLoading.call(true);
            completer.complete();
          }
        } else {
          final previousEventId =
              note.replyTo.isNotEmpty ? note.replyTo : note.originId ?? '';

          if (previousEventId.isNotEmpty) {
            if (state.events[previousEventId] != null) {
              map[note.id] = [state.events[previousEventId]!];

              emit(
                state.copyWith(
                  previousNotes: map,
                  refresher: !state.refresher,
                ),
              );

              setLoading.call(false);
              completer.complete();
            } else {
              NostrFunctionsRepository.getEvents(
                ids: [previousEventId],
              ).listen(
                (event) {
                  if ((noteEvent?.createdAt ?? 0) < event.createdAt) {
                    noteEvent = event;
                  }
                },
              ).onDone(
                () {
                  if (noteEvent != null) {
                    map[note.id] = [DetailedNoteModel.fromEvent(noteEvent!)];

                    emit(
                      state.copyWith(
                        previousNotes: map,
                        refresher: !state.refresher,
                      ),
                    );

                    setLoading.call(false);
                  }

                  completer.complete();
                },
              );
            }
          } else {
            setLoading.call(true);
            completer.complete();
          }
        }
      }

      return completer.future;
    }
  }

  void _laterNotesSearch(bool selfStats) async {
    if (_notesIds.isEmpty || (selfStats && !isUsingPrivatekey())) {
      return;
    }

    final copyNoteIds = List<String>.from(_notesIds);

    NostrFunctionsRepository.getNoteStats(
      noteIds: _notesIds,
      isSelfStats: selfStats,
      pubkeys: selfStats && isUsingPrivatekey()
          ? [nostrRepository.usm!.pubKey]
          : null,
    ).listen(
      (event) {
        if (event.kind == EventKind.ZAP) {
          final isATagAvailable = event.tags.where((element) =>
              element.first == 'e' && copyNoteIds.contains(element[1]));

          if (isATagAvailable.isNotEmpty) {
            final receipt = Nip57.getZapReceipt(event);
            final req = Bolt11PaymentRequest(receipt.bolt11);

            final zapPubkey = getZapPubkey(event.tags).first;
            final usedPubkey = zapPubkey.isNotEmpty ? zapPubkey : event.pubkey;
            final amount =
                (req.amount.toDouble() * 100000000).round().toDouble();

            final id = isATagAvailable.first[1];

            if (zaps[id] != null) {
              if (zaps[usedPubkey] == null) {
                zaps[id]![usedPubkey] = amount;
              } else {
                zaps[id]![usedPubkey] = (zaps[id]![usedPubkey] ?? 0) + amount;
              }
            } else {
              zaps[id] = {
                usedPubkey: amount,
              };
            }
          }
        }

        _onNoteEvent(event);
      },
      onDone: () {},
    );

    _notesIds.clear();
  }

  void repostNote(DetailedNoteModel note) async {
    final _cancel = BotToast.showLoading();

    final event = await Event.genEvent(
      kind: EventKind.REPOST,
      tags: [
        [
          'e',
          note.id,
        ],
        ['p', note.pubkey],
      ],
      content: note.stringifiedEvent,
      pubkey: nostrRepository.usm!.pubKey,
      privkey: nostrRepository.usm!.privKey,
    );

    _cancel.call();

    if (event != null) {
      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: true,
      );

      if (isSuccessful) {
        final stats = Map<String, Map<String, Event>>.from(state.notesStats);

        stats[note.id] = {
          ...stats[note.id] ?? {},
          event.id: event,
        };

        emit(
          state.copyWith(
            notesStats: stats,
            refresher: !state.refresher,
          ),
        );
      }
    } else {
      BotToastUtils.showError('Error occured while generating the event');
    }
  }

  void onSetVote(DetailedNoteModel note) async {
    String? voteId;

    if (state.notesStats[note.id] != null) {
      for (final ev in state.notesStats[note.id]!.values) {
        if (ev.pubkey == (nostrRepository.usm?.pubKey ?? '') &&
            ev.kind == EventKind.REACTION) {
          voteId = ev.id;
        }
      }
    }

    final currentEvents =
        Map<String, Map<String, Event>>.from(state.notesStats);

    if (voteId == null) {
      final event = await Event.genEvent(
        kind: EventKind.REACTION,
        tags: [
          ['e', note.id],
          ['p', note.pubkey],
        ],
        content: '+',
        pubkey: nostrRepository.usm!.pubKey,
        privkey: nostrRepository.usm!.privKey,
      );

      if (event != null) {
        NostrFunctionsRepository.sendEvent(
          event: event,
          setProgress: true,
        );

        currentEvents[note.id] = {
          ...currentEvents[note.id] ?? {},
          event.id: event,
        };
      }
    } else {
      await NostrFunctionsRepository.deleteEvent(eventId: voteId);

      currentEvents[note.id] = {
        ...(currentEvents[note.id] ?? {})..remove(voteId),
      };
    }

    emit(
      state.copyWith(
        notesStats: currentEvents,
        refresher: !state.refresher,
      ),
    );
  }

  void addComment({
    required String content,
    required DetailedNoteModel replyNote,
    required List<String> mentions,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    final event = await NostrFunctionsRepository.addNoteReply(
      note: replyNote,
      content: content,
      mentions: mentions,
    );

    if (event != null) {
      onSuccess.call();

      final currentEvents =
          Map<String, Map<String, Event>>.from(state.notesStats);

      currentEvents[replyNote.id] = {
        ...currentEvents[replyNote.id] ?? {},
        event.id: event,
      };

      emit(
        state.copyWith(
          notesStats: currentEvents,
          refresher: !state.refresher,
        ),
      );
    } else {
      BotToastUtils.showError('Error occured while posting a comment');
    }

    _cancel.call();
  }

  void _onNoteEvent(Event event) {
    _pendingNotesEvents.add(event);
    later(() {
      _handleNotePendingEvents();
    }, null);
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
        hasBeenMuted ? 'User has been muted' : 'User has been unmuted',
      );

      onSuccess.call();
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }
  }

  @override
  Future<void> close() {
    disposeLater();
    muteListSubscription.cancel();
    return super.close();
  }
}
