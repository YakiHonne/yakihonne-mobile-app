import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/write_smart_widget_cubit/write_smart_widget_cubit.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/modal_with_blur.dart';
import 'package:yakihonne/views/write_smart_widget_view/widgets/smart_widget_component_customization.dart';
import 'package:yakihonne/views/write_smart_widget_view/widgets/smart_widget_components_list.dart';
import 'package:yakihonne/views/write_smart_widget_view/widgets/smart_widget_single_component.dart';

class GridWidget extends StatelessWidget {
  const GridWidget({
    Key? key,
    required this.grid,
    required this.hasManyGrids,
    required this.toggleView,
    required this.menuDisplayIds,
    required this.isSelected,
    required this.onAddMenuElements,
    required this.onRemoveMenuElements,
    required this.canBeMovedUp,
    required this.canBeMovedDown,
  }) : super(key: key);

  final SmartWidgetGrid grid;
  final bool hasManyGrids;
  final bool toggleView;
  final List<String> menuDisplayIds;
  final bool isSelected;
  final Function(List<String>) onAddMenuElements;
  final Function(List<String>) onRemoveMenuElements;
  final bool canBeMovedUp;
  final bool canBeMovedDown;

  @override
  Widget build(BuildContext context) {
    final widget = Stack(
      children: [
        Row(
          children: [
            Expanded(
              flex: grid.getDivision(true),
              child: FrameVerticalView(
                components: grid.leftSide,
                gridId: grid.id,
                toggleView: toggleView,
                menuDisplayIds: menuDisplayIds,
                onAddMenuElements: onAddMenuElements,
                onRemoveMenuElements: onRemoveMenuElements,
                isLeftSide: true,
                canAddToColumn: grid.layout == 2,
              ),
            ),
            if (grid.layout == 2) ...[
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              Expanded(
                flex: grid.getDivision(false),
                child: FrameVerticalView(
                  components: grid.rightSide,
                  gridId: grid.id,
                  toggleView: toggleView,
                  menuDisplayIds: menuDisplayIds,
                  onAddMenuElements: onAddMenuElements,
                  onRemoveMenuElements: onRemoveMenuElements,
                  canAddToColumn: grid.layout == 2,
                  isLeftSide: false,
                ),
              ),
            ],
          ],
        ),
        if (isSelected && grid.layout == 2 && !toggleView)
          Positioned.fill(
            child: Builder(builder: (context) {
              final leftDivision = grid.getDivision(true);
              final rightDivision = grid.getDivision(false);

              return Align(
                alignment: Alignment(
                  leftDivision == 1 && rightDivision == 1
                      ? 0
                      : leftDivision == 1
                          ? -0.35
                          : 0.35,
                  0,
                ),
                child: CustomIconButton(
                  onClicked: () {
                    context.read<WriteSmartWidgetCubit>().toggleGrid(grid.id);
                  },
                  icon: FeatureIcons.refresh,
                  size: 15,
                  vd: -2,
                  iconColor: Theme.of(context).primaryColorLight,
                  backgroundColor:
                      Theme.of(context).primaryColorDark.withValues(alpha: 0.7),
                ),
              );
            }),
          ),
      ],
    );

    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: !toggleView
                ? DottedBorder(
                    color: isSelected
                        ? Theme.of(context).primaryColorDark
                        : kDimGrey.withValues(alpha: 0.5),
                    strokeCap: StrokeCap.round,
                    borderType: BorderType.RRect,
                    dashPattern: [4],
                    strokeWidth: 0.5,
                    radius: Radius.circular(kDefaultPadding / 2),
                    child: widget,
                  )
                : widget,
          ),
          if (!toggleView) ...[
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: !hasManyGrids ? 80 : 120,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasManyGrids) ...[
                    SizedBox(
                      height: kDefaultPadding * 1.2,
                      child: Opacity(
                        opacity: canBeMovedUp ? 1 : 0.5,
                        child: gridSideButton(
                          onTap: () {
                            if (canBeMovedUp) {
                              context
                                  .read<WriteSmartWidgetCubit>()
                                  .moveComponent(
                                    componentId: grid.id,
                                    toBottom: false,
                                  );
                            }
                          },
                          backGroundColor: kDimGrey2,
                          icon: FeatureIcons.arrowUp,
                          isSmall: true,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                  ],
                  Expanded(
                    flex: 4,
                    child: gridSideButton(
                      onTap: () {
                        if (grid.layout == 1) {
                          bool hasForbiddenItems = false;

                          if (grid.leftSide.isNotEmpty) {
                            final first = grid.leftSide.values.first;

                            if (first is SmartWidgetVideo ||
                                first is SmartWidgetZapPoll) {
                              BotToastUtils.showError(
                                'Only monolayout required',
                              );

                              return;
                            }
                          }

                          for (final item in grid.leftSide.values) {
                            if (item is SmartWidgetZapPoll ||
                                item is SmartWidgetVideo) {
                              hasForbiddenItems = true;
                            }
                          }

                          context.read<WriteSmartWidgetCubit>().updateComponent(
                                component: grid.copyWith(
                                  layout: 2,
                                  division: '1:1',
                                  leftSide: hasForbiddenItems ? {} : null,
                                ),
                              );
                        } else {
                          showModalBottomSheet(
                            context: context,
                            builder: (_) {
                              return BlocProvider.value(
                                value: context.read<WriteSmartWidgetCubit>(),
                                child: FrameComponentCustomization(
                                  frameComponent: grid,
                                ),
                              );
                            },
                            isScrollControlled: true,
                            useRootNavigator: true,
                            useSafeArea: true,
                            elevation: 0,
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                          );
                        }
                      },
                      isSmall: false,
                      backGroundColor: kDimGrey2,
                      icon: grid.layout == 2
                          ? FeatureIcons.editWidget
                          : FeatureIcons.addRaw,
                    ),
                  ),
                  if (hasManyGrids) ...[
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Expanded(
                      flex: 4,
                      child: gridSideButton(
                        onTap: () {
                          context.read<WriteSmartWidgetCubit>().deleteComponent(
                                componentId: grid.id,
                              );
                        },
                        isSmall: false,
                        backGroundColor: kRed,
                        icon: FeatureIcons.trash,
                      ),
                    ),
                  ],
                  if (hasManyGrids) ...[
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    SizedBox(
                      height: kDefaultPadding * 1.2,
                      child: Opacity(
                        opacity: canBeMovedDown ? 1 : 0.5,
                        child: gridSideButton(
                          onTap: () {
                            if (canBeMovedDown) {
                              context
                                  .read<WriteSmartWidgetCubit>()
                                  .moveComponent(
                                    componentId: grid.id,
                                    toBottom: true,
                                  );
                            }
                          },
                          backGroundColor: kDimGrey2,
                          icon: FeatureIcons.arrowDown,
                          isSmall: true,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class gridSideButton extends StatelessWidget {
  const gridSideButton({
    Key? key,
    required this.icon,
    required this.backGroundColor,
    required this.onTap,
    required this.isSmall,
  }) : super(key: key);

  final String icon;
  final Color backGroundColor;
  final Function() onTap;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: kDefaultPadding * 1.2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 4),
          color: backGroundColor,
        ),
        child: Center(
          child: SvgPicture.asset(
            icon,
            width: 15,
            height: 15,
            colorFilter: ColorFilter.mode(
              kWhite,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

class FrameVerticalView extends StatelessWidget {
  const FrameVerticalView({
    Key? key,
    required this.components,
    required this.gridId,
    required this.toggleView,
    required this.menuDisplayIds,
    required this.onAddMenuElements,
    required this.onRemoveMenuElements,
    required this.isLeftSide,
    required this.canAddToColumn,
  }) : super(key: key);

  final Map<String, SmartWidgetComponent> components;
  final String gridId;
  final bool toggleView;
  final List<String> menuDisplayIds;
  final bool isLeftSide;
  final bool canAddToColumn;
  final Function(List<String>) onAddMenuElements;
  final Function(List<String>) onRemoveMenuElements;

  @override
  Widget build(BuildContext context) {
    final widget = Center(
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 8),
        child: components.isEmpty && !toggleView
            ? GestureDetector(
                onTap: () {
                  showBlurredModal(
                    context: context,
                    view: FrameComponents(
                      parentId: gridId,
                      enableForbiddenItem: !canAddToColumn,
                      onFrameComponentSelected: (c) {
                        Navigator.pop(context);
                        context.read<WriteSmartWidgetCubit>().addCompoenent(
                              component: c,
                              horizontalGridId: gridId,
                              isLeftSide: isLeftSide,
                            );
                      },
                    ),
                  );
                },
                child: Center(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(
                        kDefaultPadding / 2,
                      ),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        FeatureIcons.addRaw,
                        width: 15,
                        height: 15,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).primaryColorDark,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : components.isEmpty
                ? SizedBox.shrink()
                : Builder(builder: (context) {
                    List<Widget> widgets = [];
                    final cs = components.values.toList();

                    for (int i = 0; i < cs.length; i++) {
                      final e = cs[i];

                      widgets.add(
                        SmartWidgetSingleComponent(
                          smartWidgetComponent: e,
                          gridId: gridId,
                          toggleView: toggleView,
                          menuDisplayIds: menuDisplayIds,
                          onAddMenuElements: onAddMenuElements,
                          onRemoveMenuElements: onRemoveMenuElements,
                        ),
                      );
                      if (i < cs.length - 1) {
                        widgets.add(
                          SizedBox(
                            height: kDefaultPadding / 3,
                          ),
                        );
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...widgets,
                        if (!toggleView && canAddToColumn) ...[
                          const SizedBox(
                            height: kDefaultPadding / 4,
                          ),
                          GestureDetector(
                            onTap: () {
                              showBlurredModal(
                                context: context,
                                view: FrameComponents(
                                  enableForbiddenItem: false,
                                  parentId: gridId,
                                  onFrameComponentSelected: (c) {
                                    Navigator.pop(context);
                                    context
                                        .read<WriteSmartWidgetCubit>()
                                        .addCompoenent(
                                          component: c,
                                          horizontalGridId: gridId,
                                          isLeftSide: isLeftSide,
                                        );
                                  },
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  kDefaultPadding / 4,
                                ),
                                color: kDimGrey2,
                              ),
                              width: double.infinity,
                              height: kDefaultPadding * 1.2,
                              child: Center(
                                child: SvgPicture.asset(
                                  FeatureIcons.addRaw,
                                  width: 15,
                                  height: 15,
                                  colorFilter: ColorFilter.mode(
                                    kWhite,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ]
                      ],
                    );
                  }),
      ),
    );

    return widget;
  }
}
