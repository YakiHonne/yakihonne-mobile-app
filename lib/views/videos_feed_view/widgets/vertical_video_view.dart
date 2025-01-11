// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:numeral/numeral.dart';
import 'package:pod_player/pod_player.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/horizontal_video_cubit/horizontal_video_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/article_view/widgets/article_curations_add.dart';
import 'package:yakihonne/views/article_view/widgets/article_report.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/tag_view/tag_view.dart';
import 'package:yakihonne/views/threads_view/threads_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/video_description.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/comment_box_view.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/widgets/share_view.dart';
import 'package:yakihonne/views/widgets/voters_view.dart';
import 'package:yakihonne/views/widgets/zappers_view.dart';
import 'package:yakihonne/views/zap_view/set_zaps_view.dart';

class VerticalVideoView extends StatelessWidget {
  static const routeName = '/verticalVideoView';
  static Route route(RouteSettings settings) {
    final items = settings.arguments as List;

    return CupertinoPageRoute(
      builder: (_) => VerticalVideoView(
        video: items[0],
      ),
    );
  }

  final VideoModel video;

  const VerticalVideoView({
    Key? key,
    required this.video,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HorizontalVideoCubit(
        video: video,
      )..initView(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: kTransparent,
          leading: Center(
            child: CustomIconButton(
              onClicked: () {
                Navigator.pop(context);
              },
              icon: FeatureIcons.closeRaw,
              size: 22,
              backgroundColor:
                  Theme.of(context).primaryColorLight.withValues(alpha: 0.6),
            ),
          ),
          actions: [
            BlocBuilder<HorizontalVideoCubit, HorizontalVideoState>(
              builder: (context, state) {
                return PullDownButton(
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
                                  'kind': EventKind.VIDEO_VERTICAL,
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
                                    box = context.findRenderObject()
                                        as RenderBox?;
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
                            if (state.reports
                                .contains(state.currentUserPubkey)) {
                              singleSnackBar(
                                context: context,
                                message:
                                    'You have already reported this video.',
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
                      backgroundColor: Theme.of(context)
                          .primaryColorLight
                          .withValues(alpha: 0.6),
                    ),
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: Theme.of(context).primaryColorDark,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<HorizontalVideoCubit, HorizontalVideoState>(
          builder: (context, state) {
            return Stack(
              children: [
                VerticalVideoPlayer(
                  video: video,
                ),
                Positioned(
                  bottom: kBottomNavigationBarHeight,
                  left: kDefaultPadding / 2,
                  right: kDefaultPadding / 2,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            BlocBuilder<AuthorsCubit, AuthorsState>(
                              builder: (context, authorState) {
                                final author =
                                    authorState.authors[video.pubkey] ??
                                        emptyUserModel.copyWith(
                                          pubKey: video.pubkey,
                                          picturePlaceholder:
                                              getRandomPlaceholder(
                                            input: video.pubkey,
                                            isPfp: true,
                                          ),
                                        );

                                return Row(
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
                                    Flexible(
                                      child: Text(
                                        getAuthorName(author),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium!
                                            .copyWith(
                                          color: kWhite,
                                          shadows: [
                                            Shadow(
                                              color: Theme.of(context)
                                                  .primaryColorLight,
                                              blurRadius: 2,
                                            )
                                          ],
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
                                );
                              },
                            ),
                            const SizedBox(
                              height: kDefaultPadding / 2,
                            ),
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
                                      shadows: [
                                        Shadow(
                                          color: Theme.of(context)
                                              .primaryColorLight,
                                          blurRadius: 2,
                                        )
                                      ],
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
                                            .labelSmall!
                                            .copyWith(
                                          shadows: [
                                            Shadow(
                                              color: Theme.of(context)
                                                  .primaryColorLight,
                                              blurRadius: 2,
                                            )
                                          ],
                                        ),
                                      ),
                                      DotContainer(
                                        color: kDimGrey,
                                        size: 3,
                                      ),
                                      Text(
                                        '${StringUtil.formatTimeDifference(video.createdAt)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall!
                                            .copyWith(
                                          shadows: [
                                            Shadow(
                                              color: Theme.of(context)
                                                  .primaryColorLight,
                                              blurRadius: 2,
                                            )
                                          ],
                                        ),
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
                                          shadows: [
                                            Shadow(
                                              color: Theme.of(context)
                                                  .primaryColorLight,
                                              blurRadius: 2,
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: kDefaultPadding / 2,
                            ),
                            Builder(builder: (context) {
                              final tags = video.tags;

                              return SizedBox(
                                height: 24,
                                child: ScrollShadow(
                                  color: Theme.of(context).primaryColorLight,
                                  size: 10,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: tags.length,
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    separatorBuilder: (context, index) {
                                      return const SizedBox(
                                        width: kDefaultPadding / 4,
                                      );
                                    },
                                    itemBuilder: (context, index) {
                                      final tag = tags[index];
                                      if (tag.trim().isEmpty) {
                                        return SizedBox.shrink();
                                      }

                                      return Center(
                                        child: InfoRoundedContainer(
                                          tag: tag,
                                          useOpacity: true,
                                          color:
                                              Theme.of(context).highlightColor,
                                          textColor: Theme.of(context)
                                              .primaryColorDark,
                                          onClicked: () {
                                            Navigator.pushNamed(
                                              context,
                                              TagView.routeName,
                                              arguments: tag,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      VerticalVideoStatsContainer(),
                    ],
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

class VerticalVideoStatsContainer extends StatelessWidget {
  const VerticalVideoStatsContainer({super.key});

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

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: kDefaultPadding / 3,
                horizontal: kDefaultPadding / 2,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  kDefaultPadding,
                ),
                color:
                    Theme.of(context).primaryColorLight.withValues(alpha: 0.6),
              ),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        context.read<HorizontalVideoCubit>().setVote(
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
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
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
                                  color: Theme.of(context).primaryColorDark,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        context.read<HorizontalVideoCubit>().setVote(
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
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
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
                                  color: Theme.of(context).primaryColorDark,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
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
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              onTap: () {},
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            HVbutton(
              text: state.comments.length.toString(),
              icon: FeatureIcons.comments,
              useOpacity: true,
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
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
              },
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            HVbutton(
              useOpacity: true,
              text: state.reports.length.toString(),
              icon: FeatureIcons.report,
              onLongPress: () {},
              onTap: () {},
            ),
          ],
        );
      },
    );
  }
}

class VerticalVideoPlayer extends StatefulWidget {
  const VerticalVideoPlayer({
    Key? key,
    required this.video,
  }) : super(key: key);

  final VideoModel video;

  @override
  State<VerticalVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<VerticalVideoPlayer> {
  late final PodPlayerController controller;
  final ratio = 9 / 16;

  @override
  void initState() {
    super.initState();
    initController();
  }

  void initController() async {
    final type = (widget.video.url.contains('youtu.be/') ||
            widget.video.url.contains('youtube.com/'))
        ? VideosKinds.youtube
        : widget.video.url.contains('vimeo.com/')
            ? VideosKinds.vimeo
            : VideosKinds.regular;

    try {
      controller = PodPlayerController(
        playVideoFrom: type == VideosKinds.youtube
            ? PlayVideoFrom.youtube(widget.video.url)
            : type == VideosKinds.vimeo
                ? PlayVideoFrom.vimeo(widget.video.url.split('/').last)
                : PlayVideoFrom.network(widget.video.url),
        podPlayerConfig: const PodPlayerConfig(
          autoPlay: true,
          isLooping: true,
        ),
      )..initialise();
    } catch (e, stackTrace) {
      lg.i(widget.video.url);
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
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => PodVideoPlayer(
          controller: controller,
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
          alwaysShowProgressBar: false,
          videoAspectRatio: constraints.maxWidth / constraints.maxHeight,
          frameAspectRatio: constraints.maxWidth / constraints.maxHeight,
          overlayBuilder: (options) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                controller.togglePlayPause();
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    child: options.podProgresssBar,
                  ),
                ],
              ),
            );
          },
          podProgressBarConfig: PodProgressBarConfig(
            circleHandlerRadius: 4,
            alwaysVisibleCircleHandler: true,
            padding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding * 1.5,
              horizontal: kDefaultPadding,
            ),
          ),
          matchVideoAspectRatioToFrame: true,
        ),
      ),
    );
  }
}
