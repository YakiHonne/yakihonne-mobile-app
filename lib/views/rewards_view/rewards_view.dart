// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/rewards_cubit/rewards_cubit.dart';
import 'package:yakihonne/blocs/single_event_cubit/single_event_cubit.dart';
import 'package:yakihonne/blocs/uncensored_notes_cubit/uncensored_notes_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/nostr/event.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/search_view/search_view.dart';
import 'package:yakihonne/views/uncensored_notes_view/uncensored_notes_view.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/un_flashnews_details.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/uncensored_note_component.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/flash_news_container.dart';
import 'package:yakihonne/views/widgets/no_content_widgets.dart';

class RewardsView extends HookWidget {
  const RewardsView({
    required this.uncensoredNotesCubit,
  });

  static const routeName = '/rewardsView';
  static Route route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (_) => RewardsView(
        uncensoredNotesCubit: settings.arguments as UncensoredNotesCubit,
      ),
    );
  }

  final UncensoredNotesCubit uncensoredNotesCubit;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();

    return BlocProvider(
      create: (context) =>
          RewardsCubit(uncensoredNotesCubit: uncensoredNotesCubit)..initView(),
      lazy: false,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Rewards',
        ),
        body: BlocBuilder<RewardsCubit, RewardsState>(
          builder: (context, state) {
            return Stack(
              children: [
                Scrollbar(
                  controller: scrollController,
                  child: NestedScrollView(
                    controller: scrollController,
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverToBoxAdapter(
                          child: BlocProvider.value(
                            value: uncensoredNotesCubit,
                            child: CommunityWalletContainer(
                              isMainView: false,
                              onClicked: () {
                                uncensoredNotesCubit.getBalance();
                                context.read<RewardsCubit>().initView();
                              },
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: kDefaultPadding,
                          ),
                        ),
                      ];
                    },
                    body: getView(updatingState: state.updatingState),
                  ),
                ),
                ResetScrollButton(
                  scrollController: scrollController,
                  isLeft: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget getView({
    required UpdatingState updatingState,
  }) {
    if (updatingState == UpdatingState.progress) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
        child: SearchLoading(),
      );
    } else if (updatingState == UpdatingState.success) {
      return RewardsList();
    } else if (updatingState == UpdatingState.failure) {
      return WrongView(
        onClicked: () {},
      );
    } else {
      return SizedBox.shrink();
    }
  }
}

class RewardsList extends StatelessWidget {
  const RewardsList({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return BlocBuilder<RewardsCubit, RewardsState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: state.rewards.isEmpty
              ? EmptyList(
                  description:
                      'You have no rewards, interact with or write uncensored notes in order to obtain them.',
                  icon: FeatureIcons.reward,
                )
              : isMobile
                  ? ListView.separated(
                      itemBuilder: (context, index) {
                        final reward = state.rewards[index];

                        return Container(
                          padding: const EdgeInsets.all(kDefaultPadding / 2),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding / 2),
                            color: Theme.of(context).primaryColorLight,
                          ),
                          child: getRewardColumn(reward),
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                      itemCount: state.rewards.length,
                    )
                  : MasonryGridView.builder(
                      gridDelegate:
                          SliverSimpleGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                      ),
                      mainAxisSpacing: kDefaultPadding / 2,
                      crossAxisSpacing: kDefaultPadding / 2,
                      itemBuilder: (context, index) {
                        final reward = state.rewards[index];

                        return Container(
                          padding: const EdgeInsets.all(kDefaultPadding / 2),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding / 2),
                            color: Theme.of(context).primaryColorLight,
                          ),
                          child: getRewardColumn(reward),
                        );
                      },
                      itemCount: state.rewards.length,
                    ),
        );
      },
    );
  }

  Widget getRewardColumn(RewardModel rewardModel) {
    if (rewardModel is RatingReward) {
      return RatingColumn(ratingReward: rewardModel);
    } else if (rewardModel is UncensoredNoteReward) {
      return UncensoredColumn(uncensoredNoteReward: rewardModel);
    } else if (rewardModel is SealedReward) {
      return SealedColumn(sealedReward: rewardModel);
    } else {
      return SizedBox.shrink();
    }
  }
}

class RatingColumn extends StatelessWidget {
  const RatingColumn({
    Key? key,
    required this.ratingReward,
  }) : super(key: key);

  final RatingReward ratingReward;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'On ${dateFormat4.format(ratingReward.rating.createdAt)}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  height: 1,
                ),
            children: [
              TextSpan(text: 'You have rated '),
              WidgetSpan(
                child: SvgPicture.asset(
                  ratingReward.rating.ratingValue
                      ? FeatureIcons.like
                      : FeatureIcons.dislike,
                  width: 15,
                  height: 15,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              TextSpan(text: ' the following note:'),
            ],
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        UncensoredNoteComponent(
          note: ratingReward.note,
          flashNewsPubkey: '-1',
          userStatus: getUserStatus(),
          isUncensoredNoteAuthor:
              ratingReward.note.pubKey == nostrRepository.usm!.pubKey,
          isComponent: false,
          isSealed: ratingReward.note.isUnSealed,
          sealedNote: ratingReward.note.isUnSealed
              ? SealedNote(
                  createdAt: ratingReward.note.createdAt,
                  uncensoredNote: ratingReward.note,
                  flashNewsId: ratingReward.note.flashNewsId,
                  noteAuthor: ratingReward.note.pubKey,
                  raters: [],
                  reasons: [],
                  isAuthentic: true,
                  isHelpful: true,
                  id: ratingReward.note.id,
                )
              : null,
          sealDisable: true,
          onDelete: (d) {},
          onLike: () {},
          onDislike: () {},
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        claim_button(
          status: ratingReward.status,
          createdAt: ratingReward.rating.createdAt,
          eventId: ratingReward.rating.id,
          kind: EventKind.REACTION,
          isAuthor: true,
          useTimer: true,
        ),
      ],
    );
  }
}

class UncensoredColumn extends StatelessWidget {
  const UncensoredColumn({
    Key? key,
    required this.uncensoredNoteReward,
  }) : super(key: key);

  final UncensoredNoteReward uncensoredNoteReward;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'On ${dateFormat4.format(uncensoredNoteReward.note.createdAt)}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Text(
          'You have left a note on this flash news:',
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                height: 1,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        BlocSelector<SingleEventCubit, SingleEventState, Event?>(
          selector: (state) => singleEventCubit.getEvent(
            uncensoredNoteReward.note.flashNewsId,
            false,
          ),
          builder: (context, event) {
            if (event == null) {
              return Text('Flash news loading ...');
            }

            final flash = FlashNews.fromEvent(event);

            return FlashNewsContainer(
              mainFlashNews: MainFlashNews(flashNews: flash),
              flashNewsType: FlashNewsType.display,
              userStatus: getUserStatus(),
              onClicked: () {
                Navigator.pushNamed(
                  context,
                  UnFlashNewsDetails.routeName,
                  arguments: UnFlashNews(
                    flashNews: flash,
                    uncensoredNotes: [],
                    isSealed: false,
                  ),
                );
              },
              isComponent: true,
            );
          },
          bloc: singleEventCubit,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        claim_button(
          status: uncensoredNoteReward.status,
          eventId: uncensoredNoteReward.note.id,
          createdAt: uncensoredNoteReward.note.createdAt,
          kind: EventKind.TEXT_NOTE,
          isAuthor: true,
          useTimer: false,
        ),
      ],
    );
  }
}

class SealedColumn extends StatelessWidget {
  const SealedColumn({
    Key? key,
    required this.sealedReward,
  }) : super(key: key);

  final SealedReward sealedReward;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'On ${dateFormat4.format(sealedReward.note.createdAt)}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Text(
          sealedReward.isAuthor
              ? 'Your following note just got sealed:'
              : 'You have rated the following note which got sealed:',
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                height: 1,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        UncensoredNoteComponent(
          note: sealedReward.note.uncensoredNote,
          flashNewsPubkey: '-1',
          userStatus: getUserStatus(),
          isUncensoredNoteAuthor: sealedReward.note.uncensoredNote.pubKey ==
              nostrRepository.usm!.pubKey,
          isComponent: false,
          isSealed: true,
          sealedNote: sealedReward.note,
          sealDisable: true,
          onDelete: (d) {},
          onLike: () {},
          onDislike: () {},
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        claim_button(
          status: sealedReward.status,
          createdAt: sealedReward.note.createdAt,
          eventId: sealedReward.note.id,
          kind: EventKind.APP_CUSTOM,
          isAuthor: sealedReward.isAuthor,
          useTimer: false,
        ),
      ],
    );
  }
}

class claim_button extends HookWidget {
  const claim_button({
    Key? key,
    required this.status,
    required this.isAuthor,
    required this.eventId,
    required this.kind,
    required this.createdAt,
    required this.useTimer,
  }) : super(key: key);

  final RewardStatus status;
  final bool isAuthor;
  final String eventId;
  final int kind;
  final DateTime createdAt;
  final bool useTimer;

  @override
  Widget build(BuildContext context) {
    final timerShown = useState(
      useTimer ? DateTime.now().difference(createdAt).inSeconds < 350 : false,
    );

    final timerText = useState('');
    final IsMounted = useIsMounted();

    useMemoized(() {
      if (timerShown.value) {
        final topDate =
            createdAt.add(Duration(minutes: 5)).toSecondsSinceEpoch();

        return Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            if (!IsMounted()) {
              timer.cancel();
              return;
            }

            if (timerShown.value) {
              final currentTime =
                  topDate - DateTime.now().toSecondsSinceEpoch();
              timerText.value = currentTime.formattedSeconds();
              if (currentTime <= 0) {
                timerShown.value = false;
                timer.cancel();
              }
            }
          },
        );
      }
    });

    return BlocBuilder<RewardsCubit, RewardsState>(
      buildWhen: (previous, current) =>
          previous.loadingClaims != current.loadingClaims,
      builder: (context, state) {
        final isLoading = state.loadingClaims.contains(eventId);

        return Row(
          children: [
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            SvgPicture.asset(
              FeatureIcons.reward,
              width: 17,
              height: 17,
              colorFilter: ColorFilter.mode(
                kOrange,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            Text(
              '${kind == EventKind.TEXT_NOTE ? state.initNotePrice : kind == EventKind.REACTION ? state.initRatingPrice : isAuthor ? state.sealedNotePrice : state.sealedRatingPrice} SATS',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: kOrange,
                  ),
            ),
            Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: AbsorbPointer(
                absorbing: isLoading,
                child: TextButton(
                  onPressed: () {
                    if (!timerShown.value && !isLoading) {
                      context
                          .read<RewardsCubit>()
                          .claimReward(eventId: eventId, kind: kind);
                    }
                  },
                  child: timerShown.value
                      ? Text(
                          'Claim in ${timerText.value}',
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: kBlack,
                                  ),
                        )
                      : isLoading
                          ? Center(
                              child: SpinKitThreeBounce(
                                color: kWhite,
                                size: 20,
                              ),
                            )
                          : Text(
                              status == RewardStatus.not_claimed
                                  ? 'Claim'
                                  : status == RewardStatus.in_progress
                                      ? 'Request in progress'
                                      : 'Granted',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(color: kWhite),
                            ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity(
                      vertical: -2,
                    ),
                    backgroundColor: timerShown.value
                        ? kDimGrey
                        : status == RewardStatus.not_claimed
                            ? kPurple
                            : status == RewardStatus.in_progress
                                ? kOrange
                                : kGreen,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
