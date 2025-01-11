// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:uuid/uuid.dart';
import 'package:yakihonne/blocs/write_smart_widget_cubit/write_smart_widget_cubit.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/write_smart_widget_view/widgets/smart_widget_drafts.dart';
import 'package:yakihonne/views/write_smart_widget_view/widgets/smart_widget_grid.dart';
import 'package:yakihonne/views/write_smart_widget_view/widgets/smart_widget_layout.dart';
import 'package:yakihonne/views/write_smart_widget_view/widgets/smart_widget_pulldown_button.dart';
import 'package:yakihonne/views/write_smart_widget_view/widgets/smart_widgets_templates_view.dart';

class FrameSpecifications extends HookWidget {
  const FrameSpecifications({
    Key? key,
    required this.toggleView,
  }) : super(key: key);

  final bool toggleView;

  @override
  Widget build(BuildContext context) {
    final menuDisplayIds = useState(<String>[]);
    final isLayoutToggled = useState(false);
    final _startX = useState(0.0);

    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    final browseTemplates = () {
      showModalBottomSheet(
        context: context,
        builder: (_) {
          return BlocProvider.value(
            value: context.read<WriteSmartWidgetCubit>(),
            child: SmartWidgetTemplatesView(
              onSmartWidgetSelected: (container) {
                context
                    .read<WriteSmartWidgetCubit>()
                    .setSmartWidgetContainer(container);
                context.read<WriteSmartWidgetCubit>().setOnboardingOff();
              },
            ),
          );
        },
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    };

    final drafts = () {
      showModalBottomSheet(
        context: context,
        builder: (_) {
          return BlocProvider.value(
            value: context.read<WriteSmartWidgetCubit>(),
            child: SmartWidgetsDrafts(
              onSmartWidgetDraftSelected: (swSaveModel) {
                context
                    .read<WriteSmartWidgetCubit>()
                    .setSwAutoSaveModel(swSaveModel);
                context.read<WriteSmartWidgetCubit>().setOnboardingOff();
              },
              onSmartWidgetPublished: (swSaveModel) {
                context
                    .read<WriteSmartWidgetCubit>()
                    .setSwAutoSaveModel(swSaveModel);
                context.read<WriteSmartWidgetCubit>().setFramePublishStep(
                      SmartWidgetPublishSteps.content,
                    );
              },
            ),
          );
        },
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    };

    return BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
      builder: (context, state) {
        if (state.isOnboarding) {
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: kDefaultPadding / 2,
              horizontal: isTablet ? 10.w : kDefaultPadding / 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Lottie.asset(
                  LottieAnimations.widgets,
                  height: 25.h,
                  fit: BoxFit.contain,
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Text(
                  'Smart widget builder',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Text(
                  'Start building and customize your smart widget to use on the Nostr network',
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: kDimGrey,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                Row(
                  children: [
                    Expanded(
                      child: OnboardingOption(
                        icon: FeatureIcons.add,
                        onClick: () {
                          context
                              .read<WriteSmartWidgetCubit>()
                              .setOnboardingOff();
                        },
                        title: 'Blank widget',
                      ),
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    ),
                    Expanded(
                      child: OnboardingOption(
                        icon: FeatureIcons.swDraft,
                        onClick: drafts,
                        title: 'My drafts',
                      ),
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    ),
                    Expanded(
                      child: OnboardingOption(
                        icon: FeatureIcons.templates,
                        onClick: browseTemplates,
                        title: 'Templates',
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        }

        final smartWidgetContainer = state.smartWidgetContainer;

        return isTablet
            ? Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: isLayoutToggled.value
                          ? () {
                              isLayoutToggled.value = false;
                            }
                          : null,
                      behavior: HitTestBehavior.opaque,
                      child: AbsorbPointer(
                        absorbing: isLayoutToggled.value,
                        child: ListView(
                          padding: const EdgeInsets.all(kDefaultPadding / 2),
                          children: [
                            if (!toggleView) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SmallRectangularButton(
                                    onClick: drafts,
                                    turns: 0,
                                    icon: FeatureIcons.swDraft,
                                    backgroundColor: null,
                                  ),
                                  SmallRectangularButton(
                                    onClick: browseTemplates,
                                    turns: 0,
                                    icon: FeatureIcons.templates,
                                    backgroundColor: null,
                                  ),
                                  if (!isTablet) ...[
                                    const SizedBox(
                                      width: kDefaultPadding / 4,
                                    ),
                                    SmallRectangularButton(
                                      onClick: () {
                                        isLayoutToggled.value = true;
                                      },
                                      icon: FeatureIcons.layers,
                                      turns: 0,
                                      backgroundColor: null,
                                    ),
                                  ],
                                  const SizedBox(
                                    width: kDefaultPadding / 4,
                                  ),
                                  FrameComponentPulldownButton(
                                    isFirstComponent: true,
                                    currentComponent: smartWidgetContainer,
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: kDefaultPadding / 4,
                              ),
                            ],
                            SMEditableContainer(
                              smartWidgetContainer: smartWidgetContainer,
                              toggleView: toggleView,
                              menuDisplayIds: menuDisplayIds,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SmartWidgetLayout(
                      onDismiss: () {
                        if (!isTablet) {
                          isLayoutToggled.value = false;
                        }
                      },
                    ),
                  ),
                ],
              )
            : LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  onHorizontalDragStart: (details) {
                    _startX.value = details.localPosition.dx;
                  },
                  onHorizontalDragUpdate: (details) {
                    double currentX = details.localPosition.dx;
                    if (currentX > _startX.value) {
                      isLayoutToggled.value = false;
                    } else if (currentX < _startX.value) {
                      isLayoutToggled.value = true;
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    _startX.value = 0;
                  },
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(
                          milliseconds: 300,
                        ),
                        curve: Curves.easeInOut,
                        right:
                            isLayoutToggled.value && !toggleView ? 80.w : 0.0,
                        height: constraints.maxHeight,
                        width: constraints.maxWidth,
                        child: GestureDetector(
                          onTap: isLayoutToggled.value
                              ? () {
                                  isLayoutToggled.value = false;
                                }
                              : null,
                          behavior: HitTestBehavior.opaque,
                          child: AbsorbPointer(
                            absorbing: isLayoutToggled.value,
                            child: ListView(
                              padding:
                                  const EdgeInsets.all(kDefaultPadding / 2),
                              children: [
                                if (!toggleView) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SmallRectangularButton(
                                        onClick: drafts,
                                        turns: 0,
                                        icon: FeatureIcons.swDraft,
                                        backgroundColor: null,
                                      ),
                                      const SizedBox(
                                        width: kDefaultPadding / 4,
                                      ),
                                      SmallRectangularButton(
                                        onClick: browseTemplates,
                                        icon: FeatureIcons.templates,
                                        turns: 0,
                                        backgroundColor: null,
                                      ),
                                      if (!isTablet) ...[
                                        const SizedBox(
                                          width: kDefaultPadding / 4,
                                        ),
                                        SmallRectangularButton(
                                          onClick: () {
                                            isLayoutToggled.value = true;
                                          },
                                          turns: 0,
                                          icon: FeatureIcons.layers,
                                          backgroundColor: null,
                                        ),
                                      ],
                                      const SizedBox(
                                        width: kDefaultPadding / 4,
                                      ),
                                      FrameComponentPulldownButton(
                                        isFirstComponent: true,
                                        currentComponent: smartWidgetContainer,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: kDefaultPadding / 4,
                                  ),
                                ],
                                SMEditableContainer(
                                  smartWidgetContainer: smartWidgetContainer,
                                  toggleView: toggleView,
                                  menuDisplayIds: menuDisplayIds,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        left:
                            isLayoutToggled.value && !toggleView ? 20.w : 100.w,
                        height: constraints.maxHeight,
                        curve: Curves.easeInOut,
                        width: 80.w,
                        child: SmartWidgetLayout(
                          onDismiss: () {
                            isLayoutToggled.value = false;
                          },
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

class SMEditableContainer extends StatelessWidget {
  const SMEditableContainer({
    super.key,
    required this.smartWidgetContainer,
    required this.toggleView,
    required this.menuDisplayIds,
  });

  final SmartWidgetContainer smartWidgetContainer;
  final bool toggleView;
  final ValueNotifier<List<String>> menuDisplayIds;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        color: smartWidgetContainer.backgroundHex != null &&
                smartWidgetContainer.backgroundHex!.isNotEmpty
            ? getColorFromHex(smartWidgetContainer.backgroundHex!)
            : Theme.of(context).primaryColorLight,
        border: smartWidgetContainer.borderColorHex != null &&
                smartWidgetContainer.borderColorHex!.isNotEmpty
            ? Border.all(
                color: getColorFromHex(
                      smartWidgetContainer.borderColorHex!,
                    ) ??
                    Theme.of(context).scaffoldBackgroundColor,
              )
            : null,
      ),
      child: Column(
        children: [
          ListView.separated(
            physics: ClampingScrollPhysics(),
            itemBuilder: (context, index) {
              final component =
                  smartWidgetContainer.grids.values.toList()[index];

              final keys = smartWidgetContainer.grids.keys.toList();

              return GridWidget(
                grid: component,
                isSelected:
                    smartWidgetContainer.highlightedGrid == component.id,
                canBeMovedDown: keys.length > 1 &&
                    keys.indexOf(component.id) < keys.length - 1,
                canBeMovedUp: keys.length > 1 && keys.indexOf(component.id) > 0,
                toggleView: toggleView,
                menuDisplayIds: menuDisplayIds.value,
                hasManyGrids: keys.length > 1,
                onAddMenuElements: (p0) {
                  menuDisplayIds.value.addAll(p0);
                },
                onRemoveMenuElements: (p0) {
                  menuDisplayIds.value.removeWhere(
                    (element) => p0.contains(element),
                  );
                },
              );
            },
            shrinkWrap: true,
            separatorBuilder: (context, index) =>
                smartWidgetContainer.grids.length > 1 && !toggleView
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: kDimGrey,
                                thickness: 1,
                                endIndent: kDefaultPadding / 8,
                              ),
                            ),
                            CustomIconButton(
                              onClicked: () {
                                context
                                    .read<WriteSmartWidgetCubit>()
                                    .addCompoenent(
                                      component: SmartWidgetGrid(
                                        id: Uuid().v4(),
                                        leftSide: {},
                                        rightSide: {},
                                      ),
                                      index: index,
                                    );
                              },
                              icon: FeatureIcons.addRaw,
                              size: 12,
                              iconColor: kWhite,
                              vd: -4,
                              backgroundColor: kDimGrey2,
                            ),
                            Expanded(
                              child: Divider(
                                color: kDimGrey,
                                thickness: 1,
                                indent: kDefaultPadding / 8,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SizedBox(
                        height: !toggleView
                            ? kDefaultPadding / 2
                            : kDefaultPadding / 4,
                      ),
            itemCount: smartWidgetContainer.grids.values.length,
          ),
          if (!toggleView) ...[
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Builder(
              builder: (context) {
                final last = smartWidgetContainer.grids.values.last;
                final disabled =
                    last.leftSide.isEmpty && last.rightSide.isEmpty;

                return AbsorbPointer(
                  absorbing: disabled,
                  child: Opacity(
                    opacity: disabled ? 0.5 : 1,
                    child: GestureDetector(
                      onTap: () {
                        context.read<WriteSmartWidgetCubit>().addCompoenent(
                              component: SmartWidgetGrid(
                                id: Uuid().v4(),
                                leftSide: {},
                                rightSide: {},
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
                  ),
                );
              },
            ),
          ]
        ],
      ),
    );
  }
}

class OnboardingOption extends StatelessWidget {
  const OnboardingOption({
    Key? key,
    required this.onClick,
    required this.title,
    required this.icon,
  }) : super(key: key);

  final Function() onClick;
  final String title;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        onTap: onClick,
        child: Container(
          height: constraints.maxWidth,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            color: Theme.of(context).primaryColorLight,
            border: Border.all(
              color: kDimGrey.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                icon,
                width: 30,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
