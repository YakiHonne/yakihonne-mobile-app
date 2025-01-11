import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/points_management_cubit/points_management_cubit.dart';
import 'package:yakihonne/models/points_system_models.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/points_management_view/widgets/consumable_points_view.dart';
import 'package:yakihonne/views/points_management_view/widgets/income_chart.dart';
import 'package:yakihonne/views/points_management_view/widgets/one_time_reward_container.dart';
import 'package:yakihonne/views/points_management_view/widgets/repeated_reward_container.dart';
import 'package:yakihonne/views/points_management_view/widgets/tier_view.dart';
import 'package:yakihonne/views/widgets/modal_with_blur.dart';

class PointsStatContainers extends StatelessWidget {
  const PointsStatContainers({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<PointsManagementCubit, PointsManagementState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    'Points system',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ),
              if (isTablet)
                SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: ChatContainer()),
                      const SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            XpContainer(),
                            const SizedBox(
                              height: kDefaultPadding / 2,
                            ),
                            PointContainer(),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: XpContainer(),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ),
                SliverToBoxAdapter(child: PointContainer()),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ),
                SliverToBoxAdapter(child: ChatContainer()),
              ],
              SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding,
                ),
              ),
              SliverToBoxAdapter(
                child: Text(
                  'One time rewards',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: kDimGrey,
                      ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ),
              if (isTablet)
                SliverToBoxAdapter(
                  child: MasonryGridView.builder(
                    shrinkWrap: true,
                    primary: false,
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        SliverSimpleGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                    ),
                    mainAxisSpacing: kDefaultPadding / 2,
                    crossAxisSpacing: kDefaultPadding / 2,
                    itemBuilder: (context, index) {
                      final standard = state
                          .userGlobalStats!.onetimePointStandards.values
                          .toList()[index];
                      final standardAction =
                          state.userGlobalStats!.actions[standard.id];

                      final isCompleted =
                          standard.count == standardAction?.count;

                      final remainingAttempts =
                          standard.count - (standardAction?.count ?? 0);

                      int total = 0;
                      int count = 0;

                      if (standardAction != null) {
                        total = standardAction.allTimePoints;
                        count = standardAction.allTimePoints;
                      } else {
                        total = standard.points.first;
                      }

                      return OneTimeRewardContainer(
                        standard: standard,
                        count: count,
                        total: total,
                        isCompleted: isCompleted,
                        standardAction: standardAction,
                        remainingAttempts: remainingAttempts,
                      );
                    },
                    itemCount: state
                        .userGlobalStats!.onetimePointStandards.values.length,
                  ),
                )
              else
                SliverList.separated(
                  itemBuilder: (context, index) {
                    final standard = state
                        .userGlobalStats!.onetimePointStandards.values
                        .toList()[index];
                    final standardAction =
                        state.userGlobalStats!.actions[standard.id];

                    final isCompleted = standard.count == standardAction?.count;

                    final remainingAttempts =
                        standard.count - (standardAction?.count ?? 0);

                    int total = 0;
                    int count = 0;

                    if (standardAction != null) {
                      total = standardAction.allTimePoints;
                      count = standardAction.allTimePoints;
                    } else {
                      total = standard.points.first;
                    }

                    return OneTimeRewardContainer(
                      standard: standard,
                      count: count,
                      total: total,
                      isCompleted: isCompleted,
                      standardAction: standardAction,
                      remainingAttempts: remainingAttempts,
                    );
                  },
                  itemCount: state
                      .userGlobalStats!.onetimePointStandards.values.length,
                  separatorBuilder: (context, index) => const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding,
                ),
              ),
              SliverToBoxAdapter(
                child: Text(
                  'Repeated rewards',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: kDimGrey,
                      ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ),
              if (isTablet)
                SliverToBoxAdapter(
                  child: MasonryGridView.builder(
                    shrinkWrap: true,
                    primary: false,
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        SliverSimpleGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                    ),
                    mainAxisSpacing: kDefaultPadding / 2,
                    crossAxisSpacing: kDefaultPadding / 2,
                    itemBuilder: (context, index) {
                      final standard = state
                          .userGlobalStats!.repeatedPointStandards.values
                          .toList()[index];
                      final standardAction =
                          state.userGlobalStats!.actions[standard.id];

                      int cooldownVal = 0;
                      int collectedPoints = 0;

                      if (standard.cooldown == 0) {
                        cooldownVal = -1;
                        if (standardAction != null) {
                          collectedPoints = standardAction.allTimePoints;
                        }
                      } else {
                        if (standardAction != null) {
                          final actionUnixTimeStamp =
                              standardAction.lastUpdated.toSecondsSinceEpoch() +
                                  standard.cooldown;
                          final currentUnixTimeStamp =
                              currentUnixTimestampSeconds();

                          if (actionUnixTimeStamp > currentUnixTimeStamp) {
                            final remaining =
                                actionUnixTimeStamp - currentUnixTimeStamp;

                            cooldownVal =
                                Duration(seconds: remaining).inMinutes;
                          }

                          collectedPoints = standardAction.allTimePoints;
                        }
                      }

                      return RepeatedReward(
                        standard: standard,
                        cooldownVal: cooldownVal,
                        collectedPoints: collectedPoints,
                      );
                    },
                    itemCount: state
                        .userGlobalStats!.repeatedPointStandards.values.length,
                  ),
                )
              else
                SliverList.separated(
                  itemBuilder: (context, index) {
                    final standard = state
                        .userGlobalStats!.repeatedPointStandards.values
                        .toList()[index];
                    final standardAction =
                        state.userGlobalStats!.actions[standard.id];

                    int cooldownVal = 0;
                    int collectedPoints = 0;

                    if (standard.cooldown == 0) {
                      cooldownVal = -1;
                      if (standardAction != null) {
                        collectedPoints = standardAction.allTimePoints;
                      }
                    } else {
                      if (standardAction != null) {
                        final actionUnixTimeStamp =
                            standardAction.lastUpdated.toSecondsSinceEpoch() +
                                standard.cooldown;
                        final currentUnixTimeStamp =
                            currentUnixTimestampSeconds();

                        if (actionUnixTimeStamp > currentUnixTimeStamp) {
                          final remaining =
                              actionUnixTimeStamp - currentUnixTimeStamp;

                          cooldownVal = Duration(seconds: remaining).inMinutes;
                        }

                        collectedPoints = standardAction.allTimePoints;
                      }
                    }

                    return RepeatedReward(
                      standard: standard,
                      cooldownVal: cooldownVal,
                      collectedPoints: collectedPoints,
                    );
                  },
                  itemCount: state
                      .userGlobalStats!.repeatedPointStandards.values.length,
                  separatorBuilder: (context, index) => const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: kBottomNavigationBarHeight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChatContainer extends StatelessWidget {
  const ChatContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PointsManagementCubit, PointsManagementState>(
      builder: (context, state) {
        List<Chart> chartList = [];

        for (final standard
            in state.userGlobalStats!.repeatedPointStandards.values) {
          final chart = Chart(
            standard: standard,
            action: state.userGlobalStats!.actions[standard.id],
          );

          chartList.add(chart);
        }

        return IncomeChart(
          chart: chartList,
        );
      },
    );
  }
}

class PointContainer extends StatelessWidget {
  const PointContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PointsManagementCubit, PointsManagementState>(
      builder: (context, state) {
        final points = (state.currentXp - state.consumablePoints);

        return Container(
          padding: const EdgeInsets.all(
            kDefaultPadding / 2,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
            borderRadius: BorderRadius.circular(
              kDefaultPadding / 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    points.toString(),
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    ' / ${state.currentXp} ',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: kDimGrey,
                        ),
                  ),
                  Text(
                    'points',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w500,
                          color: kDimGrey,
                        ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      showBlurredModal(
                        context: context,
                        view: ConsumablePointsView(),
                      );
                    },
                    child: Text(
                      "What's this?",
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: kWhite,
                          ),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity(
                        horizontal: -2,
                        vertical: -2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              LinearProgressIndicator(
                value: state.consumablePoints / state.currentXp,
                color: kRed,
                minHeight: 5,
                backgroundColor: kBlack.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(
                  kDefaultPadding / 2,
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Consumable points',
                      style:
                          Theme.of(context).textTheme.labelMedium!.copyWith(),
                    ),
                  ),
                  Text(
                    'last used ${points == 0 ? 'N/A' : dateFormat2.format(state.userGlobalStats!.currentPointsLastUpdated)}',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class XpContainer extends StatelessWidget {
  const XpContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PointsManagementCubit, PointsManagementState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(
            kDefaultPadding / 2,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
            borderRadius: BorderRadius.circular(
              kDefaultPadding / 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    state.currentXp.toString(),
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 4,
                  ),
                  Text(
                    'xp',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(fontWeight: FontWeight.w600, color: kDimGrey),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  Text(
                    'lvl',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 4,
                  ),
                  Text(
                    '${state.currentLevel}',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: kOrange,
                        ),
                  ),
                  Spacer(),
                  ...state.userGlobalStats!.pointSystemTiers.values.map(
                    (tier) {
                      final isUnlocked = tier.getStats()['isUnlocked'];

                      return Opacity(
                        opacity: isUnlocked ? 1 : 0.5,
                        child: IconButton(
                          style: IconButton.styleFrom(
                            visualDensity: VisualDensity(
                              horizontal: -2,
                              vertical: -2,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            showBlurredModal(
                              context: context,
                              view: TierView(
                                tier: tier,
                              ),
                            );
                          },
                          icon: Image.asset(
                            isUnlocked ? tier.icon : Images.silverTier,
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ],
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${state.nextLevelXp - state.currentLevelXp - state.additionalXp} remaining',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    'Level ${state.currentLevel + 1}',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: kOrange,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              LinearProgressIndicator(
                value: state.percentage,
                color: kRed,
                minHeight: 5,
                backgroundColor: kBlack.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(
                  kDefaultPadding / 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
