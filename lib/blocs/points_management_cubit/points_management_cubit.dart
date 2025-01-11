import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/scheduler.dart';
import 'package:yakihonne/models/points_system_models.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/app_cycle.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'points_management_state.dart';

class PointsManagementCubit extends Cubit<PointsManagementState> {
  PointsManagementCubit()
      : super(
          PointsManagementState(
            isUpdated: true,
            userGlobalStats: null,
            isNew: false,
            currentXp: 0,
            standards: [],
            additionalXp: 0,
            currentLevel: 0,
            currentLevelXp: 0,
            nextLevelXp: 0,
            percentage: 0,
            consumablePoints: 0,
          ),
        ) {
    setZapsToPointsSubscription();
  }

  final _appLifecycleNotifier = AppLifecycleNotifier();
  StreamSubscription? _appLifeCycle;
  List<ZapsToPoints> zapsToPointsList = [];
  String? id;

  void login({
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    final res = await HttpFunctionsRepository.loginPointsSystem();

    if (res != null) {
      BotToastUtils.showSuccess("You are logged in to Yakihonne's chest");
      getRecentStats();

      final isNew = (res['isNew'] as bool?) ?? false;
      final actions = (res['actions'] as List?) ?? <PointAction>[];

      if (isNew && actions.isNotEmpty) {
        int currentXp = res['xp'] ?? 0;
        List<String> pointsNames = [];
        final standards = res['standards'];

        if (standards != null) {
          for (final action in (res['actions'] as List<PointAction>)) {
            if (standards[action.actionId] != null) {
              pointsNames.add(standards[action.actionId].displayName);
            }
          }
        }

        final currentLevel = getCurrentLevel(currentXp);
        final currentLevelXp = getRemainingXp(currentLevel);
        final additionalXp = currentXp - currentLevelXp;
        final nextLevelXp = getRemainingXp(currentLevel + 1);

        emit(
          state.copyWith(
            currentXp: currentXp,
            percentage: additionalXp / (nextLevelXp - currentLevelXp),
            standards: pointsNames,
            currentLevel: currentLevel,
            isNew: true,
          ),
        );
      } else {
        onSuccess.call();
      }
    } else {
      BotToastUtils.showError(
        "Error occured while logging in to Yakihonne's chest",
      );
    }

    _cancel.call();
  }

  void setZapsToPointsSubscription() {
    _appLifeCycle = _appLifecycleNotifier.lifecycleStream.listen(
      (appState) {
        if (appState == AppLifecycleState.resumed) {
          checkZapsToPoints();
        }
      },
    );
  }

  void checkZapsToPoints({List<ZapsToPoints>? zapsToPoints}) {
    if (state.userGlobalStats != null) {
      if (zapsToPoints != null) {
        zapsToPointsList.addAll(zapsToPoints);
      }

      for (int i = 0; i < zapsToPointsList.length; i++) {
        if (zapsToPointsList[i].shouldBeDeleted()) {
          zapsToPointsList.removeAt(i);
        }
      }

      if (zapsToPointsList.isNotEmpty) {
        NostrFunctionsRepository.sendZapsToPoints(
          zapsToPointsList: zapsToPointsList,
          id: id,
        );
      }
    }
  }

  void sendZapsPoints(num sats) {
    try {
      String zapCode = '';
      if (sats >= 1 && sats <= 20) {
        zapCode = PointsActions.ZAP1;
      } else if (sats >= 21 && sats <= 60) {
        zapCode = PointsActions.ZAP20;
      } else if (sats >= 61 && sats <= 100) {
        zapCode = PointsActions.ZAP60;
      } else {
        zapCode = PointsActions.ZAP100;
      }

      HttpFunctionsRepository.sendAction(zapCode);
    } catch (e) {
      lg.i(e);
    }
  }

  void logout() async {
    await HttpFunctionsRepository.logoutPointsSystem();
    _appLifeCycle?.cancel();
    zapsToPointsList.clear();

    if (id != null) {
      NostrConnect.sharedInstance.closeRequests([id!]);
    }

    emit(
      state.copyWith(
        isUpdated: !state.isUpdated,
        userGlobalStats: null,
        isNew: false,
        currentXp: 0,
        standards: [],
        currentLevel: 0,
        percentage: 0,
      ),
    );
  }

  void setUserStats(UserGlobalStats? userStats) {
    if (userStats != null) {
      final currentLevel = userStats.currentLevel();
      final currentXp = userStats.xp;
      final currentLevelXp = getRemainingXp(currentLevel);
      final additionalXp = currentXp - currentLevelXp;
      final nextLevelXp = getRemainingXp(currentLevel + 1);
      final points = userStats.currentPoints;

      emit(
        state.copyWith(
          isUpdated: !state.isUpdated,
          userGlobalStats: userStats,
          currentXp: currentXp,
          currentLevel: currentLevel,
          additionalXp: additionalXp,
          currentLevelXp: currentLevelXp,
          nextLevelXp: nextLevelXp,
          percentage: additionalXp / (nextLevelXp - currentLevelXp),
          consumablePoints: points,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isUpdated: !state.isUpdated,
          userGlobalStats: userStats,
        ),
      );
    }
  }

  Future<void> getRecentStats() async {
    final userStats = await HttpFunctionsRepository.getUserStats();
    setUserStats(userStats);
  }

  @override
  Future<void> close() {
    _appLifeCycle?.cancel();
    return super.close();
  }
}
