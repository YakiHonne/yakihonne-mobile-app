// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/curations_cubit/curations_cubit.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/curation_view/curation_view.dart';
import 'package:yakihonne/views/home_view/widgets/home_curation_container.dart';
import 'package:yakihonne/views/widgets/loading_indicators.dart';

class CurationsView extends StatelessWidget {
  CurationsView({
    Key? key,
    required this.mainScrollController,
  }) : super(key: key) {
    FirebaseAnalytics.instance
        .setCurrentScreen(screenName: 'List of curations screen');
  }

  final ScrollController mainScrollController;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CurationsCubit(
        nostrRepository: context.read<NostrDataRepository>(),
      )..getCurations(),
      child: Scrollbar(
        controller: mainScrollController,
        child: BlocBuilder<CurationsCubit, CurationsState>(
          builder: (context, state) {
            if (state.isCurationsLoading) {
              return LoadingWidget();
            } else {
              if (ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
                return NestedScrollView(
                  controller: mainScrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      CurationsViewHeader(),
                    ];
                  },
                  body: MasonryGridView.count(
                    crossAxisCount: 2,
                    itemCount: state.curations.length,
                    crossAxisSpacing: kDefaultPadding / 2,
                    mainAxisSpacing: kDefaultPadding,
                    padding: const EdgeInsets.all(kDefaultPadding / 2),
                    itemBuilder: (context, index) {
                      final curation = state.curations.elementAt(index);

                      return HomeCurationContainer(
                        curation: curation,
                        userStatus: state.userStatus,
                        isBookmarked:
                            state.bookmarks.contains(curation.identifier),
                        onClicked: () {
                          Navigator.pushNamed(
                            context,
                            CurationView.routeName,
                            arguments: curation,
                          );
                        },
                        padding: kDefaultPadding / 2,
                      );
                    },
                  ),
                );
              } else {
                return CustomScrollView(
                  controller: mainScrollController,
                  slivers: [
                    CurationsViewHeader(),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 4,
                      ),
                      sliver: SliverList.separated(
                        separatorBuilder: (context, index) => const SizedBox(
                          height: kDefaultPadding + 5,
                        ),
                        itemBuilder: (context, index) {
                          final curation = state.curations.elementAt(index);

                          return HomeCurationContainer(
                            curation: curation,
                            userStatus: state.userStatus,
                            isBookmarked:
                                state.bookmarks.contains(curation.identifier),
                            onClicked: () {
                              Navigator.pushNamed(
                                context,
                                CurationView.routeName,
                                arguments: curation,
                              );
                            },
                            padding: kDefaultPadding / 4,
                          );
                        },
                        itemCount: state.curations.length,
                      ),
                    )
                  ],
                );
              }
            }
          },
        ),
      ),
    );
  }
}

class CurationsViewHeader extends StatelessWidget {
  const CurationsViewHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurationsCubit, CurationsState>(
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
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      Text(
                        '(In ${state.chosenRelay.isEmpty ? 'all relays' : state.chosenRelay.split('wss://')[1]})',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              fontWeight: FontWeight.w500,
                              color: kOrange,
                            ),
                      ),
                    ],
                  ),
                ),
                PullDownButton(
                  animationBuilder: (context, state, child) {
                    return child;
                  },
                  routeTheme: PullDownMenuRouteTheme(
                    backgroundColor: Theme.of(context).primaryColorLight,
                  ),
                  itemBuilder: (context) {
                    final activeRelays =
                        NostrConnect.sharedInstance.activeRelays();

                    return [
                      PullDownMenuItem.selectable(
                        onTap: () {
                          context
                              .read<CurationsCubit>()
                              .filterCurationsByRelay(relay: '');
                        },
                        selected: state.chosenRelay.isEmpty,
                        title: 'All relays',
                        itemTheme: PullDownMenuItemTheme(
                          textStyle:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    fontWeight: state.chosenRelay.isEmpty
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
                                    .read<CurationsCubit>()
                                    .filterCurationsByRelay(relay: e);
                              },
                              selected: e == state.chosenRelay,
                              title: e.split('wss://')[1],
                              iconColor:
                                  activeRelays.contains(e) ? kGreen : kRed,
                              iconWidget: Icon(
                                CupertinoIcons.circle_fill,
                                size: 7,
                              ),
                              itemTheme: PullDownMenuItemTheme(
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(
                                      fontWeight: state.chosenRelay == e
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                    ),
                              ),
                            ),
                          )
                          .toList(),
                    ];
                  },
                  buttonBuilder: (context, showMenu) => IconButton(
                    onPressed: showMenu,
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColorLight,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
