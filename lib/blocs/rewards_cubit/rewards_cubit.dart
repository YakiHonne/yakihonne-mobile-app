// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:amberflutter/amberflutter.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/blocs/uncensored_notes_cubit/uncensored_notes_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'rewards_state.dart';

class RewardsCubit extends Cubit<RewardsState> {
  RewardsCubit({
    required this.uncensoredNotesCubit,
  }) : super(
          RewardsState(
            rewards: [],
            updatingState: UpdatingState.progress,
            userStatus: getUserStatus(),
            loadingClaims: {},
            initNotePrice: nostrRepository.initNotePrice,
            initRatingPrice: nostrRepository.initRatingPrice,
            sealedNotePrice: nostrRepository.sealedNotePrice,
            sealedRatingPrice: nostrRepository.sealedRatingPrice,
          ),
        );

  final UncensoredNotesCubit uncensoredNotesCubit;

  void initView() async {
    try {
      emit(
        state.copyWith(
          updatingState: UpdatingState.progress,
        ),
      );

      final results = await HttpFunctionsRepository.getRewards(
        nostrRepository.usm!.pubKey,
      );

      emit(
        state.copyWith(
          rewards: results,
          updatingState: UpdatingState.success,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          updatingState: UpdatingState.failure,
        ),
      );
    }
  }

  void claimReward({
    required String eventId,
    required int kind,
  }) async {
    try {
      emit(
        state.copyWith(
          loadingClaims: Set.from(state.loadingClaims)..add(eventId),
        ),
      );

      String encoredData = '';
      final data = {
        'pubkey': nostrRepository.usm!.pubKey,
        'event_id': eventId,
        'kind': kind,
      };

      if (nostrRepository.isUsingExternalSigner) {
        final nip04 = await Amberflutter().nip04Encrypt(
          plaintext: jsonEncode(data),
          currentUser: nostrRepository.usm!.pubKey,
          pubKey: yakihonneHex,
        );

        final encryptedText = nip04['signature'] as String?;

        if (encryptedText != null && encryptedText.isNotEmpty) {
          encoredData = encryptedText;
        }
      } else {
        encoredData = await Nip4.encryptContent(
          jsonEncode(data),
          yakihonneHex,
          nostrRepository.usm!.pubKey,
          nostrRepository.usm!.privKey,
        );
      }

      if (encoredData.isEmpty) {
        BotToastUtils.showError('Error occured while claiming rewarded');

        emit(
          state.copyWith(
            loadingClaims: Set.from(state.loadingClaims)..remove(eventId),
          ),
        );

        return;
      }

      final result = await HttpFunctionsRepository.claimReward(
        pubkey: nostrRepository.usm!.pubKey,
        encodedMessage: encoredData,
      );

      emit(
        state.copyWith(
          loadingClaims: Set.from(state.loadingClaims)..remove(eventId),
        ),
      );

      if (result) {
        initView();
        uncensoredNotesCubit.getBalance();
      } else {
        BotToastUtils.showError('Error occured while claiming a reward');
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          loadingClaims: Set.from(state.loadingClaims)..remove(eventId),
        ),
      );

      BotToastUtils.showError(
        e.response?.data['message'] ?? 'Error occured while claiming a reward',
      );
    }
  }
}
