import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'add_curation_state.dart';

class AddCurationCubit extends Cubit<AddCurationState> {
  AddCurationCubit({
    required this.nostrRepository,
    required this.isAddingOperation,
    required this.curation,
  }) : super(
          AddCurationState(
            imageLink: isAddingOperation ? '' : curation?.image ?? '',
            isLocalImage: false,
            isImageSelected: !isAddingOperation,
            isArticlesCuration: true,
            localImage: null,
            selectedRelays: curation == null
                ? mandatoryRelays
                : [
                    ...mandatoryRelays,
                    ...curation.relays.toList(),
                  ].toSet().toList(),
            totalRelays: nostrRepository.relays.toList(),
            curationPublishSteps: CurationPublishSteps.content,
            title: curation?.title ?? '',
            description: curation?.description ?? '',
            isZapSplitEnabled: curation?.zapsSplits.isNotEmpty ?? false,
            zapsSplits: curation?.zapsSplits ??
                [
                  ZapSplit(
                    pubkey: nostrRepository.usm!.pubKey,
                    percentage: 95,
                  ),
                  ZapSplit(
                    pubkey: yakihonneHex,
                    percentage: 5,
                  ),
                ],
          ),
        );

  final NostrDataRepository nostrRepository;
  final bool isAddingOperation;
  final Curation? curation;

  void toggleZapsSplits() {
    if (!isClosed)
      emit(
        state.copyWith(
          isZapSplitEnabled: !state.isZapSplitEnabled,
        ),
      );
  }

  void setZapPropertion({
    required int index,
    required ZapSplit zapSplit,
    required int newPercentage,
  }) {
    final zaps = List<ZapSplit>.from(state.zapsSplits);

    zaps[index] = ZapSplit(
      pubkey: zapSplit.pubkey,
      percentage: newPercentage,
    );

    emit(
      state.copyWith(
        zapsSplits: zaps,
      ),
    );
  }

  void addZapSplit(String pubkey) {
    final zaps = List<ZapSplit>.from(state.zapsSplits);
    final doesNotExist =
        zaps.where((element) => element.pubkey == pubkey).toList().isEmpty;

    if (doesNotExist) {
      zaps.add(
        ZapSplit(
          pubkey: pubkey,
          percentage: 1,
        ),
      );

      emit(
        state.copyWith(
          zapsSplits: zaps,
        ),
      );
    }
  }

  void onRemoveZapSplit(String pubkey) {
    if (state.zapsSplits.length > 1) {
      final zaps = List<ZapSplit>.from(state.zapsSplits);
      zaps.removeWhere(
        (element) => element.pubkey == pubkey,
      );

      emit(
        state.copyWith(
          zapsSplits: zaps,
        ),
      );
    } else {
      BotToastUtils.showError(
        'For zap splits, there should be at least one person',
      );
    }
  }

  Future<void> selectProfileImage({
    required Function() onFailed,
  }) async {
    if (Platform.isIOS) {
      try {
        final XFile? image;
        image = await ImagePicker().pickImage(source: ImageSource.gallery);

        if (image != null) {
          final file = File(image.path);

          if (!isClosed)
            emit(
              state.copyWith(
                localImage: file,
                isLocalImage: true,
                imageLink: '',
                isImageSelected: true,
              ),
            );
        }
      } catch (e) {
        onFailed.call();
      }
    } else {
      if (!isClosed)
        emit(
          state.copyWith(
            localImage: null,
            isLocalImage: false,
            isImageSelected: false,
          ),
        );

      bool storage = true;
      bool photos = true;

      final deviceInfo = await DeviceInfoPlugin().androidInfo;

      if (deviceInfo.version.sdkInt >= 33) {
        photos = await _requestPermission(Permission.photos);
      } else {
        storage = await _requestPermission(Permission.storage);
      }

      if (storage && photos) {
        final XFile? image;
        image = await ImagePicker().pickImage(source: ImageSource.gallery);

        if (image != null) {
          final file = File(image.path);

          if (!isClosed)
            emit(
              state.copyWith(
                localImage: file,
                isLocalImage: true,
                imageLink: '',
                isImageSelected: true,
              ),
            );
        }
      } else {
        onFailed.call();
      }
    }
  }

  void setTitle(String title) {
    emit(
      state.copyWith(
        title: title,
      ),
    );
  }

  void setDescription(String description) {
    emit(
      state.copyWith(
        description: description,
      ),
    );
  }

  void setCurationType() {
    emit(
      state.copyWith(
        isArticlesCuration: !state.isArticlesCuration,
      ),
    );
  }

  void setView(bool isNext) {
    late CurationPublishSteps nextStep;
    if (isNext) {
      nextStep = state.curationPublishSteps == CurationPublishSteps.content
          ? CurationPublishSteps.zaps
          : CurationPublishSteps.relays;
    } else {
      nextStep = state.curationPublishSteps == CurationPublishSteps.relays
          ? CurationPublishSteps.zaps
          : CurationPublishSteps.content;
    }

    emit(
      state.copyWith(
        curationPublishSteps: nextStep,
      ),
    );
  }

  void setRelaySelection(String relay) {
    if (state.selectedRelays.contains(relay)) {
      if (!isClosed)
        emit(
          state.copyWith(
            selectedRelays: List.from(state.selectedRelays)..remove(relay),
          ),
        );
    } else {
      if (!isClosed)
        emit(
          state.copyWith(
            selectedRelays: List.from(state.selectedRelays)..add(relay),
          ),
        );
    }
  }

  Future<void> selectUrlImage({
    required String url,
    required Function() onFailed,
  }) async {
    if (url.trim().isEmpty || !url.startsWith('https')) {
      onFailed.call();
      return;
    }

    if (!isClosed)
      emit(
        state.copyWith(
          localImage: null,
          isLocalImage: false,
          isImageSelected: true,
          imageLink: url,
        ),
      );
  }

  void removeImage() {
    if (!isClosed)
      emit(
        state.copyWith(
          localImage: null,
          isLocalImage: false,
          isImageSelected: false,
          imageLink: '',
        ),
      );
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }

  Future<String> uploadImage() async {
    try {
      return await HttpFunctionsRepository.uploadImage(
        file: state.localImage!,
        pubKey: nostrRepository.usm!.pubKey,
      );
    } catch (e) {
      Logger().i(e);
      rethrow;
    }
  }

  Future<void> addCuration({
    required Function(String) onFailure,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    try {
      if (state.title.trim().isEmpty) {
        onFailure.call(
          'Make sure to add a valid title for this curation',
        );
        _cancel.call();
        return;
      }

      if (!state.isImageSelected) {
        onFailure.call(
          'Make sure to add a valid image for this curation',
        );
        _cancel.call();
        return;
      }

      String imageLink = '';

      if (state.isLocalImage) {
        imageLink = await uploadImage();
      } else {
        imageLink = state.imageLink;
      }

      List<List<String>> articles = [];

      if (!isAddingOperation && curation != null) {
        for (final element in curation!.eventsIds) {
          if (element.kind == EventKind.LONG_FORM) {
            articles.add(
              ['a', element.toString()],
            );
          }
        }
      }

      final event = await Event.genEvent(
        kind: state.isArticlesCuration
            ? EventKind.CURATION_ARTICLES
            : EventKind.CURATION_VIDEOS,
        content: '',
        privkey: nostrRepository.usm!.privKey,
        pubkey: nostrRepository.usm!.pubKey,
        verify: true,
        tags: [
          ['d', isAddingOperation ? randomHexString(16) : curation!.identifier],
          ['title', state.title.trim()],
          ['description', state.description.trim()],
          ['image', imageLink],
          [
            'published_at',
            curation != null
                ? curation!.publishedAt.toSecondsSinceEpoch().toString()
                : currentUnixTimestampSeconds().toString(),
          ],
          if (state.isZapSplitEnabled)
            ...state.zapsSplits.map(
              (e) => [
                'zap',
                e.pubkey,
                mandatoryRelays.first,
                e.percentage.toString(),
              ],
            ),
        ]..addAll(articles),
      );

      if (event == null) {
        _cancel.call();
        return;
      }

      final isSuccessful = await NostrFunctionsRepository.addEvent(
        event: event,
        relays: state.selectedRelays,
      );

      if (isSuccessful) {
        onSuccess.call();
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }

      _cancel.call();
    } catch (_) {
      _cancel.call();
      onFailure.call(
        'An error occured while ${isAddingOperation ? 'adding' : 'updating'} the curation',
      );
    }
  }
}
