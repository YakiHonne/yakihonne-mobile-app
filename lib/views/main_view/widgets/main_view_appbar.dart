// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class MainViewAppBar extends StatelessWidget {
  final Function() onClicked;

  const MainViewAppBar({
    Key? key,
    required this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        return AppBar(
          elevation: isNotElevated(state) ? 0 : null,
          scrolledUnderElevation: isNotElevated(state) ? 0 : null,
          leading: Center(
            child: IconButton(
              onPressed: () {
                onClicked.call();
                context.read<MainCubit>().updateIndex(2);
              },
              icon: SvgPicture.asset(
                FeatureIcons.search,
                width: kToolbarHeight / 2.2,
                height: kToolbarHeight / 2.2,
                fit: BoxFit.scaleDown,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          title: FadeInDown(
            duration: const Duration(milliseconds: 300),
            from: 15,
            child: state.mainView == MainViews.videosFeed
                ? IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Videos',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 1.5,
                        ),
                        VerticalDivider(
                          width: 0,
                          indent: kDefaultPadding / 4,
                          endIndent: kDefaultPadding / 4,
                        ),
                        GestureDetector(
                          onTap: () => context.read<MainCubit>().toggleVideo(),
                          child: IconButton(
                            onPressed: () =>
                                context.read<MainCubit>().toggleVideo(),
                            style: IconButton.styleFrom(
                              visualDensity: VisualDensity(
                                vertical: -2,
                              ),
                            ),
                            icon: Icon(
                              state.isHorizontal
                                  ? CupertinoIcons.device_phone_portrait
                                  : CupertinoIcons.device_phone_landscape,
                              color: kRed,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    getTitle(state.mainView),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
          ),
          centerTitle: true,
          actions: <Widget>[
            BlocBuilder<MainCubit, MainState>(
              builder: (context, state) {
                return IconButton(
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                  icon: state.userStatus != UserStatus.notConnected
                      ? ProfilePicture2(
                          size: kToolbarHeight / 1.7,
                          image: state.image.isEmpty
                              ? profileImages.first
                              : state.image,
                          placeHolder: state.random,
                          padding: 0,
                          strokeWidth: 0,
                          strokeColor: kTransparent,
                          onClicked: () {
                            Scaffold.of(context).openEndDrawer();
                            lightningZapsCubit.getWalletBalanceInUSD();
                          },
                        )
                      : SvgPicture.asset(
                          FeatureIcons.menu,
                          height: kToolbarHeight / 2.2,
                          width: kToolbarHeight / 2.2,
                          fit: BoxFit.scaleDown,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColorDark,
                            BlendMode.srcIn,
                          ),
                        ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget getMainButton({
    required BuildContext context,
    required bool isSelected,
    required String title,
    required String icon,
    required String selectedIcon,
    required Function() onTap,
  }) {
    final color = isSelected
        ? Theme.of(context).primaryColorLight
        : Theme.of(context).primaryColorDark;

    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).primaryColorDark
            : Theme.of(context).primaryColorLight,
        visualDensity: VisualDensity(
          vertical: -2,
          horizontal: -2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
        ),
      ),
      icon: SvgPicture.asset(
        isSelected ? selectedIcon : icon,
        width: 15,
        height: 15,
        colorFilter: ColorFilter.mode(
          color,
          BlendMode.srcIn,
        ),
      ),
      label: Row(
        children: [
          Text(
            title,
            style:
                Theme.of(context).textTheme.labelSmall!.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  bool isNotElevated(MainState state) {
    return state.mainView == MainViews.home ||
        state.mainView == MainViews.flashNews ||
        state.mainView == MainViews.uncensoredNotes ||
        state.mainView == MainViews.dms ||
        state.mainView == MainViews.notifications ||
        state.mainView == MainViews.buzzFeed ||
        state.mainView == MainViews.smartWidgets;
  }

  String getTitle(MainViews mainView) {
    if (mainView == MainViews.home) {
      return 'Home';
    } else if (mainView == MainViews.bookmarks) {
      return 'My bookmarks';
    } else if (mainView == MainViews.curations) {
      return 'Curations';
    } else if (mainView == MainViews.properties) {
      return 'My properties';
    } else if (mainView == MainViews.search) {
      return 'Search';
    } else if (mainView == MainViews.selfArticles) {
      return 'My articles';
    } else if (mainView == MainViews.selfCurations) {
      return 'My curations';
    } else if (mainView == MainViews.notifications) {
      return 'Notifications';
    } else if (mainView == MainViews.flashNews) {
      return 'Flash news';
    } else if (mainView == MainViews.selfFlashNews) {
      return 'My flash news';
    } else if (mainView == MainViews.uncensoredNotes) {
      return 'Uncensored notes';
    } else if (mainView == MainViews.dms) {
      return 'DMs';
    } else if (mainView == MainViews.videosFeed) {
      return 'Videos';
    } else if (mainView == MainViews.selfVideos) {
      return 'My videos';
    } else if (mainView == MainViews.buzzFeed) {
      return 'Buzz feed';
    } else if (mainView == MainViews.articles) {
      return 'Articles';
    } else if (mainView == MainViews.notes) {
      return 'Notes';
    } else if (mainView == MainViews.polls) {
      return 'Zap polls';
    } else if (mainView == MainViews.wallet) {
      return 'Wallet';
    } else if (mainView == MainViews.selfNotes) {
      return 'My notes';
    } else if (mainView == MainViews.selfSmartWidgets) {
      return 'My smart widgets';
    } else if (mainView == MainViews.smartWidgets) {
      return 'Smart widgets';
    } else {
      return 'App settings';
    }
  }
}
