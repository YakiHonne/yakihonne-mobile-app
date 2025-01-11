// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:numeral/numeral.dart';
import 'package:pod_player/pod_player.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/horizontal_video_cubit/horizontal_video_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/article_view/widgets/article_curations_add.dart';
import 'package:yakihonne/views/article_view/widgets/article_report.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/threads_view/threads_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_container.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/video_description.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/comment_box_view.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/widgets/share_view.dart';
import 'package:yakihonne/views/widgets/voters_view.dart';
import 'package:yakihonne/views/widgets/zappers_view.dart';
import 'package:yakihonne/views/zap_view/set_zaps_view.dart';

class HorizontalVideoView extends HookWidget {
  static const routeName = '/horizontalVideoView';
  static Route route(RouteSettings settings) {
    final items = settings.arguments as List;

    return CupertinoPageRoute(
      builder: (_) => HorizontalVideoView(
        video: items[0],
      ),
    );
  }

  final VideoModel video;

  const HorizontalVideoView({
    Key? key,
    required this.video,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final videoSuggestions =
        useState(nostrRepository.getVideoSuggestions(video.identifier));
    PodPlayerController? controller;

    return BlocProvider(
      create: (context) => HorizontalVideoCubit(
        video: video,
      )..initView(),
      child: Scaffold(
        extendBody: false,
        extendBodyBehindAppBar: false,
        body: BlocBuilder<HorizontalVideoCubit, HorizontalVideoState>(
          builder: (context, state) {
            return CustomScrollView(
              physics: ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: kToolbarHeight,
                    child: ClipRRect(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: CachedNetworkImage(
                          imageUrl: video.thumbnail,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              NoThumbnailPlaceHolder(
                            isError: true,
                            icon: video.placeHolder,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: HorizontalCustomVideoPlayer(
                    video: video,
                    controllerEmitter: (p0) {
                      controller = p0;
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(kDefaultPadding / 2),
                    child: BlocBuilder<AuthorsCubit, AuthorsState>(
                      builder: (context, authorState) {
                        final author = authorState.authors[video.pubkey] ??
                            emptyUserModel.copyWith(
                              pubKey: video.pubkey,
                              picturePlaceholder: getRandomPlaceholder(
                                input: video.pubkey,
                                isPfp: true,
                              ),
                            );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  elevation: 0,
                                  builder: (_) {
                                    return HVDescription(
                                      createdAt: video.createdAt,
                                      description: video.summary,
                                      title: video.title,
                                      tags: video.tags,
                                      upvotes: state.votes.values
                                          .map((element) => element.vote)
                                          .toList()
                                          .length
                                          .toString(),
                                      views: state.viewsCount.length.toString(),
                                    );
                                  },
                                  isScrollControlled: true,
                                  useRootNavigator: true,
                                  useSafeArea: true,
                                  backgroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                );
                              },
                              behavior: HitTestBehavior.translucent,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    video.title.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge!
                                        .copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(
                                    height: kDefaultPadding / 2,
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${Numeral(state.viewsCount.length)} views',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                      DotContainer(
                                        color: kDimGrey,
                                        size: 3,
                                      ),
                                      Text(
                                        '${StringUtil.formatTimeDifference(video.createdAt)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                      const SizedBox(
                                        width: kDefaultPadding / 4,
                                      ),
                                      Text(
                                        '...more',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall!
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: kDefaultPadding,
                            ),
                            Row(
                              children: [
                                ProfilePicture2(
                                  size: 30,
                                  image: author.picture,
                                  placeHolder: author.picturePlaceholder,
                                  padding: 0,
                                  strokeWidth: 0,
                                  reduceSize: true,
                                  strokeColor: kTransparent,
                                  onClicked: () {
                                    openProfileFastAccess(
                                      context: context,
                                      pubkey: author.pubKey,
                                    );
                                  },
                                ),
                                const SizedBox(
                                  width: kDefaultPadding / 2,
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          getAuthorName(author),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium!
                                              .copyWith(
                                                color: kWhite,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Builder(
                                        builder: (context) {
                                          final authNip05 = authorState
                                              .nip05Validations[author.pubKey];
                                          if (authNip05 != null && authNip05) {
                                            return Row(
                                              children: [
                                                const SizedBox(
                                                  width: kDefaultPadding / 4,
                                                ),
                                                SvgPicture.asset(
                                                  FeatureIcons.verified,
                                                  width: 15,
                                                  height: 15,
                                                  colorFilter: ColorFilter.mode(
                                                    kOrangeContrasted,
                                                    BlendMode.srcIn,
                                                  ),
                                                ),
                                              ],
                                            );
                                          } else {
                                            return SizedBox.shrink();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  width: kDefaultPadding / 2,
                                ),
                                NewBorderedIconButton(
                                  onClicked: () {
                                    context
                                        .read<HorizontalVideoCubit>()
                                        .setFollowingState();
                                  },
                                  icon: state.isFollowingAuthor
                                      ? FeatureIcons.userFollowed
                                      : FeatureIcons.userToFollow,
                                  buttonStatus: state.userStatus !=
                                              UserStatus.UsingPrivKey ||
                                          state.isSameArticleAuthor
                                      ? ButtonStatus.disabled
                                      : state.isFollowingAuthor
                                          ? ButtonStatus.active
                                          : ButtonStatus.inactive,
                                ),
                                const SizedBox(
                                  width: kDefaultPadding / 4,
                                ),
                                NewBorderedIconButton(
                                  onClicked: () {
                                    showModalBottomSheet(
                                      elevation: 0,
                                      context: context,
                                      builder: (_) {
                                        return SetZapsView(
                                          author: state.author,
                                          isZapSplit:
                                              video.zapsSplits.isNotEmpty,
                                          zapSplits: video.zapsSplits,
                                          aTag:
                                              '${state.video.kind}:${state.video.pubkey}:${state.video.identifier}',
                                        );
                                      },
                                      isScrollControlled: true,
                                      useRootNavigator: true,
                                      useSafeArea: true,
                                      backgroundColor: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    );
                                  },
                                  icon: FeatureIcons.zaps,
                                  buttonStatus: !state.canBeZapped
                                      ? ButtonStatus.disabled
                                      : ButtonStatus.inactive,
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: kDefaultPadding,
                            ),
                            HorizontalVideoStatsContainer(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (controller != null && controller!.isVideoPlaying) {
                        controller!.pause();
                      }

                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => ThreadsView(
                            mainCommentId: '',
                            authorPubkey: state.video.pubkey,
                            threadsType: ThreadsType.horizontalVideo,
                            horizontalVideoCubit:
                                context.read<HorizontalVideoCubit>(),
                            userStatus: state.userStatus,
                            currentUserPubkey: state.currentUserPubkey,
                            shareableLink: createShareableLink(
                              state.video.kind,
                              state.video.pubkey,
                              state.video.identifier,
                            ),
                            mutes: state.mutes,
                            kind: state.video.kind,
                            onAddComment:
                                (commentContent, mentions, commentId) {
                              context.read<HorizontalVideoCubit>().addComment(
                                    content: commentContent,
                                    replyCommentId: commentId,
                                    mentions: mentions,
                                    onSuccess: () {
                                      Navigator.pop(context);
                                    },
                                  );
                            },
                            onDeleteComment: (commentId) {
                              context
                                  .read<HorizontalVideoCubit>()
                                  .deleteComment(commentId: commentId);
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColorLight,
                        borderRadius: BorderRadius.circular(kDefaultPadding),
                      ),
                      padding: const EdgeInsets.all(kDefaultPadding / 2),
                      margin: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 2,
                        vertical: kDefaultPadding / 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Comments',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              DotContainer(
                                color: kDimGrey,
                                size: 3,
                              ),
                              Text(
                                '${state.comments.length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: kOrange,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: kDefaultPadding / 2,
                          ),
                          if (state.comments.isEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No comments can be found',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall!
                                      .copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                  textAlign: TextAlign.start,
                                ),
                                const SizedBox(
                                  height: kDefaultPadding / 4,
                                ),
                                Text(
                                  'Be the first to comment on this video !',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(),
                                  textAlign: TextAlign.start,
                                ),
                              ],
                            )
                          else
                            Builder(
                              builder: (context) {
                                final comment = state.comments.first;

                                final author = authorsCubit
                                        .state.authors[comment.pubKey] ??
                                    emptyUserModel.copyWith(
                                      pubKey: comment.pubKey,
                                      picturePlaceholder: getRandomPlaceholder(
                                        input: comment.pubKey,
                                        isPfp: true,
                                      ),
                                    );

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ProfilePicture2(
                                      size: 25,
                                      image: author.picture,
                                      placeHolder: author.picturePlaceholder,
                                      padding: 0,
                                      strokeWidth: 1,
                                      strokeColor:
                                          Theme.of(context).primaryColorDark,
                                      onClicked: () {},
                                    ),
                                    const SizedBox(
                                      width: kDefaultPadding / 2,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            getAuthorName(author),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge!
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  height: 1,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(
                                            height: kDefaultPadding / 4,
                                          ),
                                          Text(
                                            comment.content,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (videoSuggestions.value.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 2,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: kDefaultPadding / 2,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  endIndent: kDefaultPadding,
                                ),
                              ),
                              Text(
                                'See also',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              Expanded(
                                child: Divider(
                                  indent: kDefaultPadding,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                    ),
                    sliver: SliverList.builder(
                      itemBuilder: (context, index) {
                        final video = videoSuggestions.value[index];

                        return HorizontalVideoContainer(
                          video: video,
                          onClicked: () {
                            if (controller != null &&
                                controller!.isVideoPlaying) {
                              controller!.pause();
                            }

                            Navigator.pushNamed(
                              context,
                              HorizontalVideoView.routeName,
                              arguments: [
                                video,
                                <VideoModel>[],
                              ],
                            );
                          },
                        );
                      },
                      itemCount: videoSuggestions.value.length,
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: kDefaultPadding,
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

class HorizontalVideoStatsContainer extends StatelessWidget {
  const HorizontalVideoStatsContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HorizontalVideoCubit, HorizontalVideoState>(
      builder: (context, state) {
        final calculatedVotes = getVotes(
          votes: state.votes,
          pubkey: state.userStatus == UserStatus.UsingPrivKey
              ? state.currentUserPubkey
              : null,
        );

        final zaps =
            state.zaps.isEmpty ? 0 : state.zaps.values.reduce((a, b) => a + b);

        return IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {},
                        onLongPress: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: kDefaultPadding / 3,
                            horizontal: kDefaultPadding / 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              kDefaultPadding * 3,
                            ),
                            color: Theme.of(context).primaryColorLight,
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () {
                                    context
                                        .read<HorizontalVideoCubit>()
                                        .setVote(
                                          upvote: true,
                                          eventId: state.video.videoId,
                                          eventPubkey: state.video.pubkey,
                                        );
                                  },
                                  onLongPress: () {
                                    showModalBottomSheet(
                                      context: context,
                                      elevation: 0,
                                      builder: (_) {
                                        final upvotes = state.votes.entries
                                            .where((element) =>
                                                element.value.vote);

                                        return VotersView(
                                          voters: Map<String,
                                              VoteModel>.fromEntries(
                                            upvotes,
                                          ),
                                          title: 'Upvoters',
                                        );
                                      },
                                      isScrollControlled: true,
                                      useRootNavigator: true,
                                      useSafeArea: true,
                                      backgroundColor: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        calculatedVotes[1]
                                            ? FeatureIcons.upvoteFilled
                                            : FeatureIcons.upvote,
                                        width: 15,
                                        height: 15,
                                        colorFilter: ColorFilter.mode(
                                          Theme.of(context).primaryColorDark,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: kDefaultPadding / 4,
                                      ),
                                      Text(
                                        calculatedVotes[0].toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall!
                                            .copyWith(
                                              color: Theme.of(context)
                                                  .primaryColorDark,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                VerticalDivider(),
                                GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () {
                                    context
                                        .read<HorizontalVideoCubit>()
                                        .setVote(
                                          upvote: false,
                                          eventId: state.video.videoId,
                                          eventPubkey: state.video.pubkey,
                                        );
                                  },
                                  onLongPress: () {
                                    showModalBottomSheet(
                                      context: context,
                                      elevation: 0,
                                      builder: (_) {
                                        final downvotes = state.votes.entries
                                            .where((element) =>
                                                !element.value.vote);

                                        return VotersView(
                                          voters: Map<String,
                                              VoteModel>.fromEntries(
                                            downvotes,
                                          ),
                                          title: 'Downvoters',
                                        );
                                      },
                                      isScrollControlled: true,
                                      useRootNavigator: true,
                                      useSafeArea: true,
                                      backgroundColor: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        calculatedVotes[3]
                                            ? FeatureIcons.downvoteFilled
                                            : FeatureIcons.downvote,
                                        width: 15,
                                        height: 15,
                                        colorFilter: ColorFilter.mode(
                                          Theme.of(context).primaryColorDark,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: kDefaultPadding / 4,
                                      ),
                                      Text(
                                        calculatedVotes[2].toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall!
                                            .copyWith(
                                              color: Theme.of(context)
                                                  .primaryColorDark,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                      HVbutton(
                        text: zaps.toString(),
                        icon: FeatureIcons.zap,
                        useOpacity: true,
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            elevation: 0,
                            builder: (_) {
                              return ZappersView(
                                zappers: state.zaps,
                              );
                            },
                            isScrollControlled: true,
                            useRootNavigator: true,
                            useSafeArea: true,
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                          );
                        },
                        onTap: () {},
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                      HVbutton(
                        text: state.comments.length.toString(),
                        icon: FeatureIcons.comments,
                        onLongPress: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => ThreadsView(
                                mainCommentId: '',
                                authorPubkey: state.video.pubkey,
                                threadsType: ThreadsType.horizontalVideo,
                                horizontalVideoCubit:
                                    context.read<HorizontalVideoCubit>(),
                                userStatus: state.userStatus,
                                currentUserPubkey: state.currentUserPubkey,
                                shareableLink: createShareableLink(
                                  state.video.kind,
                                  state.video.pubkey,
                                  state.video.identifier,
                                ),
                                mutes: state.mutes,
                                kind: state.video.kind,
                                onAddComment:
                                    (commentContent, mentions, commentId) {
                                  context
                                      .read<HorizontalVideoCubit>()
                                      .addComment(
                                        content: commentContent,
                                        replyCommentId: commentId,
                                        mentions: mentions,
                                        onSuccess: () {
                                          Navigator.pop(context);
                                        },
                                      );
                                },
                                onDeleteComment: (commentId) {
                                  context
                                      .read<HorizontalVideoCubit>()
                                      .deleteComment(commentId: commentId);
                                },
                              ),
                            ),
                          );
                        },
                        onTap: () {
                          if (state.userStatus == UserStatus.UsingPrivKey)
                            showModalBottomSheet(
                              context: context,
                              elevation: 0,
                              builder: (_) {
                                return CommentBoxView(
                                  commentId: '',
                                  commentPubkey: state.video.pubkey,
                                  commentContent: state.video.title,
                                  commentDate: state.video.createdAt,
                                  kind: state.video.kind,
                                  shareableLink: createShareableLink(
                                    state.video.kind,
                                    state.video.pubkey,
                                    state.video.identifier,
                                  ),
                                  onAddComment:
                                      (commentContent, mentions, commentId) {
                                    context
                                        .read<HorizontalVideoCubit>()
                                        .addComment(
                                          content: commentContent,
                                          replyCommentId: commentId,
                                          mentions: mentions,
                                          onSuccess: () {
                                            Navigator.pop(context);
                                          },
                                        );
                                  },
                                );
                              },
                              isScrollControlled: true,
                              useRootNavigator: true,
                              useSafeArea: true,
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                            );
                        },
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                      HVbutton(
                        text: state.reports.length.toString(),
                        icon: FeatureIcons.report,
                        onLongPress: () {},
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
              VerticalDivider(
                indent: kDefaultPadding / 4,
                endIndent: kDefaultPadding / 4,
              ),
              PullDownButton(
                animationBuilder: (context, state, child) {
                  return child;
                },
                routeTheme: PullDownMenuRouteTheme(
                  backgroundColor: Theme.of(context).primaryColorLight,
                ),
                itemBuilder: (context) {
                  final textStyle = Theme.of(context).textTheme.labelMedium;

                  return [
                    if (getUserStatus() == UserStatus.UsingPrivKey) ...[
                      PullDownMenuItem(
                        title: 'Bookmark',
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            elevation: 0,
                            builder: (_) {
                              return AddBookmarkView(
                                kind: state.video.kind,
                                identifier: state.video.identifier,
                                eventPubkey: state.video.pubkey,
                                image: state.video.thumbnail.isNotEmpty
                                    ? state.video.thumbnail
                                    : '',
                              );
                            },
                            isScrollControlled: true,
                            useRootNavigator: true,
                            useSafeArea: true,
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                          );
                        },
                        itemTheme: PullDownMenuItemTheme(
                          textStyle: textStyle,
                        ),
                        iconWidget: BlocBuilder<ThemeCubit, ThemeState>(
                          builder: (context, themeState) {
                            final isDark =
                                themeState.theme == AppTheme.purpleDark;

                            return SvgPicture.asset(
                              state.isBookmarked
                                  ? isDark
                                      ? FeatureIcons.bookmarkFilledWhite
                                      : FeatureIcons.bookmarkFilledBlack
                                  : isDark
                                      ? FeatureIcons.bookmarkEmptyWhite
                                      : FeatureIcons.bookmarkEmptyBlack,
                            );
                          },
                        ),
                      ),
                      PullDownMenuItem(
                        title: 'Add to curation',
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            elevation: 0,
                            builder: (_) {
                              return AddItemToCurationView(
                                articleId: state.video.identifier,
                                articlePubkey: state.video.pubkey,
                                kind: EventKind.CURATION_VIDEOS,
                              );
                            },
                            isScrollControlled: true,
                            useRootNavigator: true,
                            useSafeArea: true,
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                          );
                        },
                        itemTheme: PullDownMenuItemTheme(
                          textStyle: textStyle,
                        ),
                        iconWidget: SvgPicture.asset(
                          FeatureIcons.addCuration,
                          height: 20,
                          width: 20,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColorDark,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                    PullDownMenuItem(
                      title: 'Share',
                      onTap: () {
                        showModalBottomSheet(
                          elevation: 0,
                          context: context,
                          builder: (_) {
                            return ShareView(
                              image: state.video.thumbnail,
                              data: {
                                'kind': EventKind.VIDEO_HORIZONTAL,
                                'id': state.video.identifier,
                              },
                              placeholder: state.video.placeHolder,
                              pubkey: state.video.pubkey,
                              title: state.video.title,
                              description: state.video.summary,
                              kindText: 'Video',
                              icon: FeatureIcons.curations,
                              upvotes: state.votes.values
                                  .where((element) => element.vote)
                                  .toList()
                                  .length,
                              downvotes: state.votes.values
                                  .where((element) => !element.vote)
                                  .toList()
                                  .length,
                              views: state.viewsCount.length,
                              onShare: () {
                                RenderBox? box;
                                if (ResponsiveBreakpoints.of(context)
                                    .largerThan(MOBILE)) {
                                  box =
                                      context.findRenderObject() as RenderBox?;
                                }

                                context
                                    .read<HorizontalVideoCubit>()
                                    .shareLink(box);
                              },
                            );
                          },
                          isScrollControlled: true,
                          useRootNavigator: true,
                          useSafeArea: true,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                        );
                      },
                      itemTheme: PullDownMenuItemTheme(
                        textStyle: textStyle,
                      ),
                      iconWidget: SvgPicture.asset(
                        FeatureIcons.share,
                        height: 20,
                        width: 20,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).primaryColorDark,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    if (getUserStatus() == UserStatus.UsingPrivKey)
                      PullDownMenuItem(
                        onTap: () {
                          if (state.reports.contains(state.currentUserPubkey)) {
                            singleSnackBar(
                              context: context,
                              message: 'You have already reported this video.',
                              color: kOrange,
                              backGroundColor: kOrangeSide,
                              icon: ToastsIcons.warning,
                            );
                          } else {
                            showModalBottomSheet(
                              context: context,
                              elevation: 0,
                              builder: (_) {
                                return BlocProvider.value(
                                  value: context.read<HorizontalVideoCubit>(),
                                  child: ArticleReports(
                                    title: state.video.title,
                                    isArticle: false,
                                    onReport: (reason, comment) {
                                      context
                                          .read<HorizontalVideoCubit>()
                                          .report(
                                            reason: reason,
                                            comment: comment,
                                            onSuccess: () {
                                              Navigator.pop(context);
                                            },
                                          );
                                    },
                                  ),
                                );
                              },
                              isScrollControlled: true,
                              useRootNavigator: true,
                              useSafeArea: true,
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                            );
                          }
                        },
                        title: 'Report',
                        isDestructive: true,
                        iconWidget: SvgPicture.asset(
                          FeatureIcons.report,
                          height: 20,
                          width: 20,
                          colorFilter: ColorFilter.mode(
                            kRed,
                            BlendMode.srcIn,
                          ),
                        ),
                        itemTheme: PullDownMenuItemTheme(
                          textStyle: textStyle,
                        ),
                      ),
                  ];
                },
                buttonBuilder: (context, showMenu) => IconButton(
                  onPressed: showMenu,
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColorLight,
                    visualDensity: VisualDensity(
                      horizontal: -2,
                      vertical: -2,
                    ),
                  ),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Theme.of(context).primaryColorDark,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HVbutton extends StatelessWidget {
  const HVbutton({
    Key? key,
    required this.icon,
    required this.text,
    required this.onTap,
    required this.onLongPress,
    this.useOpacity,
  }) : super(key: key);

  final String icon;
  final String text;
  final bool? useOpacity;
  final Function() onTap;
  final Function() onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 3,
          horizontal: kDefaultPadding / 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            kDefaultPadding * 3,
          ),
          color: useOpacity != null
              ? Theme.of(context).primaryColorLight.withValues(alpha: 0.6)
              : Theme.of(context).primaryColorLight,
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              width: 15,
              height: 15,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
            if (text.isNotEmpty) ...[
              const SizedBox(
                width: kDefaultPadding / 3,
              ),
              Text(
                text,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).primaryColorDark,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HorizontalCustomVideoPlayer extends StatefulWidget {
  const HorizontalCustomVideoPlayer({
    Key? key,
    required this.video,
    required this.controllerEmitter,
  }) : super(key: key);

  final VideoModel video;
  final Function(PodPlayerController) controllerEmitter;

  @override
  State<HorizontalCustomVideoPlayer> createState() =>
      _HorizontalCustomVideoPlayerState();
}

class _HorizontalCustomVideoPlayerState
    extends State<HorizontalCustomVideoPlayer> {
  late final PodPlayerController controller;
  final ratio = 16 / 9;

  @override
  void initState() {
    super.initState();
    initController();
  }

  void initController() {
    String url = widget.video.url;
    VideosKinds type = VideosKinds.regular;

    if (!url.contains('player.vimeo.com/progressive_redirect/playback')) {
      type = (url.contains('youtu.be/') || url.contains('youtube.com/'))
          ? VideosKinds.youtube
          : url.contains('vimeo.com/')
              ? VideosKinds.vimeo
              : VideosKinds.regular;
    }

    try {
      controller = PodPlayerController(
        playVideoFrom: type == VideosKinds.youtube
            ? PlayVideoFrom.youtube(url)
            : type == VideosKinds.vimeo
                ? PlayVideoFrom.vimeo(url.split('/').last)
                : PlayVideoFrom.network(url),
        podPlayerConfig: const PodPlayerConfig(
          autoPlay: true,
          isLooping: false,
        ),
      )..initialise();
      widget.controllerEmitter.call(controller);
    } catch (e, stackTrace) {
      lg.i(stackTrace);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kBlack,
      ),
      child: Stack(
        children: [
          PodVideoPlayer(
            controller: controller,
            matchVideoAspectRatioToFrame: true,
            videoThumbnail: widget.video.thumbnail.isNotEmpty
                ? DecorationImage(
                    image: CachedNetworkImageProvider(widget.video.thumbnail),
                  )
                : null,
            onVideoError: () {
              return AspectRatio(
                aspectRatio: ratio,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning,
                        size: 20,
                      ),
                      const SizedBox(height: kDefaultPadding / 2),
                      Text(
                        'Error while loading the video',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
            podProgressBarConfig: PodProgressBarConfig(
              circleHandlerRadius: 4,
            ),
          ),
          if (!controller.isVideoPlaying)
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: IconButton.styleFrom(
                backgroundColor: kDarkGrey.withValues(alpha: 0.8),
                visualDensity: VisualDensity(
                  horizontal: -2,
                  vertical: -2,
                ),
                padding: EdgeInsets.zero,
              ),
              icon: Icon(
                Icons.keyboard_arrow_left,
                color: kWhite,
              ),
            ),
        ],
      ),
    );
  }
}

class StatContainer extends StatelessWidget {
  const StatContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HorizontalVideoCubit, HorizontalVideoState>(
      builder: (context, state) {
        final calculatedVotes = getVotes(
          votes: state.votes,
          pubkey: state.userStatus == UserStatus.UsingPrivKey
              ? state.currentUserPubkey
              : null,
        );

        final zaps =
            state.zaps.isEmpty ? 0 : state.zaps.values.reduce((a, b) => a + b);

        return Row(
          children: [
            Expanded(
              child: CustomIconButton(
                backgroundColor: kTransparent,
                icon: FeatureIcons.zap,
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    elevation: 0,
                    builder: (_) {
                      return ZappersView(
                        zappers: state.zaps,
                      );
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
                onClicked: () {},
                value: zaps.toString(),
                size: 22,
              ),
            ),
            Expanded(
              child: CustomIconButton(
                backgroundColor: kTransparent,
                icon: FeatureIcons.comments,
                onClicked: () {
                  if (state.userStatus == UserStatus.UsingPrivKey)
                    showModalBottomSheet(
                      context: context,
                      elevation: 0,
                      builder: (_) {
                        return CommentBoxView(
                          commentId: '',
                          commentPubkey: state.video.pubkey,
                          commentContent: state.video.title,
                          commentDate: state.video.createdAt,
                          kind: EventKind.LONG_FORM,
                          shareableLink: createShareableLink(
                            EventKind.LONG_FORM,
                            state.video.pubkey,
                            state.video.identifier,
                          ),
                          onAddComment: (commentContent, mentions, commentId) {
                            context.read<HorizontalVideoCubit>().addComment(
                                  content: commentContent,
                                  replyCommentId: commentId,
                                  mentions: mentions,
                                  onSuccess: () {
                                    Navigator.pop(context);
                                  },
                                );
                          },
                        );
                      },
                      isScrollControlled: true,
                      useRootNavigator: true,
                      useSafeArea: true,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    );
                },
                onLongPress: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => ThreadsView(
                        mainCommentId: '',
                        authorPubkey: state.video.pubkey,
                        threadsType: ThreadsType.horizontalVideo,
                        horizontalVideoCubit:
                            context.read<HorizontalVideoCubit>(),
                        userStatus: state.userStatus,
                        currentUserPubkey: state.currentUserPubkey,
                        shareableLink: createShareableLink(
                          state.video.kind,
                          state.video.pubkey,
                          state.video.identifier,
                        ),
                        mutes: state.mutes,
                        kind: state.video.kind,
                        onAddComment: (commentContent, mentions, commentId) {
                          context.read<HorizontalVideoCubit>().addComment(
                                content: commentContent,
                                replyCommentId: commentId,
                                mentions: mentions,
                                onSuccess: () {
                                  Navigator.pop(context);
                                },
                              );
                        },
                        onDeleteComment: (commentId) {
                          context
                              .read<HorizontalVideoCubit>()
                              .deleteComment(commentId: commentId);
                        },
                      ),
                    ),
                  );
                },
                value: getCommentsCount(state.comments).toString(),
                size: 22,
              ),
            ),
            Expanded(
              child: CustomIconButton(
                backgroundColor: kTransparent,
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    elevation: 0,
                    builder: (_) {
                      final upvotes = state.votes.entries
                          .where((element) => element.value.vote);

                      return VotersView(
                        voters: Map<String, VoteModel>.fromEntries(
                          upvotes,
                        ),
                        title: 'Upvoters',
                      );
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
                icon: calculatedVotes[1]
                    ? FeatureIcons.upvoteFilled
                    : FeatureIcons.upvote,
                onClicked: () {
                  context.read<HorizontalVideoCubit>().setVote(
                        upvote: true,
                        eventId: state.video.videoId,
                        eventPubkey: state.video.pubkey,
                      );
                },
                value: calculatedVotes[0].toString(),
                size: 22,
              ),
            ),
            Expanded(
              child: CustomIconButton(
                backgroundColor: kTransparent,
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    elevation: 0,
                    builder: (_) {
                      final downvotes = state.votes.entries
                          .where((element) => !element.value.vote);

                      return VotersView(
                        voters: Map<String, VoteModel>.fromEntries(
                          downvotes,
                        ),
                        title: 'Downvoters',
                      );
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
                icon: calculatedVotes[3]
                    ? FeatureIcons.downvoteFilled
                    : FeatureIcons.downvote,
                onClicked: () {
                  context.read<HorizontalVideoCubit>().setVote(
                        upvote: false,
                        eventId: state.video.videoId,
                        eventPubkey: state.video.pubkey,
                      );
                },
                value: calculatedVotes[2].toString(),
                size: 22,
              ),
            ),
            Expanded(
              child: CustomIconButton(
                backgroundColor: kTransparent,
                onLongPress: () {},
                icon: FeatureIcons.report,
                onClicked: () {},
                value: state.reports.length.toString(),
                size: 22,
              ),
            ),
          ],
        );
      },
    );
  }
}
