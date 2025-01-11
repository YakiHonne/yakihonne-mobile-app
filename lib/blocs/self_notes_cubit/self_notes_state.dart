// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'self_notes_cubit.dart';

class SelfNotesState extends Equatable {
  final UpdatingState notesLoading;
  final List<Event> detailedNotes;
  final bool isNotesLoading;

  SelfNotesState({
    required this.notesLoading,
    required this.detailedNotes,
    required this.isNotesLoading,
  });

  @override
  List<Object> get props => [
        notesLoading,
        detailedNotes,
        isNotesLoading,
      ];

  SelfNotesState copyWith({
    UpdatingState? notesLoading,
    List<Event>? detailedNotes,
    bool? isNotesLoading,
  }) {
    return SelfNotesState(
      notesLoading: notesLoading ?? this.notesLoading,
      detailedNotes: detailedNotes ?? this.detailedNotes,
      isNotesLoading: isNotesLoading ?? this.isNotesLoading,
    );
  }
}
