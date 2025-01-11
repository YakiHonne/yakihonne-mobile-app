import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/utils.dart';

part 'curations_state.dart';

class CurationsCubit extends Cubit<CurationsState> {
  CurationsCubit({
    required this.nostrRepository,
  }) : super(
          CurationsState(
            authors: {},
            curations: nostrRepository.curationsMemBox.getCurations.values
                .where((element) =>
                    !nostrRepository.mutes.contains(element.pubKey))
                .toList(),
            articles: [],
            articlesAuthors: {},
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            chosenRelay: '',
            relays: nostrRepository.relays,
            isCurationsLoading:
                nostrRepository.curationsMemBox.getCurations.isEmpty,
            isArticleLoading: true,
            userStatus: getUserStatus(),
          ),
        ) {
    userSubcription = nostrRepository.userModelStream.listen(
      (user) {
        if (user == null) {
          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: UserStatus.notConnected,
              ),
            );
        } else {
          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: user.isUsingPrivKey
                    ? UserStatus.UsingPrivKey
                    : UserStatus.UsingPubKey,
              ),
            );
        }
      },
    );

    muteListSubscription = nostrRepository.mutesStream.listen(
      (mutes) {
        if (!isClosed)
          emit(
            state.copyWith(
              curations: state.curations
                  .where((curation) =>
                      !nostrRepository.mutes.contains(curation.pubKey))
                  .toList(),
            ),
          );
      },
    );

    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        if (!isClosed)
          emit(
            state.copyWith(
              bookmarks: getBookmarkIds(bookmarks).toSet(),
            ),
          );
      },
    );
  }

  final NostrDataRepository nostrRepository;
  late StreamSubscription bookmarksSubscription;
  late StreamSubscription muteListSubscription;
  late StreamSubscription userSubcription;
  Set<String> requests = {};

  void getCurations() {
    if (state.curations.isNotEmpty) {
      final authors =
          state.curations.map((curation) => curation.pubKey).toSet().toList();

      authorsCubit.getAuthors(authors);

      return;
    }

    NostrFunctionsRepository.getCurations(
      onCurations: (curations) {
        emit(
          state.copyWith(
            curations: curations,
            isCurationsLoading: false,
          ),
        );
      },
      onDone: () {
        emit(
          state.copyWith(
            isCurationsLoading: false,
          ),
        );
      },
    );

    if (!isClosed)
      emit(
        state.copyWith(
          curations: [],
          isCurationsLoading: true,
        ),
      );
  }

  void filterCurationsByRelay({required String relay}) {
    if (relay.isEmpty) {
      emit(
        state.copyWith(
          curations: nostrRepository.curationsMemBox.getCurations.values
              .where(
                  (element) => !nostrRepository.mutes.contains(element.pubKey))
              .toList(),
          chosenRelay: relay,
        ),
      );
    } else {
      final newCurations =
          nostrRepository.curationsMemBox.getCurations.values.toList().where(
                (curation) =>
                    curation.relays.contains(relay) &&
                    !nostrRepository.mutes.contains(curation.pubKey),
              );

      emit(
        state.copyWith(
          curations: newCurations.toList(),
          chosenRelay: relay,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    NostrConnect.sharedInstance.closeRequests(requests.toList());
    bookmarksSubscription.cancel();
    muteListSubscription.cancel();
    userSubcription.cancel();
    return super.close();
  }
}
