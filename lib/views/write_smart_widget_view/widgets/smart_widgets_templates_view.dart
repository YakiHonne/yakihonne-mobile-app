// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_container.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';

class SmartWidgetTemplatesView extends StatelessWidget {
  const SmartWidgetTemplatesView({
    Key? key,
    required this.onSmartWidgetSelected,
  }) : super(key: key);

  final Function(SmartWidgetContainer) onSmartWidgetSelected;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

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
        builder: (context, scrollController) => Column(
          children: [
            ModalBottomSheetHandle(),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                children: [
                  Text(
                    'Smart widgets templates',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  Divider(
                    color: kDimGrey.withValues(alpha: 0.2),
                    indent: kDefaultPadding / 2,
                    endIndent: kDefaultPadding / 2,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 4,
                  ),
                  ...nostrRepository.SmartWidgetTemplates.keys.map((e) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final templates =
                            nostrRepository.SmartWidgetTemplates[e]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            SizedBox(
                              width: kDefaultPadding * 3,
                              child: Divider(
                                thickness: 2,
                                height: kDefaultPadding / 8,
                                color: Theme.of(context).primaryColorDark,
                              ),
                            ),
                            templates.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                      top: kDefaultPadding / 2,
                                    ),
                                    child: Text(
                                      'No templates can be found in this category.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium!
                                          .copyWith(
                                            color: kDimGrey,
                                          ),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(
                                      top: kDefaultPadding / 2,
                                    ),
                                    child: SizedBox(
                                      width: constraints.maxWidth,
                                      height: (9 *
                                              constraints.maxWidth *
                                              (isTablet ? 0.5 : 0.7) /
                                              16) +
                                          45,
                                      child: ListView.separated(
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(
                                          width: kDefaultPadding / 1.5,
                                        ),
                                        scrollDirection: Axis.horizontal,
                                        itemBuilder: (context, index) {
                                          final template = templates[index];

                                          return SWTemplateContainer(
                                            template: template,
                                            constraints: constraints,
                                            onClicked: () {
                                              showModalBottomSheet(
                                                context: context,
                                                builder: (_) {
                                                  return TemplateShowcase(
                                                    smartWidgetTemplate:
                                                        template,
                                                    onSmartWidgetSelected: () {
                                                      onSmartWidgetSelected
                                                          .call(
                                                        template
                                                            .smartWidgetContainer,
                                                      );

                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                    },
                                                  );
                                                },
                                                isScrollControlled: true,
                                                useRootNavigator: true,
                                                useSafeArea: true,
                                                elevation: 0,
                                                backgroundColor: Theme.of(
                                                        context)
                                                    .scaffoldBackgroundColor,
                                              );
                                            },
                                            onSmartWidgetSelected: () {
                                              onSmartWidgetSelected.call(
                                                  template
                                                      .smartWidgetContainer);
                                            },
                                          );
                                        },
                                        itemCount: templates.length,
                                      ),
                                    ),
                                  )
                          ],
                        );
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SWTemplateContainer extends StatelessWidget {
  const SWTemplateContainer({
    Key? key,
    required this.template,
    required this.constraints,
    required this.onSmartWidgetSelected,
    required this.onClicked,
  }) : super(key: key);

  final SmartWidgetTemplate template;
  final BoxConstraints constraints;
  final Function() onSmartWidgetSelected;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return GestureDetector(
      onTap: onClicked,
      child: SizedBox(
        width: constraints.maxWidth * (isTablet ? 0.5 : 0.7),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: template.thumbnail,
                    fit: BoxFit.cover,
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          kDefaultPadding,
                        ),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => NoImagePlaceHolder(),
                  ),
                  Positioned(
                    top: kDefaultPadding / 3,
                    right: kDefaultPadding / 3,
                    child: Row(
                      children: [
                        CustomIconButton(
                          onClicked: onClicked,
                          icon: FeatureIcons.informationRaw,
                          size: 10,
                          vd: -4,
                          iconColor: kWhite,
                          backgroundColor: Theme.of(context).primaryColorLight,
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 8,
                        ),
                        CustomIconButton(
                          onClicked: () {
                            onSmartWidgetSelected.call();
                            Navigator.pop(context);
                          },
                          icon: FeatureIcons.addRaw,
                          size: 10,
                          vd: -4,
                          backgroundColor: Theme.of(context).primaryColorLight,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Text(
              template.title,
              maxLines: 2,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class TemplateShowcase extends StatelessWidget {
  const TemplateShowcase({
    Key? key,
    required this.smartWidgetTemplate,
    required this.onSmartWidgetSelected,
  }) : super(key: key);

  final SmartWidgetTemplate smartWidgetTemplate;
  final Function() onSmartWidgetSelected;

  @override
  Widget build(BuildContext context) {
    final desc = smartWidgetTemplate.description.replaceAll(r'\n', '\n');

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
        initialChildSize: 0.90,
        minChildSize: 0.40,
        maxChildSize: 0.90,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              ModalBottomSheetHandle(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(kDefaultPadding / 2),
                  children: [
                    Text(
                      smartWidgetTemplate.title,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Text(
                      desc,
                      softWrap: true,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium!
                          .copyWith(color: kDimGrey),
                    ),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    SmartWidget(
                      smartWidgetContainer:
                          smartWidgetTemplate.smartWidgetContainer,
                      disableWidget: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    child: Text(
                      'Use template',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).primaryColorDark,
                          ),
                    ),
                    onPressed: onSmartWidgetSelected,
                    style: TextButton.styleFrom(
                      backgroundColor: kOrangeContrasted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
