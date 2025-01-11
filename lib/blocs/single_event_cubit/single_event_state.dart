// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'single_event_cubit.dart';

class SingleEventState extends Equatable {
  final Map<String, Event> events;
  final Map<String, SealedNote> sealedNotes;
  final Map<String, List<PollStat>> pollStats;

  SingleEventState({
    required this.events,
    required this.sealedNotes,
    required this.pollStats,
  });

  @override
  List<Object> get props => [
        events,
        sealedNotes,
        pollStats,
      ];

  SingleEventState copyWith({
    Map<String, Event>? events,
    Map<String, SealedNote>? sealedNotes,
    Map<String, List<PollStat>>? pollStats,
  }) {
    return SingleEventState(
      events: events ?? this.events,
      sealedNotes: sealedNotes ?? this.sealedNotes,
      pollStats: pollStats ?? this.pollStats,
    );
  }
}
