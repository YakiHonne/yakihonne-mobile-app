// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:yakihonne/blocs/home_cubit/home_cubit.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/topic.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/home_view/widgets/flash_news_page_view.dart';
import 'package:yakihonne/views/home_view/widgets/home_content_List_view.dart';
import 'package:yakihonne/views/home_view/widgets/topics_view.dart';

class HomeView extends StatelessWidget {
  HomeView({
    Key? key,
    required this.scrollController,
  }) : super(key: key) {
    FirebaseAnalytics.instance.setCurrentScreen(screenName: 'Home screen');
  }

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(
        nostrRepository: context.read<NostrDataRepository>(),
        localDatabaseRepository: context.read<LocalDatabaseRepository>(),
        buildContext: context,
      ),
      lazy: false,
      child: Builder(
        builder: (context) {
          return NestedHomeView(
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

class NestedHomeView extends HookWidget {
  final ScrollController scrollController;

  NestedHomeView({
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isToggled = useState(false);

    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) =>
          previous.userTopics != current.userTopics ||
          previous.userStatus != current.userStatus,
      builder: (context, state) {
        return DefaultTabController(
          length: state.userTopics.length + 3,
          child: NestedScrollView(
            controller: scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kDefaultPadding / 1.5,
                          vertical: kDefaultPadding / 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Important flash news',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            TransparentTextButtonWithIcon(
                              onClicked: () {
                                context.read<MainCubit>().updateIndex(9);
                              },
                              text: 'see all',
                            ),
                          ],
                        ),
                      ),
                      FlashNewsPageView(),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                    ),
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                      color: Theme.of(context).primaryColorLight,
                      image: DecorationImage(
                        image: AssetImage(Images.banner),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          kDimBgGrey.withValues(
                            alpha: 0.7,
                          ),
                          BlendMode.srcATop,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: FastAccessButton(
                            icon: FeatureIcons.selfArticles,
                            onClicked: () {
                              context.read<MainCubit>().updateIndex(16);
                            },
                            title: 'Articles\nfeed',
                          ),
                        ),
                        Expanded(
                          child: FastAccessButton(
                            icon: FeatureIcons.flashNews,
                            onClicked: () {
                              context.read<MainCubit>().updateIndex(9);
                            },
                            title: 'Flash\nnews',
                          ),
                        ),
                        Expanded(
                          child: FastAccessButton(
                            icon: FeatureIcons.uncensoredNote,
                            onClicked: () {
                              context.read<MainCubit>().updateIndex(11);
                            },
                            title: 'Uncensored\nnotes',
                          ),
                        ),
                        Expanded(
                          child: FastAccessButton(
                            icon: FeatureIcons.curations,
                            onClicked: () {
                              context.read<MainCubit>().updateIndex(1);
                            },
                            title: 'Curations\nfeed',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: kDefaultPadding / 1.5,
                  ),
                ),
                SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                  leadingWidth: 0,
                  toolbarHeight: 45,
                  actions: [const SizedBox.shrink()],
                  elevation: 0,
                  centerTitle: true,
                  titleSpacing: kDefaultPadding / 2,
                  title: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: TopicsList(),
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(
                            milliseconds: 200,
                          ),
                          firstChild: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (state.userStatus == UserStatus.UsingPrivKey)
                                IconButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      TopicsView.routeName,
                                    );
                                  },
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity(
                                    horizontal: -4,
                                    vertical: -4,
                                  ),
                                  icon: Icon(Icons.add),
                                ),
                              BlocBuilder<HomeCubit, HomeState>(
                                builder: (context, state) {
                                  return PullDownButton(
                                    animationBuilder: (context, state, child) {
                                      return child;
                                    },
                                    routeTheme: PullDownMenuRouteTheme(
                                      backgroundColor:
                                          Theme.of(context).primaryColorLight,
                                    ),
                                    itemBuilder: (context) {
                                      final activeRelays = NostrConnect
                                          .sharedInstance
                                          .activeRelays();

                                      return [
                                        PullDownMenuItem.selectable(
                                          onTap: () {
                                            final hc =
                                                context.read<HomeCubit>();

                                            hc.getTopicContent(
                                              null,
                                              '',
                                            );
                                          },
                                          selected: state.chosenRelay.isEmpty,
                                          title: 'All relays',
                                          itemTheme: PullDownMenuItemTheme(
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .labelMedium!
                                                .copyWith(
                                                  fontWeight:
                                                      state.chosenRelay.isEmpty
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                ),
                                          ),
                                        ),
                                        ...state.relays
                                            .map(
                                              (e) =>
                                                  PullDownMenuItem.selectable(
                                                onTap: () {
                                                  context
                                                      .read<HomeCubit>()
                                                      .getTopicContent(
                                                        null,
                                                        e,
                                                      );
                                                },
                                                selected:
                                                    e == state.chosenRelay,
                                                title: e.split('wss://')[1],
                                                iconColor:
                                                    activeRelays.contains(e)
                                                        ? kGreen
                                                        : kRed,
                                                iconWidget: Icon(
                                                  CupertinoIcons.circle_fill,
                                                  size: 7,
                                                ),
                                                itemTheme:
                                                    PullDownMenuItemTheme(
                                                  textStyle: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium!
                                                      .copyWith(
                                                        fontWeight:
                                                            state.chosenRelay ==
                                                                    e
                                                                ? FontWeight
                                                                    .w500
                                                                : FontWeight
                                                                    .w400,
                                                      ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ];
                                    },
                                    buttonBuilder: (context, showMenu) =>
                                        IconButton(
                                      onPressed: showMenu,
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
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
                                  );
                                },
                              ),
                            ],
                          ),
                          secondChild: const SizedBox(
                            height: 30,
                            width: 0,
                          ),
                          crossFadeState: isToggled.value
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                        ),
                        IconButton(
                          onPressed: () {
                            isToggled.value = !isToggled.value;
                          },
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity(
                            horizontal: -4,
                            vertical: -4,
                          ),
                          icon: AnimatedRotation(
                            duration: const Duration(milliseconds: 200),
                            turns: isToggled.value ? 0.5 : 1,
                            child: SvgPicture.asset(
                              FeatureIcons.settings,
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
              ];
            },
            body: HomeContentListView(),
          ),
        );
      },
    );
  }
}

class FastAccessButton extends StatelessWidget {
  const FastAccessButton({
    Key? key,
    required this.icon,
    required this.title,
    required this.onClicked,
  }) : super(key: key);

  final String icon;
  final String title;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            icon,
            width: 23,
            height: 23,
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              kWhite,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: kWhite,
                  height: 1.3,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class TransparentTextButtonWithIcon extends StatelessWidget {
  const TransparentTextButtonWithIcon({
    Key? key,
    required this.onClicked,
    required this.text,
    this.iconWidget,
  }) : super(key: key);

  final Function() onClicked;
  final String text;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onClicked,
      style: TextButton.styleFrom(
        backgroundColor: kTransparent,
        padding: const EdgeInsets.symmetric(
          horizontal: 0,
        ),
        visualDensity: VisualDensity(
          horizontal: -4,
          vertical: -4,
        ),
      ),
      icon: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).primaryColorDark,
              height: 1,
            ),
      ),
      label: iconWidget ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: Theme.of(context).primaryColorDark,
          ),
    );
  }
}

class TransparentTextButton extends StatelessWidget {
  const TransparentTextButton({
    Key? key,
    required this.onClicked,
    required this.text,
    this.underlined,
  }) : super(key: key);

  final Function() onClicked;
  final String text;
  final bool? underlined;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onClicked,
      style: TextButton.styleFrom(
        backgroundColor: kTransparent,
        padding: const EdgeInsets.symmetric(
          horizontal: 0,
        ),
        visualDensity: VisualDensity(
          horizontal: -4,
          vertical: -4,
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).primaryColorDark,
              height: 1,
              decoration: underlined != null ? TextDecoration.underline : null,
            ),
      ),
    );
  }
}

class TopicsList extends StatefulWidget {
  const TopicsList();

  @override
  State<TopicsList> createState() => _TopicsListState();
}

class _TopicsListState extends State<TopicsList> with TickerProviderStateMixin {
  late TabController tabController;
  int index = 0;

  @override
  void initState() {
    tabController = TabController(
      length: context.read<HomeCubit>().state.userTopics.length + 2,
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
    return BlocConsumer<HomeCubit, HomeState>(
      listenWhen: (previous, current) =>
          previous.userTopics != current.userTopics ||
          previous.userStatus != current.userStatus,
      listener: (context, state) {
        if (state.userTopics.isNotEmpty ||
            (state.userTopics.isEmpty ||
                state.userStatus != UserStatus.UsingPrivKey)) {
          final tempController = tabController;

          tabController = TabController(
            length: state.userTopics.length + 2,
            vsync: this,
          );

          tempController.dispose();
          if (context.read<HomeCubit>().topicIndex != 0) {
            context.read<HomeCubit>().getTopicContent(0, null);
          }
        }
      },
      buildWhen: (previous, current) =>
          previous.userTopics != current.userTopics,
      builder: (context, state) {
        return ScrollShadow(
          color: Theme.of(context).scaffoldBackgroundColor,
          size: 10,
          child: FadeInDown(
            duration: const Duration(milliseconds: 200),
            child: ButtonsTabBar(
              controller: tabController,
              backgroundColor: Theme.of(context).primaryColorDark,
              unselectedBackgroundColor: Theme.of(context).primaryColorLight,
              unselectedLabelStyle: TextStyle(
                color: Theme.of(context).primaryColorDark,
              ),
              labelStyle: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              radius: 300,
              height: 40,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
                vertical: 0,
              ),
              onTap: (selectedIndex) {
                context.read<HomeCubit>().getTopicContent(selectedIndex, null);
                setState(
                  () {
                    index = selectedIndex;
                  },
                );
              },
              tabs: [
                Tab(
                  icon: SvgPicture.asset(
                    FeatureIcons.timeline,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      index == 0
                          ? Theme.of(context).primaryColorLight
                          : Theme.of(context).primaryColorDark,
                      BlendMode.srcIn,
                    ),
                  ),
                  text: 'Timeline',
                  height: 50,
                ),
                Tab(
                  icon: SvgPicture.asset(
                    FeatureIcons.followings,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      index == 1
                          ? Theme.of(context).primaryColorLight
                          : Theme.of(context).primaryColorDark,
                      BlendMode.srcIn,
                    ),
                  ),
                  text: 'Followings',
                  height: 50,
                ),
                ...state.userTopics.map(
                  (topic) {
                    final link = getIcon(topic);

                    return Tab(
                      icon: link.isEmpty
                          ? Image.asset(
                              Images.defaultTopicIcon,
                              width: 20,
                              height: 20,
                            )
                          : CachedNetworkImage(
                              imageUrl: link,
                              width: 20,
                              height: 20,
                              errorWidget: (context, url, error) => Image.asset(
                                Images.defaultTopicIcon,
                              ),
                            ),
                      text: topic,
                    );
                  },
                ).toList()
              ],
            ),
          ),
        );
      },
    );
  }

  String getIcon(String selectedTopic) {
    if (nostrRepository.buzzFeedSources.keys.contains(selectedTopic)) {
      return nostrRepository.buzzFeedSources[selectedTopic]?.icon ?? '';
    } else {
      return nostrRepository.topics.firstWhere(
        (topic) => topic.topic.toLowerCase() == selectedTopic.toLowerCase(),
        orElse: () {
          return Topic(
            topic: selectedTopic,
            icon: '',
            subTopics: [],
          );
        },
      ).icon;
    }
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
      length: context.read<HomeCubit>().state.sources.length + 1,
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
    return BlocConsumer<HomeCubit, HomeState>(
      listenWhen: (previous, current) => previous.sources != current.sources,
      listener: (context, state) {
        if (state.sources.isNotEmpty) {
          final tempController = tabController;

          tabController = TabController(
            length: state.sources.length + 1,
            vsync: this,
          );

          tempController.dispose();
        }
      },
      buildWhen: (previous, current) => previous.sources != current.sources,
      builder: (context, state) {
        return ScrollShadow(
          color: Theme.of(context).scaffoldBackgroundColor,
          size: 10,
          child: FadeInUp(
            duration: const Duration(milliseconds: 200),
            child: ButtonsTabBar(
              controller: tabController,
              backgroundColor: Theme.of(context).primaryColorDark,
              unselectedBackgroundColor: Theme.of(context).primaryColorLight,
              unselectedLabelStyle: TextStyle(
                color: Theme.of(context).primaryColorDark,
              ),
              labelStyle: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              radius: 300,
              height: 40,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
                vertical: 0,
              ),
              onTap: (selectedIndex) {
                context.read<HomeCubit>().getTopicContent(
                      selectedIndex,
                      state.chosenRelay,
                    );

                setState(
                  () {
                    index = selectedIndex;
                  },
                );
              },
              tabs: [
                Tab(
                  icon: Icon(
                    CupertinoIcons.cloud,
                    size: 20,
                  ),
                  text: 'All',
                  height: 50,
                ),
                ...state.sources.map(
                  (source) {
                    return Tab(
                      icon: source.icon.isEmpty
                          ? Image.asset(
                              Images.defaultTopicIcon,
                              width: 20,
                              height: 20,
                            )
                          : CachedNetworkImage(
                              imageUrl: source.icon,
                              width: 20,
                              height: 20,
                              imageBuilder: (context, imageProvider) {
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image:
                                        DecorationImage(image: imageProvider),
                                  ),
                                );
                              },
                              errorWidget: (context, url, error) => Image.asset(
                                Images.defaultTopicIcon,
                              ),
                            ),
                      text: source.name,
                    );
                  },
                ).toList()
              ],
            ),
          ),
        );
      },
    );
  }
}
