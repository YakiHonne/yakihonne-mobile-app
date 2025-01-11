import 'package:aescryptojs/aescryptojs.dart';
import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'write_flash_news_state.dart';

final starting = 'nostr:npub1';

RegExp npubRegex = RegExp(
  r'@?(nostr:)?@?(npub1)([qpzry9x8gf2tvdw0s3jn54khce6mua7l]+)([\\S]*)',
);

RegExp userRegex = RegExp(
  r'@?(nostr:)?@?(npub1|nprofile1)([qpzry9x8gf2tvdw0s3jn54khce6mua7l]+)([\\S]*)',
);

class WriteFlashNewsCubit extends Cubit<WriteFlashNewsState> {
  WriteFlashNewsCubit()
      : super(
          WriteFlashNewsState(
            content: '',
            flashNewsKinds: FlashNewsKinds.plain,
            isImportant: false,
            keywords: [],
            suggestions: [],
            flashNewsPublishSteps: FlashNewsPublishSteps.content,
            selectedRelays: mandatoryRelays,
            totalRelays: nostrRepository.relays.toList(),
            source: '',
            updateKind: false,
            isEventConfirmation: false,
            article: null,
            curation: null,
          ),
        ) {
    setSuggestions();
  }

  PendingFlashNews? toBeSubmittedEvent;

  void setSuggestions() {
    Set<String> suggestions = {};

    for (final topic in nostrRepository.topics) {
      suggestions.addAll([topic.topic, ...topic.subTopics]);
      suggestions.addAll(nostrRepository.userTopics);
    }

    emit(
      state.copyWith(
        suggestions: suggestions.toList(),
        article: state.article,
        curation: state.curation,
      ),
    );
  }

  void setContent(String text) {
    emit(
      state.copyWith(
        content: text,
        article: state.article,
        curation: state.curation,
      ),
    );
  }

  void setImportant(bool important) {
    emit(
      state.copyWith(
        isImportant: important,
        article: state.article,
        curation: state.curation,
      ),
    );
  }

  void setSource(String text) {
    emit(
      state.copyWith(
        source: text,
        article: state.article,
        curation: state.curation,
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
            article: state.article,
            curation: state.curation,
          ),
        );
    }
  }

  void setFlashNewsKind(FlashNewsKinds flashNewsKinds) {
    emit(
      state.copyWith(
        flashNewsKinds: flashNewsKinds,
        updateKind: !state.updateKind,
        article: null,
        curation: null,
      ),
    );
  }

  void setFlashNewsKindValue({
    required bool isArticle,
    Article? article,
    Curation? curation,
  }) {
    emit(
      state.copyWith(
        article: isArticle ? article : null,
        curation: isArticle ? null : curation,
        flashNewsKinds:
            isArticle ? FlashNewsKinds.article : FlashNewsKinds.curation,
        updateKind: !state.updateKind,
      ),
    );
  }

  void deleteKeyword(String keyword) {
    if (state.keywords.contains(keyword)) {
      final keywords = List<String>.from(state.keywords)..remove(keyword);

      if (!isClosed)
        emit(
          state.copyWith(
            keywords: keywords,
            article: state.article,
            curation: state.curation,
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
            article: state.article,
            curation: state.curation,
          ),
        );
    } else {
      if (!isClosed)
        emit(
          state.copyWith(
            selectedRelays: List.from(state.selectedRelays)..add(relay),
            article: state.article,
            curation: state.curation,
          ),
        );
    }
  }

  void setFlashNewsStep(FlashNewsPublishSteps step) {
    if (state.flashNewsPublishSteps == FlashNewsPublishSteps.content) {
      final content = state.content.trim();

      if (content.isEmpty) {
        BotToastUtils.showError('No content available');
        return;
      } else if (getTextLengthWithoutParsables(content) > FN_MAX_LENGTH) {
        BotToastUtils.showError(
          'Ensure that your content respects the required length',
        );
        return;
      } else {
        final onError = (state.flashNewsKinds == FlashNewsKinds.article &&
                state.article == null) ||
            (state.flashNewsKinds == FlashNewsKinds.curation &&
                state.curation == null);

        if (onError) {
          BotToastUtils.showError(
            'Select ${state.flashNewsKinds == FlashNewsKinds.article ? 'an article' : 'a curation'}',
          );
          return;
        }
      }
    }

    emit(
      state.copyWith(
        flashNewsPublishSteps: step,
        article: state.article,
        curation: state.curation,
      ),
    );
  }

  Future<PendingFlashNews?> createEvent() async {
    final createdAt = currentUnixTimestampSeconds();
    final encryptedMessage = encryptAESCryptoJS(
      createdAt.toString(),
      dotenv.env['FN_KEY']!,
    );

    final splits = npubRegex.allMatches(state.content);
    List<List<String>> pTags = [];
    splits.forEach((e) {
      String pTag = '';
      try {
        pTag = Nip19.decodePubkey(e.group(0)!.split('nostr:').last);
      } catch (_) {}

      if (pTag.isNotEmpty) {
        pTags.add([
          'p',
          pTag,
        ]);
      }
    });

    final event = await Event.genEvent(
      kind: EventKind.TEXT_NOTE,
      createdAt: createdAt,
      tags: [
        ['l', FN_SEARCH_VALUE],
        if (state.isImportant) ['important', createdAt.toString()],
        [FN_SOURCE, state.source],
        [
          FN_ENCRYPTION,
          encryptedMessage,
        ],
        if (state.keywords.isNotEmpty)
          ...state.keywords.map((keyword) => ['t', keyword]).toList(),
        if (pTags.isNotEmpty) ...pTags,
      ],
      content: state.content,
      privkey: nostrRepository.usm!.privKey,
      pubkey: nostrRepository.usm!.pubKey,
    );

    if (event == null) {
      return null;
    }

    toBeSubmittedEvent = PendingFlashNews(
      flashNews: FlashNews.fromEvent(event),
      eventId: event.id,
      pubkey: event.pubkey,
      event: event.toJson(),
      lnbc: '',
    );

    return toBeSubmittedEvent;
  }

  void setPendingFlashNews(String lnbc) {
    toBeSubmittedEvent = toBeSubmittedEvent!.copyWith(
      lnbc: lnbc,
    );

    nostrRepository.setPendingFlashNews(toBeSubmittedEvent!);
  }

  void submitEvent(Function() onSuccess) async {
    final _cancel = BotToast.showLoading();

    final isChecked = await NostrFunctionsRepository.checkPayment(
      toBeSubmittedEvent!.eventId,
    );

    if (isChecked) {
      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: Event.fromJson(toBeSubmittedEvent!.event),
        setProgress: true,
      );

      if (isSuccessful) {
        nostrRepository.deletePendingFlashNews(toBeSubmittedEvent!);
        BotToastUtils.showSuccess('Your flash news has been published');
        onSuccess.call();
      } else {
        BotToastUtils.showError(
          'Error occured while publishing the event',
        );
      }

      _cancel.call();
    } else {
      _cancel.call();
      BotToastUtils.showError(
        "It seemse that you didn't pay the invoice, recheck again",
      );
    }
  }
}
