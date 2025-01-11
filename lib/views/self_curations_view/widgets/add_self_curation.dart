// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/self_curations_cubit/add_curation_cubit/add_curation_cubit.dart';
import 'package:yakihonne/blocs/self_curations_cubit/self_curations_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/content_zap_splits.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/write_article_view/widgets/article_selected_relays.dart';

// ignore: must_be_immutable
class AddSelfCurationView extends HookWidget {
  static const routeName = '/addSelfCurationView';
  static Route route(RouteSettings settings) {
    final list = settings.arguments as List;

    return CupertinoPageRoute(
      builder: (_) => AddSelfCurationView(
        selfCurationsCubit: list[0],
        isAddingOperation: list[1],
        curation: list.length > 2 ? list[2] : null,
      ),
    );
  }

  AddSelfCurationView({
    required this.selfCurationsCubit,
    required this.isAddingOperation,
    this.curation,
    super.key,
  }) {
    curationCubit = AddCurationCubit(
      nostrRepository: nostrRepository,
      isAddingOperation: isAddingOperation,
      curation: curation,
    );
  }

  final SelfCurationsCubit? selfCurationsCubit;
  final bool isAddingOperation;
  final Curation? curation;

  late AddCurationCubit curationCubit;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocProvider(
      create: (context) => AddCurationCubit(
        nostrRepository: context.read<NostrDataRepository>(),
        curation: curation,
        isAddingOperation: isAddingOperation,
      ),
      child: Scaffold(
        appBar: CustomAppBar(
          title: '${isAddingOperation ? 'Add' : 'Update'} curation',
        ),
        bottomNavigationBar: SizedBox(
          height: kBottomNavigationBarHeight +
              MediaQuery.of(context).padding.bottom,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 15.w : kDefaultPadding,
            ),
            child: BlocBuilder<AddCurationCubit, AddCurationState>(
              builder: (context, state) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Visibility(
                      visible: state.curationPublishSteps !=
                          CurationPublishSteps.content,
                      child: IconButton(
                        onPressed: () {
                          context.read<AddCurationCubit>().setView(false);
                        },
                        icon: Icon(
                          Icons.keyboard_arrow_left_rounded,
                          color: kWhite,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: kPurple,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 4,
                    ),
                    StatusButton(
                      isDisabled: !state.isImageSelected ||
                          state.title.trim().isEmpty ||
                          state.description.trim().isEmpty,
                      onClicked: () {
                        if (state.curationPublishSteps ==
                            CurationPublishSteps.relays) {
                          context.read<AddCurationCubit>().addCuration(
                            onFailure: (message) {
                              singleSnackBar(
                                context: context,
                                message: message,
                                color: kRed,
                                backGroundColor: kRedSide,
                                icon: ToastsIcons.error,
                              );
                            },
                            onSuccess: () {
                              singleSnackBar(
                                context: context,
                                message: isAddingOperation
                                    ? 'Curation has been added successfuly'
                                    : 'Curation has been updated successfuly',
                                color: kGreen,
                                backGroundColor: kGreenSide,
                                icon: ToastsIcons.success,
                              );

                              if (selfCurationsCubit != null) {
                                selfCurationsCubit!.getCurations(
                                  relay: selfCurationsCubit!.state.chosenRelay,
                                );
                              }

                              Navigator.pop(context);
                            },
                          );
                        } else {
                          context.read<AddCurationCubit>().setView(true);
                        }
                      },
                      text: state.curationPublishSteps !=
                              CurationPublishSteps.relays
                          ? 'Next'
                          : isAddingOperation
                              ? 'Add'
                              : 'update',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        body: BlocBuilder<AddCurationCubit, AddCurationState>(
          builder: (context, state) {
            if (state.curationPublishSteps == CurationPublishSteps.relays) {
              return ArticleSelectedRelays(
                selectedRelays: state.selectedRelays,
                totaRelays: state.totalRelays,
                onToggle: (relay) {
                  if (!mandatoryRelays.contains(relay)) {
                    context.read<AddCurationCubit>().setRelaySelection(relay);
                  }
                },
                deleteDraft: false,
                isDraft: false,
                isDraftShown: false,
                isForwardedAsDraft: false,
                onDeleteDraft: () {},
              );
            } else if (state.curationPublishSteps ==
                CurationPublishSteps.zaps) {
              return ContentZapSplits(
                isZapSplitEnabled: state.isZapSplitEnabled,
                zaps: state.zapsSplits,
                onToggleZapSplit: () {
                  context.read<AddCurationCubit>().toggleZapsSplits();
                },
                onAddZapSplitUser: (pubkey) {
                  context.read<AddCurationCubit>().addZapSplit(pubkey);
                },
                onRemoveZapSplitUser: (pubkey) {
                  context.read<AddCurationCubit>().onRemoveZapSplit(pubkey);
                },
                onSetZapProportions: (index, zap, percentage) {
                  context.read<AddCurationCubit>().setZapPropertion(
                        index: index,
                        zapSplit: zap,
                        newPercentage: percentage,
                      );
                },
              );
            } else {
              return AddCurationContent(
                image: state.imageLink,
                isArticlesCurationState: state.isArticlesCuration,
                isAdding: isAddingOperation,
              );
            }
          },
        ),
      ),
    );
  }
}

class AddCurationContent extends HookWidget {
  const AddCurationContent({
    required this.image,
    required this.isArticlesCurationState,
    required this.isAdding,
  });

  final String image;
  final bool isArticlesCurationState;
  final bool isAdding;

  @override
  Widget build(BuildContext context) {
    final imageUrlController = useTextEditingController(text: image);
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<AddCurationCubit, AddCurationState>(
      builder: (context, state) {
        return FadeInLeft(
          duration: const Duration(milliseconds: 300),
          child: ListView(
            padding: EdgeInsets.all(isTablet ? 15.w : kDefaultPadding / 2),
            children: [
              const SizedBox(
                height: kDefaultPadding,
              ),
              Stack(
                children: [
                  Container(
                    height: 20.h,
                    decoration: state.isImageSelected
                        ? null
                        : BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding),
                            border: Border.all(
                              width: 0.5,
                              color: kDimGrey,
                            ),
                          ),
                    foregroundDecoration:
                        state.isImageSelected && state.isLocalImage
                            ? BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(kDefaultPadding),
                                image: DecorationImage(
                                  image: FileImage(
                                    state.localImage!,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : null,
                    child: state.isImageSelected && !state.isLocalImage
                        ? state.imageLink.isEmpty
                            ? SizedBox(
                                height: 20.h,
                                child: NoMediaPlaceHolder(
                                  image: '',
                                  isError: false,
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: state.imageLink,
                                height: 20.h,
                                width: double.infinity,
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(kDefaultPadding),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        state.imageLink,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                placeholder: (context, url) =>
                                    NoMediaPlaceHolder(
                                  image: '',
                                  isError: false,
                                ),
                                errorWidget: (context, url, error) =>
                                    NoMediaPlaceHolder(
                                  image: '',
                                  isError: false,
                                ),
                              )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  FeatureIcons.image,
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.scaleDown,
                                  colorFilter: ColorFilter.mode(
                                    kDimGrey,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(
                                  height: kDefaultPadding / 2,
                                ),
                                Text(
                                  'Thumbnail preview',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ),
                  ),
                  if (state.isImageSelected)
                    Positioned(
                      right: kDefaultPadding / 2,
                      top: kDefaultPadding / 2,
                      child: CircleAvatar(
                        backgroundColor: kWhite.withValues(alpha: 0.8),
                        child: IconButton(
                          onPressed: () {
                            context.read<AddCurationCubit>().removeImage();
                            imageUrlController.clear();
                          },
                          icon: SvgPicture.asset(
                            FeatureIcons.trash,
                            width: 25,
                            height: 25,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
              Row(
                children: [
                  Expanded(
                    child: BlocBuilder<AddCurationCubit, AddCurationState>(
                      builder: (context, state) {
                        return TextFormField(
                          controller: imageUrlController,
                          decoration: InputDecoration(
                            hintText: 'Image url',
                          ),
                          onChanged: (link) {
                            context.read<AddCurationCubit>().selectUrlImage(
                                  url: link,
                                  onFailed: () {
                                    singleSnackBar(
                                      context: context,
                                      message: 'Select a valid url image.',
                                      color: kRed,
                                      backGroundColor: kRedSide,
                                      icon: ToastsIcons.error,
                                    );
                                  },
                                );
                          },
                          onFieldSubmitted: (url) {},
                        );
                      },
                    ),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  BlocBuilder<AddCurationCubit, AddCurationState>(
                    builder: (context, state) {
                      return BorderedIconButton(
                        firstSelection: true,
                        onClicked: () {
                          imageUrlController.clear();
                          context.read<AddCurationCubit>().selectProfileImage(
                            onFailed: () {
                              singleSnackBar(
                                context: context,
                                message:
                                    'Issue occured while selecting the image.',
                                color: kRed,
                                backGroundColor: kRedSide,
                                icon: ToastsIcons.error,
                              );
                            },
                          );
                        },
                        primaryIcon: FeatureIcons.upload,
                        secondaryIcon: FeatureIcons.notVisible,
                        borderColor: state.isLocalImage
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).primaryColorLight,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              TextFormField(
                initialValue: state.title,
                decoration: InputDecoration(
                  hintText: 'Title',
                ),
                onChanged: (title) =>
                    context.read<AddCurationCubit>().setTitle(title),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              TextFormField(
                initialValue: state.description,
                onChanged: (description) => context
                    .read<AddCurationCubit>()
                    .setDescription(description),
                decoration: InputDecoration(
                  hintText: 'Description',
                ),
                minLines: 5,
                maxLines: 5,
              ),
              if (isAdding) ...[
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColorLight,
                    borderRadius: BorderRadius.circular(kDefaultPadding),
                  ),
                  padding: const EdgeInsets.all(kDefaultPadding / 1.5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Curation type',
                        ),
                      ),
                      CurationTypeToggle(
                        isArticlesCuration: state.isArticlesCuration,
                        onToggle: () {
                          context.read<AddCurationCubit>().setCurationType();
                        },
                      ),
                    ],
                  ),
                )
              ]
            ],
          ),
        );
      },
    );
  }
}

class CurationTypeToggle extends StatelessWidget {
  const CurationTypeToggle({
    super.key,
    required this.isArticlesCuration,
    required this.onToggle,
  });

  final Function() onToggle;
  final bool isArticlesCuration;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 90,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              color: isArticlesCuration ? kBlue : kOrange,
            ),
            child: Row(
              children: [
                if (isArticlesCuration)
                  SizedBox(
                    width: 28,
                  ),
                Expanded(
                  child: Text(
                    isArticlesCuration ? 'Articles' : 'Videos',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: kWhite,
                        ),
                  ),
                ),
                if (!isArticlesCuration)
                  SizedBox(
                    width: 28,
                  ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: 2,
            bottom: 2,
            left: isArticlesCuration ? 2 : 60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kWhite,
              ),
              child: Center(
                child: SvgPicture.asset(
                  isArticlesCuration
                      ? FeatureIcons.selfArticles
                      : FeatureIcons.videoOcta,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    isArticlesCuration ? kBlue : kOrange,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CustomTypeToggle extends StatelessWidget {
  const CustomTypeToggle({
    super.key,
    required this.isFirstToggle,
    required this.onToggle,
  });

  final Function() onToggle;
  final bool isFirstToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 90,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              color: Theme.of(context).primaryColorLight,
            ),
            child: Row(
              children: [
                if (isFirstToggle)
                  SizedBox(
                    width: 28,
                  ),
                Expanded(
                  child: Text(
                    isFirstToggle ? 'Home' : 'Notes',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: kWhite,
                        ),
                  ),
                ),
                if (!isFirstToggle)
                  SizedBox(
                    width: 28,
                  ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: 2,
            bottom: 2,
            left: isFirstToggle ? 2 : 60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kWhite,
              ),
              child: Center(
                child: SvgPicture.asset(
                  isFirstToggle ? FeatureIcons.home : FeatureIcons.note,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    kBlack,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
