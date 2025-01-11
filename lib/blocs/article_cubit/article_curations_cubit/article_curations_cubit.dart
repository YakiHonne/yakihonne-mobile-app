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
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

import '../../../nostr/nostr.dart';

part 'article_curations_state.dart';

class ArticleCurationsCubit extends Cubit<ArticleCurationsState> {
  ArticleCurationsCubit({
    required String articleId,
    required String articleAuthor,
    required int kind,
    required this.nostrRepository,
  }) : super(
          ArticleCurationsState(
            userStatus: getUserStatus(),
            articleId: articleId,
            articleAuthor: articleAuthor,
            curations: [],
            isCurationsLoading: true,
            articleCuration: ArticleCuration.curationsList,
            imageLink: '',
            isLocalImage: false,
            isImageSelected: false,
            localImage: null,
            description: '',
            title: '',
            selectedRelays: mandatoryRelays,
            curationKind: kind,
            totalRelays: nostrRepository.relays.toList(),
            isZapSplitEnabled: false,
            zapsSplits: [
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
        ) {
    if (nostrRepository.usm != null) {
      getCurations();
    }
  }

  final NostrDataRepository nostrRepository;
  Timer? curationsTimer;
  Set<String> requests = {};

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

  void setText(bool isTitle, String text) {
    if (isTitle) {
      emit(
        state.copyWith(
          title: text,
        ),
      );
    } else {
      emit(
        state.copyWith(
          description: text,
        ),
      );
    }
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

  void canProceedToRelays(
      {required Function() onSuccess, required Function() on}) {}

  void emptyText() {
    emit(
      state.copyWith(
        title: '',
        description: '',
      ),
    );
  }

  void getCurations() {
    curationsTimer?.cancel();

    if (!isClosed)
      emit(
        state.copyWith(
          curations: [],
          isCurationsLoading: true,
        ),
      );

    Map<String, Curation> curationsToBeEmitted = {};

    final request = NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: [state.curationKind],
          authors: [nostrRepository.user.pubKey],
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        if (event.kind == state.curationKind) {
          final curation = Curation.fromEvent(event, relay);

          final oldCuration = curationsToBeEmitted[curation.identifier];

          curationsToBeEmitted[curation.identifier] = filterCuration(
            oldCuration: oldCuration,
            newCuration: curation,
          );
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        if (curationsToBeEmitted.isNotEmpty) {
          List<Curation> curations = List.from(state.curations);

          curations.removeWhere(
            (element) => curationsToBeEmitted.keys.contains(element.identifier),
          );

          curations.insertAll(0, curationsToBeEmitted.values);

          if (!isClosed)
            emit(
              state.copyWith(
                curations: curations,
                isCurationsLoading: false,
              ),
            );
        } else {
          if (!isClosed)
            emit(
              state.copyWith(
                curations: [],
                isCurationsLoading: false,
              ),
            );
        }

        NostrConnect.sharedInstance.closeSubscription(curationRequestId, relay);
      },
    );

    curationsTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (timer.tick >= 6 && state.curations.isEmpty) {
          timer.cancel;

          emit(
            state.copyWith(
              isCurationsLoading: false,
            ),
          );
        }
      },
    );

    requests.add(request);
  }

  void setView(ArticleCuration articleCuration) {
    emit(
      state.copyWith(
        articleCuration: articleCuration,
      ),
    );
  }

  Curation filterCuration({
    required Curation? oldCuration,
    required Curation newCuration,
  }) {
    if (oldCuration != null) {
      final isNew = oldCuration.createdAt.compareTo(newCuration.createdAt) < 1;
      if (isNew) {
        newCuration.relays.addAll(oldCuration.relays);
        return newCuration;
      } else {
        oldCuration.relays.addAll(newCuration.relays);
        return oldCuration;
      }
    } else {
      return newCuration;
    }
  }

  Future<void> setCuration({
    required Curation curation,
    required Function(String) onFailure,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    try {
      final articlesList = curation.eventsIds
          .map(
            (event) => [
              'a',
              EventCoordinates(
                EventKind.LONG_FORM,
                event.pubkey,
                event.identifier,
                '',
              ).toString()
            ],
          )
          .toList();

      articlesList.add(
        [
          'a',
          EventCoordinates(
            EventKind.LONG_FORM,
            state.articleAuthor,
            state.articleId,
            '',
          ).toString()
        ],
      );

      final event = await Event.genEvent(
        kind: state.curationKind,
        content: '',
        pubkey: nostrRepository.usm!.pubKey,
        privkey: nostrRepository.usm!.privKey,
        verify: true,
        tags: [
          ['d', curation.identifier],
          ['title', curation.title],
          ['description', curation.description],
          ['image', curation.image],
        ]..addAll(articlesList),
      );

      if (event == null) {
        _cancel.call();
        return;
      }

      final isSuccessful = await NostrFunctionsRepository.addEvent(
        event: event,
      );

      if (isSuccessful) {
        onSuccess.call();
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }

      _cancel.call();
    } catch (_) {
      onFailure.call(
        'An error occured while updating the curation',
      );
    }
  }

  Future<void> addCuration({
    required Function(String) onFailure,
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

      final event = await Event.genEvent(
        kind: state.curationKind,
        content: '',
        pubkey: nostrRepository.usm!.pubKey,
        privkey: nostrRepository.usm!.privKey,
        verify: true,
        tags: [
          ['d', randomHexString(16)],
          ['title', state.title],
          ['description', state.description],
          ['image', imageLink],
          [
            'published_at',
            currentUnixTimestampSeconds().toString(),
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
        ],
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
        emit(
          state.copyWith(
            curations: List<Curation>.from(state.curations)
              ..add(
                Curation.fromEvent(event, ''),
              ),
            articleCuration: ArticleCuration.curationsList,
          ),
        );
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }

      _cancel.call();
    } catch (_) {
      _cancel.call();
      onFailure.call(
        'An error occured while adding the curation',
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
}
