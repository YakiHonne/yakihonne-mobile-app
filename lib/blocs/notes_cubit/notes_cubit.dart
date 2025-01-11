import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/utils.dart';

part 'notes_state.dart';

class NotesCubit extends Cubit<NotesState> {
  NotesCubit()
      : super(NotesState(
          detailedNotes: [],
          isLoading: true,
          loadingMoreState: UpdatingState.success,
        )) {
    notesEventsCubit.alreadySearchedNotes.clear();
    getNotes(
      false,
      isUsingPrivatekey() ? NotesType.followings : NotesType.trending,
    );
  }

  String? id;

  void getNotes(bool isAdd, NotesType notesType) async {
    String localId = uuid.v4();
    id = localId;

    if (notesType == NotesType.trending) {
      List<Event> notes = [];

      emit(
        state.copyWith(
          isLoading: true,
          loadingMoreState: UpdatingState.progress,
        ),
      );

      notes = await HttpFunctionsRepository.getTrendingNotes();

      notesEventsCubit.addNoteMultipleEvents(
        notes.map((e) => DetailedNoteModel.fromEvent(e)).toList(),
      );

      if (localId == id) {
        emit(
          state.copyWith(
            isLoading: false,
            detailedNotes: notes,
            loadingMoreState: UpdatingState.idle,
          ),
        );
      }
    } else {
      getNotesFromNostr(isAdd, notesType);
    }
  }

  void getNotesFromNostr(bool isAdd, NotesType notesType) {
    String localId = uuid.v4();
    id = localId;

    List<Event> oldNotes = [];
    List<Event> newNotes = [];
    int? since;

    if (isAdd) {
      oldNotes = state.detailedNotes;

      emit(
        state.copyWith(
          loadingMoreState: UpdatingState.progress,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isLoading: true,
        ),
      );
    }

    if (notesType == NotesType.followings &&
        nostrRepository.user.followings.isEmpty) {
      emit(
        state.copyWith(
          isLoading: false,
          detailedNotes: [],
          loadingMoreState: UpdatingState.idle,
        ),
      );

      return;
    }

    NostrFunctionsRepository.getDetailedNotes(
      kinds: [EventKind.TEXT_NOTE, EventKind.REPOST],
      lTags: notesType == NotesType.widgets ? ['smart-widget'] : null,
      limit: 50,
      since: since,
      until: isAdd ? oldNotes.last.createdAt - 1 : null,
      pubkeys: notesType == NotesType.followings
          ? [
              nostrRepository.user.pubKey,
              ...nostrRepository.user.followings.map((e) => e.key).toList(),
            ]
          : null,
      onNotesFunc: (notes) {
        if (localId == id) {
          newNotes = notes;
          if (!isClosed)
            emit(
              state.copyWith(
                isLoading: false,
                detailedNotes: [
                  ...oldNotes,
                  ...notes,
                ],
              ),
            );
        }
      },
      onDone: () {
        notesEventsCubit.addNoteMultipleEvents(
          state.detailedNotes
              .map((e) => DetailedNoteModel.fromEvent(e))
              .toList(),
        );

        if (localId == id) {
          if (!isClosed)
            emit(
              state.copyWith(
                isLoading: false,
                loadingMoreState: newNotes.isEmpty
                    ? UpdatingState.idle
                    : UpdatingState.success,
              ),
            );
        }
      },
    );
  }
}
