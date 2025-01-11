// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:yakihonne/blocs/write_smart_widget_cubit/write_smart_widget_cubit.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';

class SmartWidgetLayout extends StatelessWidget {
  const SmartWidgetLayout({
    Key? key,
    required this.onDismiss,
  }) : super(key: key);

  final Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
        builder: (context, state) {
          final grids = state.smartWidgetContainer.grids.values.toList();

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Layout',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.w800,
                              color: kOrangeContrasted,
                            ),
                      ),
                    ),
                    RotatedBox(
                      quarterTurns: 1,
                      child: CustomIconButton(
                        onClicked: onDismiss,
                        icon: FeatureIcons.arrowUp,
                        size: 15,
                        vd: -3,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                Expanded(
                  child: ScrollShadow(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: ListView.separated(
                      separatorBuilder: (context, index) => SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                      itemBuilder: (context, index) {
                        final grid = grids[index];
                        final components = [
                          ...grid.leftSide.values.toList(),
                          ...grid.rightSide.values.toList()
                        ];

                        return Column(
                          children: [
                            LayoutTreeComponent(
                              smartWidgetComponent: grid,
                              borderColor:
                                  state.smartWidgetContainer.highlightedGrid ==
                                          grid.id
                                      ? Theme.of(context).primaryColorDark
                                      : kDimGrey.withValues(alpha: 0.5),
                              onClicked: () {},
                              onDelete: () {
                                context
                                    .read<WriteSmartWidgetCubit>()
                                    .deleteComponent(componentId: grid.id);
                              },
                            ),
                            SizedBox(
                              height: kDefaultPadding / 4,
                            ),
                            ListView.separated(
                              primary: false,
                              shrinkWrap: true,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(
                                height: kDefaultPadding / 4,
                              ),
                              padding:
                                  const EdgeInsets.only(left: kDefaultPadding),
                              itemBuilder: (context, index) {
                                final component = components[index];

                                return LayoutTreeComponent(
                                  borderColor: state.smartWidgetContainer
                                              .highlightedComponent ==
                                          component.id
                                      ? kOrangeContrasted
                                      : kDimGrey.withValues(alpha: 0.5),
                                  smartWidgetComponent: component,
                                  onClicked: () {
                                    context
                                        .read<WriteSmartWidgetCubit>()
                                        .setHighlightedComponents(
                                          gridId: grid.id,
                                          componentId: component.id,
                                        );
                                    onDismiss.call();
                                  },
                                  onDelete: () {
                                    context
                                        .read<WriteSmartWidgetCubit>()
                                        .deleteComponent(
                                          componentId: component.id,
                                          horizontalGridId: grid.id,
                                        );
                                  },
                                );
                              },
                              itemCount: components.length,
                            )
                          ],
                        );
                      },
                      itemCount: grids.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class LayoutTreeComponent extends StatelessWidget {
  const LayoutTreeComponent({
    Key? key,
    required this.borderColor,
    required this.smartWidgetComponent,
    required this.onClicked,
    required this.onDelete,
  }) : super(key: key);

  final Color borderColor;
  final SmartWidgetComponent smartWidgetComponent;
  final Function() onClicked;
  final Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final props = getProps();

    return GestureDetector(
      onTap: onClicked,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: kTransparent,
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 3,
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              props[0],
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Text(
                props[1],
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            CustomIconButton(
              onClicked: onDelete,
              icon: FeatureIcons.trash,
              size: 20,
              backgroundColor: kTransparent,
              vd: -4,
            ),
          ],
        ),
      ),
    );
  }

  List<String> getProps() {
    String icon = '';
    String title = '';

    if (smartWidgetComponent is SmartWidgetButton) {
      icon = FeatureIcons.button;
      title = 'Button';
    } else if (smartWidgetComponent is SmartWidgetGrid) {
      icon = FeatureIcons.layout1;
      title = 'Container';
    } else if (smartWidgetComponent is SmartWidgetImage) {
      icon = FeatureIcons.image;
      title = 'Image';
    } else if (smartWidgetComponent is SmartWidgetText) {
      icon = FeatureIcons.insertText;
      title = 'Text';
    } else if (smartWidgetComponent is SmartWidgetVideo) {
      icon = FeatureIcons.videoOcta;
      title = 'Video';
    } else {
      icon = FeatureIcons.polls;
      title = 'Zap poll';
    }

    return [icon, title];
  }
}
