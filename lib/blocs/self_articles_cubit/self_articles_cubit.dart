import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'self_articles_state.dart';

class SelfArticlesCubit extends Cubit<SelfArticlesState> {
  SelfArticlesCubit({required this.nostrRepository})
      : super(
          SelfArticlesState(
            userStatus: getUserStatus(),
            articles: [],
            isArticlesLoading: true,
            chosenRelay: '',
            relays: nostrRepository.relays,
            articleAvailability: {},
            articleFilter: ArticleFilter.All,
            articleAvailabilityToggle: true,
            relaysColors: {},
          ),
        ) {
    setRelaysColors();

    if (nostrRepository.usm != null) {
      getArticles(
        relay: '',
      );
    }

    userSubcription = nostrRepository.userModelStream.listen(
      (user) {
        if (user == null) {
          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: UserStatus.notConnected,
                articles: [],
                isArticlesLoading: false,
                articleAvailability: {},
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

          getArticles(
            relay: '',
          );
        }
      },
    );

    refreshSelfArticles = nostrRepository.refreshSelfArticlesStream.listen(
      (user) {
        getArticles(relay: state.chosenRelay);
      },
    );
  }

  final NostrDataRepository nostrRepository;
  late StreamSubscription userSubcription;
  late StreamSubscription refreshSelfArticles;
  Timer? articlesTimer;
  Set<String> requests = {};

  void setRelaysColors() {
    Map<String, int> colors = {};

    nostrRepository.relays.toList().forEach(
      (element) {
        colors[element] = randomColor().value;
      },
    );

    emit(
      state.copyWith(
        relaysColors: colors,
      ),
    );
  }

  void setArticleFilter(ArticleFilter articleFilter) {
    if (state.articleFilter != articleFilter) {
      getArticles(relay: state.chosenRelay, articleFilter: articleFilter);
    }
  }

  void getArticles({
    required String relay,
    ArticleFilter? articleFilter,
  }) {
    articlesTimer?.cancel();

    if (!isClosed)
      emit(
        state.copyWith(
          isArticlesLoading: true,
          articles: [],
          chosenRelay: relay,
          articleAvailability: {},
          articleFilter: articleFilter,
        ),
      );

    NostrFunctionsRepository.getArticles(
      pubkeys: [nostrRepository.user.pubKey],
      articleFilter: state.articleFilter,
      relay: relay.isEmpty ? null : relay,
    ).listen(
      (articles) {
        emit(
          state.copyWith(
            articles: articles,
            isArticlesLoading: false,
          ),
        );
      },
      onDone: () {
        emit(
          state.copyWith(
            isArticlesLoading: false,
          ),
        );
      },
    );
  }

  void deleteArticle(String eventId, Function() onSuccess) async {
    final _cancel = BotToast.showLoading();

    final isSuccessful =
        await NostrFunctionsRepository.deleteEvent(eventId: eventId);

    if (isSuccessful) {
      onSuccess.call();
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }

    _cancel.call();
  }

  @override
  Future<void> close() {
    NostrConnect.sharedInstance.closeRequests(requests.toList());
    userSubcription.cancel();
    refreshSelfArticles.cancel();
    return super.close();
  }
}
