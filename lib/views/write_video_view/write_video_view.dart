// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/blocs/write_video_cubit/write_video_cubit.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/content_zap_splits.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/write_article_view/widgets/responding_relays_view.dart';
import 'package:yakihonne/views/write_video_view/widgets/video_content.dart';
import 'package:yakihonne/views/write_video_view/widgets/video_selected_relays.dart';
import 'package:yakihonne/views/write_video_view/widgets/video_specifications.dart';

class WriteVideoView extends StatelessWidget {
  WriteVideoView({
    Key? key,
    required this.mainCubit,
    this.videoModel,
  }) {
    FirebaseAnalytics.instance
        .setCurrentScreen(screenName: 'Write video screen');
  }

  static const routeName = '/writeVideo';
  static Route route(RouteSettings settings) {
    final list = settings.arguments as List;

    return CupertinoPageRoute(
      builder: (_) => WriteVideoView(
        mainCubit: list[0],
        videoModel: list.length > 1 ? list[1] : null,
      ),
    );
  }

  final MainCubit mainCubit;
  final VideoModel? videoModel;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: mainCubit,
        ),
        BlocProvider(
          create: (context) => WriteVideoCubit(videoModel: videoModel),
        )
      ],
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: BlocBuilder<WriteVideoCubit, WriteVideoState>(
            builder: (context, state) {
              return AppBar(
                leading: IconButton(
                  onPressed: () {
                    showCupertinoCustomDialogue(
                      context: context,
                      title: 'Exit',
                      description:
                          'You are about the exit the video screen, do you wish to proceed?',
                      buttonText: 'exit',
                      buttonTextColor: kRed,
                      onClicked: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                    );
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                  ),
                ),
                title: Column(
                  children: [
                    Text(
                      '${state.videoPublishSteps == VideoPublishSteps.content ? 'Video content' : state.videoPublishSteps == VideoPublishSteps.specifications ? 'Video specifications' : 'Select your relays'}',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      '${state.videoPublishSteps == VideoPublishSteps.content ? "what's your video about" : state.videoPublishSteps == VideoPublishSteps.specifications ? 'set your specifications' : 'list of available relays'}',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: kDimGrey,
                          ),
                    ),
                  ],
                ),
                centerTitle: true,
              );
            },
          ),
        ),
        bottomNavigationBar: BlocBuilder<WriteVideoCubit, WriteVideoState>(
          builder: (context, state) {
            final step = state.videoPublishSteps == VideoPublishSteps.content
                ? 1
                : state.videoPublishSteps == VideoPublishSteps.specifications
                    ? 2
                    : state.videoPublishSteps == VideoPublishSteps.zaps
                        ? 3
                        : 4;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 2,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(
                      begin: 0,
                      end: step / 4,
                    ),
                    builder: (context, value, _) =>
                        LinearProgressIndicator(value: value),
                  ),
                ),
                _bottomNavBar(context, state, isTablet),
              ],
            );
          },
        ),
        body: BlocBuilder<WriteVideoCubit, WriteVideoState>(
          builder: (context, state) {
            return getView(state.videoPublishSteps);
          },
        ),
      ),
    );
  }

  Container _bottomNavBar(
    BuildContext context,
    WriteVideoState state,
    bool isTablet,
  ) {
    return Container(
      height:
          kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        left: kDefaultPadding / 2,
        right: kDefaultPadding / 2,
        bottom: MediaQuery.of(context).padding.bottom / 2,
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Visibility(
              visible: state.videoPublishSteps != VideoPublishSteps.content,
              child: IconButton(
                onPressed: () {
                  context.read<WriteVideoCubit>().setVideoPublishStep(
                        state.videoPublishSteps ==
                                VideoPublishSteps.specifications
                            ? VideoPublishSteps.content
                            : state.videoPublishSteps == VideoPublishSteps.zaps
                                ? VideoPublishSteps.specifications
                                : VideoPublishSteps.zaps,
                      );
                },
                icon: Icon(
                  Icons.keyboard_arrow_left_rounded,
                  color: kWhite,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: kPurple,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (state.videoPublishSteps != VideoPublishSteps.relays) {
                  context.read<WriteVideoCubit>().setVideoPublishStep(
                        state.videoPublishSteps == VideoPublishSteps.content
                            ? VideoPublishSteps.specifications
                            : state.videoPublishSteps ==
                                    VideoPublishSteps.specifications
                                ? VideoPublishSteps.zaps
                                : VideoPublishSteps.relays,
                      );
                } else {
                  context.read<WriteVideoCubit>().setVideo(
                    onFailure: (message) {
                      singleSnackBar(
                        context: context,
                        message: message,
                        color: kRed,
                        backGroundColor: kRedSide,
                        icon: ToastsIcons.error,
                      );
                    },
                    onSuccess: (successfulRelays, unsuccessfulRelays) {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (BuildContext _, __, ___) =>
                              BlocProvider.value(
                            value: context.read<MainCubit>(),
                            child: RespondingRelaysView(
                              successfulRelays: successfulRelays,
                              unsuccessfulRelays: unsuccessfulRelays,
                              index: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
              child: Text(
                state.videoPublishSteps == VideoPublishSteps.relays
                    ? 'Publish'
                    : 'Next',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getView(VideoPublishSteps videoPublishSteps) {
    if (videoPublishSteps == VideoPublishSteps.content) {
      return VideoContent();
    } else if (videoPublishSteps == VideoPublishSteps.specifications) {
      return BlocBuilder<WriteVideoCubit, WriteVideoState>(
        builder: (context, state) {
          return VideoSpecifications(
            image: state.imageLink,
            isAdding: videoModel == null,
          );
        },
      );
    } else if (videoPublishSteps == VideoPublishSteps.zaps) {
      return BlocBuilder<WriteVideoCubit, WriteVideoState>(
        buildWhen: (previous, current) =>
            previous.isZapSplitEnabled != current.isZapSplitEnabled ||
            previous.zapsSplits != current.zapsSplits,
        builder: (context, state) {
          return ContentZapSplits(
            isZapSplitEnabled: state.isZapSplitEnabled,
            zaps: state.zapsSplits,
            onToggleZapSplit: () {
              context.read<WriteVideoCubit>().toggleZapsSplits();
            },
            onAddZapSplitUser: (pubkey) {
              context.read<WriteVideoCubit>().addZapSplit(pubkey);
            },
            onRemoveZapSplitUser: (pubkey) {
              context.read<WriteVideoCubit>().onRemoveZapSplit(pubkey);
            },
            onSetZapProportions: (index, zap, percentage) {
              context.read<WriteVideoCubit>().setZapPropertion(
                    index: index,
                    zapSplit: zap,
                    newPercentage: percentage,
                  );
            },
          );
        },
      );
    } else {
      return BlocBuilder<WriteVideoCubit, WriteVideoState>(
        builder: (context, state) {
          return VideoSelectedRelays(
            selectedRelays: state.selectedRelays,
            totaRelays: state.totalRelays,
            onToggle: (relay) {
              if (!mandatoryRelays.contains(relay)) {
                context.read<WriteVideoCubit>().setRelaySelection(relay);
              }
            },
          );
        },
      );
    }
  }
}
