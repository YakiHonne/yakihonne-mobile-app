// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'write_note_state.dart';

class WriteNoteCubit extends Cubit<WriteNoteState> {
  WriteNoteCubit(
    this.quotedNote,
  ) : super(
          WriteNoteState(
            images: [],
            isQuotedNoteAvailable: quotedNote != null,
            quotedNote: quotedNote,
            widgets: [],
          ),
        );

  final DetailedNoteModel? quotedNote;

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

  void addWidget(SmartWidgetModel widget) {
    emit(
      state.copyWith(
        widgets: List.from(state.widgets)..add(widget),
      ),
    );
  }

  void removeWidget(int index) {
    emit(
      state.copyWith(
        widgets: List.from(state.widgets)..removeAt(index),
      ),
    );
  }

  void removeQuotedNote() {
    emit(
      state.copyWith(
        isQuotedNoteAvailable: false,
        quotedNote: null,
      ),
    );
  }

  void postNote({
    required String content,
    required List<String> mentions,
    required List<String> tags,
    required Function() onSuccess,
  }) async {
    String updatedContent = content;
    List<String> pTags = mentions;

    if (state.isQuotedNoteAvailable) {
      updatedContent =
          '$updatedContent nostr:${Nip19.encodeNote(state.quotedNote!.id)}';
      if (!tags.contains(state.quotedNote!.pubkey)) {
        pTags.add(state.quotedNote!.pubkey);
      }
    }

    Iterable<Match> matches = hashtagsRegExp.allMatches(content);
    List<String> hashtags = matches.map((match) => match.group(0)!).toList();

    final _cancel = BotToast.showLoading();

    final event = await Event.genEvent(
      kind: EventKind.TEXT_NOTE,
      tags: [
        if (state.isQuotedNoteAvailable)
          [
            'q',
            state.quotedNote!.id,
          ],
        if (state.widgets.isNotEmpty) ['l', 'smart-widget'],
        if (pTags.isNotEmpty) ...pTags.map((p) => ['p', p]).toList(),
        if (hashtags.isNotEmpty)
          ...hashtags.map((t) => ['t', t.split('#')[1]]).toList()
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
        BotToastUtils.showSuccess('Note was posted!');
        onSuccess.call();
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
