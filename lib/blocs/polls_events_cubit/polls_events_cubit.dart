import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/nostr/nostr.dart';

part 'polls_events_state.dart';

class PollsEventsCubit extends Cubit<PollsEventsState> {
  PollsEventsCubit()
      : super(
          PollsEventsState(
            pollsStats: {},
            refresher: true,
          ),
        );
}
