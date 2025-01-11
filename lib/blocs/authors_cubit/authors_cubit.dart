import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/database/cache_database.dart';
import 'package:yakihonne/database/cache_manager_db.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';

import '../../nostr/nostr.dart';

part 'authors_state.dart';

class AuthorsCubit extends Cubit<AuthorsState> {
  AuthorsCubit()
      : super(
          AuthorsState(
            authors: {},
            nip05Validations: {},
          ),
        );

  Set<String> notFound = {};
  Timer? addFollowingOnStop;
  Timer? searchOnStop;
  String search = '';
  Set<String> globalPubKeys = {};

  List<UserModel> getAuthorsByNameNip05(String search) {
    return state.authors.values
        .where((author) =>
            author.name.contains(search) || author.nip05.contains(search))
        .toList();
  }

  void getInitialAuthors() {
    if (state.authors.isNotEmpty) {
      Map<String, UserModel> toBeAddedAuthors = {};

      NostrFunctionsRepository.startSearchForAuthors(
        state.authors.values.map((e) => e.pubKey).toList(),
        toBeSearchedAuthorsFunc: (pubkeys) {
          notFound.addAll(pubkeys);
        },
        authorsFunc: (authors) {
          toBeAddedAuthors = authors;
        },
        resetPubkeys: true,
        onDone: () {
          CacheManagerDB.addMultiMetadata(toBeAddedAuthors.values.toList());

          emit(
            state.copyWith(
              authors: toBeAddedAuthors,
            ),
          );
        },
      );
    }
  }

  void getAuthors(List<String> pubkeys, {bool? resetPubkeys}) {
    addFollowingOnStop?.cancel();
    globalPubKeys.addAll(pubkeys);

    addFollowingOnStop = Timer(
      const Duration(seconds: 1),
      () {
        if (globalPubKeys.isNotEmpty)
          NostrFunctionsRepository.startSearchForAuthors(
            globalPubKeys.toList(),
            toBeSearchedAuthorsFunc: (pubkeys) {
              notFound.addAll(pubkeys);
            },
            authorsFunc: (authors) {
              emit(
                state.copyWith(
                  authors: authors,
                ),
              );
            },
            resetPubkeys: resetPubkeys,
            onDone: () {
              CacheManagerDB.addMultiMetadata(state.authors.values.toList());
            },
          );
      },
    );
  }

  void getUsersBySearch(String search) {
    searchOnStop?.cancel();

    searchOnStop = Timer(
      const Duration(seconds: 1),
      () async {
        if (search.isNotEmpty) {
          final users = await HttpFunctionsRepository.getUsers(search);
          addAuthors(users);
        }
      },
    );
  }

  void setAuthors(List<MetadataData> metadata) {
    Map<String, UserModel> toBeSubmittedAuthors = {};

    for (var meta in metadata) {
      toBeSubmittedAuthors[meta.pubKey] = UserModel.fromMetadata(meta);
    }

    emit(
      state.copyWith(
        authors: toBeSubmittedAuthors,
      ),
    );
  }

  Map<String, UserModel> getAuthorsByPubkeys(List<String> pubkeys) {
    final authors =
        state.authors.entries.where((entry) => pubkeys.contains(entry.key));

    return Map<String, UserModel>.fromEntries(authors);
  }

  UserModel? getSpecificAuthor(String pubkey) => state.authors[pubkey];

  void addAuthors(List<UserModel> authors) {
    for (var author in authors) {
      addAuthor(author);
    }
  }

  void addAuthor(UserModel author, {Event? event}) async {
    final canBeAdded = state.authors[author.pubKey] == null ||
        state.authors[author.pubKey]!.createdAt.compareTo(author.createdAt) < 0;

    if (canBeAdded) {
      if (event != null) NostrFunctionsRepository.checkNip05Validity(event);

      CacheManagerDB.updateMetadata(author);

      final authors = Map<String, UserModel>.from(state.authors);
      authors[author.pubKey] = author;

      emit(
        state.copyWith(
          authors: authors,
        ),
      );
    }
  }

  UserModel? getAuthor(String pubkey) {
    if (pubkey.isEmpty) {
      return null;
    }

    final author = state.authors[pubkey];

    if (author != null) {
      if (state.nip05Validations[author.pubKey] == null) {
        NostrFunctionsRepository.checkNip05ValidityFromData(
          pubkey: author.pubKey,
          nip05: author.nip05,
        );
      }

      return author;
    }

    getAuthors([pubkey]);

    return null;
  }

  Future<UserModel?> getFutureAuthor(String pubkey) async {
    if (pubkey.isEmpty) {
      return null;
    }

    final completer = Completer<UserModel?>();

    final author = state.authors[pubkey];

    if (author != null) {
      return author;
    }

    UserModel? searchAuthor;

    NostrFunctionsRepository.getAuthorsByPubkeys(authors: [pubkey]).listen(
      (map) {
        searchAuthor = map[pubkey];
      },
    ).onDone(
      () {
        completer.complete(searchAuthor);
      },
    );

    return completer.future;
  }

  void setNip05Validations(Map<String, bool> nip05Validations) {
    emit(
      state.copyWith(
        nip05Validations: nip05Validations,
      ),
    );
  }
}
