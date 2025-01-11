// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/blocs/self_curations_cubit/self_curations_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/curation_view/curation_view.dart';
import 'package:yakihonne/views/search_view/search_view.dart';
import 'package:yakihonne/views/self_curations_view/widgets/add_curation_articles.dart';
import 'package:yakihonne/views/self_curations_view/widgets/add_self_curation.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/no_content_widgets.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class SelfCurationsView extends HookWidget {
  SelfCurationsView({
    Key? key,
    required this.mainScrollController,
  }) {
    FirebaseAnalytics.instance
        .setCurrentScreen(screenName: 'My curations screen');
  }

  final ScrollController mainScrollController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SelfCurationsCubit(
        nostrRepository: context.read<NostrDataRepository>(),
      ),
      child: BlocBuilder<SelfCurationsCubit, SelfCurationsState>(
        buildWhen: (previous, current) =>
            previous.isActualUser != current.isActualUser ||
            previous.isUserConnected != current.isUserConnected,
        builder: (context, state) {
          return getView(
            isUserConnected: state.isUserConnected,
            isActualUser: state.isActualUser,
            context: context,
          );
        },
      ),
    );
  }

  Widget getView({
    required bool isUserConnected,
    required bool isActualUser,
    required BuildContext context,
  }) {
    if (isUserConnected) {
      if (isActualUser) {
        return CurationsList(
          scrollController: mainScrollController,
        );
      } else {
        return NoPrivateWidget(
          title: 'Private key required!',
          description:
              "It seems that you don't own this account, please reconnect with the secret key to commit actions on this account.",
          icon: PagesIcons.noPrivate,
          buttonText: 'Logout',
          onClicked: () {
            context.read<MainCubit>().disconnect();
          },
        );
      }
    } else {
      return NotConnectedWidget();
    }
  }
}

class CurationsList extends HookWidget {
  const CurationsList({required this.scrollController, super.key});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelfCurationsCubit, SelfCurationsState>(
      buildWhen: (previous, current) =>
          previous.curations != current.curations ||
          previous.isCurationsLoading != current.isCurationsLoading,
      builder: (context, state) {
        return Stack(
          children: [
            Scrollbar(
              controller: scrollController,
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  BlocBuilder<SelfCurationsCubit, SelfCurationsState>(
                    builder: (context, state) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding / 2,
                            vertical: kDefaultPadding,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${state.curations.length.toString().padLeft(2, '0')} Curations',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    Text(
                                      '(In ${state.chosenRelay.isEmpty ? 'all relays' : state.chosenRelay.split('wss://')[1]})',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall!
                                          .copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: kOrange,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              CurationTypeToggle(
                                isArticlesCuration: state.isArticleCurations,
                                onToggle: () {
                                  context
                                      .read<SelfCurationsCubit>()
                                      .togglerCurationType();
                                },
                              ),
                              const SizedBox(
                                width: kDefaultPadding / 8,
                              ),
                              PullDownButton(
                                animationBuilder: (context, state, child) {
                                  return child;
                                },
                                routeTheme: PullDownMenuRouteTheme(
                                  backgroundColor:
                                      Theme.of(context).primaryColorLight,
                                ),
                                itemBuilder: (context) {
                                  final activeRelays = NostrConnect
                                      .sharedInstance
                                      .activeRelays();

                                  return [
                                    PullDownMenuItem.selectable(
                                      onTap: () {
                                        context
                                            .read<SelfCurationsCubit>()
                                            .getCurations(relay: '');
                                      },
                                      selected: state.chosenRelay.isEmpty,
                                      title: 'All relays',
                                      itemTheme: PullDownMenuItemTheme(
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .labelMedium!
                                            .copyWith(
                                              fontWeight:
                                                  state.chosenRelay.isEmpty
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                            ),
                                      ),
                                    ),
                                    ...state.relays
                                        .map(
                                          (e) => PullDownMenuItem.selectable(
                                            onTap: () {
                                              context
                                                  .read<SelfCurationsCubit>()
                                                  .getCurations(relay: e);
                                            },
                                            selected: e == state.chosenRelay,
                                            title: e.split('wss://')[1],
                                            iconColor: activeRelays.contains(e)
                                                ? kGreen
                                                : kRed,
                                            iconWidget: Icon(
                                              CupertinoIcons.circle_fill,
                                              size: 7,
                                            ),
                                            itemTheme: PullDownMenuItemTheme(
                                              textStyle: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium!
                                                  .copyWith(
                                                    fontWeight:
                                                        state.chosenRelay == e
                                                            ? FontWeight.w500
                                                            : FontWeight.w400,
                                                  ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ];
                                },
                                buttonBuilder: (context, showMenu) =>
                                    IconButton(
                                  onPressed: showMenu,
                                  padding: EdgeInsets.zero,
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColorLight,
                                  ),
                                  icon: SvgPicture.asset(
                                    FeatureIcons.relays,
                                    width: 20,
                                    height: 20,
                                    colorFilter: ColorFilter.mode(
                                      Theme.of(context).primaryColorDark,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AddSelfCurationView.routeName,
                                    arguments: [
                                      context.read<SelfCurationsCubit>(),
                                      true,
                                    ],
                                  );
                                },
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColorLight,
                                ),
                                icon: SvgPicture.asset(
                                  FeatureIcons.add,
                                  width: 20,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context).primaryColorDark,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  BlocBuilder<SelfCurationsCubit, SelfCurationsState>(
                    builder: (context, state) {
                      final selectedCurtions = state.isArticleCurations
                          ? state.curations
                              .where((element) => element.isArticleCuration())
                              .toList()
                          : state.curations
                              .where((element) => !element.isArticleCuration())
                              .toList();

                      if (selectedCurtions.isEmpty &&
                          !state.isCurationsLoading) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 2,
                            ),
                            child: EmptyList(
                              description:
                                  'No curations were found on this relay.',
                              icon: FeatureIcons.selfCurations,
                            ),
                          ),
                        );
                      }

                      if (state.isCurationsLoading) {
                        return SliverToBoxAdapter(
                          child: SearchLoading(),
                        );
                      } else {
                        return SliverPadding(
                          padding: const EdgeInsets.only(
                            bottom: kDefaultPadding,
                          ),
                          sliver: SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding / 2,
                            ),
                            sliver: ResponsiveBreakpoints.of(context)
                                    .largerThan(MOBILE)
                                ? SliverGrid.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: kDefaultPadding / 2,
                                      mainAxisExtent: 350,
                                    ),
                                    itemBuilder: (context, index) {
                                      final curation = selectedCurtions[index];

                                      return SelfCurationContainerMethod(
                                        curation: curation,
                                        relays: curation.relays.toList(),
                                        relaysColors: state.relaysColors,
                                        chosenRelay: state.chosenRelay,
                                      );
                                    },
                                    itemCount: selectedCurtions.length,
                                  )
                                : SliverList.builder(
                                    itemBuilder: (context, index) {
                                      final curation = selectedCurtions[index];
                                      return SelfCurationContainerMethod(
                                        curation: curation,
                                        relays: curation.relays.toList(),
                                        relaysColors: state.relaysColors,
                                        chosenRelay: state.chosenRelay,
                                      );
                                    },
                                    itemCount: selectedCurtions.length,
                                  ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            ResetScrollButton(
              scrollController: scrollController,
              isLeft: true,
              padding: 20,
            ),
          ],
        );
      },
    );
  }
}

class SelfCurationContainerMethod extends StatelessWidget {
  const SelfCurationContainerMethod({
    Key? key,
    required this.curation,
    required this.relays,
    required this.relaysColors,
    required this.chosenRelay,
  }) : super(key: key);

  final Curation curation;
  final String chosenRelay;
  final List<String> relays;
  final Map<String, int> relaysColors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          CurationView.routeName,
          arguments: curation,
        );
      },
      child: SelfCurationContainer(
        curation: curation,
        relays: relays,
        relaysColors: relaysColors,
        onAdd: () {
          final newCuration =
              nostrRepository.curationsMemBox.getCurations[curation.identifier];
          final updatedCuration = curation.copyWith(
            relays: newCuration != null ? newCuration.relays : null,
          );

          Navigator.pushNamed(
            context,
            AddCurationArticlesView.routeName,
            arguments: [
              context.read<SelfCurationsCubit>(),
              updatedCuration,
            ],
          );
        },
        onEdit: () {
          Navigator.pushNamed(
            context,
            AddSelfCurationView.routeName,
            arguments: [
              context.read<SelfCurationsCubit>(),
              false,
              curation,
            ],
          );
        },
        onDelete: () {
          showDeletionDialogue(
            context: context,
            title: 'Delete ${curation.title}?',
            description:
                "You're about to delete this curation, do you wish to proceed?",
            buttonText: 'Delete curation',
            onDelete: () {
              context.read<SelfCurationsCubit>().deleteCuration(
                curation,
                () {
                  Navigator.of(context).pop();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class SelfCurationContainer extends StatelessWidget {
  const SelfCurationContainer({
    super.key,
    required this.curation,
    required this.onEdit,
    required this.onAdd,
    required this.onDelete,
    required this.relays,
    required this.relaysColors,
  });

  final Curation curation;
  final List<String> relays;
  final Map<String, int> relaysColors;
  final Function() onEdit;
  final Function() onAdd;
  final Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        color: Theme.of(context).primaryColorLight,
      ),
      margin: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      child: Column(
        children: [
          Stack(
            children: [
              if (curation.image.isEmpty)
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: errorContainer(),
                )
              else
                CachedNetworkImage(
                  imageUrl: curation.image,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                          kDefaultPadding,
                        ),
                        topRight: Radius.circular(
                          kDefaultPadding,
                        ),
                      ),
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => errorContainer(),
                ),
              Positioned(
                right: kDefaultPadding / 2,
                top: kDefaultPadding / 2,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: kWhite.withValues(alpha: 0.9),
                      child: IconButton(
                        onPressed: onAdd,
                        icon: SvgPicture.asset(
                          FeatureIcons.addCuration,
                          width: 25,
                          height: 25,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    ),
                    CircleAvatar(
                      backgroundColor: kWhite.withValues(alpha: 0.9),
                      child: IconButton(
                        onPressed: onEdit,
                        icon: SvgPicture.asset(
                          FeatureIcons.article,
                          width: 25,
                          height: 25,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    ),
                    CircleAvatar(
                      backgroundColor: kWhite.withValues(alpha: 0.9),
                      child: IconButton(
                        onPressed: onDelete,
                        icon: SvgPicture.asset(
                          FeatureIcons.trash,
                          width: 25,
                          height: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Last modified: ${dateFormat2.format(
                        curation.publishedAt,
                      )}',
                      style: Theme.of(context).textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    DotContainer(
                      color: kDimGrey,
                    ),
                    SvgPicture.asset(
                      curation.isArticleCuration()
                          ? FeatureIcons.selfArticles
                          : FeatureIcons.videoOcta,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).primaryColorDark,
                        BlendMode.srcIn,
                      ),
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 4,
                    ),
                    Text(
                      '${curation.eventsIds.length.toString().padLeft(2, '0')} ${curation.isArticleCuration() ? 'articles' : 'videos'}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Text(
                  curation.title,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Text(
                  curation.description,
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Divider(
            height: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 1.5),
            child: Row(
              children: [
                Text(
                  'Posted on',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    height: 15,
                    child: ListView.separated(
                      separatorBuilder: (context, index) {
                        return SizedBox(
                          width: kDefaultPadding / 4,
                        );
                      },
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final relay = relays[index];

                        return Tooltip(
                          message: relay,
                          textStyle: Theme.of(context)
                              .textTheme
                              .labelMedium!
                              .copyWith(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                          triggerMode: TooltipTriggerMode.tap,
                          child: Center(
                            child: DotContainer(
                              color: Color(
                                relaysColors[relay] ??
                                    Theme.of(context).primaryColorLight.value,
                              ),
                              size: 15,
                              isNotMarging: true,
                            ),
                          ),
                        );
                      },
                      itemCount: relays.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container errorContainer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topRight: const Radius.circular(kDefaultPadding),
          topLeft: const Radius.circular(kDefaultPadding),
        ),
        image: DecorationImage(
          image: AssetImage(Images.invalidMedia),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
