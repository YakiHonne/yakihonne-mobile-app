import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';

part 'flash_user_content_state.dart';

class FlashUserContentCubit extends Cubit<FlashUserContentState> {
  FlashUserContentCubit({
    required bool isArticles,
  }) : super(
          FlashUserContentState(
            articles: [],
            curations: [],
            isArticles: isArticles,
            isLoading: true,
          ),
        );

  void initView() {
    if (state.isArticles) {
      NostrFunctionsRepository.getArticles(
        pubkeys: [nostrRepository.usm!.pubKey],
      ).listen(
        (articles) {
          emit(
            state.copyWith(
              articles: articles.toList(),
              isLoading: false,
            ),
          );
        },
        onDone: () {
          emit(
            state.copyWith(
              isLoading: false,
            ),
          );
        },
      );
    } else {
      NostrFunctionsRepository.getCurationsByPubkeys(
        pubkeys: [nostrRepository.usm!.pubKey],
      ).listen(
        (curations) {
          emit(
            state.copyWith(
              curations: curations,
              isLoading: false,
            ),
          );
        },
        onDone: () {
          emit(
            state.copyWith(
              isLoading: false,
            ),
          );
        },
      );
    }
  }
}
