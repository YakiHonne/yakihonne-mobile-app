// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/buzz_feed_cubit/buzz_feed_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_container.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_details.dart';
import 'package:yakihonne/views/search_view/search_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/classic_footer.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';

class BuzzFeedView extends StatefulWidget {
  const BuzzFeedView({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  State<BuzzFeedView> createState() => _BuzzFeedViewState();
}

class _BuzzFeedViewState extends State<BuzzFeedView> {
  final refreshController = RefreshController();
  bool isGrouped = false;

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

    return BlocProvider(
      create: (context) => BuzzFeedCubit()..getBuzzFeed(index: 0),
      lazy: false,
      child: BlocConsumer<BuzzFeedCubit, BuzzFeedState>(
        listener: (context, state) {
          if (state.loadMoreFeed == UpdatingState.success) {
            refreshController.loadComplete();
          } else if (state.loadMoreFeed == UpdatingState.idle) {
            refreshController.loadNoData();
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      pinned: true,
                      automaticallyImplyLeading: false,
                      leadingWidth: 0,
                      toolbarHeight: 45,
                      actions: [const SizedBox.shrink()],
                      elevation: 0,
                      centerTitle: true,
                      titleSpacing: 0,
                      title: SourcesList(),
                    ),
                  ];
                },
                body: state.isBuzzFeedLoading
                    ? SearchLoading()
                    : state.buzzFeed.isEmpty
                        ? EmptyList(
                            description: 'No news can be found.',
                            icon: FeatureIcons.flashNews,
                          )
                        : SmartRefresher(
                            controller: refreshController,
                            enablePullDown: false,
                            enablePullUp: true,
                            header: const MaterialClassicHeader(
                              color: kPurple,
                            ),
                            footer: const RefresherClassicFooter(),
                            onLoading: () =>
                                context.read<BuzzFeedCubit>().getMoreBuzzFeed(),
                            onRefresh: () => onRefresh(
                              onInit: () => context
                                  .read<BuzzFeedCubit>()
                                  .getBuzzFeed(index: state.index),
                            ),
                            child: isTablet
                                ? MasonryGridView.count(
                                    crossAxisCount: 2,
                                    itemCount: state.buzzFeed.length,
                                    crossAxisSpacing: kDefaultPadding / 2,
                                    mainAxisSpacing: kDefaultPadding / 2,
                                    padding: const EdgeInsets.all(
                                      kDefaultPadding / 2,
                                    ),
                                    itemBuilder: (context, index) {
                                      final buzzFeed = state.buzzFeed[index];

                                      return BuzzFeedContainer(
                                        buzzFeedModel: buzzFeed,
                                        isBookmarked: state.bookmarks
                                            .contains(buzzFeed.id),
                                        onClicked: () {
                                          Navigator.pushNamed(
                                            context,
                                            BuzzFeedDetails.routeName,
                                            arguments: buzzFeed,
                                          );
                                        },
                                        onExternalShare: () {
                                          openWebPage(url: buzzFeed.sourceUrl);
                                        },
                                      );
                                    },
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: kDefaultPadding / 2,
                                      vertical: kDefaultPadding / 2,
                                    ),
                                    itemBuilder: (context, index) {
                                      final buzzFeed = state.buzzFeed[index];

                                      return BuzzFeedContainer(
                                        buzzFeedModel: buzzFeed,
                                        isBookmarked: state.bookmarks
                                            .contains(buzzFeed.id),
                                        onClicked: () {
                                          Navigator.pushNamed(
                                            context,
                                            BuzzFeedDetails.routeName,
                                            arguments: buzzFeed,
                                          );
                                        },
                                        onExternalShare: () {
                                          openWebPage(
                                            url: buzzFeed.sourceUrl,
                                          );
                                        },
                                      );
                                    },
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(
                                      height: kDefaultPadding / 2,
                                    ),
                                    itemCount: state.buzzFeed.length,
                                  ),
                          ),
              ),
              ResetScrollButton(
                scrollController: widget.scrollController,
                isLeft: true,
                padding: kDefaultPadding,
              ),
            ],
          );
        },
      ),
    );
  }
}

class SourcesList extends StatefulWidget {
  @override
  State<SourcesList> createState() => _SourcesListState();
}

class _SourcesListState extends State<SourcesList>
    with TickerProviderStateMixin {
  late TabController tabController;
  int index = 0;

  @override
  void initState() {
    tabController = TabController(
      length: context.read<BuzzFeedCubit>().state.buzzFeedSources.length + 1,
      vsync: this,
    );
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BuzzFeedCubit, BuzzFeedState>(
      listenWhen: (previous, current) =>
          previous.buzzFeedSources != current.buzzFeedSources,
      listener: (context, state) {
        if (state.buzzFeedSources.isNotEmpty) {
          final tempController = tabController;

          tabController = TabController(
            length: state.buzzFeedSources.length + 1,
            vsync: this,
          );

          tempController.dispose();
        }
      },
      builder: (context, state) {
        return Row(
          children: [
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available news',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${state.buzzFeed.length.toString()} news',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium!
                        .copyWith(fontWeight: FontWeight.w700),
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
                return [
                  PullDownMenuItem.selectable(
                    onTap: () {
                      context.read<BuzzFeedCubit>().getBuzzFeed(
                            index: 0,
                          );

                      index = 0;
                    },
                    selected: index == 0,
                    title: 'All',
                    iconWidget: SvgPicture.asset(
                      FeatureIcons.buzzFeed,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).primaryColorDark,
                        BlendMode.srcIn,
                      ),
                    ),
                    itemTheme: PullDownMenuItemTheme(
                      textStyle: Theme.of(context).textTheme.labelMedium!,
                    ),
                  ),
                  ...state.buzzFeedSources
                      .map(
                        (e) => PullDownMenuItem.selectable(
                          onTap: () {
                            final selectedIndex =
                                state.buzzFeedSources.indexOf(e) + 1;

                            context.read<BuzzFeedCubit>().getBuzzFeed(
                                  index: selectedIndex,
                                );

                            index = selectedIndex;
                          },
                          selected:
                              state.buzzFeedSources.indexOf(e) + 1 == index,
                          title: e.name,
                          iconWidget: CachedNetworkImage(
                            imageUrl: e.icon,
                            width: 20,
                            height: 20,
                            imageBuilder: (context, imageProvider) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(image: imageProvider),
                                ),
                              );
                            },
                            errorWidget: (context, url, error) => Image.asset(
                              Images.defaultTopicIcon,
                            ),
                          ),
                          itemTheme: PullDownMenuItemTheme(
                            textStyle: Theme.of(context).textTheme.labelMedium!,
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
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
          ],
        );
      },
    );
  }
}
