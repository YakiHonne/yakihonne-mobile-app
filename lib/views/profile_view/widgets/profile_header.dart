// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:numeral/numeral.dart';
import 'package:yakihonne/blocs/profile_cubit/profile_cubit.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/profile_view/profile_view.dart';
import 'package:yakihonne/views/profile_view/widgets/profile_follow_authors_view.dart';
import 'package:yakihonne/views/profile_view/widgets/relays_list.dart';
import 'package:yakihonne/views/profile_view/widgets/un_stats_details.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: ListView(
        shrinkWrap: true,
        primary: false,
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
        ),
        children: [
          BlocBuilder<ProfileCubit, ProfileState>(
            buildWhen: (previous, current) =>
                previous.user != current.user ||
                previous.isNip05 != current.isNip05 ||
                previous.userRelays != current.userRelays ||
                previous.isRelaysLoading != current.isRelaysLoading,
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  Builder(
                    builder: (context) {
                      final userName = state.user.name.trim().isEmpty
                          ? Nip19.encodePubkey(state.user.pubKey)
                              .substring(0, 10)
                          : state.user.name.trim();

                      return GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            new ClipboardData(
                              text: userName,
                            ),
                          );

                          BotToastUtils.showSuccess(
                            'User name successfully copied!',
                          );
                        },
                        child: Text(
                          userName,
                          style:
                              Theme.of(context).textTheme.titleLarge!.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      );
                    },
                  ),
                  if (state.user.nip05.isNotEmpty) ...[
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Row(
                      children: [
                        if (state.user.nip05.isNotEmpty)
                          Expanded(
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  FeatureIcons.nip05,
                                  width: 20,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context).primaryColorDark,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(
                                  width: kDefaultPadding / 4,
                                ),
                                Flexible(
                                  child: Text(
                                    state.user.nip05,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium!
                                        .copyWith(
                                          color: state.isNip05
                                              ? kOrangeContrasted
                                              : kDimGrey,
                                        ),
                                  ),
                                ),
                                if (state.isNip05) ...[
                                  const SizedBox(
                                    width: kDefaultPadding / 2,
                                  ),
                                  SvgPicture.asset(
                                    FeatureIcons.verified,
                                    width: 15,
                                    height: 15,
                                    colorFilter: ColorFilter.mode(
                                      kOrangeContrasted,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        TextButton.icon(
                          onPressed: () {
                            context.read<ProfileCubit>().setRelays();

                            showModalBottomSheet(
                              context: context,
                              builder: (_) {
                                return BlocProvider.value(
                                  value: context.read<ProfileCubit>(),
                                  child: ProfileRelays(),
                                );
                              },
                              isScrollControlled: true,
                              useRootNavigator: true,
                              useSafeArea: true,
                              elevation: 0,
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                            );
                          },
                          icon: SvgPicture.asset(
                            FeatureIcons.relays,
                            width: 15,
                            height: 15,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).primaryColorDark,
                              BlendMode.srcIn,
                            ),
                          ),
                          label: Text(
                            'Relays - ${state.userRelays.length}',
                            style:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      color: Theme.of(context).primaryColorDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: kTransparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding / 2,
                            ),
                            visualDensity: VisualDensity(
                              vertical: -4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (state.user.website.isNotEmpty) ...[
                    SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    GestureDetector(
                      onTap: () {
                        openWebPage(url: state.user.website);
                      },
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            FeatureIcons.link,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).primaryColorDark,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 4,
                          ),
                          Flexible(
                            child: Text(
                              state.user.website,
                              style: Theme.of(context).textTheme.labelMedium!,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (state.user.about.isNotEmpty) ...[
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    SelectableText(
                      state.user.about.trim(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Row(
                    children: [
                      Text(
                        'Last updated on: ',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        dateFormat2.format(state.user.createdAt),
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: kOrange,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 1.5,
                  ),
                ],
              );
            },
          ),
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              return ProfileUncensoredNoteStats(
                ratingImpact: state.ratingImpact,
                writingImpact: state.writingImpact,
                negativeWritingImpact: state.negativeWritingImpact,
                ongoingWritingImpact: state.ongoingWritingImpact,
                positiveWritingImpact: state.positiveWritingImpact,
                positiveRatingH: state.positiveRatingImpactH,
                positiveRatingNh: state.positiveRatingImpactNh,
                negativeRatingH: state.negativeRatingImpactH,
                negativeRatingNh: state.negativeRatingImpactNh,
                ongoingRating: state.ongoingRatingImpact,
              );
            },
          ),
          const SizedBox(
            height: kDefaultPadding / 1.5,
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                BlocBuilder<ProfileCubit, ProfileState>(
                  buildWhen: (previous, current) =>
                      previous.followersLength != current.followersLength ||
                      previous.followingsLength != current.followingsLength ||
                      previous.followers != current.followers ||
                      previous.followings != current.followings,
                  builder: (context, state) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            elevation: 0,
                            builder: (_) {
                              return BlocProvider.value(
                                value: context.read<ProfileCubit>(),
                                child: ProfileFollowAuthorsView(
                                  followers: state.followers,
                                  followings: state.followings,
                                ),
                              );
                            },
                            isScrollControlled: true,
                            useRootNavigator: true,
                            useSafeArea: true,
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                          );
                        },
                        behavior: HitTestBehavior.translucent,
                        child: UserStatsRow(
                          icon: FeatureIcons.user,
                          firstTitle: 'Followings',
                          firstValue:
                              Numeral(state.followingsLength).toString(),
                          secondtitle: 'Followers',
                          secondValue:
                              Numeral(state.followersLength).toString(),
                        ),
                      ),
                    );
                  },
                ),
                VerticalDivider(),
                BlocBuilder<ProfileCubit, ProfileState>(
                  buildWhen: (previous, current) =>
                      previous.sentZaps != current.sentZaps ||
                      previous.receivedZaps != current.receivedZaps,
                  builder: (context, state) {
                    return Expanded(
                      child: UserStatsRow(
                        icon: FeatureIcons.zap,
                        firstTitle: 'Sent',
                        firstValue: Numeral(state.sentZaps).toString(),
                        secondtitle: 'Received',
                        secondValue: Numeral(state.receivedZaps).toString(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: kDefaultPadding,
          ),
        ],
      ),
    );
  }
}

class ProfileUncensoredNoteStats extends HookWidget {
  const ProfileUncensoredNoteStats({
    required this.writingImpact,
    required this.positiveWritingImpact,
    required this.negativeWritingImpact,
    required this.ongoingWritingImpact,
    required this.ratingImpact,
    required this.positiveRatingH,
    required this.positiveRatingNh,
    required this.negativeRatingH,
    required this.negativeRatingNh,
    required this.ongoingRating,
  });

  final num writingImpact;
  final num positiveWritingImpact;
  final num negativeWritingImpact;
  final num ongoingWritingImpact;
  final num ratingImpact;
  final num positiveRatingH;
  final num positiveRatingNh;
  final num negativeRatingH;
  final num negativeRatingNh;
  final num ongoingRating;

  @override
  Widget build(BuildContext context) {
    final isShrinked = useState(true);

    return GestureDetector(
      onTap: () => isShrinked.value = !isShrinked.value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColorLight,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: AnimatedCrossFade(
                firstChild: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UnStatsRow(
                            impact: writingImpact,
                            text: 'Writing impact',
                            onClicked: () {
                              showModalBottomSheet(
                                context: context,
                                elevation: 0,
                                builder: (_) {
                                  return UnStatsDetails(
                                    isWriting: true,
                                    totalVal: writingImpact,
                                    firstVal: positiveWritingImpact,
                                    secondVal: negativeWritingImpact,
                                    thirdVal: ongoingWritingImpact,
                                    fifthVal: 0,
                                    fourthVal: 0,
                                  );
                                },
                                isScrollControlled: true,
                                useRootNavigator: true,
                                useSafeArea: true,
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                              );
                            },
                          ),
                          Divider(
                            indent: kDefaultPadding,
                            thickness: 0.5,
                          ),
                          UnStatsRow(
                            impact: ratingImpact,
                            text: 'Rating impact',
                            onClicked: () {
                              showModalBottomSheet(
                                context: context,
                                elevation: 0,
                                builder: (_) {
                                  return UnStatsDetails(
                                    isWriting: false,
                                    totalVal: ratingImpact,
                                    firstVal: positiveRatingH,
                                    secondVal: positiveRatingNh,
                                    thirdVal: negativeRatingH,
                                    fourthVal: negativeRatingNh,
                                    fifthVal: ongoingRating,
                                  );
                                },
                                isScrollControlled: true,
                                useRootNavigator: true,
                                useSafeArea: true,
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    ),
                    GestureDetector(
                      onTap: () => isShrinked.value = !isShrinked.value,
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                secondChild: GestureDetector(
                  onTap: () => isShrinked.value = !isShrinked.value,
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            FeatureIcons.unStats,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).primaryColorDark,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      Expanded(
                        child: Text(
                          'Uncensored notes stats',
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                crossFadeState: isShrinked.value
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UnStatsRow extends StatelessWidget {
  const UnStatsRow({
    Key? key,
    required this.text,
    required this.impact,
    required this.onClicked,
  }) : super(key: key);

  final String text;
  final num impact;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          DotContainer(
            color: kDimGrey,
            size: 3,
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: Theme.of(context).primaryColorDark,
                  ),
            ),
          ),
          Text(
            impact.toString(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).primaryColorDark,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          Icon(
            Icons.keyboard_arrow_right_rounded,
            size: 20,
          ),
        ],
      ),
    );
  }
}
