// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/articles_cubit/articles_cubit.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/article_view/article_view.dart';
import 'package:yakihonne/views/widgets/article_container.dart';
import 'package:yakihonne/views/widgets/classic_footer.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/place_holders.dart';

class ArticlesView extends StatefulWidget {
  const ArticlesView({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  State<ArticlesView> createState() => _ArticlesViewState();
}

class _ArticlesViewState extends State<ArticlesView> {
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
    return BlocProvider(
      create: (context) => ArticlesCubit(),
      child: BlocConsumer<ArticlesCubit, ArticlesState>(
        listener: (context, state) {
          if (state.loadingState == UpdatingState.success) {
            refreshController.loadComplete();
          } else if (state.loadingState == UpdatingState.idle) {
            refreshController.loadNoData();
          }
        },
        builder: (context, state) {
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                ArticlesViewHeader(),
              ];
            },
            body: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
                ? getTabletArticles(state, context)
                : getMobileArticles(state, context),
          );
        },
      ),
    );
  }

  Widget getTabletArticles(ArticlesState state, BuildContext context) {
    return state.isLoading
        ? ListView(
            children: [
              SkeletonSelector(
                placeHolderWidget: ArticleSkeleton(),
              ),
            ],
          )
        : state.articles.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: kDefaultPadding,
                ),
                child: Column(
                  children: [
                    Text(
                      'No articles can been found',
                    ),
                  ],
                ),
              )
            : BlocBuilder<ArticlesCubit, ArticlesState>(
                buildWhen: (previous, current) =>
                    previous.articles != current.articles ||
                    previous.followings != current.followings ||
                    previous.bookmarks != current.bookmarks ||
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
                        context.read<ArticlesCubit>().getArticles(isAdd: true),
                    onRefresh: () => onRefresh(
                      onInit: () => context.read<ArticlesCubit>().getArticles(
                            isAdd: false,
                            relay: '',
                          ),
                    ),
                    child: MasonryGridView.count(
                      crossAxisCount: 2,
                      itemCount: state.articles.length,
                      crossAxisSpacing: kDefaultPadding / 2,
                      mainAxisSpacing: kDefaultPadding / 2,
                      padding: const EdgeInsets.all(kDefaultPadding / 2),
                      itemBuilder: (context, index) {
                        final item = state.articles[index];

                        return getItem(item);
                      },
                    ),
                  );
                },
              );
  }

  Widget getMobileArticles(ArticlesState state, BuildContext context) {
    Widget list = SmartRefresher(
      controller: refreshController,
      enablePullDown: true,
      enablePullUp: true,
      header: const MaterialClassicHeader(
        color: kPurple,
      ),
      footer: const RefresherClassicFooter(),
      onLoading: () => context.read<ArticlesCubit>().getArticles(isAdd: true),
      onRefresh: () => onRefresh(
        onInit: () => context.read<ArticlesCubit>().getArticles(
              isAdd: false,
              relay: '',
            ),
      ),
      child: CustomScrollView(
        slivers: [
          BlocBuilder<ArticlesCubit, ArticlesState>(
            buildWhen: (previous, current) =>
                previous.articles != current.articles ||
                previous.followings != current.followings ||
                previous.bookmarks != current.bookmarks ||
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
                  itemCount: state.articles.length,
                  separatorBuilder: (context, index) => const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  itemBuilder: (context, index) {
                    final item = state.articles[index];

                    return getItem(item);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );

    return state.isLoading
        ? ListView(
            children: [
              SkeletonSelector(placeHolderWidget: ArticleSkeleton()),
            ],
          )
        : state.articles.isEmpty
            ? EmptyList(
                description: 'No articles have been found',
                icon: FeatureIcons.selfArticles,
              )
            : list;
  }

  Widget getItem(Article article) {
    return BlocBuilder<ArticlesCubit, ArticlesState>(
      builder: (context, state) {
        return ArticleContainer(
          article: article,
          isProfileAccessible: true,
          highlightedTag: '',
          padding: 0,
          margin: 0,
          isMuted: state.mutes.contains(article.pubkey),
          isBookmarked: state.bookmarks.contains(article.identifier),
          userStatus: getUserStatus(),
          onClicked: () {
            Navigator.pushNamed(
              context,
              ArticleView.routeName,
              arguments: article,
            );
          },
          isFollowing: state.followings.contains(article.pubkey),
        );
      },
    );
  }
}

class ArticlesViewHeader extends StatelessWidget {
  const ArticlesViewHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArticlesCubit, ArticlesState>(
      builder: (context, state) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.articles.length.toString().padLeft(2, '0')} Articles',
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      Text(
                        '(In ${state.selectedRelay.isEmpty ? 'all relays' : state.selectedRelay.split('wss://')[1]})',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
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
                    backgroundColor: Theme.of(context).primaryColorLight,
                  ),
                  itemBuilder: (context) {
                    final activeRelays =
                        NostrConnect.sharedInstance.activeRelays();

                    return [
                      PullDownMenuItem.selectable(
                        onTap: () {
                          context.read<ArticlesCubit>().getArticles(
                                isAdd: false,
                                relay: '',
                              );
                        },
                        selected: state.selectedRelay.isEmpty,
                        title: 'All relays',
                        itemTheme: PullDownMenuItemTheme(
                          textStyle:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    fontWeight: state.selectedRelay.isEmpty
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                        ),
                      ),
                      ...state.relays
                          .map(
                            (e) => PullDownMenuItem.selectable(
                              onTap: () {
                                context.read<ArticlesCubit>().getArticles(
                                      isAdd: false,
                                      relay: e,
                                    );
                              },
                              selected: e == state.selectedRelay,
                              title: e.split('wss://')[1],
                              iconColor:
                                  activeRelays.contains(e) ? kGreen : kRed,
                              iconWidget: Icon(
                                CupertinoIcons.circle_fill,
                                size: 7,
                              ),
                              itemTheme: PullDownMenuItemTheme(
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(
                                      fontWeight: state.selectedRelay == e
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
                      backgroundColor: Theme.of(context).primaryColorLight,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
