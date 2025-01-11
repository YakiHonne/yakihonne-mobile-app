import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/self_smart_widgets_cubit/self_smart_widgets_cubit.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/search_view/search_view.dart';
import 'package:yakihonne/views/self_smart_widgets_view/widgets/self_smart_widget_container.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/write_smart_widget_view/write_smart_widget_view.dart';

class SelfSmartWidgetsList extends HookWidget {
  const SelfSmartWidgetsList({
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          controller: scrollController,
          slivers: [
            BlocBuilder<SelfSmartWidgetsCubit, SelfSmartWidgetsState>(
              builder: (context, state) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                      vertical: kDefaultPadding,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${state.widgets.length.toString().padLeft(2, '0')} Smart widgets',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              Text(
                                '(In ${state.chosenRelay.isEmpty ? 'all relays' : state.chosenRelay.split('wss://')[1]})',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
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
                            backgroundColor:
                                Theme.of(context).primaryColorLight,
                          ),
                          itemBuilder: (context) {
                            final activeRelays =
                                NostrConnect.sharedInstance.activeRelays();

                            return [
                              PullDownMenuItem.selectable(
                                onTap: () {
                                  context
                                      .read<SelfSmartWidgetsCubit>()
                                      .getSmartWidgets(relay: '');
                                },
                                selected: state.chosenRelay.isEmpty,
                                title: 'All relays',
                                itemTheme: PullDownMenuItemTheme(
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        fontWeight: state.chosenRelay.isEmpty
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                ),
                              ),
                              ...state.relays
                                  .map(
                                    (e) => PullDownMenuItem.selectable(
                                      onTap: () {
                                        context
                                            .read<SelfSmartWidgetsCubit>()
                                            .getSmartWidgets(relay: e);
                                      },
                                      selected: e == state.chosenRelay,
                                      title: e.split('wss://')[1],
                                      iconColor: activeRelays.contains(e)
                                          ? kGreen
                                          : kRed,
                                      iconWidget: Icon(
                                        CupertinoIcons.circle_fill,
                                        size: 7,
                                      ),
                                      itemTheme: PullDownMenuItemTheme(
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .labelMedium!
                                            .copyWith(
                                              fontWeight: state.chosenRelay == e
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
                              backgroundColor:
                                  Theme.of(context).primaryColorLight,
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
            ),
            BlocBuilder<SelfSmartWidgetsCubit, SelfSmartWidgetsState>(
              buildWhen: (previous, current) =>
                  previous.widgets != current.widgets ||
                  previous.isWidgetsLoading != current.isWidgetsLoading,
              builder: (context, state) {
                if (state.widgets.isEmpty && !state.isWidgetsLoading) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: kDefaultPadding),
                      child: EmptyList(
                        description:
                            'No smart widgets were found on this relay.',
                        icon: FeatureIcons.smartWidget,
                      ),
                    ),
                  );
                } else if (state.isWidgetsLoading) {
                  return SliverToBoxAdapter(
                    child: SearchLoading(),
                  );
                } else {
                  if (!ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
                    return SliverPadding(
                      padding: const EdgeInsets.all(
                        kDefaultPadding / 2,
                      ),
                      sliver: SliverList.separated(
                        separatorBuilder: (context, index) => SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                        itemBuilder: (context, index) {
                          final widget = state.widgets[index];

                          return selfSmartWidgetContainer(
                            widget,
                            context,
                          );
                        },
                        itemCount: state.widgets.length,
                      ),
                    );
                  } else {
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 2,
                      ),
                      sliver: SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: kDefaultPadding / 2,
                          mainAxisSpacing: kDefaultPadding / 2,
                          mainAxisExtent: 275,
                        ),
                        itemBuilder: (context, index) {
                          final widget = state.widgets[index];

                          return selfSmartWidgetContainer(
                            widget,
                            context,
                          );
                        },
                        itemCount: state.widgets.length,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
        ResetScrollButton(
          scrollController: scrollController,
          isLeft: true,
          padding: kDefaultPadding,
        ),
      ],
    );
  }

  Widget selfSmartWidgetContainer(
    SmartWidgetModel smartWidgetModel,
    BuildContext context,
  ) {
    return BlocBuilder<SelfSmartWidgetsCubit, SelfSmartWidgetsState>(
      builder: (context, state) {
        return SelfSmartWidgetContainer(
          smartWidgetModel: smartWidgetModel,
          onEditOrClone: (isCloning) {
            Navigator.pushNamed(
              context,
              WriteSmartWidgetView.routeName,
              arguments: [
                smartWidgetModel,
                isCloning,
              ],
            );
          },
          onDelete: () {
            showDialog(
              context: context,
              builder: (alertContext) => AlertDialog(
                title: Text(
                  'Delete "${smartWidgetModel.title}"?',
                  textAlign: TextAlign.center,
                ),
                titleTextStyle:
                    Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                content: Text(
                  "You're about to delete this smart widget, do you wish to proceed?",
                  textAlign: TextAlign.center,
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                      onPressed: () {
                        context.read<SelfSmartWidgetsCubit>().deleteSmartWidget(
                          smartWidgetModel.smartWidgetId,
                          () {
                            context
                                .read<SelfSmartWidgetsCubit>()
                                .getSmartWidgets(relay: state.chosenRelay);

                            Navigator.of(context).pop();
                          },
                        );
                      },
                      child: Text(
                        'Delete widget',
                        style: TextStyle(
                          color: Theme.of(context).primaryColorDark,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: kTransparent,
                        side: BorderSide(
                          color: kRed,
                        ),
                      )),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: kWhite,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: kRed,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
