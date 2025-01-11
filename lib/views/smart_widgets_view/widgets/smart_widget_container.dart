// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/string_inlineSpan.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/gallery_view/gallery_image_viewer.dart';
import 'package:yakihonne/views/gallery_view/multi_image_provider.dart';
import 'package:yakihonne/views/polls_view/polls_view.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/link_previewer.dart';
import 'package:yakihonne/views/zap_view/set_zaps_view.dart';

class SmartWidget extends StatelessWidget {
  const SmartWidget({
    Key? key,
    required this.smartWidgetContainer,
    this.backgroundColor,
    this.disableWidget,
  }) : super(key: key);

  final SmartWidgetContainer smartWidgetContainer;
  final Color? backgroundColor;
  final bool? disableWidget;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: disableWidget != null,
      child: Builder(
        builder: (context) {
          final grids = smartWidgetContainer.grids.values.toList();

          return Container(
            padding: EdgeInsets.all(kDefaultPadding / 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              color: smartWidgetContainer.backgroundHex != null &&
                      smartWidgetContainer.backgroundHex!.isNotEmpty &&
                      smartWidgetContainer.backgroundHex !=
                          Theme.of(context).primaryColorLight.toHex()
                  ? getColorFromHex(smartWidgetContainer.backgroundHex!)
                  : backgroundColor ?? Theme.of(context).primaryColorLight,
              border: smartWidgetContainer.borderColorHex != null &&
                      smartWidgetContainer.borderColorHex!.isNotEmpty
                  ? Border.all(
                      color: getColorFromHex(
                              smartWidgetContainer.borderColorHex!) ??
                          kTransparent,
                    )
                  : null,
            ),
            child: Builder(
              builder: (context) {
                List<Widget> widgets = [];

                for (int i = 0; i < grids.length; i++) {
                  final e = grids[i];

                  widgets.add(SmartWidgetGridUI(grid: e));
                  if (i < grids.length - 1) {
                    widgets.add(
                      SizedBox(
                        height: kDefaultPadding / 3,
                      ),
                    );
                  }
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widgets,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class SmartWidgetGridUI extends StatelessWidget {
  const SmartWidgetGridUI({
    Key? key,
    required this.grid,
  }) : super(key: key);

  final SmartWidgetGrid grid;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            flex: grid.getDivision(true),
            child: GridVerticalView(
              components: grid.leftSide,
              gridId: grid.id,
            ),
          ),
          if (grid.layout == 2) ...[
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            Expanded(
              flex: grid.getDivision(false),
              child: GridVerticalView(
                components: grid.rightSide,
                gridId: grid.id,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GridVerticalView extends StatelessWidget {
  const GridVerticalView({
    Key? key,
    required this.components,
    required this.gridId,
  }) : super(key: key);

  final Map<String, SmartWidgetComponent> components;
  final String gridId;

  @override
  Widget build(BuildContext context) {
    final widget = Builder(
      builder: (context) {
        List<Widget> widgets = [];
        final cs = components.values.toList();

        for (int i = 0; i < cs.length; i++) {
          final e = cs[i];

          widgets.add(
            SmartWidgetComponentUI(
              smartWidgetComponent: e,
              gridId: gridId,
            ),
          );
          if (i < cs.length - 1) {
            widgets.add(
              SizedBox(
                height: kDefaultPadding / 2,
              ),
            );
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: widgets,
        );
      },
    );

    return widget;
  }
}

class SmartWidgetComponentUI extends StatelessWidget {
  const SmartWidgetComponentUI({
    Key? key,
    required this.smartWidgetComponent,
    required this.gridId,
  }) : super(key: key);

  final SmartWidgetComponent smartWidgetComponent;
  final String gridId;

  @override
  Widget build(BuildContext context) {
    if (smartWidgetComponent is SmartWidgetText) {
      final textComponent = smartWidgetComponent as SmartWidgetText;
      final widget = linkifiedText(
        context: context,
        text: textComponent.text,
        disableVisualParsing: true,
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

      return widget;
    } else if (smartWidgetComponent is SmartWidgetButton) {
      final buttonComponent = smartWidgetComponent as SmartWidgetButton;
      final props = getSmartWidgetButtonProps(buttonComponent.type);

      final widget = TextButton(
        onPressed: () async {
          final usedUrl = buttonComponent.url.trim();

          if (buttonComponent.type == SmartWidgetButtonType.Zap &&
              usedUrl.isNotEmpty &&
              nostrRepository.usm?.pubKey != buttonComponent.pubkey) {
            if (usedUrl.toLowerCase().startsWith('lnbc')) {
              showModalBottomSheet(
                context: context,
                elevation: 0,
                builder: (_) {
                  return SetZapsView(
                    author: emptyUserModel.copyWith(
                      lud06: usedUrl,
                      lud16: usedUrl,
                      picturePlaceholder: getRandomPlaceholder(
                        input: usedUrl,
                        isPfp: true,
                      ),
                    ),
                    lnbc: usedUrl.trim(),
                    zapSplits: [],
                    isZapSplit: false,
                  );
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            } else if (emailRegExp.hasMatch(usedUrl) ||
                usedUrl.toLowerCase().startsWith('lnurl')) {
              UserModel user = emptyUserModel.copyWith(
                pubKey: buttonComponent.pubkey,
                lud06: usedUrl,
                lud16: usedUrl,
                picturePlaceholder: getRandomPlaceholder(
                  input: usedUrl,
                  isPfp: true,
                ),
              );

              if (buttonComponent.pubkey.isNotEmpty) {
                user = await authorsCubit
                        .getFutureAuthor(buttonComponent.pubkey) ??
                    user;
              }

              showModalBottomSheet(
                elevation: 0,
                context: context,
                builder: (_) {
                  return SetZapsView(
                    author: user,
                    zapSplits: [],
                    isZapSplit: false,
                  );
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            } else {
              BotToastUtils.showError('Invalid invoice or lightning address');
            }
          } else if (buttonComponent.type == SmartWidgetButtonType.Nostr &&
              Nip19.nip19regex.allMatches(usedUrl).isNotEmpty) {
            nostrRepository.mainCubit.forwardView(
              uriString: usedUrl,
              isNostrScheme: true,
              skipDelay: true,
            );
          } else if (urlRegExp.hasMatch(usedUrl)) {
            openWebPage(url: usedUrl);
          } else {
            BotToastUtils.showError('Unable to open url');
          }
        },
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

      return widget;
    } else if (smartWidgetComponent is SmartWidgetZapPoll) {
      final zapPollComponent = smartWidgetComponent as SmartWidgetZapPoll;
      final poll = zapPollComponent.getPollModel()!;

      final widget = Builder(
        builder: (context) {
          return PollContainer(
            poll: poll,
            includeUser: false,
            onTap: () {},
            contentColor: getColorFromHex(
              zapPollComponent.contentTextColor,
            ),
            optionBackgroundColor: getColorFromHex(
              zapPollComponent.optionBackgroundColor,
            ),
            optionTextColor: getColorFromHex(
              zapPollComponent.optionTextColor,
            ),
            optionForegroundColor: getColorFromHex(
              zapPollComponent.optionForegroundColor,
            ),
          );
        },
      );

      return widget;
    } else if (smartWidgetComponent is SmartWidgetImage) {
      final imageComponent = smartWidgetComponent as SmartWidgetImage;
      final usedUrl = imageComponent.url.trim();

      final widget = ClipRRect(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        child: AspectRatio(
          aspectRatio: imageComponent.aspectRatio.getAspectRatio(),
          child: usedUrl.isEmpty
              ? NoImage2PlaceHolder(
                  icon: FeatureIcons.image,
                )
              : GestureDetector(
                  onTap: () {
                    final imageProvider = CachedNetworkImageProvider(
                      usedUrl,
                    );

                    MultiImageProvider multiImageProvider = MultiImageProvider(
                      [imageProvider],
                      initialIndex: 0,
                    );

                    showImageViewerPager(
                      context,
                      multiImageProvider,
                      onDownload: shareImage,
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                    );
                  },
                  child: CachedNetworkImage(
                    imageUrl: usedUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => NoImagePlaceHolder(),
                  ),
                ),
        ),
      );

      return widget;
    } else if (smartWidgetComponent is SmartWidgetVideo) {
      final videoComponent = smartWidgetComponent as SmartWidgetVideo;
      final usedUrl = videoComponent.url.trim();

      final widget = usedUrl.isEmpty
          ? AspectRatio(
              aspectRatio: 16 / 9,
              child: NoImage2PlaceHolder(
                icon: FeatureIcons.videoOcta,
              ),
            )
          : CustomVideoPlayer(
              link: usedUrl,
              removePadding: true,
            );

      return widget;
    } else {
      return SizedBox.shrink();
    }
  }
}
