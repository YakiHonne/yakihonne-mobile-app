// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'notes_cubit.dart';

class NotesState extends Equatable {
  final List<Event> detailedNotes;
  final UpdatingState loadingMoreState;
  final bool isLoading;

  NotesState({
    required this.detailedNotes,
    required this.loadingMoreState,
    required this.isLoading,
  });

  @override
  List<Object> get props => [
        detailedNotes,
        loadingMoreState,
        isLoading,
      ];

  NotesState copyWith({
    List<Event>? detailedNotes,
    UpdatingState? loadingMoreState,
    bool? isLoading,
  }) {
    return NotesState(
      detailedNotes: detailedNotes ?? this.detailedNotes,
      loadingMoreState: loadingMoreState ?? this.loadingMoreState,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
