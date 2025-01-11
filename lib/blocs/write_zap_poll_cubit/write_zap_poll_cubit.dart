import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'write_zap_poll_state.dart';

class WriteZapPollCubit extends Cubit<WriteZapPollState> {
  WriteZapPollCubit()
      : super(
          WriteZapPollState(
            images: [],
            options: [
              'A',
              'B',
            ],
          ),
        );

  void addImage(String link) {
    emit(
      state.copyWith(
        images: List.from(state.images)..add(link),
      ),
    );
  }

  void removeImage(int index) {
    emit(
      state.copyWith(
        images: List.from(state.images)..removeAt(index),
      ),
    );
  }

  void addPollOption() {
    emit(
      state.copyWith(
        options: List.from(state.options)..add(''),
      ),
    );
  }

  void updatePollOption(String pollOption, int index) {
    final newList = List<String>.from(state.options);
    newList[index] = pollOption;

    emit(
      state.copyWith(
        options: newList,
      ),
    );
  }

  void removePollOption(int index) {
    emit(
      state.copyWith(
        options: List.from(state.options)..removeAt(index),
      ),
    );
  }

  void PostZapPoll({
    required String content,
    required List<String> mentions,
    required List<String> tags,
    required String minimumSatoshis,
    required String maximumSatoshis,
    required DateTime? closedAt,
    required Function(Event) onSuccess,
  }) async {
    String updatedContent = content;
    List<String> pTags = mentions;
    final minSat = minimumSatoshis.trim();
    final maxSat = maximumSatoshis.trim();

    if (minSat.isNotEmpty && maxSat.isNotEmpty) {
      int min = int.parse(minimumSatoshis);
      int max = int.parse(maximumSatoshis);

      if (max < min) {
        BotToastUtils.showError(
          'Make sure to submit valid minimum & maximum satoshis',
        );

        return;
      }
    }

    if (closedAt != null && closedAt.compareTo(DateTime.now()) <= 0) {
      BotToastUtils.showError('Make sure to submit valid close date.');
      return;
    }

    List<List<String>> polls = [];

    bool hasEmptyOption = false;
    for (int i = 0; i < state.options.length; i++) {
      final e = state.options[i].trim();

      polls.add(['poll_option', '$i', e]);

      if (e.isEmpty) {
        hasEmptyOption = true;
      }
    }

    if (hasEmptyOption) {
      BotToastUtils.showError('Make sure to submit valid options.');
      return;
    }

    Iterable<Match> matches = hashtagsRegExp.allMatches(content);
    List<String> hashtags = matches.map((match) => match.group(0)!).toList();
    if (state.images.isNotEmpty) {
      for (final image in state.images) {
        updatedContent = '$updatedContent $image';
      }
    }

    final _cancel = BotToast.showLoading();

    final event = await Event.genEvent(
      kind: EventKind.POLL,
      tags: [
        if (pTags.isNotEmpty) ...pTags.map((p) => ['p', p]).toList(),
        if (hashtags.isNotEmpty)
          ...hashtags.map((t) => ['t', t.split('#')[1]]).toList(),
        ['p', nostrRepository.usm!.pubKey, mandatoryRelays.first],
        ...polls,
        [
          'closed_at',
          closedAt != null
              ? (closedAt.millisecondsSinceEpoch ~/ 1000).toString()
              : 'null'
        ],
        if (minSat.isNotEmpty) ['value_minimum', minSat],
        if (maxSat.isNotEmpty) ['value_maximum', maxSat]
      ],
      content: updatedContent,
      pubkey: nostrRepository.usm!.pubKey,
      privkey: nostrRepository.usm!.privKey,
    );

    if (event != null) {
      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: true,
      );

      if (isSuccessful) {
        BotToastUtils.showSuccess('Poll zap was posted!');
        onSuccess.call(event);
      } else {
        BotToastUtils.showError('Error occured while sending the event');
      }
    } else {
      BotToastUtils.showError('Error occured while generating the event');
      return;
    }

    _cancel.call();
  }
}
