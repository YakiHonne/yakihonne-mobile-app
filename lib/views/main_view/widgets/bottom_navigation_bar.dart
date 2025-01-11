// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/dms_cubit/dms_cubit.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/blocs/notifications_cubit/notifications_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';

class MainViewBottomNavigationBar extends StatelessWidget {
  const MainViewBottomNavigationBar({
    super.key,
    required this.onClicked,
  });

  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        return Container(
          height: kBottomNavigationBarHeight +
              MediaQuery.of(context).padding.bottom,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(kDefaultPadding),
              topRight: Radius.circular(kDefaultPadding),
            ),
            border: Border(
              top: BorderSide(
                color:
                    Theme.of(context).primaryColorDark.withValues(alpha: 0.5),
              ),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: BottomNavBarItem(
                  icon: FeatureIcons.home,
                  selectedIcon: FeatureIcons.homeFilled,
                  isSelected: state.selectedIndex == 0,
                  onClicked: () {
                    onClicked.call();
                    context.read<MainCubit>().updateIndex(0);
                  },
                ),
              ),
              Expanded(
                child: BottomNavBarItem(
                  icon: FeatureIcons.note,
                  selectedIcon: FeatureIcons.noteFilled,
                  isSelected: state.selectedIndex == 17,
                  isNoteRipple: true,
                  onClicked: () {
                    onClicked.call();
                    context.read<MainCubit>().updateIndex(17);
                  },
                ),
              ),
              Expanded(
                child: BottomNavBarItem(
                  icon: FeatureIcons.wallet,
                  selectedIcon: FeatureIcons.wallet,
                  isSelected: state.selectedIndex == 19,
                  color: kOrangeContrasted,
                  onClicked: () {
                    onClicked.call();
                    lightningZapsCubit.getWalletBalanceInUSD();
                    context.read<MainCubit>().updateIndex(19);
                  },
                ),
              ),
              if (state.userStatus == UserStatus.UsingPrivKey)
                Expanded(
                  child: BlocBuilder<DmsCubit, DmsState>(
                    builder: (context, dmState) {
                      return Stack(
                        children: [
                          BottomNavBarItem(
                            icon: FeatureIcons.message,
                            selectedIcon: FeatureIcons.messageFilled,
                            isSelected: state.selectedIndex == 12,
                            onClicked: () {
                              onClicked.call();
                              context.read<MainCubit>().updateIndex(12);
                            },
                          ),
                          Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 15, bottom: 10),
                              child: DotContainer(
                                color: Colors.redAccent,
                                isNotMarging: true,
                                size: dmsCubit.gotMessages() ? 8 : 0,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              if (state.userStatus == UserStatus.UsingPrivKey)
                Expanded(
                  child: BlocBuilder<NotificationsCubit, NotificationsState>(
                    builder: (context, notiState) {
                      return Stack(
                        children: [
                          BottomNavBarItem(
                            icon: FeatureIcons.notification,
                            selectedIcon: FeatureIcons.notificationsFilled,
                            isSelected: state.selectedIndex == 8,
                            onClicked: () {
                              onClicked.call();
                              context.read<MainCubit>().updateIndex(8);
                              notificationsCubit.markRead();
                            },
                          ),
                          Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 10, bottom: 10),
                              child: DotContainer(
                                color: Colors.redAccent,
                                isNotMarging: true,
                                size: notiState.isRead ? 0 : 8,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class RippleContainer extends HookWidget {
  const RippleContainer({
    required this.widget,
  });

  final Widget widget;

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    useInterval(
      () {
        animationController
            .forward()
            .whenComplete(() => animationController.reverse())
            .whenComplete(
              () => animationController.forward().whenComplete(
                    () => animationController.reverse(),
                  ),
            );
      },
      const Duration(seconds: 5),
    );

    final regularSize = kToolbarHeight / 2;
    final addedSize = 5;

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Container(
          width: animationController.value * addedSize + regularSize,
          height: animationController.value * addedSize + regularSize,
          child: widget,
        );
      },
    );
  }
}

class BottomNavBarItem extends StatelessWidget {
  const BottomNavBarItem({
    Key? key,
    required this.onClicked,
    required this.isSelected,
    required this.icon,
    required this.selectedIcon,
    this.isNoteRipple,
    this.color,
  }) : super(key: key);

  final Function() onClicked;
  final bool isSelected;
  final String icon;
  final String selectedIcon;
  final bool? isNoteRipple;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconAsset = SvgPicture.asset(
      isSelected ? selectedIcon : icon,
      width: kToolbarHeight / 2,
      height: kToolbarHeight / 2,
      colorFilter: ColorFilter.mode(
        color ?? Theme.of(context).primaryColorDark,
        BlendMode.srcIn,
      ),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onClicked,
          highlightColor: kTransparent,
          icon: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              isNoteRipple != null && !isSelected
                  ? RippleContainer(widget: iconAsset)
                  : iconAsset,
              Center(
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 200,
                  ),
                  margin: EdgeInsets.only(top: isSelected ? 4 : 0),
                  width: isSelected ? 4 : 0,
                  height: isSelected ? 4 : 0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding),
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
