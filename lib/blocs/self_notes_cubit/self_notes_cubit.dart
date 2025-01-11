import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/utils.dart';

part 'self_notes_state.dart';

class SelfNotesCubit extends Cubit<SelfNotesState> {
  SelfNotesCubit()
      : super(
          SelfNotesState(
            isNotesLoading: true,
            detailedNotes: [],
            notesLoading: UpdatingState.success,
          ),
        ) {
    getNotes(false);
  }

  void getNotes(bool isAdd) {
    List<Event> oldNotes = [];
    List<Event> newNotes = [];
    int? since;

    if (isAdd) {
      oldNotes = state.detailedNotes;

      emit(
        state.copyWith(
          notesLoading: UpdatingState.progress,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isNotesLoading: true,
        ),
      );
    }

    NostrFunctionsRepository.getDetailedNotes(
      kinds: [EventKind.TEXT_NOTE],
      onNotesFunc: (notes) {
        newNotes = notes;

        emit(
          state.copyWith(
            isNotesLoading: false,
            detailedNotes: [
              ...oldNotes,
              ...notes,
            ],
          ),
        );
      },
      limit: 50,
      since: since,
      until: isAdd ? oldNotes.last.createdAt + 1 : null,
      pubkeys: [nostrRepository.user.pubKey],
      onDone: () {
        notesEventsCubit.addNoteMultipleEvents(state.detailedNotes
            .map((e) => DetailedNoteModel.fromEvent(e))
            .toList());

        emit(
          state.copyWith(
            isNotesLoading: false,
            notesLoading:
                newNotes.isEmpty ? UpdatingState.idle : UpdatingState.success,
          ),
        );
      },
    );
  }
}
