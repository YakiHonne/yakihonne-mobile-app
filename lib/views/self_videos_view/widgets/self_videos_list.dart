// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/blocs/self_videos_cubit/self_video_cubit.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/search_view/search_view.dart';
import 'package:yakihonne/views/self_videos_view/widgets/self_video_container.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/vertical_video_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/write_video_view/write_video_view.dart';

class SelfVideosList extends HookWidget {
  const SelfVideosList({
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          controller: scrollController,
          slivers: [
            BlocBuilder<SelfVideoCubit, SelfVideoState>(
              builder: (context, state) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                      vertical: kDefaultPadding,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${state.videos.length.toString().padLeft(2, '0')} Videos',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              Text(
                                '(In ${state.chosenRelay.isEmpty ? 'all relays' : state.chosenRelay.split('wss://')[1]})',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: kOrange,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        PullDownButton(
                          animationBuilder: (context, state, child) {
                            return child;
                          },
                          routeTheme: PullDownMenuRouteTheme(
                            backgroundColor:
                                Theme.of(context).primaryColorLight,
                          ),
                          itemBuilder: (context) {
                            final activeRelays =
                                NostrConnect.sharedInstance.activeRelays();

                            return [
                              PullDownMenuItem.selectable(
                                onTap: () {
                                  context
                                      .read<SelfVideoCubit>()
                                      .getVideos(relay: '');
                                },
                                selected: state.chosenRelay.isEmpty,
                                title: 'All relays',
                                itemTheme: PullDownMenuItemTheme(
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        fontWeight: state.chosenRelay.isEmpty
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                ),
                              ),
                              ...state.relays
                                  .map(
                                    (e) => PullDownMenuItem.selectable(
                                      onTap: () {
                                        context
                                            .read<SelfVideoCubit>()
                                            .getVideos(relay: e);
                                      },
                                      selected: e == state.chosenRelay,
                                      title: e.split('wss://')[1],
                                      iconColor: activeRelays.contains(e)
                                          ? kGreen
                                          : kRed,
                                      iconWidget: Icon(
                                        CupertinoIcons.circle_fill,
                                        size: 7,
                                      ),
                                      itemTheme: PullDownMenuItemTheme(
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .labelMedium!
                                            .copyWith(
                                              fontWeight: state.chosenRelay == e
                                                  ? FontWeight.w500
                                                  : FontWeight.w400,
                                            ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ];
                          },
                          buttonBuilder: (context, showMenu) => IconButton(
                            onPressed: showMenu,
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).primaryColorLight,
                            ),
                            icon: SvgPicture.asset(
                              FeatureIcons.relays,
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        PullDownButton(
                          animationBuilder: (context, state, child) {
                            return child;
                          },
                          routeTheme: PullDownMenuRouteTheme(
                            backgroundColor:
                                Theme.of(context).primaryColorLight,
                          ),
                          itemBuilder: (context) {
                            return [
                              ...VideoFilter.values
                                  .map(
                                    (e) => PullDownMenuItem.selectable(
                                      onTap: () {
                                        context
                                            .read<SelfVideoCubit>()
                                            .setVideoFilter(e);
                                      },
                                      selected: e == state.videoFilter,
                                      title: e.name,
                                      itemTheme: PullDownMenuItemTheme(
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .labelMedium!
                                            .copyWith(
                                              fontWeight: state.chosenRelay == e
                                                  ? FontWeight.w500
                                                  : FontWeight.w400,
                                            ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ];
                          },
                          buttonBuilder: (context, showMenu) => IconButton(
                            onPressed: showMenu,
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).primaryColorLight,
                            ),
                            icon: SvgPicture.asset(
                              FeatureIcons.properties,
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            BlocBuilder<SelfVideoCubit, SelfVideoState>(
              buildWhen: (previous, current) =>
                  previous.videos != current.videos ||
                  previous.isVideosLoading != current.isVideosLoading ||
                  current.videosAvailability != previous.videosAvailability,
              builder: (context, state) {
                if (state.videos.isEmpty && !state.isVideosLoading) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: kDefaultPadding),
                      child: EmptyList(
                        description: 'No videos were found on this relay.',
                        icon: FeatureIcons.videoOcta,
                      ),
                    ),
                  );
                } else if (state.isVideosLoading) {
                  return SliverToBoxAdapter(
                    child: SearchLoading(),
                  );
                } else {
                  if (!ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 2,
                      ),
                      sliver: SliverList.builder(
                        itemBuilder: (context, index) {
                          final video = state.videos[index];

                          return selfVideoContainer(
                            video,
                            state,
                            context,
                            video.relays,
                            state.relaysColors,
                          );
                        },
                        itemCount: state.videos.length,
                      ),
                    );
                  } else {
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                      ),
                      sliver: SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: kDefaultPadding / 2,
                          mainAxisSpacing: kDefaultPadding / 2,
                          mainAxisExtent: 275,
                        ),
                        itemBuilder: (context, index) {
                          final video = state.videos[index];

                          return selfVideoContainer(
                            video,
                            state,
                            context,
                            video.relays,
                            state.relaysColors,
                          );
                        },
                        itemCount: state.videos.length,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
        ResetScrollButton(
          scrollController: scrollController,
          isLeft: true,
          padding: kDefaultPadding,
        ),
      ],
    );
  }

  SelfVideoContainer selfVideoContainer(
    VideoModel video,
    SelfVideoState state,
    BuildContext context,
    Set<String> relays,
    Map<String, int> relaysColors,
  ) {
    return SelfVideoContainer(
      video: video,
      userStatus: state.userStatus,
      relays: relays.toList(),
      relaysColors: relaysColors,
      onClicked: () {
        Navigator.pushNamed(
          context,
          video.isHorizontal
              ? HorizontalVideoView.routeName
              : VerticalVideoView.routeName,
          arguments: [video],
        );
      },
      onEdit: () {
        Navigator.pushNamed(
          context,
          WriteVideoView.routeName,
          arguments: [
            context.read<MainCubit>(),
            video,
          ],
        );
      },
      onDelete: () {
        showDialog(
          context: context,
          builder: (alertContext) => AlertDialog(
            title: Text(
              'Delete "${video.title}"?',
              textAlign: TextAlign.center,
            ),
            titleTextStyle: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            content: Text(
              "You're about to delete this video, do you wish to proceed?",
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                  onPressed: () {
                    context.read<SelfVideoCubit>().deleteVideo(
                      video.videoId,
                      () {
                        context
                            .read<SelfVideoCubit>()
                            .getVideos(relay: state.chosenRelay);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                  child: Text(
                    'Delete video',
                    style: TextStyle(
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: kTransparent,
                    side: BorderSide(
                      color: kRed,
                    ),
                  )),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: kWhite,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: kRed,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
