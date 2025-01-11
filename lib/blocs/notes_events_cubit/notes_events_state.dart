// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'notes_events_cubit.dart';

class NotesEventsState extends Equatable {
  final Map<String, Map<String, Event>> notesStats;
  final Map<String, DetailedNoteModel> events;
  final Map<String, List<DetailedNoteModel>> previousNotes;
  final bool refresher;
  final List<String> mutes;
  final Set<String> bookmarks;

  NotesEventsState({
    required this.notesStats,
    required this.events,
    required this.previousNotes,
    required this.refresher,
    required this.mutes,
    required this.bookmarks,
  });

  @override
  List<Object> get props => [
        notesStats,
        refresher,
        previousNotes,
        events,
        mutes,
        bookmarks,
      ];

  NotesEventsState copyWith({
    Map<String, Map<String, Event>>? notesStats,
    Map<String, DetailedNoteModel>? events,
    Map<String, List<DetailedNoteModel>>? previousNotes,
    bool? refresher,
    List<String>? mutes,
    Set<String>? bookmarks,
  }) {
    return NotesEventsState(
      notesStats: notesStats ?? this.notesStats,
      events: events ?? this.events,
      previousNotes: previousNotes ?? this.previousNotes,
      refresher: refresher ?? this.refresher,
      mutes: mutes ?? this.mutes,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}
