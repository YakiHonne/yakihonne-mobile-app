import 'package:aescryptojs/aescryptojs.dart';
import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/static_properties.dart';

part 'set_un_rating_state.dart';

class SetUnRatingCubit extends Cubit<SetUnRatingState> {
  SetUnRatingCubit() : super(SetUnRatingState());

  void addRating({
    required bool isUpvote,
    required String uncensoredNoteId,
    required List<String> reasons,
    required Function() onSuccess,
  }) async {
    final createdAt = currentUnixTimestampSeconds();
    final encryptedMessage = encryptAESCryptoJS(
      createdAt.toString(),
      dotenv.env['FN_KEY']!,
    );

    final event = await Event.genEvent(
      kind: EventKind.REACTION,
      content: isUpvote ? '+' : '-',
      createdAt: createdAt,
      privkey: nostrRepository.usm!.privKey,
      pubkey: nostrRepository.usm!.pubKey,
      verify: true,
      tags: [
        ['l', NR_SEARCH_VALUE],
        [
          FN_ENCRYPTION,
          encryptedMessage,
        ],
        ...reasons
            .map(
              (e) => ['cause', e],
            )
            .toList(),
        ['e', uncensoredNoteId],
      ],
    );

    if (event == null) {
      return;
    }

    final _cancel = BotToast.showLoading();

    final isSuccessful = await NostrFunctionsRepository.addEvent(
      event: event,
    );

    if (isSuccessful) {
      BotToastUtils.showSuccess(
        'Your rating has been submitted, check your rewards page to claim your rating reward',
      );

      onSuccess.call();
    } else {
      BotToastUtils.showError(
        'Error occured while submitting your rating',
      );
    }

    _cancel.call();
  }
}
