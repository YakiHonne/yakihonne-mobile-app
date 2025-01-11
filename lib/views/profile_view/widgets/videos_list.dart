// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/profile_cubit/profile_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/vertical_video_view.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/place_holders.dart';
import 'package:yakihonne/views/widgets/video_common_container.dart';

class ProfileVideos extends StatelessWidget {
  const ProfileVideos({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (previous, current) =>
            previous.isVideoLoading != current.isVideoLoading ||
            previous.videos != current.videos ||
            previous.user != current.user ||
            previous.bookmarks != current.bookmarks,
        builder: (context, state) {
          if (state.isVideoLoading) {
            return MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                children: [
                  SkeletonSelector(
                    placeHolderWidget: ArticleSkeleton(),
                  ),
                ],
              ),
            );
          } else {
            if (state.videos.isEmpty) {
              return EmptyList(
                description: '${state.user.name} has no videos',
                icon: FeatureIcons.videoOcta,
              );
            } else {
              if (ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
                return MasonryGridView.builder(
                  physics: AlwaysScrollableScrollPhysics(),
                  gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  crossAxisSpacing: kDefaultPadding / 2,
                  mainAxisSpacing: kDefaultPadding / 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding,
                    vertical: kDefaultPadding / 2,
                  ),
                  itemBuilder: (context, index) {
                    final video = state.videos[index];

                    return VideoCommonContainer(
                      isBookmarked: state.bookmarks.contains(video.identifier),
                      isMuted: state.mutes.contains(video.pubkey),
                      isFollowing: state.followings.contains(video.pubkey),
                      video: video,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          video.isHorizontal
                              ? HorizontalVideoView.routeName
                              : VerticalVideoView.routeName,
                          arguments: [video],
                        );
                      },
                    );
                  },
                  itemCount: state.videos.length,
                );
              } else {
                return ListView.separated(
                  separatorBuilder: (context, index) => const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  padding: const EdgeInsets.only(
                    top: kDefaultPadding / 2,
                    bottom: kBottomNavigationBarHeight,
                    left: kDefaultPadding / 2,
                    right: kDefaultPadding / 2,
                  ),
                  physics: AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final video = state.videos[index];

                    return VideoCommonContainer(
                      isBookmarked: state.bookmarks.contains(video.identifier),
                      video: video,
                      isMuted: state.mutes.contains(video.pubkey),
                      isFollowing: state.followings.contains(video.pubkey),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          video.isHorizontal
                              ? HorizontalVideoView.routeName
                              : VerticalVideoView.routeName,
                          arguments: [video],
                        );
                      },
                    );
                  },
                  itemCount: state.videos.length,
                );
              }
            }
          }
        },
      ),
    );
  }
}
