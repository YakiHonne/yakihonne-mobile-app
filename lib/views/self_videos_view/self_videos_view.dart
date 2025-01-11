// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/self_videos_cubit/self_video_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/self_videos_view/widgets/self_videos_list.dart';
import 'package:yakihonne/views/widgets/no_content_widgets.dart';

class SelfVideosView extends StatelessWidget {
  SelfVideosView({
    Key? key,
    required this.scrollController,
  }) {
    FirebaseAnalytics.instance
        .setCurrentScreen(screenName: 'My articles screen');
  }

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelfVideoCubit(),
      child: BlocBuilder<SelfVideoCubit, SelfVideoState>(
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
      return SelfVideosList(
        scrollController: scrollController,
      );
    }
  }
}
