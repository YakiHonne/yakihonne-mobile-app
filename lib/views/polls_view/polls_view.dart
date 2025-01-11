// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/polls_cubit/polls_cubit.dart';
import 'package:yakihonne/blocs/single_event_cubit/single_event_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/poll_model.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/classic_footer.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/note_container.dart';
import 'package:yakihonne/views/zap_view/set_zaps_view.dart';

class PollsView extends StatefulWidget {
  const PollsView({
    Key? key,
    required this.scrollController,
  }) : super(key: key);
  final ScrollController scrollController;
  @override
  State<PollsView> createState() => _PollsViewState();
}

class _PollsViewState extends State<PollsView> {
  final refreshController = RefreshController();

  void onRefresh({required Function onInit}) {
    refreshController.resetNoData();
    onInit.call();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocProvider(
      create: (context) => PollsCubit(),
      child: BlocConsumer<PollsCubit, PollsState>(
        listener: (context, state) {
          if (state.loadingState == UpdatingState.success) {
            refreshController.loadComplete();
          } else if (state.loadingState == UpdatingState.idle) {
            refreshController.loadNoData();
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return Center(
              child: SpinKitPulse(
                color: Theme.of(context).primaryColorDark,
                size: 20,
              ),
            );
          } else if (state.polls.isEmpty) {
            return EmptyList(
              description: 'No polls can be found',
              icon: FeatureIcons.polls,
            );
          } else {
            return SmartRefresher(
              controller: refreshController,
              enablePullDown: false,
              enablePullUp: true,
              header: const MaterialClassicHeader(
                color: kPurple,
              ),
              footer: const RefresherClassicFooter(),
              onLoading: () => context
                  .read<PollsCubit>()
                  .getPolls(isAdd: true, isSelf: false),
              onRefresh: () => onRefresh(
                onInit: () => context
                    .read<PollsCubit>()
                    .getPolls(isAdd: false, isSelf: false),
              ),
              child: isTablet
                  ? MasonryGridView.count(
                      crossAxisCount: 2,
                      itemCount: state.polls.length,
                      crossAxisSpacing: kDefaultPadding / 2,
                      mainAxisSpacing: kDefaultPadding / 2,
                      padding: const EdgeInsets.all(kDefaultPadding / 2),
                      itemBuilder: (context, index) {
                        final poll = state.polls[index];

                        return PollContainer(
                          poll: poll,
                          includeUser: true,
                        );
                      },
                    )
                  : ListView.separated(
                      itemCount: state.polls.length,
                      padding: const EdgeInsets.all(kDefaultPadding / 2),
                      separatorBuilder: (context, index) => const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                      itemBuilder: (context, index) {
                        final poll = state.polls[index];

                        return PollContainer(
                          poll: poll,
                          includeUser: true,
                        );
                      },
                    ),
            );
          }
        },
      ),
    );
  }
}

class PollContainer extends HookWidget {
  const PollContainer({
    required this.poll,
    required this.includeUser,
    this.contentColor,
    this.optionBackgroundColor,
    this.optionTextColor,
    this.optionForegroundColor,
    this.onTap,
  });

  final PollModel poll;
  final bool includeUser;
  final Color? contentColor;
  final Color? optionBackgroundColor;
  final Color? optionTextColor;
  final Color? optionForegroundColor;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final votesByZaps = useState(true);
    final hasPubkey = useState(false);
    final hasReachedEnd = useState(false);
    final displayResults = useState(PollStatsStatus.idle);
    final pollStats = useState(singleEventCubit.state.pollStats[poll.id] ?? []);

    final searchFunc = useCallback(
      (bool showMessage) {
        pollStats.value = singleEventCubit.state.pollStats[poll.id] ?? [];

        hasReachedEnd.value = poll.closedAt != DateTime(1950, 1, 1) &&
            DateTime.now().compareTo(poll.closedAt) > 1;

        if (hasReachedEnd.value ||
            (isUsingPrivatekey() &&
                poll.pubkey == nostrRepository.usm!.pubKey)) {
          displayResults.value = PollStatsStatus.visible;
        } else {
          hasPubkey.value = isUsingPrivatekey() &&
              pollStats.value
                  .where((element) =>
                      element.pubkey == nostrRepository.usm!.pubKey)
                  .isNotEmpty;

          if (hasPubkey.value) {
            displayResults.value = PollStatsStatus.visible;
          } else {
            if (showMessage)
              BotToastUtils.showWarning(
                'You should vote to be able to see stats',
              );

            displayResults.value = PollStatsStatus.invisible;
          }
        }
      },
    );

    return BlocBuilder<SingleEventCubit, SingleEventState>(
      buildWhen: (previous, current) =>
          previous.pollStats[poll.id] != current.pollStats[poll.id],
      builder: (context, state) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                !includeUser ? null : const EdgeInsets.all(kDefaultPadding / 2),
            decoration: !includeUser
                ? null
                : BoxDecoration(
                    color: Theme.of(context).primaryColorLight,
                    borderRadius: BorderRadius.circular(
                      kDefaultPadding / 2,
                    ),
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (includeUser) ...[
                  ProfileInfoHeader(
                    createdAt: poll.createdAt,
                    pubkey: poll.pubkey,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ],
                linkifiedText(
                  context: context,
                  text: poll.content.trim(),
                  color: contentColor,
                  inverseNoteColor: includeUser,
                ),
                SizedBox(
                  height: kDefaultPadding,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Options',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: contentColor,
                                ),
                          ),
                          Text(
                            'Total: ${poll.options.length}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(color: contentColor),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        votesByZaps.value = !votesByZaps.value;
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: optionBackgroundColor ??
                            Theme.of(context).primaryColorLight,
                        visualDensity: VisualDensity(
                          vertical: -2,
                          horizontal: -2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: kDefaultPadding / 2,
                        ),
                      ),
                      icon: SvgPicture.asset(
                        votesByZaps.value
                            ? FeatureIcons.zap
                            : FeatureIcons.user,
                        width: 15,
                        height: 15,
                        colorFilter: ColorFilter.mode(
                          optionTextColor ?? Theme.of(context).primaryColorDark,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: Text(
                        'Votes by ${votesByZaps.value ? 'zaps' : 'users'}',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: optionTextColor ??
                                Theme.of(context).primaryColorDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                ...poll.options
                    .map(
                      (e) => Builder(
                        builder: (context) {
                          num val = 0;
                          num total = 0;

                          final ps = getPollStats(
                            total: pollStats.value,
                            pollOption: e,
                            poll: poll,
                          );

                          final vps = getValidPollStats(
                            total: pollStats.value,
                            poll: poll,
                          );

                          final selfVote = hasPubkey.value &&
                              ps
                                  .where((element) =>
                                      element.pubkey ==
                                      nostrRepository.usm!.pubKey)
                                  .isNotEmpty;

                          for (final p in ps) {
                            val += p.zapAmount;
                          }

                          for (final v in vps) {
                            total += v.zapAmount;
                          }

                          return PollOptionContainer(
                            pollOption: e,
                            selfVote: selfVote,
                            val: votesByZaps.value ? val : ps.length,
                            displayResults:
                                displayResults.value == PollStatsStatus.visible,
                            backgroundColor: optionBackgroundColor,
                            textColor: optionTextColor,
                            fillColor: optionForegroundColor,
                            total: votesByZaps.value ? total : vps.length,
                            onClick: () async {
                              if (isUsingPrivatekey() &&
                                  displayResults.value !=
                                      PollStatsStatus.visible &&
                                  !hasPubkey.value) {
                                final user = await authorsCubit
                                    .getFutureAuthor(poll.zapPubkey);

                                if (user != null) {
                                  if (user.pubKey ==
                                      nostrRepository.usm!.pubKey) {
                                    return;
                                  }

                                  singleEventCubit.zapPollSearch(
                                    poll.id,
                                    () async {
                                      searchFunc.call(false);

                                      if (hasPubkey.value) {
                                        BotToastUtils.showWarning(
                                          'You have already voted on this poll',
                                        );
                                      } else {
                                        showModalBottomSheet(
                                          elevation: 0,
                                          context: context,
                                          builder: (_) {
                                            return SetZapsView(
                                              author: user,
                                              pollOption: e.index.toString(),
                                              isZapSplit: false,
                                              zapSplits: [],
                                              eventId: poll.id,
                                              valMax: poll.valMax,
                                              valMin: poll.valMin,
                                              onSuccess: () async {
                                                await Future.delayed(
                                                  const Duration(
                                                    seconds: 1,
                                                  ),
                                                ).then(
                                                  (value) => singleEventCubit
                                                      .zapPollSearch(
                                                    poll.id,
                                                    () {
                                                      searchFunc.call(true);
                                                    },
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                          isScrollControlled: true,
                                          useRootNavigator: true,
                                          useSafeArea: true,
                                          backgroundColor: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                        );
                                      }
                                    },
                                  );
                                } else {
                                  BotToastUtils.showError(
                                    'User cannot be found',
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                    )
                    .toList(),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    displayResults.value == PollStatsStatus.visible
                        ? Builder(
                            builder: (context) {
                              final vps = getValidPollStats(
                                total: pollStats.value,
                                poll: poll,
                              );

                              return Text(
                                'Votes: ${vps.length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                      color: contentColor,
                                    ),
                              );
                            },
                          )
                        : displayResults.value == PollStatsStatus.invisible
                            ? Text(
                                'Vote is required to display stats.',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                      color: contentColor,
                                    ),
                              )
                            : GestureDetector(
                                onTap: () {
                                  singleEventCubit.zapPollSearch(
                                    poll.id,
                                    () {
                                      searchFunc.call(true);
                                    },
                                  );
                                },
                                child: Text(
                                  'Show stats',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall!
                                      .copyWith(
                                        decoration: TextDecoration.underline,
                                        color: contentColor,
                                      ),
                                ),
                              ),
                    if (poll.closedAt != DateTime(1950, 1, 1)) ...[
                      const SizedBox(
                        height: kDefaultPadding / 8,
                      ),
                      Text(
                        '${poll.closedAt.compareTo(DateTime.now()) > 0 ? 'Closes at: ' : 'Closed at: '}${dateFormat3.format(poll.closedAt)}',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: contentColor,
                            ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PollStat> getPollStats({
    required List<PollStat> total,
    required PollOption pollOption,
    required PollModel poll,
  }) {
    final pollMax = poll.valMax;
    final pollMin = poll.valMin;
    List<PollStat> pollStats = [];

    for (final pollStat in total) {
      if (pollStat.index == pollOption.index) {
        if (pollMin != -1 && pollStat.zapAmount < pollMin) {
          break;
        }

        if (pollMax != -1 && pollStat.zapAmount > pollMax) {
          break;
        }

        pollStats.add(pollStat);
      }
    }

    return pollStats;
  }

  List<PollStat> getValidPollStats({
    required List<PollStat> total,
    required PollModel poll,
  }) {
    List<PollStat> pollStats = [];

    for (final pollStat in total) {
      if ((poll.valMax == -1 || pollStat.zapAmount <= poll.valMax) &&
          (poll.valMin == -1 || pollStat.zapAmount >= poll.valMin)) {
        pollStats.add(pollStat);
      }
    }

    return pollStats;
  }
}

class PollOptionContainer extends StatelessWidget {
  const PollOptionContainer({
    Key? key,
    required this.pollOption,
    required this.displayResults,
    required this.val,
    required this.total,
    required this.selfVote,
    required this.onClick,
    this.textColor,
    this.backgroundColor,
    this.fillColor,
  }) : super(key: key);

  final PollOption pollOption;
  final bool displayResults;
  final num val;
  final num total;
  final bool selfVote;
  final Function() onClick;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(
          bottom: kDefaultPadding / 4,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(300),
          border: selfVote
              ? Border.all(
                  color: (fillColor ?? kOrange),
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(300),
          child: Stack(
            children: [
              Positioned.fill(
                child: LinearProgressIndicator(
                  color: (fillColor ?? kOrange),
                  backgroundColor: backgroundColor ??
                      Theme.of(context).unselectedWidgetColor,
                  borderRadius: BorderRadius.circular(300),
                  value: displayResults
                      ? total == 0
                          ? 0
                          : val / total
                      : 0.05,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                  vertical: kDefaultPadding / 1.8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        pollOption.content,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium!
                            .copyWith(
                                color: textColor ??
                                    Theme.of(context).primaryColorDark),
                      ),
                    ),
                    if (displayResults)
                      Text(
                        val.toStringAsFixed(0),
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium!
                            .copyWith(
                                color: textColor ??
                                    Theme.of(context).primaryColorDark),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
