import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/self_smart_widgets_cubit/self_smart_widgets_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/self_smart_widgets_view/widgets/self_smart_widgets_list.dart';
import 'package:yakihonne/views/widgets/no_content_widgets.dart';

class SelfSmartWidgetsView extends StatelessWidget {
  SelfSmartWidgetsView({
    Key? key,
    required this.scrollController,
  }) {
    FirebaseAnalytics.instance
        .setCurrentScreen(screenName: 'My smart widgets screen');
  }

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelfSmartWidgetsCubit(),
      child: BlocBuilder<SelfSmartWidgetsCubit, SelfSmartWidgetsState>(
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
      return SelfSmartWidgetsList(
        scrollController: scrollController,
      );
    }
  }
}
