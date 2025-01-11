// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/curation_cubit/curation_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/nostr/nips/nip_019.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/article_view/article_view.dart';
import 'package:yakihonne/views/article_view/widgets/article_report.dart';
import 'package:yakihonne/views/curation_view/widgets/curation_article_item.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/threads_view/threads_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/vertical_video_view.dart';
import 'package:yakihonne/views/widgets/article_thumbnail.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/comment_box_view.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/place_holders.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/widgets/share_view.dart';
import 'package:yakihonne/views/widgets/voters_view.dart';
import 'package:yakihonne/views/widgets/zappers_view.dart';
import 'package:yakihonne/views/zap_view/set_zaps_view.dart';

class CurationView extends HookWidget {
  static const routeName = '/curationView';
  static Route route(RouteSettings settings) {
    final curation = settings.arguments as Curation;

    return CupertinoPageRoute(
      builder: (_) => CurationView(
        curation: curation,
      ),
    );
  }

  final Curation curation;

  CurationView({
    Key? key,
    required this.curation,
  }) : super(key: key) {
    FirebaseAnalytics.instance.setCurrentScreen(screenName: 'Curation screen');
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController(
      initialScrollOffset: 0,
    );

    return BlocProvider(
      create: (context) => CurationCubit(
        curation: curation,
        nostrRepository: context.read<NostrDataRepository>(),
      )..initView(),
      child: Scaffold(
        appBar: CustomAppBar(title: 'Curation'),
        body: Stack(
          children: [
            CurationContentView(
              scrollController: scrollController,
              curation: curation,
            ),
            ResetScrollButton(scrollController: scrollController),
          ],
        ),
      ),
    );
  }
}

class CurationContentView extends StatelessWidget {
  const CurationContentView({
    super.key,
    required this.scrollController,
    required this.curation,
  });

  final ScrollController scrollController;
  final Curation curation;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: scrollController,
      child: NestedScrollView(
        controller: scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                vertical: kDefaultPadding / 2,
                horizontal: kDefaultPadding / 2,
              ),
              sliver: SliverToBoxAdapter(
                child: BlocBuilder<CurationCubit, CurationState>(
                  builder: (context, state) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CurationHeader(curation: curation),
                        const SizedBox(
                          height: kDefaultPadding / 1.5,
                        ),
                        GestureDetector(
                          onTap: () {
                            if (curation.image.isNotEmpty) {
                              final imageProvider = CachedNetworkImageProvider(
                                curation.image,
                              );

                              showImageViewer(
                                context,
                                imageProvider,
                                doubleTapZoomable: true,
                                swipeDismissible: true,
                              );
                            }
                          },
                          child: ArticleThumbnail(
                            image: curation.image,
                            width: double.infinity,
                            placeholder: curation.placeHolder,
                            height: 100,
                          ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 3,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    height: kDefaultPadding / 2,
                                  ),
                                  Text(
                                    curation.title.trim(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                    textAlign: TextAlign.left,
                                  ),
                                  if (curation.description
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(
                                      height: kDefaultPadding / 4,
                                    ),
                                    Text(
                                      curation.description.trim(),
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      textAlign: TextAlign.left,
                                    )
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: kDefaultPadding / 2,
                ),
                child: CurationStatContainer(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    BlocBuilder<CurationCubit, CurationState>(
                      buildWhen: (previous, current) =>
                          previous.articles != current.articles ||
                          previous.videos != current.videos,
                      builder: (context, state) {
                        final type =
                            state.isArticlesCuration ? 'Articles' : 'Videos';
                        final length = state.isArticlesCuration
                            ? state.articles.length
                            : state.videos.length;
                        return Text(
                          '$type on this curation (${length.toString().padLeft(2, '0')})',
                          textAlign: TextAlign.start,
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: kOrange,
                                  ),
                        );
                      },
                    ),
                    Divider(),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Padding(
          padding: const EdgeInsets.only(
            bottom: kDefaultPadding,
          ),
          child: BlocBuilder<CurationCubit, CurationState>(
            buildWhen: (previous, current) =>
                previous.articles != current.articles ||
                previous.videos != current.videos ||
                previous.isArticleLoading != current.isArticleLoading ||
                previous.mutes != current.mutes,
            builder: (context, state) {
              if (state.isArticleLoading) {
                return Column(
                  children: [
                    Center(
                      child: SkeletonSelector(
                        placeHolderWidget: ArticleSkeleton(),
                      ),
                    ),
                  ],
                );
              } else if (state.isArticlesCuration
                  ? state.articles.isEmpty
                  : state.videos.isEmpty) {
                return EmptyList(
                  description:
                      'No ${state.isArticlesCuration ? 'articles' : 'videos'} on this curation have been found',
                  icon: FeatureIcons.curations,
                );
              } else {
                if (curation.isArticleCuration()) {
                  return MasonryGridView.count(
                    crossAxisCount: 2,
                    itemCount: state.articles.length,
                    crossAxisSpacing: kDefaultPadding / 2,
                    mainAxisSpacing: kDefaultPadding / 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                    ),
                    itemBuilder: (context, index) {
                      final article = state.articles[index];

                      return CurationItem(
                        createdAt: article.createdAt,
                        image: article.image,
                        isArticle: true,
                        muteKind: 'article',
                        placeholder: article.placeholder,
                        pubkey: article.pubkey,
                        title: article.title,
                        isMuted: state.mutes.contains(article.pubkey),
                        index: index,
                        onClicked: () {
                          Navigator.pushNamed(
                            context,
                            ArticleView.routeName,
                            arguments: article,
                          );
                        },
                      );
                    },
                  );
                } else {
                  return MasonryGridView.count(
                    crossAxisCount: 2,
                    itemCount: state.videos.length,
                    crossAxisSpacing: kDefaultPadding / 2,
                    mainAxisSpacing: kDefaultPadding / 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                    ),
                    itemBuilder: (context, index) {
                      final video = state.videos[index];

                      return CurationItem(
                        createdAt: video.createdAt,
                        image: video.thumbnail,
                        isArticle: false,
                        muteKind: 'video',
                        placeholder: video.placeHolder,
                        pubkey: video.pubkey,
                        title: video.title,
                        isMuted: state.mutes.contains(video.pubkey),
                        index: index,
                        onClicked: () {
                          if (video.isHorizontal) {
                            Navigator.pushNamed(
                              context,
                              HorizontalVideoView.routeName,
                              arguments: [
                                video,
                              ],
                            );
                          } else {
                            Navigator.pushNamed(
                              context,
                              VerticalVideoView.routeName,
                              arguments: [
                                video,
                                <VideoModel>[],
                              ],
                            );
                          }
                        },
                      );
                    },
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }
}

class CurationHeader extends StatelessWidget {
  const CurationHeader({
    super.key,
    required this.curation,
  });

  final Curation curation;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurationCubit, CurationState>(
      builder: (context, state) {
        return BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
          selector: (state) => state.authors[curation.pubKey],
          builder: (context, user) {
            final author = user ??
                emptyUserModel.copyWith(
                  pubKey: curation.pubKey,
                  picturePlaceholder:
                      getRandomPlaceholder(input: curation.pubKey, isPfp: true),
                );

            return Row(
              children: [
                ProfilePicture2(
                  size: 35,
                  image: author.picture,
                  placeHolder: author.picturePlaceholder,
                  padding: 0,
                  strokeWidth: 1,
                  reduceSize: true,
                  strokeColor: kWhite,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Posted by ',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            TextSpan(
                              text: author.name.isEmpty
                                  ? Nip19.encodePubkey(
                                      curation.pubKey,
                                    ).substring(0, 10)
                                  : author.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    color: kGreen,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          DateRow(
                            createdAt: curation.createdAt,
                            publishedAt: curation.publishedAt,
                            color: Theme.of(context).primaryColorDark,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                            ),
                            child: DotContainer(
                              color: Theme.of(context).primaryColorDark,
                              size: 3,
                              isNotMarging: true,
                            ),
                          ),
                          Text(
                            '${curation.eventsIds.length.toString().padLeft(2, '0')} arts.',
                            style: Theme.of(context).textTheme.labelSmall!,
                          ),
                        ],
                      ),
                    ],
                  ),
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
                      if (state.isValidUser) ...[
                        PullDownMenuItem(
                          title: 'Bookmark',
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              elevation: 0,
                              builder: (_) {
                                return AddBookmarkView(
                                  kind: EventKind.CURATION_ARTICLES,
                                  identifier: curation.identifier,
                                  eventPubkey: curation.pubKey,
                                  image: curation.image,
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
                        if (state.canBeZapped)
                          PullDownMenuItem(
                            title: 'Zap',
                            onTap: () {
                              showModalBottomSheet(
                                elevation: 0,
                                context: context,
                                builder: (_) {
                                  return SetZapsView(
                                    author: author,
                                    aTag:
                                        '${EventKind.CURATION_ARTICLES}:${curation.pubKey}:${curation.identifier}',
                                    isZapSplit: curation.zapsSplits.isNotEmpty,
                                    zapSplits: curation.zapsSplits,
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
                              FeatureIcons.zap,
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
                                image: curation.image,
                                data: {
                                  'kind': curation.kind,
                                  'id': curation.identifier,
                                },
                                placeholder: curation.placeHolder,
                                pubkey: curation.pubKey,
                                title: curation.title,
                                description: curation.description,
                                kindText: 'Curation',
                                icon: FeatureIcons.curations,
                                upvotes: state.votes.values
                                    .where((element) => element.vote)
                                    .toList()
                                    .length,
                                downvotes: state.votes.values
                                    .where((element) => !element.vote)
                                    .toList()
                                    .length,
                                onShare: () {
                                  RenderBox? box;
                                  if (ResponsiveBreakpoints.of(context)
                                      .largerThan(MOBILE)) {
                                    box = context.findRenderObject()
                                        as RenderBox?;
                                  }

                                  context.read<CurationCubit>().shareLink(box);
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
                      if (state.isValidUser)
                        PullDownMenuItem(
                          onTap: () {
                            if (state.reports
                                .contains(state.currentUserPubkey)) {
                              singleSnackBar(
                                context: context,
                                message:
                                    'You have already reported this article.',
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
                                    value: context.read<CurationCubit>(),
                                    child: ArticleReports(
                                      title: curation.title,
                                      isArticle: false,
                                      onReport: (reason, comment) {
                                        context.read<CurationCubit>().report(
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
                    ),
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class CurationStatContainer extends StatelessWidget {
  const CurationStatContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurationCubit, CurationState>(
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
                          commentPubkey: state.curation.pubKey,
                          commentContent: state.curation.title,
                          commentDate: state.curation.createdAt,
                          kind: EventKind.CURATION_ARTICLES,
                          shareableLink: createShareableLink(
                            EventKind.CURATION_ARTICLES,
                            state.curation.pubKey,
                            state.curation.identifier,
                          ),
                          onAddComment: (commentContent, mentions, commentId) {
                            context.read<CurationCubit>().addComment(
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
                        authorPubkey: state.curation.pubKey,
                        threadsType: ThreadsType.curation,
                        curationCubit: context.read<CurationCubit>(),
                        userStatus: state.userStatus,
                        currentUserPubkey: state.currentUserPubkey,
                        shareableLink: createShareableLink(
                          state.curation.kind,
                          state.curation.pubKey,
                          state.curation.identifier,
                        ),
                        mutes: state.mutes,
                        kind: EventKind.CURATION_ARTICLES,
                        onAddComment: (commentContent, mentions, commentId) {
                          context.read<CurationCubit>().addComment(
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
                              .read<CurationCubit>()
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
                  context.read<CurationCubit>().setVote(
                        upvote: true,
                        eventId: state.curation.eventId,
                        eventPubkey: state.curation.pubKey,
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
                  context.read<CurationCubit>().setVote(
                        upvote: false,
                        eventId: state.curation.eventId,
                        eventPubkey: state.curation.pubKey,
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

  int getCommentsCount(List<Comment> comments) {
    final rootComments = comments.where((comment) => comment.isRoot).toList();

    int count = rootComments.length;

    if (rootComments.isNotEmpty) {
      for (int i = 0; i < rootComments.length; i++) {
        int subsCount = getSubComments(
          comments: comments,
          commentId: rootComments[i].id,
        ).length;

        count += subsCount;
      }
    }

    return count;
  }

  List<String> getSubComments({
    required List<Comment> comments,
    required String commentId,
  }) {
    Set<String> subCommentsIds = {};

    for (final subComment in comments) {
      if (!subComment.isRoot && !subCommentsIds.contains(subComment.id)) {
        if (commentId == subComment.replyTo) {
          subCommentsIds.add(subComment.id);

          final list = getSubComments(
            comments: comments,
            commentId: subComment.id,
          );

          subCommentsIds.addAll(list);
        }
      }
    }

    return subCommentsIds.toList();
  }
}
