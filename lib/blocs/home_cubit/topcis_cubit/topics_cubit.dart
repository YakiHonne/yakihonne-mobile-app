// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'topics_state.dart';

class TopicsCubit extends Cubit<TopicsState> {
  TopicsCubit({
    required this.nostrRepository,
    required this.localDatabaseRepository,
  }) : super(
          TopicsState(
            activeTopics: nostrRepository.userTopics,
            generalTopics: nostrRepository.topics.map((e) => e.topic).toList(),
            isSameTopics: true,
            suggestions: [],
          ),
        ) {
    initView();
  }

  final NostrDataRepository nostrRepository;
  final LocalDatabaseRepository localDatabaseRepository;

  List<String> initialUserTopics = [];

  void initView() {
    initialUserTopics = nostrRepository.userTopics;
  }

  void setSuggestions() {
    Set<String> suggestions = {};
    for (final topic in nostrRepository.topics) {
      suggestions.addAll([topic.topic, ...topic.subTopics]);
    }

    emit(
      state.copyWith(suggestions: suggestions.toList()),
    );
  }

  void addTopic(String topic) {
    if (state.activeTopics.contains(topic)) {
      final activeTopics = List<String>.from(state.activeTopics)..remove(topic);

      emit(
        state.copyWith(
          activeTopics: activeTopics,
          isSameTopics: listEquals(activeTopics, initialUserTopics),
        ),
      );
    } else {
      final activeTopics = List<String>.from(state.activeTopics)..add(topic);

      emit(
        state.copyWith(
          activeTopics: List.from(state.activeTopics)..add(topic),
          isSameTopics: activeTopics.contains(
            initialUserTopics,
          ),
        ),
      );
    }
  }

  void setTopics() async {
    final _cancel = BotToast.showLoading();

    final event = await Event.genEvent(
      kind: EventKind.APP_CUSTOM,
      tags: [
        ['d', yakihonneTopicTag],
        ...state.activeTopics.map((e) => ['t', e]).toList(),
      ],
      content: '',
      privkey: nostrRepository.usm!.privKey,
      pubkey: nostrRepository.usm!.pubKey,
    );

    if (event == null) {
      _cancel.call();
      return;
    }

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: event,
      setProgress: true,
    );

    if (isSuccessful) {
      _cancel.call();
      nostrRepository.setTopics(state.activeTopics);
      BotToastUtils.showSuccess('Your topics have been updated');
      initialUserTopics = state.activeTopics;
      emit(
        state.copyWith(
          isSameTopics: true,
        ),
      );
    } else {
      _cancel.call();
      BotToastUtils.showUnreachableRelaysError();
    }
  }

  void addCustomTopics({
    required List<String> topics,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();
    final active = List<String>.from(state.activeTopics)..toLowerCase();

    topics.removeWhere(
      (topic) => active.contains(topic.trim().toLowerCase()),
    );

    topics.removeWhere(
      (topic) => active.contains(topic.trim().toLowerCase()),
    );

    for (final globalTopic in state.generalTopics) {
      for (final topic in topics) {
        if (topic.trim().toLowerCase() == globalTopic.trim().toLowerCase()) {
          topics.remove(topic);
          topics.add(globalTopic);
        }
      }
    }

    final event = await Event.genEvent(
      kind: EventKind.APP_CUSTOM,
      tags: [
        ['d', yakihonneTopicTag],
        ...state.activeTopics.map((e) => ['t', e]).toList(),
        ...topics.map((e) => ['t', e]).toList(),
      ],
      content: '',
      privkey: nostrRepository.usm!.privKey,
      pubkey: nostrRepository.usm!.pubKey,
    );

    if (event == null) {
      _cancel.call();
      return;
    }

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: event,
      setProgress: true,
    );

    if (isSuccessful) {
      _cancel.call();

      final newActiveTopics = List<String>.from(state.activeTopics)
        ..addAll(topics);

      emit(
        state.copyWith(
          activeTopics: newActiveTopics,
          isSameTopics: true,
        ),
      );

      initialUserTopics = state.activeTopics;
      nostrRepository.setTopics(newActiveTopics);
      BotToastUtils.showSuccess('Your topics have been updated');
      onSuccess.call();
    } else {
      _cancel.call();
      BotToastUtils.showUnreachableRelaysError();
    }
  }
}
