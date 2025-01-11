// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/blocs/videos_cubit/videos_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_container.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/vertical_video_container.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/vertical_video_view.dart';
import 'package:yakihonne/views/widgets/classic_footer.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';

class VideoFeedView extends HookWidget {
  const VideoFeedView({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VideosCubit(
        isHorizontal: context.read<MainCubit>().state.isHorizontal,
      )..initView(
          loadHorizontal: true,
          loadVertical: true,
        ),
      child: BlocListener<MainCubit, MainState>(
        listenWhen: (previous, current) =>
            previous.isHorizontal != current.isHorizontal,
        listener: (context, state) {
          context.read<VideosCubit>().setIsHorizontal(state.isHorizontal);
        },
        child: BlocBuilder<VideosCubit, VideosState>(
          builder: (context, state) {
            final isHorizontal = state.isHorizontalVideoSelected;

            if (state.isHorizontalLoading && isHorizontal ||
                state.isVerticalLoading && !isHorizontal) {
              return Center(
                child: SpinKitChasingDots(
                  color: Theme.of(context).primaryColorDark,
                  size: 15,
                ),
              );
            }

            if (isHorizontal && state.horizontalVideos.isEmpty ||
                !isHorizontal && state.verticalVideos.isEmpty) {
              return Center(
                child: EmptyList(
                  description:
                      'It seems that no ${isHorizontal ? 'horizontal' : 'vertical'} videos can be found.',
                  icon: FeatureIcons.videoOcta,
                ),
              );
            }

            if (isHorizontal) {
              return HorizontalVideosList(scrollController: scrollController);
            } else {
              return VerticalVideosList(scrollController: scrollController);
            }
          },
        ),
      ),
    );
  }
}

class VerticalVideosList extends StatefulWidget {
  const VerticalVideosList({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  State<VerticalVideosList> createState() => _VerticallVideosListState();
}

class _VerticallVideosListState extends State<VerticalVideosList> {
  final refreshController = RefreshController();

  void onRefresh({required Function onInit}) {
    refreshController.resetNoData();
    onInit.call();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocConsumer<VideosCubit, VideosState>(
      listenWhen: (previous, current) =>
          previous.loadingVerticalState != current.loadingVerticalState,
      listener: (context, state) {
        if (state.loadingVerticalState == UpdatingState.success) {
          refreshController.loadComplete();
        } else if (state.loadingVerticalState == UpdatingState.idle) {
          refreshController.loadNoData();
        }
      },
      builder: (context, state) {
        return SmartRefresher(
          scrollController: widget.scrollController,
          controller: refreshController,
          enablePullDown: false,
          enablePullUp: true,
          header: const MaterialClassicHeader(
            color: kPurple,
          ),
          footer: const RefresherClassicFooter(),
          onLoading: () => context.read<VideosCubit>().loadMore(),
          onRefresh: () => onRefresh(
            onInit: () => context.read<VideosCubit>().initView(
                  loadHorizontal: state.isHorizontalVideoSelected,
                  loadVertical: !state.isHorizontalVideoSelected,
                ),
          ),
          child: MasonryGridView.count(
            crossAxisCount: isTablet ? 4 : 2,
            itemCount: state.verticalVideos.length,
            crossAxisSpacing: kDefaultPadding / 4,
            padding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding / 2,
              horizontal: kDefaultPadding / 4,
            ),
            itemBuilder: (context, index) {
              final video = state.verticalVideos[index];

              return VerticalVideoContainer(
                video: video,
                onClicked: () {
                  Navigator.pushNamed(
                    context,
                    VerticalVideoView.routeName,
                    arguments: [
                      video,
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class HorizontalVideosList extends StatefulWidget {
  const HorizontalVideosList({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  State<HorizontalVideosList> createState() => _HorizontalVideosListState();
}

class _HorizontalVideosListState extends State<HorizontalVideosList> {
  final refreshController = RefreshController();

  void onRefresh({required Function onInit}) {
    refreshController.resetNoData();
    onInit.call();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocConsumer<VideosCubit, VideosState>(
      listenWhen: (previous, current) =>
          previous.loadingHorizontalState != current.loadingHorizontalState,
      listener: (context, state) {
        if (state.loadingHorizontalState == UpdatingState.success) {
          refreshController.loadComplete();
        } else if (state.loadingHorizontalState == UpdatingState.idle) {
          refreshController.loadNoData();
        }
      },
      builder: (context, state) {
        return SmartRefresher(
          scrollController: widget.scrollController,
          controller: refreshController,
          enablePullDown: false,
          enablePullUp: true,
          header: const MaterialClassicHeader(
            color: kPurple,
          ),
          footer: const RefresherClassicFooter(),
          onLoading: () => context.read<VideosCubit>().loadMore(),
          onRefresh: () => onRefresh(
            onInit: () => context.read<VideosCubit>().initView(
                  loadHorizontal: state.isHorizontalVideoSelected,
                  loadVertical: !state.isHorizontalVideoSelected,
                ),
          ),
          child: isTablet
              ? MasonryGridView.count(
                  crossAxisCount: 2,
                  itemCount: state.horizontalVideos.length,
                  crossAxisSpacing: kDefaultPadding / 2,
                  padding: const EdgeInsets.all(kDefaultPadding),
                  itemBuilder: (context, index) {
                    final video = state.horizontalVideos[index];

                    return HorizontalVideoContainer(
                      video: video,
                      onClicked: () {
                        Navigator.pushNamed(
                          context,
                          HorizontalVideoView.routeName,
                          arguments: [
                            video,
                          ],
                        );
                      },
                    );
                  },
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                  ),
                  itemBuilder: (context, index) {
                    final video = state.horizontalVideos[index];

                    return HorizontalVideoContainer(
                      video: video,
                      onClicked: () {
                        Navigator.pushNamed(
                          context,
                          HorizontalVideoView.routeName,
                          arguments: [
                            video,
                          ],
                        );
                      },
                    );
                  },
                  itemCount: state.horizontalVideos.length,
                ),
        );
      },
    );
  }
}
