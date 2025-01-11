// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:convert/src/hex.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/single_event_cubit/single_event_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/self_smart_widgets_view/widgets/self_smart_widget_container.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_container.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/write_smart_widget_view/widgets/smart_widget_pulldown_button.dart';

class SmartWidgetChecker extends HookWidget {
  static const routeName = '/smartWidgetCheckerView';
  static Route route(RouteSettings settings) {
    final items = settings.arguments as List?;

    return CupertinoPageRoute(
      builder: (_) => SmartWidgetChecker(
        naddr: items?[0] as String?,
        swm: items?[1] as SmartWidgetModel?,
      ),
    );
  }

  const SmartWidgetChecker({
    Key? key,
    this.naddr,
    this.swm,
  }) : super(key: key);

  final String? naddr;
  final SmartWidgetModel? swm;

  @override
  Widget build(BuildContext context) {
    final naddrTextEditingController = useTextEditingController(text: naddr);
    final naddNotifier = useState<String>(naddr ?? '');
    final isLayoutToggled = useState(false);
    final swmNotifier = useState(swm);
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final _startX = useState(0.0);
    final timer = useState<Timer?>(null);

    final searchFunc = useCallback(
      (String naddr) {
        if (timer.value != null) {
          timer.value!.cancel();
        }

        if (naddr.trim().isEmpty) {
          swmNotifier.value = null;
          isLayoutToggled.value = false;
          return;
        }

        timer.value = Timer(
          Duration(seconds: 1),
          () async {
            try {
              final nostrDecode = Nip19.decodeShareableEntity(naddr);
              final hexCode = hex.decode(nostrDecode['special']);
              final special = String.fromCharCodes(hexCode);
              final ev = await singleEventCubit.getEvenById(
                id: special,
                isIdentifier: true,
                kinds: [EventKind.SMART_WIDGET],
              );

              if (ev != null && ev.kind == EventKind.SMART_WIDGET) {
                swmNotifier.value = SmartWidgetModel.fromEvent(ev);
              } else {
                swmNotifier.value = null;
              }
            } catch (e) {
              lg.i(e);
              swmNotifier.value = null;
            }

            isLayoutToggled.value = false;
          },
        );
      },
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Smart widget checker',
        notElevated: true,
      ),
      body: Column(
        children: [
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
            child: TextFormField(
              controller: naddrTextEditingController,
              decoration: InputDecoration(
                labelText: 'naddr',
                prefixIcon: SizedBox(
                  width: 10,
                  height: 10,
                  child: Center(
                    child: SvgPicture.asset(
                      FeatureIcons.search,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).primaryColorDark,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                suffixIcon: CustomIconButton(
                  onClicked: () {
                    naddrTextEditingController.clear();
                    naddNotifier.value = '';
                    isLayoutToggled.value = false;
                    swmNotifier.value = null;
                  },
                  icon: FeatureIcons.closeRaw,
                  size: 20,
                  vd: -4,
                  backgroundColor: Theme.of(context).primaryColorLight,
                ),
              ),
              onChanged: (naddrVal) {
                naddNotifier.value = naddrVal;
                isLayoutToggled.value = false;
                searchFunc.call(naddrVal);
              },
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Expanded(
            child: BlocBuilder<SingleEventCubit, SingleEventState>(
              builder: (context, state) {
                return isTablet
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: isLayoutToggled.value
                                  ? () => isLayoutToggled.value = false
                                  : null,
                              child: AbsorbPointer(
                                absorbing: isLayoutToggled.value,
                                child: WidgetCheckerComponent(
                                  naddNotifier: naddNotifier.value,
                                  isTablet: isTablet,
                                  swm: swmNotifier.value,
                                  isLayoutToggled: isLayoutToggled.value,
                                  onToggle: () {
                                    isLayoutToggled.value = true;
                                  },
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Builder(builder: (context) {
                              return swmNotifier.value != null
                                  ? WidgetCheckerLayout(
                                      smartWidgetModel: swmNotifier.value!,
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(
                                          kDefaultPadding / 2),
                                      margin: const EdgeInsets.only(
                                        right: kDefaultPadding,
                                        top: kDefaultPadding * 2,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          kDefaultPadding / 2,
                                        ),
                                        color:
                                            Theme.of(context).primaryColorLight,
                                      ),
                                      child: EmptyList(
                                        description:
                                            'No components can be displayed',
                                        icon: FeatureIcons.swChecker,
                                      ),
                                    );
                            }),
                          ),
                        ],
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
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
                                  right: isLayoutToggled.value ? 90.w : 0.0,
                                  height: constraints.maxHeight,
                                  width: constraints.maxWidth,
                                  child: GestureDetector(
                                    onTap: isLayoutToggled.value
                                        ? () => isLayoutToggled.value = false
                                        : null,
                                    child: AbsorbPointer(
                                      absorbing: isLayoutToggled.value,
                                      child: WidgetCheckerComponent(
                                        naddNotifier: naddNotifier.value,
                                        isTablet: isTablet,
                                        swm: swmNotifier.value,
                                        isLayoutToggled: isLayoutToggled.value,
                                        onToggle: () {
                                          isLayoutToggled.value = true;
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 300),
                                  left: isLayoutToggled.value ? 10.w : 100.w,
                                  height: constraints.maxHeight,
                                  curve: Curves.easeInOut,
                                  width: 88.w,
                                  child: swmNotifier.value != null
                                      ? WidgetCheckerLayout(
                                          smartWidgetModel: swmNotifier.value!,
                                        )
                                      : Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(
                                                kDefaultPadding / 2,
                                              ),
                                              alignment: Alignment.topCenter,
                                              margin: const EdgeInsets.only(
                                                right: kDefaultPadding,
                                                top: kDefaultPadding * 2,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  kDefaultPadding / 2,
                                                ),
                                                color: Theme.of(context)
                                                    .primaryColorLight,
                                              ),
                                              child: EmptyList(
                                                description:
                                                    'No components can be displayed',
                                                icon: FeatureIcons.swChecker,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WidgetCheckerLayout extends StatelessWidget {
  const WidgetCheckerLayout({
    Key? key,
    required this.smartWidgetModel,
  }) : super(key: key);

  final SmartWidgetModel smartWidgetModel;

  @override
  Widget build(BuildContext context) {
    List<Widget> containerProperties = [];
    List<Widget> grids = [];
    final map = smartWidgetModel.dataMap;

    for (final item in map.entries) {
      containerProperties.add(
        WidgetCheckerRow(
          mapKey: item.key.toString(),
          mapValue: item.value.toString(),
          mapStatus: getPropertyStatus(item, 'container', null),
          color: kOrangeContrasted,
        ),
      );
    }

    if (map.containsKey('components')) {
      final entry = MapEntry('components', map['components']);

      final status = getPropertyStatus(entry, 'container', null);

      if (status == PropertyStatus.valid) {
        for (final item in entry.value) {
          if (item is Map<String, dynamic>) {
            grids.add(
              Divider(
                indent: kDefaultPadding,
                thickness: 0.5,
                height: kDefaultPadding,
              ),
            );

            grids.add(
              Padding(
                padding: const EdgeInsets.only(
                  left: kDefaultPadding / 1.5,
                ),
                child: WidgetCheckerGrid(grid: item),
              ),
            );
          }
        }
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Metadata',
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: kDimGrey,
                  ),
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 3,
          ),
          Container(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              color: Theme.of(context).primaryColorLight,
            ),
            width: double.infinity,
            child: Column(
              children: [
                getMetadataRow(
                  content: smartWidgetModel.title,
                  title: 'Title',
                  context: context,
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                getMetadataRow(
                  content: smartWidgetModel.summary.isNotEmpty
                      ? smartWidgetModel.summary
                      : 'No description',
                  title: 'Description',
                  context: context,
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                getMetadataRow(
                  content: dateFormat3.format(smartWidgetModel.createdAt),
                  title: 'Created at',
                  context: context,
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                getMetadataRow(
                  content: smartWidgetModel.identifier,
                  title: 'Identifier (#d)',
                  context: context,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 1.5,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Widget',
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: kDimGrey,
                  ),
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 3,
          ),
          Container(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              color: Theme.of(context).primaryColorLight,
            ),
            width: double.infinity,
            child: Column(
              children: [
                ...containerProperties,
                ...grids,
              ],
            ),
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
        ],
      ),
    );
  }

  Row getMetadataRow({
    required String title,
    required String content,
    required BuildContext context,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: ',
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: kDimGrey,
              ),
        ),
        Expanded(
          child: Text(
            content,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(),
          ),
        ),
      ],
    );
  }
}

class WidgetCheckerGrid extends StatelessWidget {
  const WidgetCheckerGrid({
    Key? key,
    required this.grid,
  }) : super(key: key);

  final Map<String, dynamic> grid;

  @override
  Widget build(BuildContext context) {
    List<Widget> properties = [];

    for (final item in grid.entries) {
      final status = getPropertyStatus(item, 'grid', grid['layout']);

      properties.add(
        WidgetCheckerRow(
          mapKey: item.key.toString(),
          mapValue: item.value.toString(),
          mapStatus: status,
          color: kYellow,
        ),
      );

      if ((item.key == 'left_side' || item.key == 'right_side') &&
          status == PropertyStatus.valid) {
        if ((item.value as List?) != null) {
          for (final item in item.value) {
            if (item is Map<String, dynamic>) {
              try {
                properties.add(
                  WidgetColumnGrid(
                    map: item,
                    type: 'component',
                  ),
                );
              } catch (e, stack) {
                lg.i(stack);
              }
            }
          }
        }
      }
    }

    return Column(
      children: properties,
    );
  }
}

class WidgetColumnGrid extends StatelessWidget {
  const WidgetColumnGrid({
    Key? key,
    required this.map,
    required this.type,
  });

  final Map<String, dynamic> map;
  final String type;

  @override
  Widget build(BuildContext context) {
    List<Widget> properties = [];

    for (final item in map.entries) {
      final status = getPropertyStatus(item, type, map['layout']);

      properties.add(
        WidgetCheckerRow(
          mapKey: item.key.toString(),
          mapValue: item.value.toString(),
          mapStatus: status,
          color: kLightPurple,
        ),
      );

      if ((item.key == 'metadata') && status == PropertyStatus.valid) {
        final status = getPropertyStatus(item, type, null);
        final metadatas = <Widget>[];

        if (status == PropertyStatus.valid) {
          for (final (item2 as MapEntry<String, dynamic>)
              in item.value.entries) {
            metadatas.add(
              WidgetCheckerRow(
                mapKey: item2.key,
                mapValue: item2.value.toString(),
                color: kBlue,
                mapStatus: getPropertyStatus(
                  item2,
                  map['type'] ?? '',
                  map['type'] == 'button' ? item.value['type'] : map['layout'],
                ),
              ),
            );
          }

          if (metadatas.isNotEmpty) {
            properties.add(
              Padding(
                padding: const EdgeInsets.only(
                  left: kDefaultPadding / 1.5,
                ),
                child: Column(
                  children: metadatas,
                ),
              ),
            );
          }
        }
      }
    }

    return Padding(
      padding: type == 'component'
          ? const EdgeInsets.only(
              left: kDefaultPadding / 1.5,
            )
          : EdgeInsets.zero,
      child: Column(
        children: [...properties],
      ),
    );
  }
}

class WidgetCheckerRow extends StatelessWidget {
  const WidgetCheckerRow({
    Key? key,
    required this.mapKey,
    required this.mapValue,
    required this.mapStatus,
    required this.color,
  }) : super(key: key);

  final String mapKey;
  final String mapValue;
  final PropertyStatus mapStatus;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isEmpty = mapValue.isEmpty || mapValue == 'null';
    final icon = addIcon(mapKey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 8),
      child: Row(
        children: [
          Text(
            '${mapKey} ',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: kDimGrey,
                ),
          ),
          if (icon)
            Expanded(
              child: Row(
                children: [
                  if (mapStatus == PropertyStatus.valid &&
                      mapValue.isNotEmpty &&
                      mapValue != '[]' &&
                      mapValue != 'null')
                    Text(
                      '↴',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            )
          else
            Expanded(
              child: Text(
                isEmpty ? 'N/A' : mapValue,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: isEmpty
                          ? kOrange
                          : Theme.of(context).primaryColorDark,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(
            width: kDefaultPadding / 3,
          ),
          SvgPicture.asset(
            mapStatus == PropertyStatus.valid
                ? FeatureIcons.widgetCorrect
                : mapStatus == PropertyStatus.invalid
                    ? FeatureIcons.widgetInfo
                    : FeatureIcons.widgetWrong,
            width: 17,
            height: 17,
          )
        ],
      ),
    );
  }

  bool addIcon(String keyUsed) {
    return keyUsed == 'components' ||
        keyUsed == 'metadata' ||
        keyUsed == 'left_side' ||
        keyUsed == 'right_side';
  }
}

class WidgetCheckerComponent extends HookWidget {
  const WidgetCheckerComponent({
    Key? key,
    required this.naddNotifier,
    required this.onToggle,
    required this.isLayoutToggled,
    required this.isTablet,
    this.swm,
  }) : super(key: key);

  final String naddNotifier;
  final Function() onToggle;
  final SmartWidgetModel? swm;
  final bool isLayoutToggled;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      children: [
        Builder(
          builder: (context) {
            if (naddNotifier.isEmpty) {
              return Column(
                children: [
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Image.asset(
                    Images.smartWidget,
                    width: 50.w,
                  ),
                  Text(
                    "Smart widget checker",
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: Theme.of(context).primaryColorDark,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Text(
                    "Enter a smart widget naddr to check for its validity.",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            } else {
              if (naddNotifier.startsWith('naddr')) {
                if (swm == null) {
                  return EmptyList(
                    description:
                        'Could not find smart widget with such address',
                    icon: FeatureIcons.smartWidget,
                  );
                } else {
                  return Column(
                    children: [
                      if (!isTablet) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: SmallRectangularButton(
                            onClick: onToggle,
                            turns: 0,
                            icon: FeatureIcons.layers,
                            backgroundColor: null,
                          ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 4,
                        ),
                      ],
                      if (swm!.container == null)
                        NoSmartWidgetContainer()
                      else
                        SmartWidget(
                          smartWidgetContainer: swm!.container!,
                        ),
                    ],
                  );
                }
              } else {
                return EmptyList(
                  description: 'Could not find smart widget with such address',
                  icon: FeatureIcons.smartWidget,
                );
              }
            }
          },
        ),
        const SizedBox(
          height: kBottomNavigationBarHeight,
        ),
      ],
    );
  }
}
