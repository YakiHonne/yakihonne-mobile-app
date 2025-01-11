import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'write_video_state.dart';

class WriteVideoCubit extends Cubit<WriteVideoState> {
  WriteVideoCubit({
    required this.videoModel,
  }) : super(
          WriteVideoState(
            contentWarning: videoModel?.contentWarning ?? '',
            isHorizontal: videoModel?.isHorizontal ?? true,
            isLocalImage: false,
            isImageSelected: videoModel != null,
            selectedRelays: mandatoryRelays,
            totalRelays: nostrRepository.relays.toList(),
            tags: videoModel?.tags ?? [],
            summary: videoModel?.summary ?? '',
            title: videoModel?.title ?? '',
            imageLink: videoModel?.thumbnail ?? '',
            suggestions: [],
            videoUrl: videoModel?.url ?? '',
            videoPublishSteps: VideoPublishSteps.content,
            isUpdating: videoModel != null,
            isZapSplitEnabled: videoModel?.zapsSplits.isNotEmpty ?? false,
            mimeType: videoModel?.mimeType ?? '',
            zapsSplits: videoModel?.zapsSplits ??
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
        ) {
    setSuggestions();
  }

  VideoModel? videoModel;

  void toggleVideoOrientation() {
    if (!isClosed)
      emit(
        state.copyWith(
          isHorizontal: !state.isHorizontal,
        ),
      );
  }

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

  void setSuggestions() {
    Set<String> suggestions = {};
    for (final topic in nostrRepository.topics) {
      suggestions.addAll([topic.topic, ...topic.subTopics]);
      suggestions.addAll(nostrRepository.userTopics);
    }

    emit(
      state.copyWith(suggestions: suggestions.toList()),
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

  void setVideoPublishStep(VideoPublishSteps step) {
    if (state.videoPublishSteps == VideoPublishSteps.content) {
      final title = state.title.trim();
      final videoUrl = state.videoUrl.trim();

      if (title.isEmpty || videoUrl.isEmpty) {
        BotToastUtils.showError('Make sure to set all the required content.');
        return;
      }
    }

    emit(
      state.copyWith(
        videoPublishSteps: step,
      ),
    );
  }

  void setTitle(String title) {
    emit(
      state.copyWith(
        title: title,
      ),
    );
  }

  void setSummary(String summary) {
    emit(
      state.copyWith(
        summary: summary,
      ),
    );
  }

  void setUrl(String videoUrl) {
    emit(
      state.copyWith(
        videoUrl: videoUrl,
      ),
    );
  }

  void addKeyword(String keyword) {
    if (!state.tags.contains(keyword.trim())) {
      final tags = [...state.tags, keyword.trim()];

      if (!isClosed)
        emit(
          state.copyWith(
            tags: tags,
          ),
        );
    }
  }

  void deleteKeyword(String keyword) {
    if (state.tags.contains(keyword)) {
      final tags = List<String>.from(state.tags)..remove(keyword);

      if (!isClosed)
        emit(
          state.copyWith(
            tags: tags,
          ),
        );
    }
  }

  void addFileMetadata(String nevent) {
    if (nevent.startsWith('nevent') || nevent.startsWith('nostr:nevent')) {
      final _cancel = BotToast.showLoading();
      final map = Nip19.decodeShareableEntity(nevent);

      if (map['prefix'] == 'nevent' && map['kind'] == EventKind.FILE_METADATA) {
        Event? currentEvent;

        NostrFunctionsRepository.getEvents(
          ids: [map['special']],
          pubkeys: [map['author']],
        ).listen((event) {
          currentEvent = event;
        }).onDone(
          () {
            if (currentEvent == null) {
              BotToastUtils.showError(
                'No event with this nevent can be found!',
              );
            } else {
              String url = '';
              bool isVideo = false;

              for (final tag in currentEvent!.tags) {
                if (tag.first == 'url' && tag.length > 1) {
                  url = tag[1];
                } else if (tag.first == 'm' && tag.length > 1) {
                  isVideo = tag[1].toLowerCase().startsWith('video/');
                }
              }

              if (!isVideo) {
                BotToastUtils.showError(
                  'This nevent is not a video!',
                );
              } else if (url.isEmpty) {
                BotToastUtils.showError(
                  'This nevent has an empty url',
                );
              } else {
                emit(
                  state.copyWith(videoUrl: url),
                );
              }
            }
          },
        );
      } else {
        BotToastUtils.showError('Please submit a valid nevent link');
      }

      _cancel.call();
    } else {
      BotToastUtils.showError('Please submit an nevent link');
    }
  }

  Future<void> selectAndUploadVideo() async {
    if (Platform.isIOS) {
      try {
        final _cancel = BotToast.showLoading();

        final XFile? video;
        video = await ImagePicker().pickVideo(source: ImageSource.gallery);

        if (video != null) {
          final file = File(video.path);
          final data = await uploadVideo(file);
          if (data.isEmpty || (data['url'] ?? '').isEmpty) {
            BotToastUtils.showError('Error occured while uploading the video');
            return;
          }

          if (!isClosed)
            emit(
              state.copyWith(
                videoUrl: data['url'],
                imageLink: data['thumbnail'] ?? '',
                mimeType: data['m'] ?? '',
              ),
            );
        }

        _cancel.call();
      } catch (e) {
        BotToastUtils.showError('Error occured while uploading the video');
      }
    } else {
      bool storage = true;
      bool photos = true;

      final deviceInfo = await DeviceInfoPlugin().androidInfo;

      if (deviceInfo.version.sdkInt >= 33) {
        photos = await _requestPermission(Permission.photos);
      } else {
        storage = await _requestPermission(Permission.storage);
      }

      if (storage && photos) {
        final _cancel = BotToast.showLoading();
        final XFile? video;
        video = await ImagePicker().pickVideo(source: ImageSource.gallery);

        if (video != null) {
          final file = File(video.path);
          final data = await uploadVideo(file);
          if (data.isEmpty || (data['url'] ?? '').isEmpty) {
            BotToastUtils.showError('Error occured while uploading the video');
            return;
          }
          _cancel.call();
          if (!isClosed)
            emit(
              state.copyWith(
                videoUrl: data['url'],
                imageLink: data['thumbnail'] ?? '',
                mimeType: data['m'] ?? '',
              ),
            );
        }
      } else {
        BotToastUtils.showError('Error occured while uploading the video');
      }
    }
  }

  Future<Map<String, String>> uploadVideo(File video) async {
    try {
      return await HttpFunctionsRepository.uploadVideo(
        file: video,
      );
    } catch (e) {
      Logger().i(e);
      rethrow;
    }
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

  Future<void> setVideo({
    required Function(String) onFailure,
    required Function(
      List<String> successfulRelays,
      List<String> unsuccessfulRelays,
    ) onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    try {
      String thumbnail = '';

      if (state.isLocalImage) {
        thumbnail = await uploadImage();
      } else {
        thumbnail = state.imageLink;
      }

      List<String> successfulRelays = [];

      final appClients = appClientsCubit.state.appClients.values
          .where((element) => element.pubkey == yakihonneHex)
          .toList();

      final event = await Event.genEvent(
        content: state.summary,
        kind: state.isHorizontal
            ? EventKind.VIDEO_HORIZONTAL
            : EventKind.VIDEO_VERTICAL,
        privkey: nostrRepository.usm!.privKey,
        pubkey: nostrRepository.usm!.pubKey,
        tags: [
          [
            'client',
            appClients.isEmpty
                ? 'YakiHonne'
                : '${EventKind.APPLICATION_INFO.toString()}:${appClients.first.pubkey}:${appClients.first.identifier}'
          ],
          [
            'd',
            videoModel != null ? videoModel!.identifier : randomHexString(16)
          ],
          ['url', state.videoUrl],
          ['thumb', thumbnail],
          ['title', state.title],
          [
            'published_at',
            videoModel != null
                ? videoModel!.publishedAt.toSecondsSinceEpoch().toString()
                : currentUnixTimestampSeconds().toString(),
          ],
          ...state.tags.map((tag) => ['t', tag]),
          if (state.mimeType.isNotEmpty) ['m', state.mimeType],
          if (state.contentWarning.isNotEmpty)
            ['content-warning', state.contentWarning],
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

      NostrFunctionsRepository.sendEventWithRelays(
        event: event,
        relays: state.selectedRelays,
      ).listen(
        (relays) {
          successfulRelays = relays;
        },
        onDone: () {
          if (successfulRelays.isEmpty) {
            BotToastUtils.showUnreachableRelaysError();
          } else {
            onSuccess.call(
              successfulRelays.toList(),
              state.selectedRelays.length == successfulRelays.length
                  ? []
                  : List.from(state.selectedRelays)
                ..removeWhere(
                  (relay) => successfulRelays.contains(relay),
                ),
            );
          }

          _cancel.call();
        },
      );
      // _cancel.call();
    } catch (e) {
      _cancel.call();
      onFailure.call(
        'An error occured while adding the article',
      );
    }
  }
}
