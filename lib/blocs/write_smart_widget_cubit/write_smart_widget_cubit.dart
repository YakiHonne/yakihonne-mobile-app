import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'write_smart_widget_state.dart';

class WriteSmartWidgetCubit extends Cubit<WriteSmartWidgetState> {
  WriteSmartWidgetCubit({
    required this.uuid,
    required this.backgroundColor,
    this.sm,
    this.isCloning,
  }) : super(
          WriteSmartWidgetState(
            isOnboarding: sm == null,
            smartWidgetPublishSteps: SmartWidgetPublishSteps.specifications,
            summary:
                sm != null && isCloning != null && !isCloning ? sm.summary : '',
            title:
                sm != null && isCloning != null && !isCloning ? sm.title : '',
            smartWidgetUpdate: true,
            smartWidgetContainer: sm?.container ??
                SmartWidgetContainer(
                  grids: sm?.container != null ||
                          (sm?.container?.grids.isNotEmpty ?? false)
                      ? sm!.container!.grids
                      : {
                          uuid: SmartWidgetGrid(
                            id: uuid,
                            leftSide: {},
                            rightSide: {},
                          ),
                        },
                  highlightedComponent: '',
                  highlightedGrid: '',
                  borderColorHex: sm?.container?.borderColorHex ?? '',
                  backgroundHex:
                      sm?.container?.backgroundHex ?? backgroundColor,
                  id: sm?.container?.id ?? Uuid().v4(),
                ),
            toggleDisplay: false,
          ),
        ) {
    final container = sm?.container ??
        SmartWidgetContainer(
          grids: sm?.container?.grids ??
              {
                uuid: SmartWidgetGrid(
                  id: uuid,
                  leftSide: {},
                  rightSide: {},
                ),
              },
          highlightedComponent: '',
          highlightedGrid: '',
          borderColorHex: sm?.container?.borderColorHex ?? '',
          backgroundHex: sm?.container?.backgroundHex ?? backgroundColor,
          id: sm?.container?.id ?? Uuid().v4(),
        );

    swAutoSaveModel = SWAutoSaveModel(
      id: Uuid().v4(),
      title: sm != null && isCloning != null && !isCloning! ? sm!.title : '',
      description:
          sm != null && isCloning != null && !isCloning! ? sm!.summary : '',
      content: container.toMap(),
    );
  }

  String uuid;
  String backgroundColor;
  SmartWidgetModel? sm;
  bool? isCloning;
  String? draftId;
  late SWAutoSaveModel swAutoSaveModel;

  void setSwAutoSaveModel(SWAutoSaveModel swAutoSaveModel) {
    this.swAutoSaveModel = swAutoSaveModel;
    final container = SmartWidgetContainer.smartWidgetContrainerfromMap(
      swAutoSaveModel.content,
    );

    if (container != null && container.grids.isEmpty) {
      container.grids = {
        uuid: SmartWidgetGrid(
          id: uuid,
          leftSide: {},
          rightSide: {},
        ),
      };
    }

    emit(
      state.copyWith(
        smartWidgetContainer: container ??
            SmartWidgetContainer(
              grids: sm?.container != null ||
                      (sm?.container?.grids.isNotEmpty ?? false)
                  ? sm!.container!.grids
                  : {
                      uuid: SmartWidgetGrid(
                        id: uuid,
                        leftSide: {},
                        rightSide: {},
                      ),
                    },
              highlightedComponent: '',
              highlightedGrid: '',
              borderColorHex: sm?.container?.borderColorHex ?? '',
              backgroundHex: sm?.container?.backgroundHex ?? backgroundColor,
              id: sm?.container?.id ?? Uuid().v4(),
            ),
        title: swAutoSaveModel.title,
        summary: swAutoSaveModel.description,
        isOnboarding: false,
        smartWidgetUpdate: !state.smartWidgetUpdate,
      ),
    );
  }

  void loadArticleAutoSaveModel(String id) {
    this.swAutoSaveModel =
        nostrRepository.swAutoSave[id] ?? this.swAutoSaveModel;

    final container = SmartWidgetContainer.smartWidgetContrainerfromMap(
      swAutoSaveModel.content,
    );

    if (container != null && container.grids.isEmpty) {
      container.grids = {
        uuid: SmartWidgetGrid(
          id: uuid,
          leftSide: {},
          rightSide: {},
        ),
      };
    }

    emit(
      state.copyWith(
        smartWidgetContainer: container ??
            SmartWidgetContainer(
              grids: sm?.container != null ||
                      (sm?.container?.grids.isNotEmpty ?? false)
                  ? sm!.container!.grids
                  : {
                      uuid: SmartWidgetGrid(
                        id: uuid,
                        leftSide: {},
                        rightSide: {},
                      ),
                    },
              highlightedComponent: '',
              highlightedGrid: '',
              borderColorHex: sm?.container?.borderColorHex ?? '',
              backgroundHex: sm?.container?.backgroundHex ?? backgroundColor,
              id: sm?.container?.id ?? Uuid().v4(),
            ),
        title: swAutoSaveModel.title,
        summary: swAutoSaveModel.description,
        isOnboarding: false,
        smartWidgetUpdate: !state.smartWidgetUpdate,
      ),
    );
  }

  void deleteArticleAutoSaveModel() {
    emit(
      state.copyWith(
        title: '',
      ),
    );

    nostrRepository.setSWAutoSave(swsm: swAutoSaveModel);

    BotToastUtils.showSuccess(
      'Auto-saved smart widget has been deleted',
    );
  }

  void setTitle(String title) {
    emit(
      state.copyWith(
        title: title,
      ),
    );

    swAutoSaveModel = swAutoSaveModel.copyWith(
      title: title,
    );

    nostrRepository.setSWAutoSave(swsm: swAutoSaveModel);
  }

  void setSummary(String summary) {
    emit(
      state.copyWith(
        summary: summary,
      ),
    );

    swAutoSaveModel = swAutoSaveModel.copyWith(
      description: summary,
    );

    nostrRepository.setSWAutoSave(swsm: swAutoSaveModel);
  }

  void setOnboardingOff() {
    emit(
      state.copyWith(
        isOnboarding: false,
      ),
    );
  }

  void setSmartWidgetContainer(SmartWidgetContainer smartWidgetContainer) {
    emit(
      state.copyWith(
        smartWidgetUpdate: !state.smartWidgetUpdate,
        smartWidgetContainer: smartWidgetContainer,
      ),
    );

    updateContainerAutoSave();
  }

  void setFramePublishStep(SmartWidgetPublishSteps step) {
    emit(
      state.copyWith(
        smartWidgetPublishSteps: step,
      ),
    );
  }

  void addCompoenent({
    required SmartWidgetComponent component,
    int? index,
    String? horizontalGridId,
    bool? isLeftSide,
  }) {
    SmartWidgetContainer frame = state.smartWidgetContainer.copyWith();

    frame.addComponent(
      frameComponent: component,
      horizontalGridId: horizontalGridId,
      isLeftSide: isLeftSide,
      index: index,
    );

    emit(
      state.copyWith(
        smartWidgetContainer: frame,
        smartWidgetUpdate: !state.smartWidgetUpdate,
      ),
    );

    updateContainerAutoSave();
  }

  void toggleGrid(String gridId) {
    SmartWidgetContainer frame = state.smartWidgetContainer.copyWith();
    final grid = frame.grids[gridId]!;
    final leftGrid = Map<String, SmartWidgetComponent>.from(grid.leftSide);
    grid.leftSide = grid.rightSide;
    grid.rightSide = leftGrid;
    frame.grids[gridId] = grid;

    emit(
      state.copyWith(
        smartWidgetContainer: frame,
        smartWidgetUpdate: !state.smartWidgetUpdate,
      ),
    );

    updateContainerAutoSave();
  }

  void updateComponent({
    required SmartWidgetComponent component,
  }) {
    SmartWidgetContainer frame = state.smartWidgetContainer.copyWith();
    frame.updateComponent(component: component);

    emit(
      state.copyWith(
        smartWidgetContainer: frame,
        smartWidgetUpdate: !state.smartWidgetUpdate,
      ),
    );

    updateContainerAutoSave();
  }

  void moveComponent({
    required String componentId,
    required bool toBottom,
    String? horizontalGridId,
  }) {
    SmartWidgetContainer frame = state.smartWidgetContainer.copyWith();

    frame.moveComponent(
      componentId: componentId,
      toBottom: toBottom,
      horizontalGridId: horizontalGridId,
    );

    emit(
      state.copyWith(
        smartWidgetContainer: frame,
        smartWidgetUpdate: !state.smartWidgetUpdate,
      ),
    );

    updateContainerAutoSave();
  }

  void deleteComponent({
    required String componentId,
    String? horizontalGridId,
  }) {
    SmartWidgetContainer frame = state.smartWidgetContainer.copyWith();

    frame.deleteComponent(
      componentId: componentId,
      horizontalGridId: horizontalGridId,
    );

    emit(
      state.copyWith(
        smartWidgetContainer: frame,
        smartWidgetUpdate: !state.smartWidgetUpdate,
      ),
    );

    updateContainerAutoSave();
  }

  void setHighlightedComponents({
    required String gridId,
    required String componentId,
  }) {
    String e = state.smartWidgetContainer.highlightedComponent;
    String selectedGrid = state.smartWidgetContainer.highlightedGrid;

    if (e == componentId) {
      e = '';
      selectedGrid = '';
    } else {
      e = componentId;
      selectedGrid = gridId;
    }

    SmartWidgetContainer frame = state.smartWidgetContainer.copyWith(
      highlightedComponent: e,
      highlightedGrid: selectedGrid,
    );

    emit(
      state.copyWith(
        smartWidgetContainer: frame,
        smartWidgetUpdate: !state.smartWidgetUpdate,
      ),
    );

    updateContainerAutoSave();
  }

  void uploadMediaAndSend({
    required File file,
    required Function(String) onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    final mediaLink = await HttpFunctionsRepository.uploadMedia(file: file);

    if (mediaLink != null) {
      _cancel.call();
      onSuccess.call(mediaLink);
    } else {
      _cancel.call();
      BotToastUtils.showError('Error occured while uploading the media');
    }
  }

  void updateContainerAutoSave() {
    swAutoSaveModel = swAutoSaveModel.copyWith(
      content: state.smartWidgetContainer.toMap(),
    );

    nostrRepository.setSWAutoSave(swsm: swAutoSaveModel);
  }

  Future<void> setSmartWidget({
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    try {
      final appClients = appClientsCubit.state.appClients.values
          .where((element) => element.pubkey == yakihonneHex)
          .toList();

      final event = await Event.genEvent(
        content: jsonEncode(state.smartWidgetContainer.toMap()),
        kind: EventKind.SMART_WIDGET,
        privkey: nostrRepository.usm!.privKey,
        pubkey: nostrRepository.usm!.pubKey,
        tags: [
          [
            'client',
            'YakiHonne',
            appClients.isEmpty
                ? 'YakiHonne'
                : '${EventKind.APPLICATION_INFO.toString()}:${appClients.first.pubkey}:${appClients.first.identifier}'
          ],
          [
            'd',
            sm != null && isCloning != null && !isCloning!
                ? sm!.identifier
                : randomHexString(16)
          ],
          ['title', state.title],
          ['summary', state.summary],
          [
            'published_at',
            sm != null && isCloning != null && !isCloning!
                ? sm!.publishedAt.toSecondsSinceEpoch().toString()
                : currentUnixTimestampSeconds().toString(),
          ],
        ],
      );

      if (event == null) {
        _cancel.call();
        return;
      }

      _cancel.call();

      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: true,
      );

      if (isSuccessful) {
        onSuccess.call();
        nostrRepository.deleteAutoSave(swAutoSaveModel.id);
        BotToastUtils.showSuccess(
          'Smart widget has been published successfuly',
        );
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }

      _cancel.call();
    } catch (e) {
      _cancel.call();
      BotToastUtils.showError('An error occured while adding the smart widget');
    }
  }
}
