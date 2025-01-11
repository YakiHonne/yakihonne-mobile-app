import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/user_status_model.dart';
import 'package:yakihonne/repositories/connectivity_repository.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';

part 'routing_state.dart';

class RoutingCubit extends Cubit<RoutingState> {
  RoutingCubit({
    required this.nostrRepository,
    required this.localDatabaseRepository,
    required this.connectivityRepository,
  }) : super(
          RoutingState(
            currentRoute: CurrentRoute.onboarding,
            updatingState: UpdatingState.progress,
          ),
        );

  final NostrDataRepository nostrRepository;
  final LocalDatabaseRepository localDatabaseRepository;
  final ConnectivityRepository connectivityRepository;
  StreamController controller = StreamController();
  late StreamSubscription _sub;
  late BuildContext context;

  Future<void> routingViewInit(BuildContext buildContext) async {
    context = buildContext;

    if (!isClosed)
      emit(
        state.copyWith(
          updatingState: UpdatingState.progress,
        ),
      );

    try {
      nostrRepository.relays.addAll(constantRelays);
      nostrRepository.getBuzzFeed();
      nostrRepository.getPricing();

      final localData = await Future.wait(
        [
          localDatabaseRepository.getCurrentUsm(),
          localDatabaseRepository.getAutoSaveContent(true),
          localDatabaseRepository.getExternalSignerStatus(),
          localDatabaseRepository.isUsingNip44(),
          localDatabaseRepository.getUploadServer(),
          HttpFunctionsRepository.getSmartWidgetsTemplates(),
          localDatabaseRepository.getAutoSaveContent(false),
          localDatabaseRepository.getUsmList(),
          nostrRepository.getTopics(),
          initRelays([]),
        ],
      );

      pointsManagementCubit.getRecentStats();

      final statusModel = localData[0] as UserStatusModel?;
      nostrRepository.usm = statusModel;
      nostrRepository.articleAutoSave = localData[1] as String;
      nostrRepository.isUsingExternalSigner = localData[2] as bool;
      nostrRepository.isUsingNip44 = localData[4] as bool;
      nostrRepository.usedUploadServer = localData[5] as String;
      nostrRepository.SmartWidgetTemplates =
          localData[6] as Map<String, List<SmartWidgetTemplate>>;
      final sw = localData[7] as String;

      Map<String, UserStatusModel> usmList =
          localData[8] as Map<String, UserStatusModel>;

      if (sw.isEmpty) {
        nostrRepository.swAutoSave = {};
      } else {
        final decodedMap = jsonDecode(sw) as Map<String, dynamic>;
        for (final entry in decodedMap.entries) {
          try {
            nostrRepository.swAutoSave[entry.key] =
                SWAutoSaveModel.fromMap(jsonDecode(entry.value));
          } catch (_) {}
        }
      }

      lightningZapsCubit.init();

      if (statusModel == null || !statusModel.isUsingPrivKey) {
        nostrRepository.mutes = localDatabaseRepository.getLocalMutes().toSet();
      }

      if (statusModel != null &&
          (usmList.isEmpty || usmList[statusModel.pubKey] == null)) {
        usmList[statusModel.pubKey] = statusModel;
        localDatabaseRepository.setUsmList(usmList);
      }

      nostrRepository.usmList = usmList;

      final onboardingStatus =
          await localDatabaseRepository.getOnboardingStatus();

      if (onboardingStatus) {
        if (!isClosed)
          emit(
            state.copyWith(
              currentRoute: CurrentRoute.onboarding,
              updatingState: UpdatingState.idle,
            ),
          );

        return;
      }

      final disclosureStatus =
          await localDatabaseRepository.getDisclosureStatus();

      if (disclosureStatus) {
        if (!isClosed)
          emit(
            state.copyWith(
              currentRoute: CurrentRoute.disclosure,
              updatingState: UpdatingState.idle,
            ),
          );

        return;
      }

      if (!isClosed)
        emit(
          state.copyWith(
            updatingState: UpdatingState.idle,
            currentRoute: CurrentRoute.main,
          ),
        );
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        if (!isClosed)
          emit(
            state.copyWith(
              updatingState: UpdatingState.networkFailure,
            ),
          );
      } else {
        if (!isClosed)
          emit(
            state.copyWith(
              updatingState: UpdatingState.failure,
            ),
          );
      }
    }
  }

  void clearWallets() {
    localDatabaseRepository.setUserWallets('');
    localDatabaseRepository.setSelectedWalletId('');
  }

  void setDisclosureView() {
    emit(
      state.copyWith(
        currentRoute: CurrentRoute.disclosure,
        updatingState: UpdatingState.idle,
      ),
    );
  }

  Future<void> initRelays(List<String> chosenRelays) async {
    await NostrConnect.sharedInstance.connectRelays(
      chosenRelays.isEmpty ? nostrRepository.relays.toList() : chosenRelays,
    );
  }

  void setMainView() {
    if (!isClosed)
      emit(
        state.copyWith(currentRoute: CurrentRoute.main),
      );
  }

  @override
  Future<void> close() {
    controller.close();
    _sub.cancel();
    return super.close();
  }
}
