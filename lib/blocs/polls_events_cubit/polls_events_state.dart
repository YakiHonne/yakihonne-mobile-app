// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'polls_events_cubit.dart';

class PollsEventsState extends Equatable {
  final Map<String, Map<String, Event>> pollsStats;
  final bool refresher;

  PollsEventsState({
    required this.pollsStats,
    required this.refresher,
  });

  @override
  List<Object> get props => [
        pollsStats,
        refresher,
      ];

  PollsEventsState copyWith({
    Map<String, Map<String, Event>>? pollsStats,
    bool? refresher,
  }) {
    return PollsEventsState(
      pollsStats: pollsStats ?? this.pollsStats,
      refresher: refresher ?? this.refresher,
    );
  }
}
