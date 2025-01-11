// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_container.dart';

class SmartWidgetDisplay extends StatelessWidget {
  const SmartWidgetDisplay({
    Key? key,
    required this.smartWidgetModel,
  }) : super(key: key);

  final SmartWidgetModel smartWidgetModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: 70.h,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        color: Theme.of(context).primaryColorLight,
      ),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      margin: const EdgeInsets.all(kDefaultPadding / 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    smartWidgetModel.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                CustomIconButton(
                  onClicked: () {
                    Navigator.pop(context);
                  },
                  icon: FeatureIcons.closeRaw,
                  size: 20,
                  vd: -2,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          SingleChildScrollView(
            child: smartWidgetModel.container == null
                ? SizedBox()
                : SmartWidget(
                    smartWidgetContainer: smartWidgetModel.container!,
                  ),
          ),
        ],
      ),
    );
  }
}
