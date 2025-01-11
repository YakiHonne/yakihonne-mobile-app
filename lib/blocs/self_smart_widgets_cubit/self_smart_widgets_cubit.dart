import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'self_smart_widgets_state.dart';

class SelfSmartWidgetsCubit extends Cubit<SelfSmartWidgetsState> {
  SelfSmartWidgetsCubit()
      : super(
          SelfSmartWidgetsState(
            userStatus: getUserStatus(),
            widgets: [],
            isWidgetsLoading: true,
            chosenRelay: '',
            relays: nostrRepository.relays,
          ),
        ) {
    if (nostrRepository.usm != null) {
      getSmartWidgets(
        relay: '',
      );
    }

    userSubcription = nostrRepository.userModelStream.listen(
      (user) {
        if (user == null) {
          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: UserStatus.notConnected,
                widgets: [],
                isWidgetsLoading: false,
              ),
            );
        } else {
          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: user.isUsingPrivKey
                    ? UserStatus.UsingPrivKey
                    : UserStatus.UsingPubKey,
              ),
            );

          getSmartWidgets(
            relay: '',
          );
        }
      },
    );

    refreshSelfArticles = nostrRepository.refreshSelfArticlesStream.listen(
      (user) {
        getSmartWidgets(relay: state.chosenRelay);
      },
    );
  }

  late StreamSubscription userSubcription;
  late StreamSubscription refreshSelfArticles;
  Timer? widgetsTimer;
  Set<String> requests = {};

  void getSmartWidgets({
    required String relay,
  }) {
    widgetsTimer?.cancel();

    if (!isClosed)
      emit(
        state.copyWith(
          isWidgetsLoading: true,
          widgets: [],
          chosenRelay: relay,
        ),
      );

    NostrFunctionsRepository.getSmartWidgets(
      pubkeys: [nostrRepository.user.pubKey],
      relay: relay.isEmpty ? null : relay,
    ).listen(
      (widgets) {
        emit(
          state.copyWith(
            widgets: widgets,
            isWidgetsLoading: false,
          ),
        );
      },
      onDone: () {
        emit(
          state.copyWith(
            isWidgetsLoading: false,
          ),
        );
      },
    );
  }

  void deleteSmartWidget(String eventId, Function() onSuccess) async {
    final _cancel = BotToast.showLoading();

    final isSuccessful =
        await NostrFunctionsRepository.deleteEvent(eventId: eventId);

    if (isSuccessful) {
      onSuccess.call();
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }

    _cancel.call();
  }

  @override
  Future<void> close() {
    NostrConnect.sharedInstance.closeRequests(requests.toList());
    userSubcription.cancel();
    refreshSelfArticles.cancel();
    return super.close();
  }
}
