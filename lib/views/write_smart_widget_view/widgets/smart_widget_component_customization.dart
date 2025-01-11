// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/write_smart_widget_cubit/write_smart_widget_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/wallet_balance_view/widgets/user_to_zap_view.dart';
import 'package:yakihonne/views/widgets/custom_drop_down.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/write_article_view/widgets/article_image_selector.dart';
import 'package:yakihonne/views/write_smart_widget_view/widgets/smart_widget_zap_polls_selection.dart';
import 'package:yakihonne/views/write_zap_poll_view/write_zap_poll_view.dart';

class FrameComponentCustomization extends HookWidget {
  const FrameComponentCustomization({
    Key? key,
    required this.frameComponent,
  }) : super(key: key);

  final SmartWidgetComponent frameComponent;

  @override
  Widget build(BuildContext context) {
    final c = useState(frameComponent);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(kDefaultPadding),
          topRight: Radius.circular(kDefaultPadding),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.70,
          minChildSize: 0.40,
          maxChildSize: 0.70,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                ModalBottomSheetHandle(),
                Expanded(
                  child: getSmartWidgetComponentWidget(
                    frameComponent,
                    scrollController,
                    (component) {
                      c.value = component;
                    },
                  ),
                ),
                SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 2,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Cancel',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(
                                      color: kWhite,
                                    ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: kRed,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 4,
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                final component = c.value;

                                final cp = canProceed(component);

                                if (!cp) {
                                  return;
                                }

                                context
                                    .read<WriteSmartWidgetCubit>()
                                    .updateComponent(component: c.value);

                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).primaryColorDark,
                              ),
                              child: Text(
                                'Update',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(
                                      color:
                                          Theme.of(context).primaryColorLight,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool canProceed(SmartWidgetComponent component) {
    if (component is SmartWidgetButton) {
      final url = component.url;
      if (component.type == SmartWidgetButtonType.Zap) {
        if (url.isNotEmpty &&
            (emailRegExp.hasMatch(url) ||
                url.toLowerCase().startsWith('lnbc') ||
                url.toLowerCase().startsWith('lnurl'))) {
          return true;
        } else {
          BotToastUtils.showError(
            'Make sure to set a valid invoice or lnurl',
          );

          return false;
        }
      } else {
        final reg = component.type == SmartWidgetButtonType.Youtube
            ? youtubeRegExp
            : component.type == SmartWidgetButtonType.Regular
                ? urlRegExp
                : component.type == SmartWidgetButtonType.Nostr
                    ? Nip19.nip19regex
                    : component.type == SmartWidgetButtonType.Discord
                        ? discordRegExp
                        : component.type == SmartWidgetButtonType.Telegram
                            ? telegramRegExp
                            : xRegExp;

        final matches = reg.allMatches(url);

        if (matches.isEmpty) {
          BotToastUtils.showError(
            'Make sure to add a valid url',
          );
          return false;
        } else {
          return true;
        }
      }
    }

    return true;
  }

  Widget getSmartWidgetComponentWidget(
    SmartWidgetComponent component,
    ScrollController controller,
    Function(SmartWidgetComponent) updateFrame,
  ) {
    if (component is SmartWidgetContainer) {
      return SmartWidgetContainerCustomization(
        frameContainer: component,
        controller: controller,
        updateFrame: updateFrame,
      );
    } else if (component is SmartWidgetText) {
      return SmartWidgetTextCustomization(
        frameText: component,
        controller: controller,
        updateFrame: updateFrame,
      );
    } else if (component is SmartWidgetImage) {
      return SmartWidgetImageCustomization(
        frameImage: component,
        controller: controller,
        updateFrame: updateFrame,
      );
    } else if (component is SmartWidgetButton) {
      return SmartWidgetButtonCustomization(
        frameButton: component,
        controller: controller,
        updateFrame: updateFrame,
      );
    } else if (component is SmartWidgetVideo) {
      return SmartWidgetVideoCustomization(
        frameVideo: component,
        controller: controller,
        updateFrame: updateFrame,
      );
    } else if (component is SmartWidgetZapPoll) {
      return SmartWidgetZapPollCustomization(
        frameZapPoll: component,
        controller: controller,
        updateFrame: updateFrame,
      );
    } else if (component is SmartWidgetGrid) {
      return SmartWidgetHoriztonalGridCustomization(
        frameHorizontalGrid: component,
        controller: controller,
        updateFrame: updateFrame,
      );
    } else {
      return SizedBox.shrink();
    }
  }
}

class SmartWidgetHoriztonalGridCustomization extends HookWidget {
  const SmartWidgetHoriztonalGridCustomization({
    Key? key,
    required this.frameHorizontalGrid,
    required this.controller,
    required this.updateFrame,
  }) : super(key: key);

  final SmartWidgetGrid frameHorizontalGrid;
  final ScrollController controller;
  final Function(SmartWidgetComponent) updateFrame;

  @override
  Widget build(BuildContext context) {
    final division = useState(frameHorizontalGrid.division);
    final layout = useState(frameHorizontalGrid.layout);

    final t = useCallback(
      () {
        final isDefault = division.value == '1:1';
        final left = frameHorizontalGrid.leftSide;
        final right = frameHorizontalGrid.rightSide;

        updateFrame.call(
          frameHorizontalGrid.copyWith(
            division: division.value,
            layout: layout.value,
            leftSide: isDefault &&
                    (left.length > 1 || (left.isNotEmpty && right.isNotEmpty))
                ? {}
                : null,
            rightSide: isDefault ? {} : null,
          ),
        );
      },
    );

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      children: [
        Text(
          'Layout customization',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        Row(
          children: [
            Expanded(
              child: gridLayout(
                context: context,
                onSelected: () {
                  division.value = '1:1';
                  layout.value = 2;
                  t.call();
                },
                isSelected: division.value == '1:1' && layout.value == 2,
                text: 'Duolayout 1:1',
                icon: FeatureIcons.layout11,
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            Expanded(
              child: gridLayout(
                context: context,
                onSelected: () {
                  division.value = '2:1';
                  layout.value = 2;
                  t.call();
                },
                text: 'Duolayout 2:1',
                isSelected: division.value == '2:1' && layout.value == 2,
                icon: FeatureIcons.layout21,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        Row(
          children: [
            Expanded(
              child: gridLayout(
                context: context,
                onSelected: () {
                  division.value = '1:2';
                  layout.value = 2;
                  t.call();
                },
                isSelected: division.value == '1:2' && layout.value == 2,
                text: 'Duolayout 1:2',
                icon: FeatureIcons.layout12,
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            Expanded(
              child: gridLayout(
                context: context,
                onSelected: () {
                  final left = frameHorizontalGrid.leftSide;
                  final right = frameHorizontalGrid.rightSide;

                  if (left.length > 1 ||
                      (left.isNotEmpty && right.isNotEmpty)) {
                    showCupertinoCustomDialogue(
                      context: context,
                      title: 'Warning!',
                      description:
                          "You're switching to a mono layout whilst having elements on both sides, this will erase the container content, do you wish to proceed?",
                      buttonText: 'erase ',
                      buttonTextColor: kRed,
                      onClicked: () {
                        division.value = '1:1';
                        layout.value = 1;
                        t.call();
                        Navigator.pop(context);
                      },
                    );
                  } else {
                    division.value = '1:1';
                    layout.value = 1;
                    t.call();
                  }
                },
                text: 'Monolayout',
                isSelected: division.value == '1:1' && layout.value == 1,
                icon: FeatureIcons.layout1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget gridLayout({
    required BuildContext context,
    required Function() onSelected,
    required bool isSelected,
    required String icon,
    required String text,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: Theme.of(context).primaryColorLight,
          border: Border.all(
            color: isSelected ? kDimGrey.withValues(alpha: 0.5) : kTransparent,
            width: 0.7,
          ),
        ),
        padding: const EdgeInsets.all(kDefaultPadding / 1.5),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Text(
                '${text}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SmartWidgetTextCustomization extends HookWidget {
  const SmartWidgetTextCustomization({
    Key? key,
    required this.frameText,
    required this.controller,
    required this.updateFrame,
  }) : super(key: key);

  final SmartWidgetText frameText;
  final ScrollController controller;
  final Function(SmartWidgetComponent) updateFrame;

  @override
  Widget build(BuildContext context) {
    final text = useState(frameText.text);
    final textSize = useState(frameText.textSize ?? TextSize.Regular);
    final textWeight = useState(frameText.textWeight ?? TextWeight.Regular);
    final textColor = useState(frameText.textColor);

    final t = useCallback(
      () {
        updateFrame.call(
          frameText.copyWith(
            text: text.value,
            textColor: textColor.value,
            textSize: textSize.value,
            textWeight: textWeight.value,
          ),
        );
      },
    );

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      children: [
        Text(
          'Text customization',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        TextFormField(
          initialValue: text.value,
          onChanged: (value) {
            text.value = value;
            t.call();
          },
          decoration: InputDecoration(
            hintText: 'Write your text',
            hintStyle: Theme.of(context).textTheme.labelMedium,
          ),
          maxLines: 3,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        DropDownRow(
          title: 'Size',
          selectedOption: textSize.value.name,
          options: TextSize.values.map((e) => e.name).toList(),
          onChanged: (val) {
            textSize.value = TextSize.values.firstWhere(
              (element) => element.name == val,
              orElse: () => TextSize.Regular,
            );

            if (textSize.value == TextSize.H1 ||
                textSize.value == TextSize.H2) {
              textWeight.value = TextWeight.Bold;
            }

            t.call();
          },
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Builder(builder: (context) {
          final isUsed = textSize.value == TextSize.Regular ||
              textSize.value == TextSize.Small;

          return AbsorbPointer(
            absorbing: !isUsed,
            child: Opacity(
              opacity: isUsed ? 1 : 0.5,
              child: DropDownRow(
                title: 'Weight',
                selectedOption: textWeight.value.name,
                options: TextWeight.values.map((e) => e.name).toList(),
                onChanged: (val) {
                  textWeight.value = TextWeight.values.firstWhere(
                    (element) => element.name == val,
                    orElse: () => TextWeight.Regular,
                  );

                  t.call();
                },
              ),
            ),
          );
        }),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        SmartWidgetColorPicker(
          colorHex: textColor.value,
          title: 'Color',
          onUpdate: (val) {
            textColor.value = val;
            t.call();
          },
        ),
      ],
    );
  }
}

class SmartWidgetVideoCustomization extends HookWidget {
  const SmartWidgetVideoCustomization({
    Key? key,
    required this.frameVideo,
    required this.controller,
    required this.updateFrame,
  }) : super(key: key);

  final SmartWidgetVideo frameVideo;
  final ScrollController controller;
  final Function(SmartWidgetComponent) updateFrame;

  @override
  Widget build(BuildContext context) {
    final url = useState(frameVideo.url);
    final urlController = useTextEditingController(text: frameVideo.url);

    final t = useCallback(
      () {
        updateFrame.call(
          frameVideo.copyWith(
            url: url.value,
          ),
        );
      },
    );

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      children: [
        Text(
          'Video customization',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: urlController,
                onChanged: (value) {
                  url.value = value;
                  t.call();
                },
                decoration: InputDecoration(
                  hintText: 'Video url...',
                  hintStyle: Theme.of(context).textTheme.labelMedium,
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            CustomIconButton(
              onClicked: () async {
                final media =
                    await nostrRepository.selectLocalMedia(MediaType.video);

                if (media != null) {
                  context.read<WriteSmartWidgetCubit>().uploadMediaAndSend(
                        file: media,
                        onSuccess: (link) {
                          url.value = link;
                          urlController.text = link;
                          t.call();
                        },
                      );
                }
              },
              icon: FeatureIcons.upload,
              size: 20,
              backgroundColor: Theme.of(context).primaryColorLight,
            ),
          ],
        ),
      ],
    );
  }
}

class SmartWidgetZapPollCustomization extends HookWidget {
  const SmartWidgetZapPollCustomization({
    Key? key,
    required this.frameZapPoll,
    required this.controller,
    required this.updateFrame,
  }) : super(key: key);

  final SmartWidgetZapPoll frameZapPoll;
  final ScrollController controller;
  final Function(SmartWidgetComponent) updateFrame;

  @override
  Widget build(BuildContext context) {
    final content = useState(frameZapPoll.content);
    final nevent = useTextEditingController(text: frameZapPoll.getNevent());
    final contentTextColor = useState(frameZapPoll.contentTextColor);
    final optionTextColor = useState(frameZapPoll.optionTextColor);
    final backgroundColor = useState(frameZapPoll.optionBackgroundColor);
    final fillColor = useState(frameZapPoll.optionForegroundColor);

    final t = useCallback(
      () {
        updateFrame.call(
          frameZapPoll.copyWith(
            content: content.value,
            contentTextColor: contentTextColor.value,
            optionBackgroundColor: backgroundColor.value,
            optionForegroundColor: fillColor.value,
            optionTextColor: optionTextColor.value,
          ),
        );
      },
    );

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      children: [
        Text(
          'Zap poll customization',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: nevent,
                decoration: InputDecoration(
                  labelText: 'Zap poll nevent',
                ),
                onChanged: (value) async {
                  final ev = await frameZapPoll.getPollEvent(value);

                  if (ev != null) {
                    content.value = ev.toJsonString();
                  } else {
                    content.value = '';
                  }

                  t.call();
                },
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            CustomIconButton(
              onClicked: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return BlocProvider.value(
                      value: context.read<WriteSmartWidgetCubit>(),
                      child: SmartWidgetZapPollSelection(
                        onZapPollAdded: (ev) {
                          Navigator.pop(context);
                          content.value = ev.toJsonString();
                          nevent.text = Nip19.encodeShareableEntity(
                            'nevent',
                            ev.id,
                            mandatoryRelays,
                            ev.pubkey,
                            ev.kind,
                          );

                          t.call();
                        },
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
              icon: FeatureIcons.polls,
              size: 20,
              backgroundColor: Theme.of(context).primaryColorLight,
            ),
            if (content.value.isEmpty) ...[
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              CustomIconButton(
                onClicked: () {
                  showModalBottomSheet(
                    context: context,
                    elevation: 0,
                    builder: (_) {
                      return WriteZapPollView(
                        onZapPollAdded: (ev) {
                          Navigator.pop(context);
                          content.value = ev.toJsonString();
                          nevent.text = Nip19.encodeShareableEntity(
                            'nevent',
                            ev.id,
                            mandatoryRelays,
                            ev.pubkey,
                            ev.kind,
                          );

                          t.call();
                        },
                      );
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
                icon: FeatureIcons.addRaw,
                size: 20,
                backgroundColor: Theme.of(context).primaryColorLight,
              ),
            ]
          ],
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        SmartWidgetColorPicker(
          colorHex: contentTextColor.value,
          title: 'Content text color',
          onUpdate: (val) {
            contentTextColor.value = val;
            t.call();
          },
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        SmartWidgetColorPicker(
          colorHex: optionTextColor.value,
          title: 'Option text color',
          onUpdate: (val) {
            optionTextColor.value = val;
            t.call();
          },
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        SmartWidgetColorPicker(
          colorHex: backgroundColor.value,
          title: 'Option background color',
          onUpdate: (val) {
            backgroundColor.value = val;
            t.call();
          },
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        SmartWidgetColorPicker(
          colorHex: fillColor.value,
          title: 'FillColor color',
          onUpdate: (val) {
            fillColor.value = val;
            t.call();
          },
        ),
      ],
    );
  }
}

class SmartWidgetImageCustomization extends HookWidget {
  const SmartWidgetImageCustomization({
    Key? key,
    required this.frameImage,
    required this.controller,
    required this.updateFrame,
  }) : super(key: key);

  final SmartWidgetImage frameImage;
  final ScrollController controller;
  final Function(SmartWidgetComponent) updateFrame;

  @override
  Widget build(BuildContext context) {
    final url = useState(frameImage.url);
    final aspectRatio = useState(frameImage.aspectRatio);
    final urlController = useTextEditingController(text: frameImage.url);

    final t = useCallback(
      () {
        updateFrame.call(
          frameImage.copyWith(
            image: url.value,
            aspectRatio: aspectRatio.value,
          ),
        );
      },
    );

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      children: [
        Text(
          'Image customization',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: urlController,
                onChanged: (value) {
                  url.value = value;
                  t.call();
                },
                decoration: InputDecoration(
                  labelText: 'Image url',
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            CustomIconButton(
              onClicked: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return ImageSelector(
                      onTap: (link) {
                        url.value = link;
                        urlController.text = link;
                        t.call();
                      },
                    );
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  elevation: 0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              icon: FeatureIcons.upload,
              size: 20,
              backgroundColor: Theme.of(context).primaryColorLight,
            ),
          ],
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        DropDownRow(
          title: 'Image aspect ratio',
          selectedOption: aspectRatio.value,
          options: aspectRatios,
          onChanged: (ar) {
            aspectRatio.value = ar ?? aspectRatios.first;
            t.call();
          },
        ),
      ],
    );
  }
}

class SmartWidgetButtonCustomization extends HookWidget {
  const SmartWidgetButtonCustomization({
    Key? key,
    required this.frameButton,
    required this.controller,
    required this.updateFrame,
  }) : super(key: key);

  final SmartWidgetButton frameButton;
  final ScrollController controller;
  final Function(SmartWidgetComponent) updateFrame;

  @override
  Widget build(BuildContext context) {
    final text = useState(frameButton.text);
    final textColor = useState(frameButton.textColor);
    final buttonColor = useState(frameButton.buttonColor);
    final type = useState(frameButton.type);
    final pubkey = useState(frameButton.pubkey);
    final url = useState(frameButton.url);
    final invoiceController = useTextEditingController(text: url.value);
    final toggleSatsMode = useState(frameButton.url.startsWith('lnbc'));
    final userToZap = useState<UserModel?>(null);

    final t = useCallback(
      () {
        updateFrame.call(
          frameButton.copyWith(
            text: text.value,
            textColor: textColor.value,
            type: type.value,
            url: url.value,
            buttonColor: buttonColor.value,
            pubkey: pubkey.value,
          ),
        );
      },
    );

    final searchAuthorFunc = useCallback(() {
      showModalBottomSheet(
        context: context,
        builder: (_) {
          return UserToZap(
            onUserSelected: (user) {
              userToZap.value = user;
              pubkey.value = user.pubKey;

              String la = (user.lud16.isNotEmpty ? user.lud16 : user.lud06)
                  .toLowerCase();

              if (la.contains("@") || la.startsWith('lnurl')) {
                invoiceController.text = la;
                url.value = la;
              }
              t.call();
              Navigator.pop(context);
            },
          );
        },
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    });

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      children: [
        Text(
          'Button customization',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        TextFormField(
          initialValue: text.value,
          onChanged: (value) {
            text.value = value;
            t.call();
          },
          decoration: InputDecoration(
            labelText: 'Button text',
          ),
          maxLines: 1,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        DropDownRow(
          title: 'Type',
          selectedOption: type.value.name,
          options: SmartWidgetButtonType.values.map((e) => e.name).toList(),
          onChanged: (val) {
            type.value = SmartWidgetButtonType.values.firstWhere(
              (element) => element.name == val,
              orElse: () => SmartWidgetButtonType.Regular,
            );

            final props = getSmartWidgetButtonProps(type.value);

            buttonColor.value = props.isNotEmpty
                ? getColorFromHex(props['color'])?.toHex() ??
                    Theme.of(context).primaryColorLight.toHex()
                : buttonColor.value;

            textColor.value =
                props.isNotEmpty ? kWhite.toHex() : textColor.value;

            pubkey.value = '';
            userToZap.value = null;

            t.call();
          },
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        if (type.value != SmartWidgetButtonType.Zap)
          TextFormField(
            initialValue: url.value,
            onChanged: (value) {
              url.value = value;
              t.call();
            },
            decoration: InputDecoration(
              labelText: hintText(type.value),
            ),
            maxLines: 1,
          )
        else ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding / 1.2),
              color: Theme.of(context).primaryColorLight,
            ),
            padding: const EdgeInsets.all(kDefaultPadding / 4),
            child: Row(
              children: [
                const SizedBox(
                  width: kDefaultPadding / 1.6,
                ),
                Expanded(
                  child: Text(
                    'Use invoice',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: CupertinoSwitch(
                    value: toggleSatsMode.value,
                    activeColor: kOrangeContrasted,
                    onChanged: (val) {
                      toggleSatsMode.value = val;
                      userToZap.value = null;
                      pubkey.value = '';
                      invoiceController.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          TextFormField(
            controller: invoiceController,
            onChanged: (value) {
              url.value = value;
              t.call();
            },
            decoration: InputDecoration(
              hintText: toggleSatsMode.value ? 'Invoice' : 'Lightning address',
              hintStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: kDimGrey,
                  ),
            ),
          ),
          if (!toggleSatsMode.value) ...[
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            GestureDetector(
              onTap: searchAuthorFunc,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 1.2),
                  color: Theme.of(context).primaryColorLight,
                ),
                padding: const EdgeInsets.all(kDefaultPadding / 6),
                child: userToZap.value != null
                    ? Row(
                        children: [
                          const SizedBox(
                            width: kDefaultPadding / 1.6,
                          ),
                          ProfilePicture2(
                            size: 25,
                            image: userToZap.value!.picture,
                            placeHolder: userToZap.value!.picturePlaceholder,
                            padding: 0,
                            strokeWidth: 0,
                            reduceSize: true,
                            strokeColor: kTransparent,
                            onClicked: () {},
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 2,
                          ),
                          Expanded(
                            child: Text(
                              getAuthorDisplayName(userToZap.value!),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          CustomIconButton(
                            onClicked: () {
                              userToZap.value = null;
                              invoiceController.clear();
                            },
                            icon: FeatureIcons.closeRaw,
                            size: 20,
                            backgroundColor:
                                Theme.of(context).primaryColorLight,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const SizedBox(
                            width: kDefaultPadding / 1.6,
                          ),
                          Expanded(
                            child: Text(
                              'Select a user to zap (optional)',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          CustomIconButton(
                            onClicked: searchAuthorFunc,
                            icon: FeatureIcons.user,
                            size: 20,
                            backgroundColor:
                                Theme.of(context).primaryColorLight,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ],
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Builder(
          builder: (context) {
            final disable = type.value != SmartWidgetButtonType.Regular &&
                type.value != SmartWidgetButtonType.Zap;

            return AbsorbPointer(
              absorbing: disable,
              child: Opacity(
                opacity: disable ? 0.5 : 1,
                child: Column(
                  children: [
                    SmartWidgetColorPicker(
                      colorHex: textColor.value,
                      title: 'Text color',
                      onUpdate: (val) {
                        textColor.value = val;
                        t.call();
                      },
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    SmartWidgetColorPicker(
                      colorHex: buttonColor.value,
                      title: 'Button color',
                      onUpdate: (val) {
                        buttonColor.value = val;
                        t.call();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String hintText(SmartWidgetButtonType action) {
    if (action == SmartWidgetButtonType.Regular) {
      return 'Url';
    } else if (action == SmartWidgetButtonType.Zap) {
      return 'Invoice or Lightning address';
    } else if (action == SmartWidgetButtonType.Youtube) {
      return 'Youtube url';
    } else if (action == SmartWidgetButtonType.Telegram) {
      return 'Telegram url';
    } else if (action == SmartWidgetButtonType.X) {
      return 'X url';
    } else if (action == SmartWidgetButtonType.Nostr) {
      return 'Nostr scheme';
    } else {
      return 'Discord url';
    }
  }
}

class DropDownRow extends StatelessWidget {
  const DropDownRow({
    Key? key,
    required this.onChanged,
    required this.selectedOption,
    required this.title,
    required this.options,
  }) : super(key: key);

  final Function(String?) onChanged;
  final String selectedOption;
  final String title;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Flexible(
          child: CustomDropDown(
            list: options,
            defaultValue: selectedOption,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class SmartWidgetContainerCustomization extends HookWidget {
  const SmartWidgetContainerCustomization({
    Key? key,
    required this.frameContainer,
    required this.controller,
    required this.updateFrame,
  }) : super(key: key);

  final SmartWidgetContainer frameContainer;
  final ScrollController controller;
  final Function(SmartWidgetComponent) updateFrame;

  @override
  Widget build(BuildContext context) {
    final borderColorHex = useState(frameContainer.borderColorHex);
    final colorHex = useState(frameContainer.backgroundHex);

    final t = useCallback(() {
      updateFrame.call(frameContainer.copyWith(
        borderColorHex: borderColorHex.value,
        backgroundHex: colorHex.value,
      ));
    });

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      children: [
        Text(
          'Container customization',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        SmartWidgetColorPicker(
          colorHex: colorHex.value,
          title: 'Background color',
          onUpdate: (val) {
            colorHex.value = val;
            t.call();
          },
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        SmartWidgetColorPicker(
          colorHex: borderColorHex.value,
          title: 'Border color',
          onUpdate: (val) {
            borderColorHex.value = val;
            t.call();
          },
        ),
      ],
    );
  }
}

class SmartWidgetColorPicker extends StatelessWidget {
  const SmartWidgetColorPicker({
    Key? key,
    required this.colorHex,
    required this.title,
    required this.onUpdate,
  }) : super(key: key);

  final String? colorHex;
  final String title;
  final Function(String) onUpdate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 8),
      child: Builder(
        builder: (context) {
          final currentColor = colorHex != null && colorHex!.isNotEmpty
              ? getColorFromHex(colorHex!)!
              : Theme.of(context).primaryColorLight;

          return Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              ColorIndicator(
                width: 30,
                height: 30,
                borderRadius: 100,
                color: currentColor,
                borderColor: kDimGrey.withValues(alpha: 0.5),
                hasBorder: true,
                onSelectFocus: false,
                onSelect: () async {
                  Color c = currentColor;

                  final isSuccessful = await colorPickerDialog(
                    context: context,
                    selectedColor: currentColor,
                    onColorChanged: (color) => c = color,
                  );

                  if (isSuccessful) {
                    onUpdate.call(c.toHex());
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class TextfieldWithTitle extends StatelessWidget {
  const TextfieldWithTitle({
    Key? key,
    required this.onChanged,
    required this.title,
    required this.initVal,
    required this.isNumeral,
  }) : super(key: key);

  final Function(String) onChanged;
  final String title;
  final String initVal;
  final bool isNumeral;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Flexible(
          child: TextFormField(
            keyboardType: isNumeral ? TextInputType.number : null,
            onChanged: onChanged,
            initialValue: initVal,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(kDefaultPadding / 1.5),
              hintText: 'value',
              hintStyle: Theme.of(context)
                  .textTheme
                  .labelMedium!
                  .copyWith(color: kDimGrey),
            ),
            inputFormatters: [
              if (isNumeral) FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),
      ],
    );
  }
}
