// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:yakihonne/blocs/write_smart_widget_cubit/write_smart_widget_cubit.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/write_smart_widget_view/widgets/smart_widget_component_customization.dart';

class FrameComponentPulldownButton extends StatelessWidget {
  const FrameComponentPulldownButton({
    Key? key,
    required this.currentComponent,
    required this.isFirstComponent,
    this.backgroundColor,
    this.horizontalGridId,
  }) : super(key: key);

  final SmartWidgetComponent currentComponent;
  final bool isFirstComponent;
  final Color? backgroundColor;
  final String? horizontalGridId;

  @override
  Widget build(BuildContext context) {
    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).primaryColorLight,
      ),
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.labelMedium;

        return [
          PullDownMenuItem(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) {
                  return BlocProvider.value(
                    value: context.read<WriteSmartWidgetCubit>(),
                    child: FrameComponentCustomization(
                      frameComponent: currentComponent,
                    ),
                  );
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            },
            title: 'Edit',
            iconWidget: SvgPicture.asset(
              FeatureIcons.article,
              height: 20,
              width: 20,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
          ),
          if (!isFirstComponent) ...[
            PullDownMenuItem(
              onTap: () {
                context.read<WriteSmartWidgetCubit>().moveComponent(
                      componentId: currentComponent.id,
                      horizontalGridId: horizontalGridId,
                      toBottom: false,
                    );
              },
              title: 'Move up',
              iconWidget: SvgPicture.asset(
                FeatureIcons.arrowUp,
                height: 20,
                width: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
              itemTheme: PullDownMenuItemTheme(
                textStyle: textStyle,
              ),
            ),
            PullDownMenuItem(
              onTap: () {
                context.read<WriteSmartWidgetCubit>().moveComponent(
                      componentId: currentComponent.id,
                      horizontalGridId: horizontalGridId,
                      toBottom: true,
                    );
              },
              title: 'Move down',
              iconWidget: SvgPicture.asset(
                FeatureIcons.arrowDown,
                height: 20,
                width: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
              itemTheme: PullDownMenuItemTheme(
                textStyle: textStyle,
              ),
            ),
            PullDownMenuItem(
              onTap: () {
                context.read<WriteSmartWidgetCubit>().deleteComponent(
                      componentId: currentComponent.id,
                      horizontalGridId: horizontalGridId,
                    );
              },
              title: 'Delete',
              isDestructive: true,
              iconWidget: SvgPicture.asset(
                FeatureIcons.trash,
                height: 20,
                width: 20,
                colorFilter: ColorFilter.mode(
                  kRed,
                  BlendMode.srcIn,
                ),
              ),
              itemTheme: PullDownMenuItemTheme(
                textStyle: textStyle,
              ),
            ),
          ]
        ];
      },
      buttonBuilder: (context, showMenu) => SmallRectangularButton(
        backgroundColor: backgroundColor,
        onClick: showMenu,
        icon: FeatureIcons.more,
      ),
    );
  }
}

class SmallRectangularButton extends StatelessWidget {
  const SmallRectangularButton({
    Key? key,
    required this.backgroundColor,
    required this.icon,
    required this.onClick,
    this.turns,
  }) : super(key: key);

  final Color? backgroundColor;
  final String icon;
  final int? turns;
  final Function() onClick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 8,
          horizontal: kDefaultPadding / 3,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).primaryColorLight,
          borderRadius: BorderRadius.circular(kDefaultPadding / 4),
        ),
        child: RotatedBox(
          quarterTurns: turns ?? 1,
          child: SvgPicture.asset(
            icon,
            width: 15,
            height: 15,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
