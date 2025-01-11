// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_container.dart';

class SelfSmartWidgetContainer extends StatelessWidget {
  const SelfSmartWidgetContainer({
    super.key,
    required this.smartWidgetModel,
    required this.onDelete,
    required this.onEditOrClone,
  });

  final SmartWidgetModel smartWidgetModel;
  final Function() onDelete;
  final Function(bool) onEditOrClone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        color: Theme.of(context).primaryColorLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            smartWidgetModel.title,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            smartWidgetModel.summary,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(
            height: kDefaultPadding / 1.5,
          ),
          if (smartWidgetModel.container != null)
            SmartWidget(
              smartWidgetContainer: smartWidgetModel.container!,
            )
          else
            NoSmartWidgetContainer(),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Row(
            children: [
              Expanded(
                child: CustomIconButton(
                  onClicked: () {
                    onEditOrClone.call(true);
                  },
                  icon: FeatureIcons.copy,
                  size: 20,
                  iconColor: Theme.of(context).primaryColorDark,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              Expanded(
                child: CustomIconButton(
                  onClicked: () {
                    onEditOrClone.call(false);
                  },
                  icon: FeatureIcons.article,
                  size: 20,
                  iconColor: Theme.of(context).primaryColorDark,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              Expanded(
                child: CustomIconButton(
                  onClicked: onDelete,
                  icon: FeatureIcons.trash,
                  size: 20,
                  iconColor: Theme.of(context).primaryColorDark,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NoSmartWidgetContainer extends StatelessWidget {
  const NoSmartWidgetContainer({
    Key? key,
    this.backgroundColor,
  }) : super(key: key);

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      ),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Text(
        'This smart widget does not follow the agreed on convention.',
        style: Theme.of(context).textTheme.labelMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
