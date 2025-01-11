// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:numeral/numeral.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/uncensored_notes_cubit/uncensored_notes_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/rewards_view/rewards_view.dart';
import 'package:yakihonne/views/search_view/search_view.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/un_flashnews_container.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/un_flashnews_details.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/uncensored_note_explanation.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/classic_footer.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';

class UncensoredNotesView extends StatelessWidget {
  const UncensoredNotesView({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UncensoredNotesCubit(),
      lazy: false,
      child: DefaultTabController(
        length: 3,
        child: Stack(
          children: [
            NestedScrollView(
              controller: scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: CommunityWalletContainer(
                      isMainView: getUserStatus() == UserStatus.UsingPrivKey,
                      onClicked: () {
                        Navigator.pushNamed(
                          context,
                          RewardsView.routeName,
                          arguments: context.read<UncensoredNotesCubit>(),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                  ),
                  SliverAppBar(
                    pinned: true,
                    automaticallyImplyLeading: false,
                    leadingWidth: 0,
                    elevation: 5,
                    toolbarHeight: 50,
                    floating: true,
                    actions: [
                      VerticalDivider(
                        indent: kDefaultPadding / 2,
                        endIndent: kDefaultPadding / 2,
                        width: 0,
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            UncensoredNoteExplanation.routeName,
                          );
                        },
                        icon: Icon(
                          CupertinoIcons.info_circle,
                          size: 20,
                        ),
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                    ],
                    centerTitle: true,
                    titleSpacing: kDefaultPadding / 2,
                    title: Align(
                      alignment: Alignment.centerLeft,
                      child: ScrollShadow(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: TabBar(
                          labelStyle:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                          tabAlignment: TabAlignment.start,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Theme.of(context).primaryColorLight,
                          isScrollable: true,
                          indicatorPadding: EdgeInsets.zero,
                          onTap: (index) {
                            context
                                .read<UncensoredNotesCubit>()
                                .setIndex(index);
                          },
                          tabs: [
                            Tab(
                              child: Text(
                                'New',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                            Tab(
                              child: Text(
                                'Needs your help',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                            Tab(
                              child: Text(
                                'Rated helpful',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: UnList(),
            ),
            ResetScrollButton(
              scrollController: scrollController,
              isLeft: true,
              padding: kDefaultPadding,
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityWalletContainer extends StatelessWidget {
  const CommunityWalletContainer({
    Key? key,
    required this.isMainView,
    required this.onClicked,
  }) : super(key: key);

  final bool isMainView;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: kDefaultPadding / 2,
        right: kDefaultPadding / 2,
        top: kDefaultPadding / 2,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding),
          color: Theme.of(context).primaryColorLight,
        ),
        child: Stack(
          children: [
            Positioned(
              left: -20,
              child: Transform.rotate(
                angle: 0.7,
                child: SvgPicture.asset(
                  FeatureIcons.reward,
                  width: 100,
                  height: 100,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark.withValues(alpha: 0.15),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community wallet',
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                        ),
                        BlocBuilder<UncensoredNotesCubit, UncensoredNotesState>(
                          builder: (context, state) {
                            return RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '${Numeral(state.balance).toString()}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                          color: kOrange,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  TextSpan(
                                    text: ' Sats.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(
                                          color: Theme.of(context)
                                              .primaryColorDark,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  CustomIconButton(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    icon:
                        isMainView ? FeatureIcons.reward : FeatureIcons.refresh,
                    onClicked: onClicked,
                    size: 22,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UnList extends StatefulWidget {
  const UnList({
    Key? key,
  }) : super(key: key);

  @override
  State<UnList> createState() => _UnListState();
}

class _UnListState extends State<UnList> {
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
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return BlocConsumer<UncensoredNotesCubit, UncensoredNotesState>(
      listener: (context, state) {
        if (state.addingFlashNewsStatus == UpdatingState.success) {
          refreshController.loadComplete();
        } else if (state.addingFlashNewsStatus == UpdatingState.idle) {
          refreshController.loadNoData();
        }
      },
      builder: (context, state) {
        if (state.loading) {
          return SearchLoading();
        } else if (state.unNewFlashNews.isEmpty) {
          return EmptyList(
            description: 'No flash news can found.',
            icon: FeatureIcons.flashNews,
          );
        } else {
          Widget child;

          if (isMobile) {
            child = ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
                vertical: kDefaultPadding,
              ),
              itemBuilder: (context, index) {
                final unFlashNews = state.unNewFlashNews[index];

                return UnFlashNewsContainer(
                  unNewFlashNews: unFlashNews,
                  isBookmarked:
                      state.bookmarks.contains(unFlashNews.flashNews.id),
                  onRefresh: () {
                    context.read<UncensoredNotesCubit>().setIndex(state.index);
                  },
                  onClicked: () {
                    Navigator.pushNamed(
                      context,
                      UnFlashNewsDetails.routeName,
                      arguments: unFlashNews,
                    );
                  },
                  userStatus: state.userStatus,
                );
              },
              separatorBuilder: (context, index) => SizedBox(
                height: kDefaultPadding / 2,
              ),
              itemCount: state.unNewFlashNews.length,
            );
          } else {
            child = MasonryGridView.builder(
              gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              mainAxisSpacing: kDefaultPadding / 2,
              crossAxisSpacing: kDefaultPadding / 2,
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
                vertical: kDefaultPadding,
              ),
              itemBuilder: (context, index) {
                final unFlashNews = state.unNewFlashNews[index];

                return UnFlashNewsContainer(
                  unNewFlashNews: unFlashNews,
                  isBookmarked:
                      state.bookmarks.contains(unFlashNews.flashNews.id),
                  onRefresh: () {
                    context.read<UncensoredNotesCubit>().setIndex(state.index);
                  },
                  onClicked: () {
                    Navigator.pushNamed(
                      context,
                      UnFlashNewsDetails.routeName,
                      arguments: unFlashNews,
                    );
                  },
                  userStatus: state.userStatus,
                );
              },
              itemCount: state.unNewFlashNews.length,
            );
          }

          return SmartRefresher(
            controller: refreshController,
            enablePullDown: false,
            enablePullUp: true,
            header: const MaterialClassicHeader(
              color: kPurple,
            ),
            footer: const RefresherClassicFooter(),
            onLoading: () =>
                context.read<UncensoredNotesCubit>().addMoreUnFlashnews(),
            onRefresh: () => onRefresh(
              onInit: () => context.read<UncensoredNotesCubit>().setIndex(
                    state.index,
                  ),
            ),
            child: child,
          );
        }
      },
    );
  }
}
