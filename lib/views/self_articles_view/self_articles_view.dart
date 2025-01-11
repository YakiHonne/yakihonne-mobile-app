import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/self_articles_cubit/self_articles_cubit.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/self_articles_view/widgets/self_articles_list.dart';
import 'package:yakihonne/views/widgets/no_content_widgets.dart';

class SelfArticlesView extends StatelessWidget {
  SelfArticlesView({super.key, required this.mainScrollController}) {
    FirebaseAnalytics.instance
        .setCurrentScreen(screenName: 'My articles screen');
  }

  final ScrollController mainScrollController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelfArticlesCubit(
        nostrRepository: context.read<NostrDataRepository>(),
      ),
      child: BlocBuilder<SelfArticlesCubit, SelfArticlesState>(
        buildWhen: (previous, current) =>
            previous.userStatus != current.userStatus,
        builder: (context, state) {
          return SafeArea(
            child: getView(
              userStatus: state.userStatus,
              context: context,
            ),
          );
        },
      ),
    );
  }

  Widget getView({
    required UserStatus userStatus,
    required BuildContext context,
  }) {
    if (userStatus == UserStatus.notConnected) {
      return NotConnectedWidget();
    } else {
      return SelfArticlesList(
        scrollController: mainScrollController,
      );
    }
  }
}
