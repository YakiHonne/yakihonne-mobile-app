// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/smart_widgets_cubit/smart_widgets_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/global_smart_widget_container.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_checker.dart';
import 'package:yakihonne/views/widgets/classic_footer.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';

class SmartWidgetsView extends StatefulWidget {
  const SmartWidgetsView({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  State<SmartWidgetsView> createState() => _SmartWidgetsViewState();
}

class _SmartWidgetsViewState extends State<SmartWidgetsView>
    with TickerProviderStateMixin {
  final refreshController = RefreshController();
  late TabController tabController;
  late bool isConnected;
  int index = 0;
  SmartWidgetType smartWidgetType = SmartWidgetType.community;

  @override
  void initState() {
    isConnected = isUsingPrivatekey();
    tabController = TabController(
      length: isConnected ? 2 : 1,
      initialIndex: 0,
      vsync: this,
    );

    super.initState();
  }

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
      create: (context) => SmartWidgetsCubit(),
      child: BlocConsumer<SmartWidgetsCubit, SmartWidgetsState>(
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
                SliverAppBar(
                  elevation: 5,
                  leadingWidth: 55,
                  pinned: true,
                  actions: [
                    SizedBox(
                      width: 70,
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 3,
                          ),
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                CustomIconButton(
                                  backgroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  onClicked: () {
                                    Navigator.pushNamed(
                                      context,
                                      SmartWidgetChecker.routeName,
                                    );
                                  },
                                  icon: FeatureIcons.swChecker,
                                  size: 20,
                                  vd: -2,
                                ),
                                VerticalDivider(
                                  width: 5,
                                  indent: kDefaultPadding / 4,
                                  endIndent: kDefaultPadding / 4,
                                ),
                                CustomIconButton(
                                  backgroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  onClicked: () {
                                    openWebPage(
                                      url: '${baseUrl}yakihonne-smart-widgets',
                                      inAppWebView: true,
                                    );
                                  },
                                  icon: FeatureIcons.widgetInfo,
                                  size: 20,
                                  vd: -2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 2.5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    ),
                  ],
                  titleSpacing: 0,
                  toolbarHeight: 38,
                  title: SizedBox(
                    width: double.infinity,
                    child: TabBar(
                      padding: const EdgeInsets.only(
                        left: kDefaultPadding / 2,
                        right: kDefaultPadding / 2,
                      ),
                      labelStyle:
                          Theme.of(context).textTheme.labelMedium!.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                      dividerColor: Theme.of(context).primaryColorLight,
                      indicatorSize: TabBarIndicatorSize.tab,
                      controller: tabController,
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 4,
                      ),
                      unselectedLabelStyle:
                          Theme.of(context).textTheme.labelMedium,
                      onTap: (index) {
                        isConnected = isUsingPrivatekey();
                        smartWidgetType = index == 0
                            ? SmartWidgetType.community
                            : SmartWidgetType.self;

                        context
                            .read<SmartWidgetsCubit>()
                            .getSmartWidgets(isAdd: false, isSelf: index == 1);
                      },
                      tabs: [
                        Tab(
                          height: 35,
                          text: 'Community',
                        ),
                        if (isConnected)
                          Tab(
                            height: 35,
                            text: 'My widgets',
                          ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: Builder(
              builder: (context) {
                if (state.isLoading) {
                  return Center(
                    child: SpinKitPulse(
                      color: Theme.of(context).primaryColorDark,
                      size: 20,
                    ),
                  );
                } else if (state.widgets.isEmpty) {
                  return EmptyList(
                    description: 'No polls can be found',
                    icon: FeatureIcons.polls,
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
                    onLoading: () => context
                        .read<SmartWidgetsCubit>()
                        .getSmartWidgets(isAdd: true, isSelf: false),
                    onRefresh: () => onRefresh(
                      onInit: () => context
                          .read<SmartWidgetsCubit>()
                          .getSmartWidgets(isAdd: false, isSelf: false),
                    ),
                    child: isTablet
                        ? MasonryGridView.count(
                            crossAxisCount: 2,
                            itemCount: state.widgets.length,
                            crossAxisSpacing: kDefaultPadding / 2,
                            mainAxisSpacing: kDefaultPadding / 2,
                            padding: const EdgeInsets.all(kDefaultPadding / 2),
                            itemBuilder: (context, index) {
                              final widget = state.widgets[index];

                              return GlobalSmartWidgetContainer(
                                smartWidgetModel: widget,
                                canPerformOwnerActions: true,
                                onClone: () {},
                              );
                            },
                          )
                        : ListView.separated(
                            itemCount: state.widgets.length,
                            padding: const EdgeInsets.all(kDefaultPadding / 2),
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                              height: kDefaultPadding / 2,
                            ),
                            itemBuilder: (context, index) {
                              final widget = state.widgets[index];

                              return GlobalSmartWidgetContainer(
                                smartWidgetModel: widget,
                                canPerformOwnerActions: true,
                                onClone: () {},
                              );
                            },
                          ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
