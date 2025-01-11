import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/vote_model.dart';

part 'detailed_note_state.dart';

class DetailedNoteCubit extends Cubit<DetailedNoteState> {
  DetailedNoteCubit({required DetailedNoteModel note})
      : super(
          DetailedNoteState(
            note: note,
            mutes: nostrRepository.mutes.toList(),
            previousNotes: [],
            votes: {},
            replies: [],
            zaps: {},
          ),
        );
}
