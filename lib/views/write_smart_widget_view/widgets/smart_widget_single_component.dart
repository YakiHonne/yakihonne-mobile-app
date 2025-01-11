import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/write_smart_widget_cubit/write_smart_widget_cubit.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/polls_view/polls_view.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/link_previewer.dart';
import 'package:yakihonne/views/write_smart_widget_view/widgets/smart_widget_pulldown_button.dart';

class SmartWidgetSingleComponent extends StatelessWidget {
  const SmartWidgetSingleComponent({
    Key? key,
    required this.smartWidgetComponent,
    required this.gridId,
    required this.toggleView,
    required this.menuDisplayIds,
    required this.onAddMenuElements,
    required this.onRemoveMenuElements,
  }) : super(key: key);

  final SmartWidgetComponent smartWidgetComponent;
  final bool toggleView;
  final String gridId;
  final List<String> menuDisplayIds;
  final Function(List<String>) onAddMenuElements;
  final Function(List<String>) onRemoveMenuElements;

  @override
  Widget build(BuildContext context) {
    if (smartWidgetComponent is SmartWidgetText) {
      final textComponent = smartWidgetComponent as SmartWidgetText;
      final widget = Text(
        textComponent.text,
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              fontSize: getTextSize(
                textComponent.textSize ?? TextSize.Regular,
                context,
              ),
              fontWeight: textComponent.textWeight == TextWeight.Bold
                  ? FontWeight.w800
                  : FontWeight.w400,
              color: textComponent.textColor != null
                  ? getColorFromHex(textComponent.textColor!)
                  : null,
            ),
      );

      final fWidget = getWidget(
        toggleView: toggleView,
        widget: widget,
        component: smartWidgetComponent,
        context: context,
      );

      return fWidget;
    } else if (smartWidgetComponent is SmartWidgetButton) {
      final buttonComponent = smartWidgetComponent as SmartWidgetButton;
      final props = getSmartWidgetButtonProps(buttonComponent.type);

      final widget = TextButton(
        onPressed: null,
        style: TextButton.styleFrom(
          backgroundColor: props.isNotEmpty
              ? getColorFromHex(props['color'])
              : getColorFromHex(buttonComponent.buttonColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (buttonComponent.type != SmartWidgetButtonType.Regular &&
                buttonComponent.type != SmartWidgetButtonType.Zap) ...[
              Builder(
                builder: (context) {
                  return SvgPicture.asset(
                    props['icon'],
                    height: 20,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      kWhite,
                      BlendMode.srcIn,
                    ),
                  );
                },
              ),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
            ],
            Flexible(
              child: Text(
                buttonComponent.text,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: getColorFromHex(buttonComponent.textColor),
                    ),
              ),
            ),
          ],
        ),
      );

      final fWidget = getWidget(
        toggleView: toggleView,
        widget: widget,
        component: buttonComponent,
        context: context,
      );

      return fWidget;
    } else if (smartWidgetComponent is SmartWidgetZapPoll) {
      final zapPollComponent = smartWidgetComponent as SmartWidgetZapPoll;
      final poll = zapPollComponent.getPollModel();

      final widget = poll == null && !toggleView
          ? Container(
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              ),
              alignment: Alignment.center,
              child: Text(
                'Edit to add zap poll',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            )
          : poll == null
              ? SizedBox.shrink()
              : Builder(
                  builder: (context) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        linkifiedText(
                          context: context,
                          text: poll.content.trim(),
                          color: getColorFromHex(
                            zapPollComponent.contentTextColor,
                          ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                        Text(
                          'Options',
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: getColorFromHex(
                                      zapPollComponent.contentTextColor,
                                    ),
                                  ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                        ...poll.options
                            .map(
                              (e) => PollOptionContainer(
                                pollOption: e,
                                displayResults: false,
                                onClick: () {},
                                selfVote: false,
                                total: 0,
                                val: 0,
                                backgroundColor: getColorFromHex(
                                  zapPollComponent.optionBackgroundColor,
                                ),
                                textColor: getColorFromHex(
                                  zapPollComponent.optionTextColor,
                                ),
                                fillColor: getColorFromHex(
                                  zapPollComponent.optionForegroundColor,
                                ),
                              ),
                            )
                            .toList()
                      ],
                    );
                  },
                );

      final fWidget = getWidget(
        toggleView: toggleView,
        widget: widget,
        component: zapPollComponent,
        context: context,
      );

      return fWidget;
    } else if (smartWidgetComponent is SmartWidgetImage) {
      final imageComponent = smartWidgetComponent as SmartWidgetImage;

      final widget = ClipRRect(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        child: AspectRatio(
          aspectRatio: imageComponent.aspectRatio.getAspectRatio(),
          child: imageComponent.url.isEmpty
              ? NoImage2PlaceHolder(
                  icon: FeatureIcons.image,
                )
              : CachedNetworkImage(
                  imageUrl: imageComponent.url,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => NoImagePlaceHolder(),
                ),
        ),
      );

      return getWidget(
        toggleView: toggleView,
        widget: widget,
        component: imageComponent,
        context: context,
      );
    } else if (smartWidgetComponent is SmartWidgetVideo) {
      final videoComponent = smartWidgetComponent as SmartWidgetVideo;

      final widget = videoComponent.url.isEmpty
          ? AspectRatio(
              aspectRatio: 16 / 9,
              child: NoImage2PlaceHolder(
                icon: FeatureIcons.videoOcta,
              ),
            )
          : CustomVideoPlayer(
              link: videoComponent.url,
              removePadding: true,
            );

      return getWidget(
        toggleView: toggleView,
        widget: widget,
        component: videoComponent,
        context: context,
      );
    } else if (smartWidgetComponent is SmartWidgetContainer) {
      final frameContainer = smartWidgetComponent as SmartWidgetContainer;

      final widget = AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: frameContainer.backgroundHex != null
              ? getColorFromHex(frameContainer.backgroundHex!)
              : Theme.of(context).primaryColorLight,
          border: frameContainer.borderColorHex != null
              ? Border.all(
                  color: getColorFromHex(frameContainer.borderColorHex!) ??
                      Theme.of(context).scaffoldBackgroundColor,
                )
              : null,
        ),
      );

      return getWidget(
        toggleView: toggleView,
        widget: widget,
        component: frameContainer,
        context: context,
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget getWidget({
    required bool toggleView,
    required Widget widget,
    required SmartWidgetComponent component,
    required BuildContext context,
  }) {
    if (toggleView) {
      return widget;
    } else {
      return BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
        builder: (context, state) {
          final isSelected =
              state.smartWidgetContainer.highlightedComponent == component.id;

          return GestureDetector(
            onTap: () {
              context.read<WriteSmartWidgetCubit>().setHighlightedComponents(
                    componentId: component.id,
                    gridId: gridId,
                  );
            },
            behavior: HitTestBehavior.translucent,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DottedBorder(
                    color:
                        isSelected ? kOrange : kDimGrey.withValues(alpha: 0.5),
                    strokeCap: StrokeCap.round,
                    borderType: BorderType.RRect,
                    dashPattern: [4],
                    strokeWidth: 0.5,
                    radius: Radius.circular(kDefaultPadding / 3),
                    padding: const EdgeInsets.all(kDefaultPadding / 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: widget,
                    ),
                  ),
                  if (isSelected) ...[
                    SizedBox(height: kDefaultPadding / 4),
                    Center(
                      child: FrameComponentPulldownButton(
                        isFirstComponent: false,
                        currentComponent: component,
                        horizontalGridId: gridId,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      );
    }
  }
}
