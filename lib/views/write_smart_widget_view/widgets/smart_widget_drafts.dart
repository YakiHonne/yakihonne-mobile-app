// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/self_smart_widgets_view/widgets/self_smart_widget_container.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_container.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';

class SmartWidgetsDrafts extends HookWidget {
  const SmartWidgetsDrafts(
      {Key? key,
      required this.onSmartWidgetDraftSelected,
      required this.onSmartWidgetPublished,
      w})
      : super(key: key);

  final Function(SWAutoSaveModel) onSmartWidgetDraftSelected;
  final Function(SWAutoSaveModel) onSmartWidgetPublished;

  @override
  Widget build(BuildContext context) {
    final draftsList =
        useState<Map<String, SWAutoSaveModel>>(nostrRepository.swAutoSave);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(kDefaultPadding),
          topRight: Radius.circular(kDefaultPadding),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.40,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              ModalBottomSheetHandle(),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              Text(
                'Smart widgets drafts',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Divider(
                color: kDimGrey.withValues(alpha: 0.2),
                indent: kDefaultPadding / 2,
                endIndent: kDefaultPadding / 2,
                height: 0,
              ),
              Expanded(
                child: draftsList.value.isEmpty
                    ? EmptyList(
                        description: 'No smart widgets drafts can be found',
                        icon: FeatureIcons.smartWidget,
                      )
                    : Builder(
                        builder: (context) {
                          final list = draftsList.value.values.toList();

                          return ListView.separated(
                            controller: scrollController,
                            itemCount: list.length,
                            padding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding / 2,
                              vertical: kDefaultPadding * 1.5,
                            ),
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                              height: kDefaultPadding / 2,
                            ),
                            itemBuilder: (context, index) {
                              final sw = list[index];
                              final container = SmartWidgetContainer
                                  .smartWidgetContrainerfromMap(
                                sw.content,
                              );

                              return Container(
                                child: Column(
                                  children: [
                                    container == null
                                        ? NoSmartWidgetContainer()
                                        : SmartWidget(
                                            smartWidgetContainer: container,
                                            disableWidget: true,
                                          ),
                                    const SizedBox(
                                      height: kDefaultPadding / 2,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            onSmartWidgetPublished.call(sw);
                                          },
                                          child: Text(
                                            'Publish',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .primaryColorDark),
                                          ),
                                          style: TextButton.styleFrom(
                                            visualDensity: VisualDensity(
                                              vertical: -0.5,
                                            ),
                                            backgroundColor: Theme.of(context)
                                                .primaryColorLight,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: kDefaultPadding / 4,
                                        ),
                                        CustomIconButton(
                                          onClicked: () {
                                            onSmartWidgetDraftSelected.call(sw);
                                            Navigator.pop(context);
                                          },
                                          icon: FeatureIcons.editWidget,
                                          size: 20,
                                          backgroundColor: Theme.of(context)
                                              .primaryColorLight,
                                        ),
                                        const SizedBox(
                                          width: kDefaultPadding / 4,
                                        ),
                                        CustomIconButton(
                                          onClicked: () {
                                            nostrRepository
                                                .deleteAutoSave(sw.id);
                                            draftsList.value.remove(sw.id);
                                            draftsList.value = Map<String,
                                                SWAutoSaveModel>.from(
                                              draftsList.value..remove(sw.id),
                                            );
                                          },
                                          icon: FeatureIcons.trash,
                                          size: 20,
                                          backgroundColor: Theme.of(context)
                                              .primaryColorLight,
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
