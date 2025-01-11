// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/lightning_zaps_cubit/lightning_zaps_cubit.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/blocs/points_management_cubit/points_management_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/authentication_view/authentication_view.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/main_view/widgets/profile_share_view.dart';
import 'package:yakihonne/views/points_management_view/points_management_view.dart';
import 'package:yakihonne/views/points_management_view/widgets/points_login_popup.dart';
import 'package:yakihonne/views/widgets/modal_with_blur.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class MainViewDrawer extends HookWidget {
  const MainViewDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final displayUsersMenu = useState(false);

    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        return Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding,
              vertical: kDefaultPadding / 1.5,
            ),
            child: Column(
              children: [
                const SizedBox(
                  height: kToolbarHeight / 1.2,
                ),
                if (state.userStatus == UserStatus.notConnected)
                  SvgPicture.asset(
                    LogosIcons.logoBlack,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColorDark,
                      BlendMode.srcIn,
                    ),
                  )
                else
                  Row(
                    children: [
                      ProfilePicture2(
                        size: 40,
                        image: state.image.isEmpty
                            ? profileImages.first
                            : state.image,
                        placeHolder: state.random,
                        padding: 0,
                        strokeWidth: 0,
                        strokeColor: kTransparent,
                        onClicked: () {
                          openProfileFastAccess(
                            context: context,
                            pubkey: Nip19.decodePubkey(state.pubKey),
                          );
                        },
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium!
                                        .copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  BlocBuilder<AuthorsCubit, AuthorsState>(
                                    builder: (context, authState) {
                                      final decodedPubkey =
                                          Nip19.decodePubkey(state.pubKey);
                                      final author =
                                          authState.authors[decodedPubkey];

                                      final nip05 = author?.nip05 ?? '';

                                      final isValid =
                                          authState.nip05Validations[
                                                  decodedPubkey] ??
                                              false;

                                      if (author != null && nip05.isNotEmpty) {
                                        return Text(
                                          '@${getAuthorName(author)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                color:
                                                    isValid ? kRed : kDimGrey,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      } else {
                                        return SizedBox();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUsingPrivatekey())
                        BlocBuilder<PointsManagementCubit,
                            PointsManagementState>(
                          builder: (context, state) {
                            if (state.userGlobalStats != null) {
                              return GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  Scaffold.of(context).closeEndDrawer();
                                  Navigator.pushNamed(
                                    context,
                                    PointsStatisticsView.routeName,
                                  );
                                },
                                child: PointsRow(
                                  currentXp: state.currentXp,
                                  nextLevelXp: state.nextLevelXp,
                                  additionalXp: state.additionalXp,
                                  currentLevelXp: state.currentLevelXp,
                                  currentLevel: state.currentLevel,
                                  percentage: state.percentage,
                                ),
                              );
                            } else {
                              return GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  Scaffold.of(context).closeEndDrawer();
                                  showBlurredModal(
                                    context: context,
                                    view: PointsLoginPopup(),
                                  );
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).primaryColorLight,
                                  ),
                                  alignment: Alignment.center,
                                  child: SvgPicture.asset(
                                    FeatureIcons.reward,
                                    width: 25,
                                    height: 25,
                                    colorFilter: ColorFilter.mode(
                                      Theme.of(context).primaryColorDark,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          child: ListView(
                            children: [
                              if (state.userStatus != UserStatus.notConnected)
                                SpecialDrawerItem(),
                              DrawerItem(
                                isSelected: state.selectedIndex == 16,
                                onClicked: () {
                                  context.read<MainCubit>().updateIndex(16);
                                  Scaffold.of(context).closeEndDrawer();
                                },
                                icon: FeatureIcons.selfArticles,
                                selectedIcon: FeatureIcons.articleFilled,
                                title: 'Articles',
                              ),
                              DrawerItem(
                                isSelected: state.selectedIndex == 22,
                                onClicked: () {
                                  context.read<MainCubit>().updateIndex(22);
                                  Scaffold.of(context).closeEndDrawer();
                                },
                                icon: FeatureIcons.smartWidget,
                                selectedIcon: FeatureIcons.smartWidgetFilled,
                                title: 'Smart widgets',
                              ),
                              DrawerItem(
                                isSelected: state.selectedIndex == 9,
                                onClicked: () {
                                  context.read<MainCubit>().updateIndex(9);
                                  Scaffold.of(context).closeEndDrawer();
                                },
                                icon: FeatureIcons.flashNews,
                                selectedIcon: FeatureIcons.flashNewsFilled,
                                title: 'Flash news',
                              ),
                              DrawerItem(
                                isSelected: state.selectedIndex == 11,
                                onClicked: () {
                                  context.read<MainCubit>().updateIndex(11);
                                  Scaffold.of(context).closeEndDrawer();
                                },
                                icon: FeatureIcons.uncensoredNote,
                                selectedIcon: FeatureIcons.uncensoredNoteFilled,
                                title: 'Uncensored notes',
                              ),
                              DrawerItem(
                                isSelected: state.selectedIndex == 15,
                                onClicked: () {
                                  context.read<MainCubit>().updateIndex(15);
                                  Scaffold.of(context).closeEndDrawer();
                                },
                                icon: FeatureIcons.buzzFeed,
                                selectedIcon: FeatureIcons.buzzFeedFilled,
                                title: 'Buzz feed',
                              ),
                              DrawerItem(
                                isSelected: state.selectedIndex == 13,
                                onClicked: () {
                                  context.read<MainCubit>().updateIndex(13);
                                  Scaffold.of(context).closeEndDrawer();
                                },
                                icon: FeatureIcons.videoOcta,
                                selectedIcon: FeatureIcons.videosFilled,
                                title: 'Videos',
                              ),
                              DrawerItem(
                                isSelected: state.selectedIndex == 1,
                                onClicked: () {
                                  context.read<MainCubit>().updateIndex(1);
                                  Scaffold.of(context).closeEndDrawer();
                                },
                                icon: FeatureIcons.curations,
                                selectedIcon: FeatureIcons.curationsFilled,
                                title: 'Curations',
                              ),
                              if (state.userStatus != UserStatus.notConnected)
                                DrawerItem(
                                  isSelected: state.selectedIndex == 5,
                                  onClicked: () {
                                    context.read<MainCubit>().updateIndex(5);
                                    Scaffold.of(context).closeEndDrawer();
                                  },
                                  icon: FeatureIcons.properties,
                                  selectedIcon: FeatureIcons.propertiesFilled,
                                  title: 'My properties',
                                ),
                              DrawerItem(
                                isSelected: state.selectedIndex == 6,
                                onClicked: () {
                                  context.read<MainCubit>().updateIndex(6);
                                  Scaffold.of(context).closeEndDrawer();
                                },
                                icon: FeatureIcons.settings,
                                selectedIcon: FeatureIcons.settingsFilled,
                                title: 'App settings',
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding / 2),
                            color: Theme.of(context).primaryColorLight,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor,
                                spreadRadius: 2,
                                blurRadius: 5,
                              )
                            ],
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          child: AnimatedCrossFade(
                            firstChild: Padding(
                              padding: const EdgeInsets.all(
                                kDefaultPadding / 2,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Switch accounts',
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  const SizedBox(
                                    height: kDefaultPadding / 2,
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final usmlist = nostrRepository
                                          .usmList.values
                                          .toList();

                                      return MediaQuery.removePadding(
                                        context: context,
                                        removeTop: true,
                                        removeBottom: true,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            final usm = usmlist[index];

                                            final user = authorsCubit
                                                    .getAuthor(usm.pubKey) ??
                                                emptyUserModel.copyWith(
                                                  pubKey: usm.pubKey,
                                                  picturePlaceholder:
                                                      getRandomPlaceholder(
                                                    input: usm.pubKey,
                                                    isPfp: true,
                                                  ),
                                                );

                                            return GestureDetector(
                                              onTap: () {
                                                context
                                                    .read<MainCubit>()
                                                    .switchAccount(usm);
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  kDefaultPadding / 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    kDefaultPadding / 2,
                                                  ),
                                                  color: nostrRepository.usm ==
                                                          usm
                                                      ? Theme.of(context)
                                                          .scaffoldBackgroundColor
                                                      : null,
                                                ),
                                                child: Row(
                                                  children: [
                                                    ProfilePicture2(
                                                      size: 30,
                                                      image: user.picture,
                                                      placeHolder: user
                                                          .picturePlaceholder,
                                                      padding: 0,
                                                      strokeWidth: 0,
                                                      reduceSize: true,
                                                      strokeColor: kTransparent,
                                                      onClicked: () {
                                                        openProfileFastAccess(
                                                          context: context,
                                                          pubkey: user.pubKey,
                                                        );
                                                      },
                                                    ),
                                                    const SizedBox(
                                                      width:
                                                          kDefaultPadding / 4,
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            getAuthorName(user),
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .labelSmall!
                                                                .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          BlocBuilder<
                                                              AuthorsCubit,
                                                              AuthorsState>(
                                                            builder: (context,
                                                                state) {
                                                              if (state.nip05Validations[
                                                                      user.pubKey] ??
                                                                  false) {
                                                                return Text(
                                                                  '@${getAuthorDisplayName(user)}',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .labelSmall!
                                                                      .copyWith(
                                                                          color:
                                                                              kRed),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                );
                                                              } else {
                                                                return SizedBox
                                                                    .shrink();
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width:
                                                          kDefaultPadding / 4,
                                                    ),
                                                    if (nostrRepository.usm ==
                                                        usm)
                                                      CustomIconButton(
                                                        onClicked: () {
                                                          context
                                                              .read<MainCubit>()
                                                              .disconnectAccount(
                                                                usm,
                                                              );
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        icon: FeatureIcons.log,
                                                        size: 20,
                                                        vd: -4,
                                                        backgroundColor: Theme
                                                                .of(context)
                                                            .scaffoldBackgroundColor,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                          itemCount: usmlist.length,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(
                                    height: kDefaultPadding / 2,
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        showBlurredModal(
                                          context: context,
                                          view: AuthenticationView(),
                                        );

                                        Scaffold.of(context).closeEndDrawer();
                                      },
                                      icon: SvgPicture.asset(
                                        FeatureIcons.addRaw,
                                        width: 15,
                                        height: 15,
                                        colorFilter: ColorFilter.mode(
                                          Theme.of(context).primaryColorDark,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      label: Text(
                                        'Add account',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: kDefaultPadding / 4,
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        context.read<MainCubit>().disconnect();
                                        context
                                            .read<LightningZapsCubit>()
                                            .deleteWalletConfiguration();
                                        Navigator.of(context)
                                            .popUntil((route) => route.isFirst);
                                        Scaffold.of(context).closeEndDrawer();
                                      },
                                      icon: SvgPicture.asset(
                                        FeatureIcons.log,
                                        width: 20,
                                        height: 20,
                                        colorFilter: ColorFilter.mode(
                                          Theme.of(context).primaryColorDark,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      label: Text(
                                        'Logout all accounts',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            secondChild: SizedBox(
                              width: double.infinity,
                            ),
                            crossFadeState: displayUsersMenu.value
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            duration: const Duration(milliseconds: 200),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.userStatus != UserStatus.notConnected)
                  Row(
                    children: [
                      Expanded(
                        child: DrawerItem(
                          isSelected: false,
                          onClicked: () {
                            displayUsersMenu.value = !displayUsersMenu.value;
                          },
                          icon: FeatureIcons.refresh,
                          selectedIcon: FeatureIcons.refresh,
                          title: 'Manage accounts',
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final onClick = () {
                            Navigator.push(
                              context,
                              createViewFromBottom(
                                BlocProvider.value(
                                  value: context.read<MainCubit>(),
                                  child: ConnectedUserProfileShareView(),
                                ),
                              ),
                            );
                          };

                          return GestureDetector(
                            onTap: onClick,
                            behavior: HitTestBehavior.translucent,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: onClick,
                                  style: IconButton.styleFrom(
                                    visualDensity: VisualDensity(
                                      horizontal: -3,
                                      vertical: -3,
                                    ),
                                  ),
                                  icon: SvgPicture.asset(
                                    FeatureIcons.qr,
                                    width: 25,
                                    height: 25,
                                    colorFilter: ColorFilter.mode(
                                      Theme.of(context).primaryColorDark,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        showBlurredModal(
                          context: context,
                          view: AuthenticationView(),
                        );

                        Scaffold.of(context).closeEndDrawer();
                      },
                      icon: SvgPicture.asset(
                        FeatureIcons.log,
                        width: kToolbarHeight / 2.5,
                        height: kToolbarHeight / 2.5,
                        colorFilter: ColorFilter.mode(
                          kWhite,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: Text(
                        'Login',
                      ),
                    ),
                  ),
                if (isUsingPrivatekey())
                  BlocBuilder<LightningZapsCubit, LightningZapsState>(
                    builder: (context, lightningState) {
                      if (lightningState.wallets.isEmpty) {
                        return SizedBox.shrink();
                      }

                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          context.read<MainCubit>().updateIndex(19);
                          Scaffold.of(context).closeEndDrawer();
                        },
                        child: Column(
                          children: [
                            Divider(
                              height: kDefaultPadding / 2,
                              indent: kDefaultPadding / 2,
                              endIndent: kDefaultPadding / 2,
                            ),
                            const SizedBox(
                              height: kDefaultPadding / 2,
                            ),
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: kDefaultPadding / 2,
                                  ),
                                  VerticalDivider(
                                    thickness: 2,
                                    color: kOrangeContrasted,
                                    width: 0,
                                  ),
                                  SizedBox(
                                    width: kDefaultPadding / 1.5,
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                lightningState.isWalletHidden
                                                    ? '*****'
                                                    : '${lightningState.balance != -1 ? lightningState.balance : 'N/A'}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineMedium!
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      height: 1,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: kDefaultPadding / 3,
                                            ),
                                            SvgPicture.asset(
                                              FeatureIcons.sats,
                                              width: 20,
                                              height: 20,
                                              colorFilter: ColorFilter.mode(
                                                Theme.of(context)
                                                    .primaryColorDark,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: kDefaultPadding / 8,
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              '~ \$${lightningState.isWalletHidden ? '*****' : lightningState.balanceInUSD == -1 ? 'N/A' : lightningState.balanceInUSD.toStringAsFixed(2)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge,
                                            ),
                                            Text(
                                              ' USD',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall!
                                                  .copyWith(
                                                    color: kDimGrey,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: kDefaultPadding / 1.5,
                                  ),
                                  CustomIconButton(
                                    onClicked: () {
                                      lightningZapsCubit.toggleWallet();
                                    },
                                    icon: !lightningState.isWalletHidden
                                        ? FeatureIcons.notVisible
                                        : FeatureIcons.visible,
                                    size: 22,
                                    backgroundColor: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(
                  height: kBottomNavigationBarHeight / 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PointsRow extends HookWidget {
  const PointsRow({
    Key? key,
    required this.currentXp,
    required this.nextLevelXp,
    required this.additionalXp,
    required this.currentLevelXp,
    required this.currentLevel,
    required this.percentage,
  }) : super(key: key);

  final int currentXp;
  final int nextLevelXp;
  final int additionalXp;
  final int currentLevelXp;
  final int currentLevel;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(seconds: 1),
    );

    final animation = Tween<double>(begin: 0, end: percentage).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ),
    );

    useEffect(
      () {
        animationController.forward();
        return;
      },
      [animationController],
    );

    return SizedBox(
      width: 55,
      height: 55,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) => CircularProgressIndicator(
                strokeWidth: 3,
                value: animation.value,
                color: getPercentageColor(animation.value * 100),
                strokeCap: StrokeCap.round,
                backgroundColor: kBlack.withValues(alpha: 0.3),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$currentXp xp',
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        height: 1,
                        color: kOrange,
                      ),
                ),
                const SizedBox(
                  height: kDefaultPadding / 8,
                ),
                Text(
                  'LVL $currentLevel',
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class SpecialDrawerItem extends StatelessWidget {
  const SpecialDrawerItem({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        if (state.userStatus != UserStatus.UsingPrivKey)
          return SizedBox.shrink();
        return ListView(
          shrinkWrap: true,
          primary: false,
          children: [
            ListTile(
              onTap: () => context.read<MainCubit>().toggleMyContentShrink(),
              contentPadding: EdgeInsets.only(left: kDefaultPadding / 4),
              horizontalTitleGap: kDefaultPadding / 2,
              visualDensity: VisualDensity(vertical: -2),
              splashColor: kTransparent,
              leading: SvgPicture.asset(
                state.isMyContentShrinked
                    ? FeatureIcons.contentClosed
                    : FeatureIcons.contentOpenFilled,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
              ),
              title: Text(
                'My content',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              trailing: AnimatedRotation(
                turns: state.isMyContentShrinked ? 0 : -0.5,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: Padding(
                padding: const EdgeInsets.only(
                    left: kDefaultPadding / 2, bottom: kDefaultPadding / 2),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DrawerSpecialItem(
                            onClicked: () {
                              context.read<MainCubit>().updateIndex(20);
                              Scaffold.of(context).closeEndDrawer();
                            },
                            icon: FeatureIcons.note,
                            selectedIcon: FeatureIcons.noteFilled,
                            title: 'Notes',
                            isSelected: state.selectedIndex == 20,
                          ),
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        Expanded(
                          child: DrawerSpecialItem(
                            onClicked: () {
                              context.read<MainCubit>().updateIndex(4);
                              Scaffold.of(context).closeEndDrawer();
                            },
                            icon: FeatureIcons.selfArticles,
                            selectedIcon: FeatureIcons.articleFilled,
                            title: 'Articles',
                            isSelected: state.selectedIndex == 4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DrawerSpecialItem(
                            onClicked: () {
                              context.read<MainCubit>().updateIndex(10);
                              Scaffold.of(context).closeEndDrawer();
                            },
                            icon: FeatureIcons.flashNews,
                            selectedIcon: FeatureIcons.flashNewsFilled,
                            title: 'Flash news',
                            isSelected: state.selectedIndex == 10,
                          ),
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        Expanded(
                          child: DrawerSpecialItem(
                            onClicked: () {
                              context.read<MainCubit>().updateIndex(14);
                              Scaffold.of(context).closeEndDrawer();
                            },
                            icon: FeatureIcons.videoOcta,
                            selectedIcon: FeatureIcons.videosFilled,
                            title: 'Videos',
                            isSelected: state.selectedIndex == 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DrawerSpecialItem(
                            onClicked: () {
                              context.read<MainCubit>().updateIndex(3);
                              Scaffold.of(context).closeEndDrawer();
                            },
                            icon: FeatureIcons.curations,
                            selectedIcon: FeatureIcons.curationsFilled,
                            title: 'Curations',
                            isSelected: state.selectedIndex == 3,
                          ),
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        Expanded(
                          child: DrawerSpecialItem(
                            onClicked: () {
                              context.read<MainCubit>().updateIndex(7);
                              Scaffold.of(context).closeEndDrawer();
                            },
                            icon: FeatureIcons.bookmark,
                            selectedIcon: FeatureIcons.bookmarkFilled,
                            title: 'Bookmarks',
                            isSelected: state.selectedIndex == 7,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox(
                width: double.infinity,
              ),
              crossFadeState: state.isMyContentShrinked
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        );
      },
    );
  }
}

class DrawerSpecialItem extends StatelessWidget {
  const DrawerSpecialItem({
    Key? key,
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onClicked,
  }) : super(key: key);

  final String title;
  final String icon;
  final String selectedIcon;
  final bool isSelected;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColorLight,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        ),
        padding: const EdgeInsets.all(kDefaultPadding / 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SvgPicture.asset(
              isSelected ? selectedIcon : icon,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
              width: 18,
              height: 18,
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).primaryColorDark,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyContentDrawerItem extends StatelessWidget {
  const MyContentDrawerItem({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        if (state.userStatus != UserStatus.UsingPrivKey)
          return SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              onTap: () => context.read<MainCubit>().toggleMyContentShrink(),
              contentPadding: EdgeInsets.only(left: kDefaultPadding / 4),
              horizontalTitleGap: kDefaultPadding / 2,
              visualDensity: VisualDensity(vertical: -2),
              splashColor: kTransparent,
              leading: SvgPicture.asset(
                state.isMyContentShrinked
                    ? FeatureIcons.contentClosed
                    : FeatureIcons.contentOpenFilled,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
              ),
              title: Text(
                'My content',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              trailing: AnimatedRotation(
                turns: state.isMyContentShrinked ? 0 : -0.5,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: Padding(
                padding: const EdgeInsets.only(
                  left: kDefaultPadding / 2,
                  bottom: kDefaultPadding / 2,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      VerticalDivider(),
                      const SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            DrawerItem(
                              onClicked: () {
                                context.read<MainCubit>().updateIndex(10);
                                Scaffold.of(context).closeEndDrawer();
                              },
                              icon: FeatureIcons.flashNews,
                              selectedIcon: FeatureIcons.flashNewsFilled,
                              title: 'My flash news',
                              isSelected: state.selectedIndex == 10,
                            ),
                            DrawerItem(
                              onClicked: () {
                                context.read<MainCubit>().updateIndex(3);
                                Scaffold.of(context).closeEndDrawer();
                              },
                              icon: FeatureIcons.curations,
                              selectedIcon: FeatureIcons.curationsFilled,
                              title: 'My curations',
                              isSelected: state.selectedIndex == 3,
                            ),
                            DrawerItem(
                              onClicked: () {
                                context.read<MainCubit>().updateIndex(4);
                                Scaffold.of(context).closeEndDrawer();
                              },
                              icon: FeatureIcons.selfArticles,
                              selectedIcon: FeatureIcons.articleFilled,
                              title: 'My articles',
                              isSelected: state.selectedIndex == 4,
                            ),
                            DrawerItem(
                              onClicked: () {
                                context.read<MainCubit>().updateIndex(14);
                                Scaffold.of(context).closeEndDrawer();
                              },
                              icon: FeatureIcons.videoOcta,
                              selectedIcon: FeatureIcons.videosFilled,
                              title: 'My videos',
                              isSelected: state.selectedIndex == 14,
                            ),
                            DrawerItem(
                              onClicked: () {
                                context.read<MainCubit>().updateIndex(7);
                                Scaffold.of(context).closeEndDrawer();
                              },
                              icon: FeatureIcons.bookmark,
                              selectedIcon: FeatureIcons.bookmarkFilled,
                              title: 'My bookmarks',
                              isSelected: state.selectedIndex == 7,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              secondChild: const SizedBox(
                width: double.infinity,
              ),
              crossFadeState: state.isMyContentShrinked
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        );
      },
    );
  }
}

class DrawerItem extends StatelessWidget {
  const DrawerItem({
    Key? key,
    required this.isSelected,
    required this.onClicked,
    required this.icon,
    required this.selectedIcon,
    required this.title,
  }) : super(key: key);

  final bool isSelected;
  final Function() onClicked;
  final String icon;
  final String selectedIcon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: kTransparent,
      ),
      child: ListTile(
        onTap: onClicked,
        contentPadding: EdgeInsets.only(left: kDefaultPadding / 4),
        horizontalTitleGap: kDefaultPadding / 2,
        visualDensity: VisualDensity(vertical: -1),
        splashColor: kTransparent,
        leading: SvgPicture.asset(
          isSelected ? selectedIcon : icon,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
          width: 24,
          height: 24,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
        trailing: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 4 : 0,
          height: isSelected ? 4 : 0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: Theme.of(context).primaryColorDark,
          ),
        ),
      ),
    );
  }
}
