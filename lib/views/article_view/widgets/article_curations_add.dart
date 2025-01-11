// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/article_cubit/article_curations_cubit/article_curations_cubit.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/views/widgets/article_thumbnail.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/content_zap_splits.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/write_article_view/widgets/article_selected_relays.dart';

import '../../../utils/utils.dart';

class ArticleSuggestedCurationList extends StatelessWidget {
  const ArticleSuggestedCurationList({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
      builder: (context, state) {
        final isArticlesCuration =
            state.curationKind == EventKind.CURATION_ARTICLES;

        if (state.isCurationsLoading) {
          return SpinKitSpinningLines(
            size: 30,
            color: Theme.of(context).primaryColorDark,
          );
        } else if (state.curations.isEmpty) {
          return Center(
            child: EmptyList(
              description:
                  'No curations have been found. Try to create one in order to be able to add ${isArticlesCuration ? 'an article' : 'a video'} to it.',
              icon: FeatureIcons.selfCurations,
            ),
          );
        } else {
          return ScrollShadow(
            color: Theme.of(context).primaryColorLight,
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return SizedBox(
                  height: kDefaultPadding / 2,
                );
              },
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
                vertical: kDefaultPadding,
              ),
              controller: scrollController,
              itemBuilder: (context, index) {
                final curation = state.curations[index];
                final canBeAddedValue =
                    canBeAdded(curation.eventsIds, state.articleId);

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding),
                    color: Theme.of(context).primaryColorLight,
                  ),
                  padding: const EdgeInsets.all(kDefaultPadding / 2),
                  child: Row(
                    children: [
                      ArticleThumbnail(
                        image: curation.image,
                        placeholder: curation.placeHolder,
                        width: 60,
                        height: 60,
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              curation.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                            ),
                            Text(
                              '${curation.eventsIds.length.toString().padLeft(2, '0')} available ${curation.isArticleCuration() ? 'article(s)' : 'video(s)'}',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            if (!canBeAddedValue)
                              Text(
                                '${curation.isArticleCuration() ? 'Articles' : 'Videos'} available on this curation',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                      color: kOrange,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      if (canBeAddedValue)
                        IconButton(
                          onPressed: () {
                            context.read<ArticleCurationsCubit>().setCuration(
                                  curation: curation,
                                  onFailure: (message) {},
                                  onSuccess: () {
                                    Navigator.pop(context);

                                    singleSnackBar(
                                      context: context,
                                      message:
                                          '${curation.isArticleCuration() ? 'Article' : 'Video'} has been added to your curation.',
                                      color: kGreen,
                                      backGroundColor: kGreenSide,
                                      icon: ToastsIcons.check,
                                    );
                                  },
                                );
                          },
                          icon: Icon(
                            Icons.add_rounded,
                          ),
                          style: IconButton.styleFrom(
                            visualDensity: VisualDensity(
                              horizontal: -2,
                              vertical: -2,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
              itemCount: state.curations.length,
            ),
          );
        }
      },
    );
  }

  bool canBeAdded(List<EventCoordinates> events, String articleId) {
    final list = events.where((element) => element.identifier == articleId);

    return list.isEmpty;
  }
}

class AddCuration extends HookWidget {
  const AddCuration({
    required this.controller,
  });

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final imageUrlController = useTextEditingController(text: '');

    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
      builder: (context, state) {
        return ListView(
          controller: controller,
          padding: EdgeInsets.all(isTablet ? 15.w : kDefaultPadding),
          children: [
            BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
              builder: (context, state) {
                return Stack(
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
                                    isError: false,
                                    image: '',
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: state.imageLink,
                                  height: 20.h,
                                  width: double.infinity,
                                  imageBuilder: (context, imageProvider) =>
                                      Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        kDefaultPadding,
                                      ),
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
                                    isError: true,
                                    image: getRandomPlaceholder(
                                      input: state.articleId,
                                      isPfp: false,
                                    ),
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
                              context
                                  .read<ArticleCurationsCubit>()
                                  .removeImage();
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
                );
              },
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Row(
              children: [
                Expanded(
                  child:
                      BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
                    builder: (context, state) {
                      return TextFormField(
                        controller: imageUrlController,
                        decoration: InputDecoration(
                          hintText: 'Image url',
                        ),
                        onChanged: (link) {
                          context.read<ArticleCurationsCubit>().selectUrlImage(
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
                BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
                  builder: (context, state) {
                    return BorderedIconButton(
                      firstSelection: true,
                      onClicked: () {
                        imageUrlController.clear();

                        context
                            .read<ArticleCurationsCubit>()
                            .selectProfileImage(
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
              onChanged: (value) {
                context.read<ArticleCurationsCubit>().setText(true, value);
              },
              decoration: InputDecoration(
                hintText: 'Title',
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            TextFormField(
              initialValue: state.description,
              onChanged: (value) {
                context.read<ArticleCurationsCubit>().setText(false, value);
              },
              decoration: InputDecoration(
                hintText: 'Description',
              ),
              minLines: 5,
              maxLines: 5,
            ),
          ],
        );
      },
    );
  }
}

class AddItemToCurationView extends StatelessWidget {
  const AddItemToCurationView({
    Key? key,
    required this.articleId,
    required this.articlePubkey,
    required this.kind,
  }) : super(key: key);

  final String articleId;
  final String articlePubkey;
  final int kind;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ArticleCurationsCubit(
        articleId: articleId,
        articleAuthor: articlePubkey,
        kind: kind,
        nostrRepository: context.read<NostrDataRepository>(),
      ),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.60,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, controller) => Column(
              children: [
                ModalBottomSheetHandle(),
                BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
                  buildWhen: (previous, current) =>
                      previous.articleCuration != current.articleCuration,
                  builder: (context, state) {
                    return SizedBox(
                      height: kToolbarHeight - 5,
                      child: Center(
                        child: Stack(
                          children: [
                            if (state.articleCuration !=
                                ArticleCuration.curationsList)
                              IconButton(
                                onPressed: () {
                                  context
                                      .read<ArticleCurationsCubit>()
                                      .setView(ArticleCuration.curationsList);
                                },
                                icon: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 20,
                                ),
                              ),
                            Center(
                              child: Text(
                                state.articleCuration ==
                                        ArticleCuration.curationsList
                                    ? 'Add ${state.curationKind == EventKind.CURATION_ARTICLES ? 'article' : 'video'} to curation'
                                    : 'Submit curation',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 0,
                ),
                BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
                  builder: (context, state) {
                    return Expanded(
                      child: getView(
                        state.articleCuration,
                        controller,
                        state,
                        context,
                      ),
                    );
                  },
                ),
                ArticleCurationsBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget getView(
    ArticleCuration isCurationsList,
    ScrollController controller,
    ArticleCurationsState state,
    BuildContext context,
  ) {
    return isCurationsList == ArticleCuration.curationsList
        ? ArticleSuggestedCurationList(
            scrollController: controller,
          )
        : isCurationsList == ArticleCuration.curationContent
            ? AddCuration(
                controller: controller,
              )
            : isCurationsList == ArticleCuration.zaps
                ? BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
                    builder: (context, state) {
                      return ContentZapSplits(
                        isZapSplitEnabled: state.isZapSplitEnabled,
                        zaps: state.zapsSplits,
                        onToggleZapSplit: () {
                          context
                              .read<ArticleCurationsCubit>()
                              .toggleZapsSplits();
                        },
                        onAddZapSplitUser: (pubkey) {
                          context
                              .read<ArticleCurationsCubit>()
                              .addZapSplit(pubkey);
                        },
                        onRemoveZapSplitUser: (pubkey) {
                          context
                              .read<ArticleCurationsCubit>()
                              .onRemoveZapSplit(pubkey);
                        },
                        onSetZapProportions: (index, zap, percentage) {
                          context
                              .read<ArticleCurationsCubit>()
                              .setZapPropertion(
                                index: index,
                                zapSplit: zap,
                                newPercentage: percentage,
                              );
                        },
                      );
                    },
                  )
                : ArticleSelectedRelays(
                    selectedRelays: state.selectedRelays,
                    totaRelays: state.totalRelays,
                    onToggle: (relay) {
                      if (!mandatoryRelays.contains(relay)) {
                        context
                            .read<ArticleCurationsCubit>()
                            .setRelaySelection(relay);
                      }
                    },
                    deleteDraft: false,
                    isDraft: false,
                    isDraftShown: false,
                    isForwardedAsDraft: false,
                    onDeleteDraft: () {},
                  );
  }
}

class ArticleCurationsBottomBar extends HookWidget {
  ArticleCurationsBottomBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArticleCurationsCubit, ArticleCurationsState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding,
            vertical: kDefaultPadding / 4,
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(
                visible: state.articleCuration == ArticleCuration.relays ||
                    state.articleCuration == ArticleCuration.zaps,
                child: IconButton(
                  onPressed: () {
                    context
                        .read<ArticleCurationsCubit>()
                        .setView(ArticleCuration.curationContent);
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
              TextButton.icon(
                onPressed: () {
                  if (state.articleCuration == ArticleCuration.curationsList) {
                    context
                        .read<ArticleCurationsCubit>()
                        .setView(ArticleCuration.curationContent);
                  } else if (state.articleCuration ==
                      ArticleCuration.curationContent) {
                    final isTitleEmpty = state.title.trim().isEmpty;
                    final isDescriptionEmpty = state.description.trim().isEmpty;

                    final isDisabled = !state.isImageSelected ||
                        state.title.trim().isEmpty ||
                        state.description.trim().isEmpty;

                    if (isDisabled) {
                      final text = isTitleEmpty
                          ? 'Make sure to add a valid title for this curation'
                          : isDescriptionEmpty
                              ? 'Make sure to add a valid description for this curation'
                              : 'Make sure to add a valid image for this curation';

                      singleSnackBar(
                        context: context,
                        message: text,
                        color: kRed,
                        backGroundColor: kRedSide,
                        icon: ToastsIcons.error,
                      );
                    } else {
                      context.read<ArticleCurationsCubit>().setView(
                            ArticleCuration.zaps,
                          );
                    }
                  } else if (state.articleCuration == ArticleCuration.zaps) {
                    context.read<ArticleCurationsCubit>().setView(
                          ArticleCuration.relays,
                        );
                  } else {
                    context.read<ArticleCurationsCubit>().addCuration(
                      onFailure: (message) {
                        singleSnackBar(
                          context: context,
                          message: message,
                          color: kRed,
                          backGroundColor: kRedSide,
                          icon: ToastsIcons.error,
                        );
                      },
                    );
                  }
                },
                icon: Text(
                  state.articleCuration == ArticleCuration.curationsList
                      ? 'Add curation'
                      : state.articleCuration ==
                                  ArticleCuration.curationContent ||
                              state.articleCuration == ArticleCuration.zaps
                          ? 'Next'
                          : 'Submit curation',
                ),
                label: Icon(
                  state.articleCuration == ArticleCuration.curationsList
                      ? Icons.add_rounded
                      : state.articleCuration ==
                                  ArticleCuration.curationContent ||
                              state.articleCuration == ArticleCuration.zaps
                          ? Icons.arrow_forward_ios_rounded
                          : Icons.check,
                  size: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
