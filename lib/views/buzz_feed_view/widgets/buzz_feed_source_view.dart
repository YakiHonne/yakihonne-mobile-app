// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/buzz_feed_source_cubit/buzz_feed_source_cubit.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_container.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_details.dart';
import 'package:yakihonne/views/search_view/search_view.dart';
import 'package:yakihonne/views/widgets/classic_footer.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class BuzzFeedSourceView extends StatefulWidget {
  const BuzzFeedSourceView({
    Key? key,
    required this.buzzFeedSource,
  }) : super(key: key);

  static const routeName = '/buzzFeedSourceView';
  static Route route(RouteSettings settings) {
    final buzzFeedModel = settings.arguments as BuzzFeedSource;

    return CupertinoPageRoute(
      builder: (_) => BuzzFeedSourceView(
        buzzFeedSource: buzzFeedModel,
      ),
    );
  }

  final BuzzFeedSource buzzFeedSource;

  @override
  State<BuzzFeedSourceView> createState() => _BuzzFeedSourceViewState();
}

class _BuzzFeedSourceViewState extends State<BuzzFeedSourceView> {
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
      create: (context) =>
          BuzzFeedSourceCubit(buzzFeedSource: widget.buzzFeedSource)
            ..getBuzzFeed(),
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: kToolbarHeight + 80,
                pinned: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                stretch: true,
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
                  if (getUserStatus() == UserStatus.UsingPrivKey) ...[
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    ),
                    BlocBuilder<BuzzFeedSourceCubit, BuzzFeedSourceState>(
                      builder: (context, state) {
                        return TextButton(
                          onPressed: () {
                            NostrFunctionsRepository.setCustomTopics(
                              widget.buzzFeedSource.name,
                            );
                          },
                          child: Text(
                            state.isSubscribed ? 'unsubscribe' : 'subscribe',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  color: state.isSubscribed ? kOrange : kGreen,
                                ),
                          ),
                          style: TextButton.styleFrom(
                            visualDensity:
                                VisualDensity(vertical: -2, horizontal: -2),
                            backgroundColor: Theme.of(context)
                                .primaryColorLight
                                .withValues(alpha: 0.7),
                          ),
                        );
                      },
                    ),
                  ],
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
                            builder: (context, constraints) => Container(
                              height: constraints.maxHeight,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xffad5389),
                                    Color(0xff3c1053),
                                  ],
                                ),
                              ),
                              foregroundDecoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).scaffoldBackgroundColor,
                                    kTransparent,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  stops: [0.2, 1],
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: kDefaultPadding / 2,
                                ),
                                child: ProfilePicture2(
                                  size: 90,
                                  image: widget.buzzFeedSource.icon,
                                  placeHolder: '',
                                  padding: 0,
                                  strokeWidth: 3,
                                  strokeColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  onClicked: () {},
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: kDefaultPadding),
                    Text(
                      widget.buzzFeedSource.name,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    linkifiedText(
                      context: context,
                      text: widget.buzzFeedSource.url,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(
                        kDefaultPadding / 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Available news: ',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          BlocBuilder<BuzzFeedSourceCubit, BuzzFeedSourceState>(
                            builder: (context, state) {
                              return Text(
                                state.buzzFeed.length.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: kOrange),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ],
                ),
              ),
            ];
          },
          body: BlocConsumer<BuzzFeedSourceCubit, BuzzFeedSourceState>(
            listener: (context, state) {
              if (state.loadMoreFeed == UpdatingState.success) {
                refreshController.loadComplete();
              } else if (state.loadMoreFeed == UpdatingState.idle) {
                refreshController.loadNoData();
              }
            },
            builder: (context, state) {
              if (state.isBuzzFeedLoading) {
                return SearchLoading();
              } else if (state.buzzFeed.isEmpty) {
                return EmptyList(
                  description: 'No news can be found.',
                  icon: FeatureIcons.flashNews,
                );
              } else {
                return SmartRefresher(
                  controller: refreshController,
                  enablePullDown: false,
                  enablePullUp: true,
                  header: const MaterialClassicHeader(
                    color: kPurple,
                  ),
                  footer: const RefresherClassicFooter(),
                  onLoading: () =>
                      context.read<BuzzFeedSourceCubit>().getMoreBuzzFeed(),
                  onRefresh: () => onRefresh(
                    onInit: () =>
                        context.read<BuzzFeedSourceCubit>().getBuzzFeed(),
                  ),
                  child: isTablet
                      ? MasonryGridView.count(
                          crossAxisCount: isTablet ? 4 : 2,
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
                              isBookmarked:
                                  state.bookmarks.contains(buzzFeed.id),
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
                          ),
                          itemBuilder: (context, index) {
                            final buzzFeed = state.buzzFeed[index];

                            return BuzzFeedContainer(
                              buzzFeedModel: buzzFeed,
                              isBookmarked:
                                  state.bookmarks.contains(buzzFeed.id),
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
                          separatorBuilder: (context, index) => const SizedBox(
                            height: kDefaultPadding / 2,
                          ),
                          itemCount: state.buzzFeed.length,
                        ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
