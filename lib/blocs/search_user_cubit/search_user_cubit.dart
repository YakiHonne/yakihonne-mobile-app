import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nips/nip_019.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'search_user_state.dart';

class SearchUserCubit extends Cubit<SearchUserState> {
  SearchUserCubit()
      : super(
          SearchUserState(
            authors: [],
            isLoading: false,
          ),
        );

  void emptyAuthorsList() {
    emit(
      state.copyWith(
        isLoading: false,
        authors: [],
      ),
    );
  }

  Future<void> getAuthors(
    String search,
    Function(UserModel) onUserSelected,
  ) async {
    try {
      if (search.startsWith('npub') ||
          search.startsWith('nprofile') ||
          search.length == 64) {
        emit(state.copyWith(isLoading: true));

        try {
          final hex = search.startsWith('npub')
              ? Nip19.decodePubkey(search)
              : search.startsWith('nprofile')
                  ? Nip19.decodeShareableEntity(search)['special']
                  : search;

          final user = await authorsCubit.getFutureAuthor(hex);

          if (user != null) {
            onUserSelected.call(user);
          } else {
            onUserSelected.call(
              emptyUserModel.copyWith(
                pubKey: hex,
                picturePlaceholder: getRandomPlaceholder(
                  input: hex,
                  isPfp: true,
                ),
              ),
            );
          }

          emit(state.copyWith(isLoading: false));
        } catch (_) {
          BotToastUtils.showError('Error occured while decoding data');
          emit(state.copyWith(isLoading: false));
          return;
        }
      } else {
        emit(
          state.copyWith(
            isLoading: true,
          ),
        );

        final searchedUsers = authorsCubit.getAuthorsByNameNip05(search)
          ..where((author) => !nostrRepository.mutes.contains(author.pubKey))
              .toList();

        if (!isClosed)
          emit(
            state.copyWith(
              authors: searchedUsers,
              isLoading: searchedUsers.isEmpty,
            ),
          );

        final users = await HttpFunctionsRepository.getUsers(search);
        final newList = <UserModel>[...state.authors];

        for (final user in users) {
          final userExists = newList
              .where((element) => element.pubKey == user.pubKey)
              .isNotEmpty;

          if (!userExists && !nostrRepository.mutes.contains(user.pubKey)) {
            newList.add(user);
            authorsCubit.addAuthor(user);
          }
        }

        newList.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );

        if (!isClosed)
          emit(
            state.copyWith(
              authors: newList,
              isLoading: false,
            ),
          );
      }
    } catch (e) {
      Logger().i(e);
    }
  }
}
