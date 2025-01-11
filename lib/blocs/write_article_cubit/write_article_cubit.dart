import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'write_article_state.dart';

class WriteArticleCubit extends Cubit<WriteArticleState> {
  WriteArticleCubit({
    required this.nostrRepository,
    this.article,
  }) : super(
          WriteArticleState(
            articlePublishSteps: ArticlePublishSteps.content,
            content: article?.content ?? '',
            excerpt: article?.summary ?? '',
            isZapSplitEnabled: article?.zapsSplits.isNotEmpty ?? false,
            zapsSplits: article?.zapsSplits ??
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
            isSensitive: article?.isSensitive ?? false,
            keywords: article?.hashTags ?? [],
            selectedRelays: mandatoryRelays,
            totalRelays: nostrRepository.relays.toList(),
            title: article?.title ?? '',
            imageLink: article?.image ?? '',
            isImageSelected: article?.image.isNotEmpty ?? false,
            isLocalImage: false,
            isDraft: article?.isDraft ?? false,
            deleteDraft: true,
            localImage: null,
            forwardedAsDraft: false,
            suggestions: [],
            tryToLoad: false,
          ),
        ) {
    setSuggestions();

    articleAutoSaveModel = ArticleAutoSaveModel(
      content: article?.content ?? '',
      title: article?.title ?? '',
      description: article?.summary ?? '',
      isSensitive: article?.isSensitive ?? false,
      tags: article?.hashTags ?? [],
    );
  }

  final NostrDataRepository nostrRepository;
  final Article? article;

  late ArticleAutoSaveModel articleAutoSaveModel;

  void loadArticleAutoSaveModel() {
    this.articleAutoSaveModel = ArticleAutoSaveModel.fromJson(
      nostrRepository.articleAutoSave,
    );

    emit(
      state.copyWith(
        content: articleAutoSaveModel.content,
        isSensitive: articleAutoSaveModel.isSensitive,
        title: articleAutoSaveModel.title,
        keywords: articleAutoSaveModel.tags,
        excerpt: articleAutoSaveModel.description,
        tryToLoad: !state.tryToLoad,
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

  void deleteArticleAutoSaveModel() {
    emit(
      state.copyWith(
        content: '',
        isSensitive: false,
        title: '',
        keywords: [],
        excerpt: '',
      ),
    );

    nostrRepository.setArticleAutoSave(content: '');

    BotToastUtils.showSuccess(
      'Auto-saved article has been deleted',
    );
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

  void setFinalStep() {
    BotToast.showText(
      text: 'Select relays in which you are going to save your draft',
      contentColor: kOrange,
      textStyle: TextStyle(
        color: kWhite,
        fontSize: 12,
      ),
    );

    if (!isClosed)
      emit(
        state.copyWith(
          articlePublishSteps: ArticlePublishSteps.publish,
          forwardedAsDraft: true,
        ),
      );
  }

  void toggleDraftDeletion() {
    if (!isClosed)
      emit(
        state.copyWith(
          deleteDraft: !state.deleteDraft,
        ),
      );
  }

  void setArticleStep(bool isNext) {
    if (state.forwardedAsDraft &&
        state.articlePublishSteps == ArticlePublishSteps.publish &&
        !isNext) {
      if (!isClosed)
        emit(
          state.copyWith(
            articlePublishSteps: ArticlePublishSteps.content,
            forwardedAsDraft: false,
          ),
        );

      return;
    }

    late ArticlePublishSteps step;

    if (isNext) {
      step = state.articlePublishSteps == ArticlePublishSteps.content
          ? ArticlePublishSteps.details
          : state.articlePublishSteps == ArticlePublishSteps.details
              ? ArticlePublishSteps.zaps
              : ArticlePublishSteps.publish;
    } else {
      step = state.articlePublishSteps == ArticlePublishSteps.publish
          ? ArticlePublishSteps.zaps
          : state.articlePublishSteps == ArticlePublishSteps.zaps
              ? ArticlePublishSteps.details
              : ArticlePublishSteps.content;
    }

    if (!isClosed)
      emit(
        state.copyWith(
          articlePublishSteps: step,
          forwardedAsDraft: false,
        ),
      );
  }

  void toggleSensitive() {
    if (!isClosed)
      emit(
        state.copyWith(
          isSensitive: !state.isSensitive,
        ),
      );

    articleAutoSaveModel = articleAutoSaveModel.copyWith(
      isSensitive: state.isSensitive,
    );

    nostrRepository.setArticleAutoSave(
      content: articleAutoSaveModel.toJson(),
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

  void setTitleText(String title) {
    if (!isClosed)
      emit(
        state.copyWith(
          title: title,
        ),
      );

    articleAutoSaveModel = articleAutoSaveModel.copyWith(
      title: title,
    );

    nostrRepository.setArticleAutoSave(
      content: articleAutoSaveModel.title.trim().isEmpty &&
              articleAutoSaveModel.content.trim().isEmpty
          ? ''
          : articleAutoSaveModel.toJson(),
    );
  }

  void setContentText(String content) {
    if (!isClosed)
      emit(
        state.copyWith(
          content: content,
        ),
      );

    articleAutoSaveModel = articleAutoSaveModel.copyWith(
      content: content,
    );

    nostrRepository.setArticleAutoSave(
      content: articleAutoSaveModel.toJson(),
    );
  }

  void setDescription(String description) {
    if (!isClosed)
      emit(
        state.copyWith(excerpt: description),
      );

    articleAutoSaveModel = articleAutoSaveModel.copyWith(
      description: description,
    );

    nostrRepository.setArticleAutoSave(
      content: articleAutoSaveModel.toJson(),
    );
  }

  Future<void> selectProfileImage({
    required Function() onFailed,
  }) async {
    if (!isClosed)
      emit(
        state.copyWith(
          localImage: null,
          isLocalImage: false,
          isImageSelected: false,
        ),
      );

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
                isImageSelected: true,
              ),
            );
        }
      } catch (e) {
        onFailed.call();
      }
    } else if (Platform.isAndroid) {
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

  void addKeyword(String keyword) {
    if (!state.keywords.contains(keyword.trim())) {
      final keywords = [...state.keywords, keyword.trim()];

      if (!isClosed)
        emit(
          state.copyWith(
            keywords: keywords,
          ),
        );

      articleAutoSaveModel = articleAutoSaveModel.copyWith(
        tags: keywords,
      );

      nostrRepository.setArticleAutoSave(
        content: articleAutoSaveModel.toJson(),
      );
    }
  }

  void deleteKeyword(String keyword) {
    if (state.keywords.contains(keyword)) {
      final keywords = List<String>.from(state.keywords)..remove(keyword);

      if (!isClosed)
        emit(
          state.copyWith(
            keywords: keywords,
          ),
        );

      articleAutoSaveModel = articleAutoSaveModel.copyWith(
        tags: keywords,
      );

      nostrRepository.setArticleAutoSave(
        content: articleAutoSaveModel.toJson(),
      );
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

  Future<void> setArticle({
    required bool isDraft,
    required Function(String) onFailure,
    required Function(
      List<String> successfulRelays,
      List<String> unsuccessfulRelays,
    ) onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    try {
      String articleImage = '';

      if (state.isLocalImage) {
        articleImage = await uploadImage();
      } else {
        articleImage = state.imageLink;
      }

      List<String> successfulRelays = [];

      final appClients = appClientsCubit.state.appClients.values
          .where((element) => element.pubkey == yakihonneHex)
          .toList();

      final event = await Event.genEvent(
        content: state.content,
        kind: isDraft ? EventKind.LONG_FORM_DRAFT : EventKind.LONG_FORM,
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
          ['d', article != null ? article!.identifier : randomHexString(16)],
          ['image', articleImage],
          ['title', state.title],
          ['summary', state.excerpt],
          [
            'published_at',
            article != null
                ? article!.publishedAt.toSecondsSinceEpoch().toString()
                : currentUnixTimestampSeconds().toString(),
          ],
          if (state.isSensitive) ['L', 'content-warning'],
          ...state.keywords.map((tag) => ['t', tag]),
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
            nostrRepository.refreshSelfArticlesController.add(true);
            nostrRepository.setArticleAutoSave(
              content: '',
            );

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

          if (article != null &&
              article!.isDraft &&
              !isDraft &&
              state.deleteDraft)
            deleteArticle(
              article!.articleId,
              () {},
            );

          _cancel.call();
        },
      );
    } catch (e) {
      _cancel.call();
      onFailure.call(
        'An error occured while adding the article',
      );
    }
  }

  void deleteArticle(
    String eventId,
    Function() onSuccess,
  ) async {
    final isSuccessful = await NostrFunctionsRepository.deleteEvent(
      eventId: eventId,
    );

    if (isSuccessful) {
      onSuccess.call();
    }
  }
}
