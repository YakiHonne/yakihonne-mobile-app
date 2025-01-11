import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/smart_widgets_cubit/smart_widgets_cubit.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/global_smart_widget_container.dart';
import 'package:yakihonne/views/widgets/classic_footer.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';

class SmartWidgetSelection extends StatefulWidget {
  const SmartWidgetSelection({
    Key? key,
    required this.onWidgetAdded,
  }) : super(key: key);

  final Function(SmartWidgetModel) onWidgetAdded;

  @override
  State<SmartWidgetSelection> createState() =>
      _SmartWidgetZapPollSelectionState();
}

class _SmartWidgetZapPollSelectionState extends State<SmartWidgetSelection>
    with TickerProviderStateMixin {
  final refreshController = RefreshController();
  late TabController tabController;

  @override
  void initState() {
    tabController = TabController(
      length: 2,
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
          return Container(
            child: DraggableScrollableSheet(
              initialChildSize: 0.80,
              minChildSize: 0.40,
              maxChildSize: 0.80,
              expand: false,
              builder: (context, scrollController) => ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(kDefaultPadding),
                  topRight: Radius.circular(kDefaultPadding),
                ),
                child: NestedScrollView(
                  controller: scrollController,
                  floatHeaderSlivers: true,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        automaticallyImplyLeading: false,
                        leadingWidth: 0,
                        elevation: 5,
                        pinned: true,
                        actions: [const SizedBox.shrink()],
                        titleSpacing: 0,
                        toolbarHeight: 64,
                        flexibleSpace: SizedBox(
                          width: double.infinity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ModalBottomSheetHandle(),
                              TabBar(
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                dividerColor:
                                    Theme.of(context).primaryColorLight,
                                controller: tabController,
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: kDefaultPadding / 4,
                                ),
                                unselectedLabelStyle:
                                    Theme.of(context).textTheme.labelMedium,
                                onTap: (index) {
                                  if (index == 0) {
                                    context
                                        .read<SmartWidgetsCubit>()
                                        .getSmartWidgets(
                                            isAdd: false, isSelf: false);
                                  } else {
                                    context
                                        .read<SmartWidgetsCubit>()
                                        .getSmartWidgets(
                                            isAdd: false, isSelf: true);
                                  }
                                },
                                tabs: [
                                  Tab(
                                    height: 35,
                                    child: Text('Community widgets'),
                                  ),
                                  Tab(height: 35, child: Text('My widgets')),
                                ],
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
                          description: 'No smart widgets can be found',
                          icon: FeatureIcons.smartWidget,
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
                                  controller: scrollController,
                                  itemCount: state.widgets.length,
                                  crossAxisSpacing: kDefaultPadding / 2,
                                  mainAxisSpacing: kDefaultPadding / 2,
                                  padding:
                                      const EdgeInsets.all(kDefaultPadding / 2),
                                  itemBuilder: (context, index) {
                                    final w = state.widgets[index];

                                    return GlobalSmartWidgetContainer(
                                      smartWidgetModel: w,
                                      onClicked: () {
                                        widget.onWidgetAdded.call(w);
                                      },
                                      onClone: () {},
                                    );
                                  },
                                )
                              : ListView.separated(
                                  itemCount: state.widgets.length,
                                  controller: scrollController,
                                  padding:
                                      const EdgeInsets.all(kDefaultPadding / 2),
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(
                                    height: kDefaultPadding / 2,
                                  ),
                                  itemBuilder: (context, index) {
                                    final w = state.widgets[index];

                                    return GlobalSmartWidgetContainer(
                                      smartWidgetModel: w,
                                      onClicked: () {
                                        widget.onWidgetAdded.call(w);
                                      },
                                      onClone: () {},
                                    );
                                  },
                                ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
