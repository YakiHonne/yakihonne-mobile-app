import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/tag_cubit/tag_cubit.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/article_view/article_view.dart';
import 'package:yakihonne/views/flash_news_details_view/flash_news_details_view.dart';
import 'package:yakihonne/views/search_view/search_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/vertical_video_view.dart';
import 'package:yakihonne/views/widgets/article_container.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/flash_news_container.dart';
import 'package:yakihonne/views/widgets/note_container.dart';
import 'package:yakihonne/views/widgets/scroll_to_top.dart';
import 'package:yakihonne/views/widgets/video_common_container.dart';

class TagView extends HookWidget {
  static const routeName = '/tagView';
  static Route route(RouteSettings settings) {
    final tag = settings.arguments as String;

    return CupertinoPageRoute(
      builder: (_) => TagView(
        tag: tag,
      ),
    );
  }

  TagView({super.key, required this.tag}) {
    FirebaseAnalytics.instance.setCurrentScreen(screenName: 'Tags screen');
  }

  final String tag;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController(
      initialScrollOffset: 0,
    );

    return BlocProvider(
      create: (context) => TagCubit(
        tag: tag,
        nostrRepository: context.read<NostrDataRepository>(),
      )..getTagData(),
      child: ScrollsToTop(
        onScrollsToTop: (event) async {
          onScrollsToTop(event, scrollController);
        },
        child: Scaffold(
          appBar: CustomAppBar(
            title: 'Selected tag',
          ),
          body: Scrollbar(
            controller: scrollController,
            child: Stack(
              children: [
                ResponsiveBreakpoints.of(context).largerThan(MOBILE)
                    ? TabletTagView(context, scrollController)
                    : MobileTagView(context, scrollController),
                ResetScrollButton(scrollController: scrollController),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget TabletTagView(
    BuildContext context,
    ScrollController scrollController,
  ) {
    return Column(
      children: [
        TagHeader(tag: tag),
        BlocBuilder<TagCubit, TagState>(
          buildWhen: (previous, current) =>
              previous.articles != current.articles ||
              previous.flashNews != current.flashNews ||
              previous.videos != current.videos ||
              previous.notes != current.notes ||
              previous.tagType != current.tagType ||
              previous.bookmarks != current.bookmarks ||
              previous.followings != current.followings ||
              previous.isFlashNewsLoading != current.isFlashNewsLoading ||
              previous.isVideosLoading != current.isVideosLoading ||
              previous.isNotesLoading != current.isNotesLoading ||
              previous.isArticleLoading != current.isArticleLoading,
          builder: (context, state) {
            return state.tagType == TagType.article && state.isArticleLoading ||
                    state.tagType == TagType.flashnews &&
                        state.isFlashNewsLoading ||
                    state.tagType == TagType.notes && state.isNotesLoading ||
                    state.tagType == TagType.video && state.isVideosLoading
                ? SearchLoading()
                : (state.tagType == TagType.article &&
                            state.articles.isEmpty) ||
                        (state.tagType == TagType.notes &&
                            state.notes.isEmpty) ||
                        (state.tagType == TagType.flashnews &&
                            state.flashNews.isEmpty) ||
                        (state.tagType == TagType.video && state.videos.isEmpty)
                    ? Builder(
                        builder: (context) {
                          final type = state.tagType == TagType.article
                              ? 'articles'
                              : state.tagType == TagType.video
                                  ? 'videos'
                                  : state.tagType == TagType.notes
                                      ? 'notes'
                                      : 'flashnews';

                          return EmptyList(
                            description: 'No $type on this tag have been found',
                            icon: FeatureIcons.selfArticles,
                          );
                        },
                      )
                    : Expanded(
                        child: Scrollbar(
                          child: MasonryGridView.count(
                            crossAxisCount: 2,
                            padding: const EdgeInsets.all(kDefaultPadding / 2),
                            crossAxisSpacing: kDefaultPadding / 2,
                            mainAxisSpacing: kDefaultPadding / 2,
                            itemBuilder: (context, index) {
                              if (state.tagType == TagType.article) {
                                final article = state.articles[index];

                                return ArticleContainer(
                                  isFollowing:
                                      state.followings.contains(article.pubkey),
                                  isProfileAccessible: true,
                                  article: article,
                                  highlightedTag: tag,
                                  userStatus: state.userStatus,
                                  isBookmarked: state.bookmarks
                                      .contains(article.identifier),
                                  onClicked: () {
                                    Navigator.pushNamed(
                                      context,
                                      ArticleView.routeName,
                                      arguments: article,
                                    );
                                  },
                                );
                              } else if (state.tagType == TagType.flashnews) {
                                final flashNews = state.flashNews[index];

                                return HomeFlashNewsContainer(
                                  userStatus: state.userStatus,
                                  isFollowing: state.followings
                                      .contains(flashNews.pubkey),
                                  mainFlashNews:
                                      MainFlashNews(flashNews: flashNews),
                                  selectedTag: tag,
                                  flashNewsType: FlashNewsType.public,
                                  isMuted:
                                      state.mutes.contains(flashNews.pubkey),
                                  isBookmarked:
                                      state.bookmarks.contains(flashNews.id),
                                  onClicked: () {
                                    Navigator.pushNamed(
                                      context,
                                      FlashNewsDetailsView.routeName,
                                      arguments: [
                                        MainFlashNews(flashNews: flashNews),
                                        true
                                      ],
                                    );
                                  },
                                );
                              } else if (state.tagType == TagType.video) {
                                final video = state.videos[index];

                                return VideoCommonContainer(
                                  isBookmarked: state.bookmarks
                                      .contains(video.identifier),
                                  isMuted: state.mutes.contains(video.pubkey),
                                  isFollowing:
                                      state.followings.contains(video.pubkey),
                                  selectedTag: tag,
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
                                final note = state.notes[index];

                                return NoteContainer(note: note);
                              }
                            },
                            itemCount: state.tagType == TagType.article
                                ? state.articles.length
                                : state.tagType == TagType.video
                                    ? state.videos.length
                                    : state.tagType == TagType.notes
                                        ? state.notes.length
                                        : state.flashNews.length,
                          ),
                        ),
                      );
          },
        ),
      ],
    );
  }

  Scrollbar MobileTagView(
    BuildContext context,
    ScrollController scrollController,
  ) {
    return Scrollbar(
      controller: scrollController,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: TagHeader(tag: tag),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
            sliver: BlocBuilder<TagCubit, TagState>(
              builder: (context, state) {
                return state.tagType == TagType.article &&
                            state.isArticleLoading ||
                        state.tagType == TagType.flashnews &&
                            state.isFlashNewsLoading ||
                        state.tagType == TagType.notes &&
                            state.isNotesLoading ||
                        state.tagType == TagType.video && state.isVideosLoading
                    ? SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SearchLoading(),
                          ],
                        ),
                      )
                    : (state.tagType == TagType.article &&
                                state.articles.isEmpty) ||
                            (state.tagType == TagType.notes &&
                                state.notes.isEmpty) ||
                            (state.tagType == TagType.flashnews &&
                                state.flashNews.isEmpty) ||
                            (state.tagType == TagType.video &&
                                state.videos.isEmpty)
                        ? SliverToBoxAdapter(
                            child: Builder(builder: (context) {
                              final type = state.tagType == TagType.article
                                  ? 'articles'
                                  : state.tagType == TagType.video
                                      ? 'videos'
                                      : state.tagType == TagType.notes
                                          ? 'notes'
                                          : 'flash news';

                              return EmptyList(
                                icon: FeatureIcons.selfArticles,
                                description:
                                    'No $type on this tag have been found',
                              );
                            }),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding / 2,
                            ),
                            sliver: SliverList.separated(
                              separatorBuilder: (context, index) => SizedBox(
                                height: kDefaultPadding / 2,
                              ),
                              itemBuilder: (context, index) {
                                if (state.tagType == TagType.article) {
                                  final article = state.articles[index];

                                  return ArticleContainer(
                                    isFollowing: state.followings
                                        .contains(article.pubkey),
                                    isProfileAccessible: true,
                                    article: article,
                                    highlightedTag: tag,
                                    userStatus: state.userStatus,
                                    isBookmarked: state.bookmarks
                                        .contains(article.identifier),
                                    onClicked: () {
                                      Navigator.pushNamed(
                                        context,
                                        ArticleView.routeName,
                                        arguments: article,
                                      );
                                    },
                                  );
                                } else if (state.tagType == TagType.flashnews) {
                                  final flashNews = state.flashNews[index];

                                  return HomeFlashNewsContainer(
                                    userStatus: state.userStatus,
                                    isFollowing: state.followings
                                        .contains(flashNews.pubkey),
                                    mainFlashNews:
                                        MainFlashNews(flashNews: flashNews),
                                    selectedTag: tag,
                                    flashNewsType: FlashNewsType.public,
                                    isMuted:
                                        state.mutes.contains(flashNews.pubkey),
                                    isBookmarked:
                                        state.bookmarks.contains(flashNews.id),
                                    onClicked: () {
                                      Navigator.pushNamed(
                                        context,
                                        FlashNewsDetailsView.routeName,
                                        arguments: [
                                          MainFlashNews(flashNews: flashNews),
                                          true
                                        ],
                                      );
                                    },
                                  );
                                } else if (state.tagType == TagType.video) {
                                  final video = state.videos[index];

                                  return VideoCommonContainer(
                                    isBookmarked: state.bookmarks
                                        .contains(video.identifier),
                                    isMuted: state.mutes.contains(video.pubkey),
                                    isFollowing:
                                        state.followings.contains(video.pubkey),
                                    selectedTag: tag,
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
                                  final note = state.notes[index];

                                  return NoteContainer(note: note);
                                }
                              },
                              itemCount: state.tagType == TagType.article
                                  ? state.articles.length
                                  : state.tagType == TagType.flashnews
                                      ? state.flashNews.length
                                      : state.tagType == TagType.notes
                                          ? state.notes.length
                                          : state.videos.length,
                            ),
                          );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: kDefaultPadding,
            ),
          ),
        ],
      ),
    );
  }
}

class TagHeader extends StatelessWidget {
  const TagHeader({
    super.key,
    required this.tag,
  });

  final String tag;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TagCubit, TagState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          child: SizedBox(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: kDefaultPadding,
                    right: kDefaultPadding,
                    top: kDefaultPadding,
                  ),
                  child: Text(
                    '#$tag',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (state.userStatus == UserStatus.UsingPrivKey) ...[
                  TextButton(
                    onPressed: () {
                      context.read<TagCubit>().setCustomTags();
                    },
                    child: Text(
                      state.isSubscribed ? 'unsubscribe' : 'subscribe',
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1,
                            color: state.isSubscribed ? kOrange : kGreen,
                          ),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity:
                          VisualDensity(vertical: -4, horizontal: -4),
                      padding: EdgeInsets.zero,
                      backgroundColor: kTransparent,
                    ),
                  ),
                  SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final type = state.tagType == TagType.article
                              ? 'Articles'
                              : state.tagType == TagType.video
                                  ? 'Videos'
                                  : state.tagType == TagType.notes
                                      ? 'Notes'
                                      : 'Flash news';

                          final count = state.tagType == TagType.article
                              ? state.articles.length
                              : state.tagType == TagType.video
                                  ? state.videos.length
                                  : state.tagType == TagType.notes
                                      ? state.notes.length
                                      : state.flashNews.length;

                          return Text(
                            '$type - ${count.toString().padLeft(2, '0')}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                          );
                        },
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
                        return [
                          PullDownMenuItem.selectable(
                            onTap: () {
                              context
                                  .read<TagCubit>()
                                  .setSelection(TagType.article);
                            },
                            selected: state.tagType == TagType.article,
                            title: 'Articles',
                            itemTheme: PullDownMenuItemTheme(
                              textStyle:
                                  Theme.of(context).textTheme.labelMedium!,
                            ),
                          ),
                          PullDownMenuItem.selectable(
                            onTap: () {
                              context
                                  .read<TagCubit>()
                                  .setSelection(TagType.flashnews);
                            },
                            selected: state.tagType == TagType.flashnews,
                            title: 'Flash news',
                            itemTheme: PullDownMenuItemTheme(
                              textStyle:
                                  Theme.of(context).textTheme.labelMedium!,
                            ),
                          ),
                          PullDownMenuItem.selectable(
                            onTap: () {
                              context
                                  .read<TagCubit>()
                                  .setSelection(TagType.video);
                            },
                            selected: state.tagType == TagType.video,
                            title: 'Videos',
                            itemTheme: PullDownMenuItemTheme(
                              textStyle:
                                  Theme.of(context).textTheme.labelMedium!,
                            ),
                          ),
                          PullDownMenuItem.selectable(
                            onTap: () {
                              context
                                  .read<TagCubit>()
                                  .setSelection(TagType.notes);
                            },
                            selected: state.tagType == TagType.notes,
                            title: 'Notes',
                            itemTheme: PullDownMenuItemTheme(
                              textStyle:
                                  Theme.of(context).textTheme.labelMedium!,
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
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
