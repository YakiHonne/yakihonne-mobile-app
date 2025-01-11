import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'smart_widgets_state.dart';

class SmartWidgetsCubit extends Cubit<SmartWidgetsState> {
  SmartWidgetsCubit()
      : super(
          SmartWidgetsState(
            isLoading: true,
            loadingState: UpdatingState.success,
            mutes: nostrRepository.mutes.toList(),
            widgets: [],
          ),
        ) {
    getSmartWidgets(isAdd: false, isSelf: false);

    muteListSubscription = nostrRepository.mutesStream.listen(
      (mutes) {
        if (!isClosed)
          emit(
            state.copyWith(
              mutes: mutes.toList(),
            ),
          );
      },
    );

    refreshSelfSmartWidgets = nostrRepository.refreshSelfArticlesStream.listen(
      (user) {
        getSmartWidgets(isAdd: false, isSelf: isSelfVal);
      },
    );
  }

  late StreamSubscription refreshSelfSmartWidgets;
  late StreamSubscription muteListSubscription;
  bool isSelfVal = false;

  void getSmartWidgets({required bool isAdd, required bool isSelf}) {
    final oldWidgets = List<SmartWidgetModel>.from(state.widgets);

    if (isAdd) {
      emit(
        state.copyWith(
          loadingState: UpdatingState.progress,
        ),
      );
    } else {
      isSelfVal = isSelf;
      emit(
        state.copyWith(
          widgets: [],
          isLoading: true,
        ),
      );
    }

    List<SmartWidgetModel> addedWidgets = [];

    NostrFunctionsRepository.getSmartWidgets(
      pubkeys: isSelfVal ? [nostrRepository.usm!.pubKey] : null,
      until:
          isAdd ? state.widgets.last.createdAt.toSecondsSinceEpoch() - 1 : null,
    ).listen(
      (widgets) {
        if (isAdd) {
          addedWidgets = widgets;

          emit(
            state.copyWith(
              widgets: [...oldWidgets, ...widgets],
              loadingState: UpdatingState.success,
            ),
          );
        } else {
          emit(
            state.copyWith(
              widgets: widgets,
              isLoading: false,
            ),
          );
        }
      },
      onDone: () {
        if (!isClosed)
          emit(
            state.copyWith(
              isLoading: false,
              loadingState:
                  isAdd && addedWidgets.isEmpty ? UpdatingState.idle : null,
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
    muteListSubscription.cancel();
    refreshSelfSmartWidgets.cancel();
    return super.close();
  }
}
