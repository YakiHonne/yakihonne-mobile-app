// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:uuid/uuid.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/write_video_view/widgets/video_content.dart';

class FrameComponents extends StatelessWidget {
  const FrameComponents({
    Key? key,
    required this.onFrameComponentSelected,
    required this.enableForbiddenItem,
    required this.parentId,
  }) : super(key: key);

  final Function(SmartWidgetComponent) onFrameComponentSelected;
  final bool enableForbiddenItem;
  final String parentId;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Container(
      width: isTablet ? 50.w : double.infinity,
      margin: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Pick your component",
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            'Select the component at convience and edit it.',
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: VideoPickChoice(
                    onClicked: () {
                      final text = SmartWidgetText(
                        id: Uuid().v4(),
                        text: 'Text',
                        textSize: TextSize.Regular,
                        textWeight: TextWeight.Regular,
                        textColor: Theme.of(context).primaryColorDark.toHex(),
                      );

                      onFrameComponentSelected.call(text);
                    },
                    icon: FeatureIcons.insertText,
                    title: 'Text',
                  ),
                ),
                VerticalDivider(
                  indent: kDefaultPadding / 2,
                  endIndent: kDefaultPadding / 2,
                ),
                Expanded(
                  child: VideoPickChoice(
                    onClicked: () {
                      onFrameComponentSelected.call(
                        SmartWidgetImage(
                          id: Uuid().v4(),
                          url: '',
                          aspectRatio: '16:9',
                        ),
                      );
                    },
                    icon: FeatureIcons.imageAttachment,
                    title: 'Image',
                  ),
                ),
                VerticalDivider(
                  indent: kDefaultPadding / 2,
                  endIndent: kDefaultPadding / 2,
                ),
                Expanded(
                  child: VideoPickChoice(
                    onClicked: () {
                      onFrameComponentSelected.call(
                        SmartWidgetButton(
                          id: Uuid().v4(),
                          pubkey: '',
                          text: 'Button',
                          type: SmartWidgetButtonType.Regular,
                          url: '',
                          textColor: kWhite.toHex(),
                          buttonColor: kPurple.toHex(),
                        ),
                      );
                    },
                    icon: FeatureIcons.button,
                    title: 'Button',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: enableForbiddenItem ? 1 : 0.5,
                    child: VideoPickChoice(
                      onClicked: () {
                        if (enableForbiddenItem) {
                          onFrameComponentSelected.call(
                            SmartWidgetVideo(
                              id: Uuid().v4(),
                              url: '',
                            ),
                          );
                        } else {
                          BotToastUtils.showWarning(
                            'Monolayout is required',
                          );
                        }
                      },
                      icon: FeatureIcons.videoOcta,
                      title: 'Video',
                    ),
                  ),
                ),
                VerticalDivider(
                  indent: kDefaultPadding / 2,
                  endIndent: kDefaultPadding / 2,
                ),
                Expanded(
                  child: Opacity(
                    opacity: enableForbiddenItem ? 1 : 0.5,
                    child: VideoPickChoice(
                      onClicked: () {
                        if (enableForbiddenItem) {
                          onFrameComponentSelected.call(
                            SmartWidgetZapPoll(
                              id: Uuid().v4(),
                              content: '',
                              optionBackgroundColor: Theme.of(context)
                                  .scaffoldBackgroundColor
                                  .toHex(),
                              optionForegroundColor: kOrange.toHex(),
                              optionTextColor:
                                  Theme.of(context).primaryColorDark.toHex(),
                              contentTextColor:
                                  Theme.of(context).primaryColorDark.toHex(),
                            ),
                          );
                        } else {
                          BotToastUtils.showWarning(
                            'Monolayout is required',
                          );
                        }
                      },
                      icon: FeatureIcons.polls,
                      title: 'Zap poll',
                    ),
                  ),
                ),
                VerticalDivider(
                  indent: kDefaultPadding / 2,
                  endIndent: kDefaultPadding / 2,
                  color: kTransparent,
                ),
                Expanded(
                  child: SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
