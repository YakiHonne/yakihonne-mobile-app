import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/repositories/connectivity_repository.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/app_cycle.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/articles_view/articles_view.dart';
import 'package:yakihonne/views/bookmarks_view/bookmarks_view.dart';
import 'package:yakihonne/views/buzz_feed_view/buzz_feed_view.dart';
import 'package:yakihonne/views/curations_view/curations_view.dart';
import 'package:yakihonne/views/dm_view/dm_view.dart';
import 'package:yakihonne/views/flash_news_view/flash_news_view.dart';
import 'package:yakihonne/views/home_view/home_view.dart';
import 'package:yakihonne/views/main_view/widgets/bottom_navigation_bar.dart';
import 'package:yakihonne/views/main_view/widgets/drawer_view.dart';
import 'package:yakihonne/views/main_view/widgets/main_view_appbar.dart';
import 'package:yakihonne/views/notes_view/notes_view.dart';
import 'package:yakihonne/views/notifications_view/notifications_view.dart';
import 'package:yakihonne/views/polls_view/polls_view.dart';
import 'package:yakihonne/views/properties_view/properties_view.dart';
import 'package:yakihonne/views/search_view/search_view.dart';
import 'package:yakihonne/views/self_articles_view/self_articles_view.dart';
import 'package:yakihonne/views/self_curations_view/self_curations_view.dart';
import 'package:yakihonne/views/self_curations_view/widgets/add_self_curation.dart';
import 'package:yakihonne/views/self_flash_news_view/self_flash_news_view.dart';
import 'package:yakihonne/views/self_notes_view/self_notes_view.dart';
import 'package:yakihonne/views/self_videos_view/self_videos_view.dart';
import 'package:yakihonne/views/settings_view/settings_view.dart';
import 'package:yakihonne/views/smart_widgets_view/smart_widgets_view.dart';
import 'package:yakihonne/views/uncensored_notes_view/uncensored_notes_view.dart';
import 'package:yakihonne/views/videos_feed_view/videos_feed_view.dart';
import 'package:yakihonne/views/wallet_balance_view/wallet_view.dart';
import 'package:yakihonne/views/widgets/scroll_to_top.dart';
import 'package:yakihonne/views/write_article_view/write_article_view.dart';
import 'package:yakihonne/views/write_flash_news_view/write_flash_news_view.dart';
import 'package:yakihonne/views/write_note_view/write_note_view.dart';
import 'package:yakihonne/views/write_smart_widget_view/write_smart_widget_view.dart';
import 'package:yakihonne/views/write_video_view/write_video_view.dart';

class MainView extends HookWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    final mainScrollController = useScrollController();

    return BlocProvider(
      create: (context) {
        YakihonneCycle(buildContext: context);
        nostrRepository.mainCubit = MainCubit(
          localDatabaseRepository: context.read<LocalDatabaseRepository>(),
          nostrRepository: context.read<NostrDataRepository>(),
          connectivityRepository: context.read<ConnectivityRepository>(),
          context: context,
        );

        return nostrRepository.mainCubit;
      },
      child: ScrollsToTop(
        onScrollsToTop: (event) async {
          onScrollsToTop(event, mainScrollController);
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          bottomNavigationBar: MainViewBottomNavigationBar(
            onClicked: () {
              if (mainScrollController.hasClients) {
                mainScrollController.animateTo(
                  0.0,
                  duration: Duration(seconds: 1),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
          floatingActionButton: FloatingButtonMenu(),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: MainViewAppBar(
              onClicked: () {
                if (mainScrollController.hasClients) {
                  mainScrollController.animateTo(
                    0.0,
                    duration: Duration(seconds: 1),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
          ),
          endDrawer: MainViewDrawer(),
          extendBody: true,
          body: SafeArea(
            child: BlocBuilder<MainCubit, MainState>(
              builder: (context, state) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: getCurrentView(
                    mainView: state.mainView,
                    scrollController: mainScrollController,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget getCurrentView({
    required MainViews mainView,
    required ScrollController scrollController,
  }) {
    if (mainView == MainViews.home) {
      return HomeView(
        scrollController: scrollController,
      );
    } else if (mainView == MainViews.curations) {
      return CurationsView(
        mainScrollController: scrollController,
      );
    } else if (mainView == MainViews.search) {
      return SearchView(
        mainScrollController: scrollController,
      );
    } else if (mainView == MainViews.selfCurations) {
      return SelfCurationsView(
        mainScrollController: scrollController,
      );
    } else if (mainView == MainViews.selfFlashNews) {
      return SelfFlashNewsView(
        mainScrollController: scrollController,
      );
    } else if (mainView == MainViews.selfArticles) {
      return SelfArticlesView(
        mainScrollController: scrollController,
      );
    } else if (mainView == MainViews.properties) {
      return PropertiesView();
    } else if (mainView == MainViews.settings) {
      return const SettingsView();
    } else if (mainView == MainViews.flashNews) {
      return FlashNewsView(
        scrollController: scrollController,
      );
    } else if (mainView == MainViews.bookmarks) {
      return BookmarksView(
        mainScollController: scrollController,
      );
    } else if (mainView == MainViews.uncensoredNotes) {
      return UncensoredNotesView(
        scrollController: scrollController,
      );
    } else if (mainView == MainViews.notifications) {
      return NotificationsView(
        scrollController: scrollController,
      );
    } else if (mainView == MainViews.dms) {
      return DmsView(
        scrollController: scrollController,
      );
    } else if (mainView == MainViews.videosFeed) {
      return VideoFeedView(
        scrollController: scrollController,
      );
    } else if (mainView == MainViews.selfVideos) {
      return SelfVideosView(
        scrollController: scrollController,
      );
    } else if (mainView == MainViews.buzzFeed) {
      return BuzzFeedView(
        scrollController: scrollController,
      );
    } else if (mainView == MainViews.articles) {
      return ArticlesView(
        scrollController: scrollController,
      );
    } else if (mainView == MainViews.notes) {
      return NotesView(
        scrollController: scrollController,
      );
    } else if (mainView == MainViews.polls) {
      return PollsView(
        scrollController: scrollController,
      );
    } else if (mainView == MainViews.wallet) {
      return InternalWalletsView(
        scrollController: scrollController,
      );
    } else if (mainView == MainViews.selfNotes) {
      return SelfNotesView(
        scrollController: scrollController,
      );
    } else if (mainView == MainViews.smartWidgets) {
      return SmartWidgetsView(
        scrollController: scrollController,
      );
    } else {
      return Container();
    }
  }
}

class FloatingButtonMenu extends StatelessWidget {
  const FloatingButtonMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        if (state.userStatus == UserStatus.UsingPrivKey) {
          if (state.mainView == MainViews.properties ||
              state.mainView == MainViews.videosFeed) {
            return SizedBox.shrink();
          }

          return SpeedDial(
            icon: CupertinoIcons.pencil,
            activeIcon: Icons.close_rounded,
            spacing: kDefaultPadding / 4,
            backgroundColor: kOrangeContrasted,
            children: [
              SpeedDialChild(
                child: SvgPicture.asset(
                  FeatureIcons.addNote,
                  width: 27,
                  height: 27,
                  colorFilter: ColorFilter.mode(
                    kWhite,
                    BlendMode.srcIn,
                  ),
                ),
                backgroundColor: kOrangeContrasted,
                foregroundColor: Colors.white,
                label: 'Note',
                shape: CircleBorder(),
                labelStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    elevation: 0,
                    builder: (_) {
                      return WriteNoteView();
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
              ),
              SpeedDialChild(
                child: SvgPicture.asset(
                  FeatureIcons.addArticle,
                  width: 27,
                  height: 27,
                  colorFilter: ColorFilter.mode(
                    kWhite,
                    BlendMode.srcIn,
                  ),
                ),
                backgroundColor: kOrangeContrasted,
                foregroundColor: Colors.white,
                label: 'Article',
                shape: CircleBorder(),
                labelStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    WriteArticleView.routeName,
                    arguments: [
                      context.read<MainCubit>(),
                    ],
                  );
                },
              ),
              SpeedDialChild(
                child: SvgPicture.asset(
                  FeatureIcons.addFlashNews,
                  width: 27,
                  height: 27,
                  colorFilter: ColorFilter.mode(
                    kWhite,
                    BlendMode.srcIn,
                  ),
                ),
                labelStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                backgroundColor: kOrangeContrasted,
                foregroundColor: Colors.white,
                shape: CircleBorder(),
                label: 'Flash news',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    WriteFlashNewsView.routeName,
                  );
                },
              ),
              SpeedDialChild(
                child: SvgPicture.asset(
                  FeatureIcons.addCuration,
                  width: 27,
                  height: 27,
                  colorFilter: ColorFilter.mode(
                    kWhite,
                    BlendMode.srcIn,
                  ),
                ),
                labelStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                backgroundColor: kOrangeContrasted,
                foregroundColor: Colors.white,
                shape: CircleBorder(),
                label: 'Curation',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AddSelfCurationView.routeName,
                    arguments: [
                      null,
                      true,
                    ],
                  );
                },
              ),
              SpeedDialChild(
                child: SvgPicture.asset(
                  FeatureIcons.addVideo,
                  width: 27,
                  height: 27,
                  colorFilter: ColorFilter.mode(
                    kWhite,
                    BlendMode.srcIn,
                  ),
                ),
                labelStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                backgroundColor: kOrangeContrasted,
                foregroundColor: Colors.white,
                shape: CircleBorder(),
                label: 'Video',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    WriteVideoView.routeName,
                    arguments: [
                      context.read<MainCubit>(),
                    ],
                  );
                },
              ),
              SpeedDialChild(
                child: SvgPicture.asset(
                  FeatureIcons.addSmartWidget,
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    kWhite,
                    BlendMode.srcIn,
                  ),
                ),
                labelStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                backgroundColor: kOrangeContrasted,
                foregroundColor: Colors.white,
                shape: CircleBorder(),
                label: 'Smart widget',
                onTap: () {
                  Navigator.pushNamed(context, WriteSmartWidgetView.routeName,
                      arguments: []);
                },
              ),
            ],
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }
}
