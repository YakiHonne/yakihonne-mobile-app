// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/home_cubit/home_cubit.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/article_view/article_view.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_container.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_details.dart';
import 'package:yakihonne/views/flash_news_details_view/flash_news_details_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/vertical_video_view.dart';
import 'package:yakihonne/views/widgets/article_container.dart';
import 'package:yakihonne/views/widgets/classic_footer.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/flash_news_container.dart';
import 'package:yakihonne/views/widgets/place_holders.dart';
import 'package:yakihonne/views/widgets/video_common_container.dart';

class HomeContentListView extends StatefulWidget {
  const HomeContentListView({super.key});

  @override
  State<HomeContentListView> createState() => _HomeContentListViewState();
}

class _HomeContentListViewState extends State<HomeContentListView> {
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
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state.relaysAddingData == UpdatingState.success) {
          refreshController.loadComplete();
        } else if (state.relaysAddingData == UpdatingState.idle) {
          refreshController.loadNoData();
        }
      },
      buildWhen: (previous, current) =>
          previous.isRelaysLoading != current.isRelaysLoading,
      builder: (context, state) {
        return Scrollbar(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
                ? getTabletArticles(state)
                : getMobileArticles(state),
          ),
        );
      },
    );
  }

  Widget getTabletArticles(HomeState state) {
    return state.isRelaysLoading
        ? ListView(
            children: [
              SkeletonSelector(
                placeHolderWidget: ArticleSkeleton(),
              ),
            ],
          )
        : state.content.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: kDefaultPadding,
                ),
                child: Column(
                  children: [
                    Text(
                      'No content can been found',
                    ),
                  ],
                ),
              )
            : BlocBuilder<HomeCubit, HomeState>(
                buildWhen: (previous, current) =>
                    previous.followings != current.followings ||
                    previous.content != current.content ||
                    previous.rebuildRelays != current.rebuildRelays ||
                    previous.bookmarks != current.bookmarks ||
                    previous.loadingBookmarks != current.loadingBookmarks ||
                    previous.mutes != current.mutes,
                builder: (context, state) {
                  return SmartRefresher(
                    controller: refreshController,
                    enablePullDown: false,
                    enablePullUp: true,
                    header: const MaterialClassicHeader(
                      color: kPurple,
                    ),
                    footer: const RefresherClassicFooter(),
                    onLoading: () =>
                        context.read<HomeCubit>().getMoreTopicContent(),
                    onRefresh: () => onRefresh(
                      onInit: () => context.read<HomeCubit>().getTopicContent(
                            null,
                            null,
                          ),
                    ),
                    child: MasonryGridView.count(
                      crossAxisCount: 2,
                      itemCount: state.content.length,
                      crossAxisSpacing: kDefaultPadding / 2,
                      mainAxisSpacing: kDefaultPadding / 2,
                      padding: const EdgeInsets.all(kDefaultPadding),
                      itemBuilder: (context, index) {
                        final item = state.content[index];

                        return getItem(item);
                      },
                    ),
                  );
                },
              );
  }

  Widget getMobileArticles(HomeState state) {
    Widget list = SmartRefresher(
      controller: refreshController,
      enablePullDown: true,
      enablePullUp: true,
      header: const MaterialClassicHeader(
        color: kPurple,
      ),
      footer: const RefresherClassicFooter(),
      onLoading: () => context.read<HomeCubit>().getMoreTopicContent(),
      onRefresh: () => onRefresh(
        onInit: () => context.read<HomeCubit>().getTopicContent(null, null),
      ),
      child: CustomScrollView(
        slivers: [
          BlocBuilder<HomeCubit, HomeState>(
            buildWhen: (previous, current) =>
                previous.followings != current.followings ||
                previous.content != current.content ||
                previous.rebuildRelays != current.rebuildRelays ||
                previous.bookmarks != current.bookmarks ||
                previous.loadingBookmarks != current.loadingBookmarks ||
                previous.mutes != current.mutes,
            builder: (context, state) {
              return SliverPadding(
                padding: const EdgeInsets.only(
                  bottom: kDefaultPadding,
                  top: kDefaultPadding / 2,
                  left: kDefaultPadding / 2,
                  right: kDefaultPadding / 2,
                ),
                sliver: SliverList.separated(
                  itemCount: state.content.length,
                  separatorBuilder: (context, index) => const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  itemBuilder: (context, index) {
                    final item = state.content[index];

                    return getItem(item);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );

    return state.isRelaysLoading
        ? ListView(
            children: [
              SkeletonSelector(placeHolderWidget: ArticleSkeleton()),
            ],
          )
        : state.content.isEmpty
            ? EmptyList(
                description: 'No content have been found',
                icon: FeatureIcons.selfArticles,
              )
            : list;
  }

  Widget getItem(CreatedAtTag item) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (item is Article) {
          return ArticleContainer(
            article: item,
            isProfileAccessible: true,
            highlightedTag: '',
            padding: 0,
            margin: 0,
            isMuted: state.mutes.contains(item.pubkey),
            isBookmarked: state.bookmarks.contains(item.identifier),
            userStatus: state.userStatus,
            onClicked: () {
              Navigator.pushNamed(
                context,
                ArticleView.routeName,
                arguments: item,
              );
            },
            isFollowing: state.followings.contains(item.pubkey),
          );
        } else if (item is BuzzFeedModel) {
          return BuzzFeedContainer(
            buzzFeedModel: item,
            isBookmarked: state.bookmarks.contains(item.id),
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
        } else if (item is FlashNews) {
          return HomeFlashNewsContainer(
            userStatus: state.userStatus,
            isFollowing: state.followings.contains(item.pubkey),
            isMuted: state.mutes.contains(item.pubkey),
            mainFlashNews: MainFlashNews(flashNews: item),
            flashNewsType: FlashNewsType.public,
            trySearch: false,
            isBookmarked: state.bookmarks.contains(item.id),
            onClicked: () {
              Navigator.pushNamed(
                context,
                FlashNewsDetailsView.routeName,
                arguments: [MainFlashNews(flashNews: item), true],
              );
            },
          );
        } else if (item is VideoModel) {
          final video = item;

          return VideoCommonContainer(
            isBookmarked: state.bookmarks.contains(item.identifier),
            video: video,
            isMuted: state.mutes.contains(item.pubkey),
            isFollowing: state.followings.contains(item.pubkey),
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
    );
  }
}
