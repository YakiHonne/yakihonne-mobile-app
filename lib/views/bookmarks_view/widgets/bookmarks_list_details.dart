// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/bookmarks_cubit/bookmark_details_cubit/bookmark_details_cubit.dart';
import 'package:yakihonne/blocs/bookmarks_cubit/bookmarks_cubit.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/bookmark_list_model.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/article_view/article_view.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_container.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_details.dart';
import 'package:yakihonne/views/curation_view/curation_view.dart';
import 'package:yakihonne/views/flash_news_details_view/flash_news_details_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/vertical_video_view.dart';
import 'package:yakihonne/views/widgets/article_container.dart';
import 'package:yakihonne/views/widgets/article_thumbnail.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/flash_news_container.dart';
import 'package:yakihonne/views/widgets/note_container.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/widgets/video_common_container.dart';

class BookmarksListDetails extends HookWidget {
  const BookmarksListDetails({
    Key? key,
    required this.bookmarkListModel,
    required this.bookmarksCubit,
  }) : super(key: key);

  static const routeName = '/bookmarksListDetails';
  static Route route(RouteSettings settings) {
    final bookmarkListModel =
        (settings.arguments as List).first as BookmarkListModel;
    final bookmarksCubit = (settings.arguments as List)[1] as BookmarksCubit;

    return CupertinoPageRoute(
      builder: (_) => BookmarksListDetails(
        bookmarkListModel: bookmarkListModel,
        bookmarksCubit: bookmarksCubit,
      ),
    );
  }

  final BookmarkListModel bookmarkListModel;
  final BookmarksCubit bookmarksCubit;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final bookmarkType = useState(bookmarksTypes.first);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: bookmarksCubit),
        BlocProvider(
          create: (context) => BookmarkDetailsCubit(
            nostrRepository: context.read<NostrDataRepository>(),
            bookmarkListModel: bookmarkListModel,
          ),
        )
      ],
      child: Scaffold(
        body: Stack(
          children: [
            NestedScrollViewPlus(
              controller: scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  BookmarksListDetailsAppbar(
                    scrollController: scrollController,
                  ),
                  BlocBuilder<BookmarkDetailsCubit, BookmarkDetailsState>(
                    builder: (context, state) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding / 2,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.bookmarkListModel.title
                                          .trim()
                                          .capitalize(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (state.bookmarkListModel.description
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(
                                        height: kDefaultPadding / 4,
                                      ),
                                      Text(
                                        state.bookmarkListModel.description
                                            .trim(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(color: kDimGrey),
                                      ),
                                    ],
                                    const SizedBox(
                                      height: kDefaultPadding / 4,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${state.content.length.toString().padLeft(2, '0')} items',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall!
                                              .copyWith(color: kDimGrey),
                                        ),
                                        DotContainer(color: kLightPurple),
                                        Text(
                                          'Edited on: ${dateFormat2.format(state.bookmarkListModel.createAt)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall!
                                              .copyWith(color: kOrange),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                width: kDefaultPadding / 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 2,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'List',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                                ...bookmarksTypes
                                    .map(
                                      (e) => PullDownMenuItem.selectable(
                                        onTap: () {
                                          context
                                              .read<BookmarkDetailsCubit>()
                                              .filterBookmarksByType(e);
                                          bookmarkType.value = e;
                                        },
                                        selected: e == bookmarkType.value,
                                        title: e,
                                        itemTheme: PullDownMenuItemTheme(
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .labelMedium!,
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
                  ),
                  SliverToBoxAdapter(
                    child: const SizedBox(
                      height: kDefaultPadding,
                    ),
                  ),
                  BlocBuilder<BookmarkDetailsCubit, BookmarkDetailsState>(
                    builder: (context, state) {
                      if (state.isLoading) {
                        return SliverToBoxAdapter(
                          child: EmptyList(
                            description:
                                'No elements can be found in bookmarks list',
                            icon: FeatureIcons.bookmark,
                          ),
                        );
                      } else if (state.content.isEmpty) {
                        return SliverToBoxAdapter(
                          child: EmptyList(
                            description:
                                'No elements can be found in bookmarks list',
                            icon: FeatureIcons.bookmark,
                          ),
                        );
                      } else {
                        if (!ResponsiveBreakpoints.of(context).isMobile) {
                          return SliverToBoxAdapter(
                            child: MasonryGridView.builder(
                              gridDelegate:
                                  SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                              ),
                              shrinkWrap: true,
                              primary: false,
                              padding: const EdgeInsets.symmetric(
                                horizontal: kDefaultPadding / 2,
                              ),
                              mainAxisSpacing: kDefaultPadding / 2,
                              crossAxisSpacing: kDefaultPadding / 2,
                              itemCount: state.content.length,
                              itemBuilder: (context, index) {
                                final item = state.content[index];

                                if (item is Article) {
                                  return ArticleContainer(
                                    article: item,
                                    isProfileAccessible: true,
                                    highlightedTag: '',
                                    padding: 0,
                                    margin: 0,
                                    isBookmarked: true,
                                    userStatus: state.userStatus,
                                    onClicked: () {
                                      Navigator.pushNamed(
                                        context,
                                        ArticleView.routeName,
                                        arguments: item,
                                      );
                                    },
                                    isFollowing:
                                        state.followings.contains(item.pubkey),
                                  );
                                } else if (item is Curation) {
                                  return CurationContainer(
                                    curation: item,
                                    isBookmarked: true,
                                    userStatus: state.userStatus,
                                    onClicked: () {
                                      Navigator.pushNamed(
                                        context,
                                        CurationView.routeName,
                                        arguments: item,
                                      );
                                    },
                                    padding: 0,
                                  );
                                } else if (item is DetailedNoteModel) {
                                  return NoteContainer(
                                    note: item,
                                  );
                                } else if (item is FlashNews) {
                                  return HomeFlashNewsContainer(
                                    userStatus: state.userStatus,
                                    isFollowing:
                                        state.followings.contains(item.pubkey),
                                    isMuted: state.mutes.contains(item.pubkey),
                                    mainFlashNews:
                                        MainFlashNews(flashNews: item),
                                    flashNewsType: FlashNewsType.public,
                                    trySearch: false,
                                    isBookmarked: true,
                                    onClicked: () {
                                      Navigator.pushNamed(
                                        context,
                                        FlashNewsDetailsView.routeName,
                                        arguments: [
                                          MainFlashNews(flashNews: item),
                                          true
                                        ],
                                      );
                                    },
                                  );
                                } else if (item is BuzzFeedModel) {
                                  return BuzzFeedContainer(
                                    buzzFeedModel: item,
                                    isBookmarked: true,
                                    onClicked: () {
                                      Navigator.pushNamed(
                                        context,
                                        BuzzFeedDetails.routeName,
                                        arguments: item,
                                      );
                                    },
                                    onExternalShare: () {
                                      openWebPage(url: item.sourceUrl);
                                    },
                                  );
                                } else if (item is VideoModel) {
                                  final video = item;

                                  return VideoCommonContainer(
                                    isBookmarked: true,
                                    isMuted: state.mutes.contains(video.pubkey),
                                    isFollowing:
                                        state.followings.contains(video.pubkey),
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
                                } else {
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          );
                        } else {
                          return SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding / 2,
                            ),
                            sliver: SliverList.separated(
                              separatorBuilder: (context, index) =>
                                  const SizedBox(
                                height: kDefaultPadding / 2,
                              ),
                              itemBuilder: (context, index) {
                                final item = state.content[index];

                                if (item is Article) {
                                  return ArticleContainer(
                                    article: item,
                                    isProfileAccessible: true,
                                    highlightedTag: '',
                                    padding: 0,
                                    margin: 0,
                                    isMuted: state.mutes.contains(item.pubkey),
                                    isBookmarked: true,
                                    userStatus: state.userStatus,
                                    onClicked: () {
                                      Navigator.pushNamed(
                                        context,
                                        ArticleView.routeName,
                                        arguments: item,
                                      );
                                    },
                                    isFollowing:
                                        state.followings.contains(item.pubkey),
                                  );
                                } else if (item is Curation) {
                                  return Stack(
                                    children: [
                                      CurationContainer(
                                        curation: item,
                                        userStatus: state.userStatus,
                                        isBookmarked: true,
                                        isMuted:
                                            state.mutes.contains(item.pubKey),
                                        onClicked: () {
                                          Navigator.pushNamed(
                                            context,
                                            CurationView.routeName,
                                            arguments: item,
                                          );
                                        },
                                        padding: 0,
                                      ),
                                    ],
                                  );
                                } else if (item is BuzzFeedModel) {
                                  return BuzzFeedContainer(
                                    buzzFeedModel: item,
                                    isBookmarked: true,
                                    onClicked: () {
                                      Navigator.pushNamed(
                                        context,
                                        BuzzFeedDetails.routeName,
                                        arguments: item,
                                      );
                                    },
                                    onExternalShare: () {
                                      openWebPage(url: item.sourceUrl);
                                    },
                                  );
                                } else if (item is DetailedNoteModel) {
                                  return GlobalNoteContainer(
                                    note: item,
                                  );
                                } else if (item is FlashNews) {
                                  return HomeFlashNewsContainer(
                                    userStatus: state.userStatus,
                                    isFollowing:
                                        state.followings.contains(item.pubkey),
                                    isMuted: state.mutes.contains(item.pubkey),
                                    mainFlashNews:
                                        MainFlashNews(flashNews: item),
                                    flashNewsType: FlashNewsType.public,
                                    trySearch: false,
                                    isBookmarked: true,
                                    onClicked: () {
                                      Navigator.pushNamed(
                                        context,
                                        FlashNewsDetailsView.routeName,
                                        arguments: [
                                          MainFlashNews(flashNews: item),
                                          true
                                        ],
                                      );
                                    },
                                  );
                                } else if (item is VideoModel) {
                                  final video = item;

                                  return VideoCommonContainer(
                                    isBookmarked: true,
                                    isMuted: state.mutes.contains(video.pubkey),
                                    isFollowing:
                                        state.followings.contains(video.pubkey),
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
                                } else {
                                  return const SizedBox.shrink();
                                }
                              },
                              itemCount: state.content.length,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ];
              },
              body: Container(),
            ),
            ResetScrollButton(scrollController: scrollController),
          ],
        ),
      ),
    );
  }
}

class BookmarksListDetailsAppbar extends HookWidget {
  const BookmarksListDetailsAppbar({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final percentage = useState(0.0);
    useMemoized(
      () {
        scrollController.addListener(
          () {
            percentage.value = scrollController.offset > 100
                ? 1
                : scrollController.offset <= 0
                    ? 0
                    : scrollController.offset / 100;
          },
        );
      },
    );

    return BlocBuilder<BookmarkDetailsCubit, BookmarkDetailsState>(
      builder: (context, state) {
        return SliverAppBar(
          expandedHeight: kToolbarHeight + 50,
          pinned: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          stretch: true,
          title: Opacity(
            opacity: percentage.value,
            child: Text(
              'Bookmark list',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          centerTitle: true,
          leading: FadeInRight(
            duration: const Duration(milliseconds: 500),
            from: 30,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Center(
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context)
                      .primaryColorLight
                      .withValues(alpha: 0.7),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            BorderedIconButton(
              onClicked: () {
                showCupertinoDeletionDialogue(
                  context: context,
                  title: 'Delete bookmark list',
                  description:
                      "You're about to delete this bookmarks list, do you wish to proceed?",
                  buttonText: 'delete',
                  onDelete: () {
                    context.read<BookmarksCubit>().deleteBookmarksList(
                          bookmarkListEventId: state.bookmarkListModel.eventId,
                          bookmarkListIdentifier:
                              state.bookmarkListModel.identifier,
                          onSuccess: () {
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                          },
                        );
                  },
                );
              },
              primaryIcon: FeatureIcons.trash,
              borderColor: Theme.of(context).primaryColorLight,
              iconColor: kWhite,
              firstSelection: true,
              secondaryIcon: FeatureIcons.trash,
              backGroundColor: kRed,
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            centerTitle: false,
            stretchModes: [
              StretchMode.zoomBackground,
            ],
            background: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) => SizedBox(
                        height: constraints.maxHeight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (state
                                      .bookmarkListModel.image.isNotEmpty) {
                                    final imageProvider =
                                        CachedNetworkImageProvider(
                                      state.bookmarkListModel.image,
                                    );

                                    showImageViewer(
                                      context,
                                      imageProvider,
                                      doubleTapZoomable: true,
                                      swipeDismissible: true,
                                    );
                                  }
                                },
                                child: Container(
                                  foregroundDecoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        kTransparent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      stops: [
                                        0.1,
                                        0.5,
                                      ],
                                    ),
                                  ),
                                  child: ArticleThumbnail(
                                    image: state.bookmarkListModel.image,
                                    placeholder:
                                        state.bookmarkListModel.placeholder,
                                    width: double.infinity,
                                    height: constraints.maxHeight,
                                    radius: 0,
                                    isRound: false,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
