// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/dms_cubit/dms_cubit.dart';
import 'package:yakihonne/blocs/lightning_zaps_cubit/lightning_zaps_cubit.dart';
import 'package:yakihonne/blocs/profile_cubit/profile_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/nostr/nips/nips.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/dm_view/widgets/dm_details.dart';
import 'package:yakihonne/views/main_view/widgets/profile_share_view.dart';
import 'package:yakihonne/views/profile_view/widgets/articles_list.dart';
import 'package:yakihonne/views/profile_view/widgets/curations_list.dart';
import 'package:yakihonne/views/profile_view/widgets/flash_news_list.dart';
import 'package:yakihonne/views/profile_view/widgets/notes_list.dart';
import 'package:yakihonne/views/profile_view/widgets/profile_header.dart';
import 'package:yakihonne/views/profile_view/widgets/videos_list.dart';
import 'package:yakihonne/views/widgets/article_thumbnail.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/widgets/scroll_to_top.dart';
import 'package:yakihonne/views/widgets/share_view.dart';
import 'package:yakihonne/views/zap_view/set_zaps_view.dart';

class ProfileView extends HookWidget {
  static const routeName = '/profileView';
  static Route route(RouteSettings settings) {
    final id = settings.arguments as String;

    return CupertinoPageRoute(
      builder: (_) => ProfileView(authorPubkey: id),
    );
  }

  ProfileView({
    super.key,
    required this.authorPubkey,
  }) {
    FirebaseAnalytics.instance.setCurrentScreen(screenName: 'Profile screen');
  }

  final String authorPubkey;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController(
      initialScrollOffset: 0,
    );

    return BlocProvider(
      create: (context) => ProfileCubit(
        nostrRepository: context.read<NostrDataRepository>(),
        authorId: authorPubkey,
      )..initView(),
      child: ScrollsToTop(
        onScrollsToTop: (event) async {
          onScrollsToTop(event, scrollController);
        },
        child: Scaffold(
          body: Stack(
            children: [
              BlocBuilder<ProfileCubit, ProfileState>(
                buildWhen: (previous, current) =>
                    previous.profileStatus != current.profileStatus,
                builder: (context, state) {
                  return DefaultTabController(
                    length: 5,
                    child: NestedScrollViewPlus(
                      controller: scrollController,
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          ProfileAppBar(),
                          SliverToBoxAdapter(
                            child: ProfileHeader(),
                          ),
                          OptionsHeader(),
                        ];
                      },
                      body: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: <Widget>[
                          ProfileNotes(),
                          ProfileArticles(),
                          ProfileCurations(),
                          ProfileFlashNews(),
                          ProfileVideos(),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ResetScrollButton(scrollController: scrollController),
            ],
          ),
        ),
      ),
    );
  }
}

class OptionsHeader extends HookWidget {
  const OptionsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final index = useState(0);

    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (previous, current) =>
          previous.curations != current.curations ||
          previous.articles != current.articles ||
          previous.flashNews != current.flashNews ||
          previous.notes != current.notes ||
          previous.videos != current.videos,
      builder: (context, state) {
        return MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            leadingWidth: 0,
            backgroundColor:
                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 1),
            toolbarHeight: 45,
            actions: [const SizedBox()],
            elevation: 0,
            title: SizedBox(
              width: double.infinity,
              child: ScrollShadow(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: ButtonsTabBar(
                  backgroundColor: Theme.of(context).primaryColorDark,
                  elevation: 0,
                  unselectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColorLight,
                    border: Border.all(
                      color: Theme.of(context).primaryColorLight,
                      width: 3,
                    ),
                  ),
                  radius: 300,
                  unselectedLabelStyle: TextStyle(
                    color: Theme.of(context).primaryColorDark,
                  ),
                  labelStyle: TextStyle(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  height: 40,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                    vertical: 0,
                  ),
                  onTap: (selectedIndex) {
                    index.value = selectedIndex;
                  },
                  tabs: [
                    Tab(
                      icon: SvgPicture.asset(
                        FeatureIcons.note,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          getColor(
                            context: context,
                            index: 0,
                            selectedIndex: index.value,
                          ),
                          BlendMode.srcIn,
                        ),
                      ),
                      text: 'Notes & replies - ${state.notes.length}',
                      height: 50,
                    ),
                    Tab(
                      icon: SvgPicture.asset(
                        FeatureIcons.selfArticles,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          getColor(
                            context: context,
                            index: 1,
                            selectedIndex: index.value,
                          ),
                          BlendMode.srcIn,
                        ),
                      ),
                      text: 'Articles - ${state.articles.length}',
                      height: 50,
                    ),
                    Tab(
                      icon: SvgPicture.asset(
                        FeatureIcons.curations,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          getColor(
                            context: context,
                            index: 2,
                            selectedIndex: index.value,
                          ),
                          BlendMode.srcIn,
                        ),
                      ),
                      text: 'Curations - ${state.curations.length}',
                      height: 50,
                    ),
                    Tab(
                      icon: SvgPicture.asset(
                        FeatureIcons.flashNews,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          getColor(
                            context: context,
                            index: 3,
                            selectedIndex: index.value,
                          ),
                          BlendMode.srcIn,
                        ),
                      ),
                      text: 'Flash news - ${state.flashNews.length}',
                      height: 50,
                    ),
                    Tab(
                      icon: SvgPicture.asset(
                        FeatureIcons.videoOcta,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          getColor(
                            context: context,
                            index: 4,
                            selectedIndex: index.value,
                          ),
                          BlendMode.srcIn,
                        ),
                      ),
                      text: 'Videos - ${state.videos.length}',
                      height: 50,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color getColor({
    required BuildContext context,
    required int index,
    required int selectedIndex,
  }) {
    if (index == 0 && selectedIndex == 0 ||
        index == 1 && selectedIndex == 1 ||
        index == 2 && selectedIndex == 2 ||
        index == 3 && selectedIndex == 3 ||
        index == 4 && selectedIndex == 4) {
      if (context.read<ThemeCubit>().state.theme == AppTheme.purpleWhite) {
        return kWhite;
      } else {
        return kBlack;
      }
    } else {
      if (context.read<ThemeCubit>().state.theme == AppTheme.purpleWhite) {
        return kBlack;
      } else {
        return kWhite;
      }
    }
  }
}

class ProfileAppBar extends StatelessWidget {
  const ProfileAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return BlocListener<AuthorsCubit, AuthorsState>(
          listener: (context, authorsState) {
            final author = authorsState.authors[state.user.pubKey];
            if (author != null) {
              context.read<ProfileCubit>().canBeZapped(author);
            }
          },
          listenWhen: (previous, current) {
            final currentAuthor = current.authors[state.user.pubKey];
            final previousAuthor = previous.authors[state.user.pubKey];
            final currentNip05 = current.nip05Validations[state.user.pubKey];
            final previousNip05 = previous.nip05Validations[state.user.pubKey];

            return currentAuthor != previousAuthor ||
                currentNip05 != previousNip05;
          },
          child: SliverAppBar(
            expandedHeight: kToolbarHeight + 80,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            stretch: true,
            leading: FadeInRight(
              duration: const Duration(milliseconds: 500),
              from: 30,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Center(
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context)
                        .primaryColorLight
                        .withValues(alpha: 0.7),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              FadeInRight(
                duration: const Duration(milliseconds: 500),
                from: 30,
                child: Center(
                  child: CircleAvatar(
                    radius: 20,
                    child: PullDownButton(
                      animationBuilder: (context, state, child) {
                        return child;
                      },
                      routeTheme: PullDownMenuRouteTheme(
                        backgroundColor: Theme.of(context).primaryColorLight,
                      ),
                      itemBuilder: (context) {
                        final textStyle =
                            Theme.of(context).textTheme.labelMedium;

                        return [
                          PullDownMenuItem(
                            title: 'Refresh',
                            onTap: () {
                              context.read<ProfileCubit>().emitEmptyState();
                              context.read<ProfileCubit>().initView();
                            },
                            itemTheme: PullDownMenuItemTheme(
                              textStyle: textStyle,
                            ),
                            iconWidget: SvgPicture.asset(
                              FeatureIcons.refresh,
                              height: 20,
                              width: 20,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          PullDownMenuItem(
                            title: 'Copy pubkey',
                            onTap: () {
                              Clipboard.setData(
                                new ClipboardData(
                                  text: Nip19.encodePubkey(state.user.pubKey),
                                ),
                              );
                            },
                            itemTheme: PullDownMenuItemTheme(
                              textStyle: textStyle,
                            ),
                            iconWidget: SvgPicture.asset(
                              FeatureIcons.copy,
                              height: 20,
                              width: 20,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          PullDownMenuItem(
                            title: 'Share',
                            onTap: () {
                              showModalBottomSheet(
                                elevation: 0,
                                context: context,
                                builder: (_) {
                                  return ShareView(
                                    image: state.user.banner,
                                    placeholder: state.user.bannerPlaceholder,
                                    pubkey: state.user.pubKey,
                                    title: state.user.name,
                                    description: state.user.about,
                                    data: {
                                      'followings': state.followings.length,
                                      'followers': state.followers.length,
                                      'kind': EventKind.METADATA,
                                      'id': state.user.pubKey,
                                    },
                                    kindText: 'Profile',
                                    icon: FeatureIcons.selfArticles,
                                    upvotes: 0,
                                    onShare: () {
                                      RenderBox? box;
                                      if (ResponsiveBreakpoints.of(context)
                                          .largerThan(MOBILE)) {
                                        box = context.findRenderObject()
                                            as RenderBox?;
                                      }

                                      context
                                          .read<ProfileCubit>()
                                          .shareLink(box);
                                    },
                                  );
                                },
                                isScrollControlled: true,
                                useRootNavigator: true,
                                useSafeArea: true,
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                              );
                            },
                            itemTheme: PullDownMenuItemTheme(
                              textStyle: textStyle,
                            ),
                            iconWidget: SvgPicture.asset(
                              FeatureIcons.share,
                              height: 20,
                              width: 20,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          if (!state.isSameArticleAuthor)
                            PullDownMenuItem(
                              title: state.mutes.contains(state.user.pubKey)
                                  ? 'Unmute'
                                  : 'Mute',
                              onTap: () {
                                final isMuted =
                                    state.mutes.contains(state.user.pubKey);
                                final isUsingPrivKey = state.userStatus;
                                String description = '';

                                if (isUsingPrivKey == UserStatus.UsingPrivKey) {
                                  description =
                                      'You are about to ${isMuted ? 'unmute' : 'mute'} "${state.user.name}", do you wish to proceed?';
                                } else {
                                  description =
                                      'You are about to ${isMuted ? 'unmute' : 'mute'} "${state.user.name}". ${!isMuted ? "This will be stored locally while you are not connected or using a public key," : ""} do you wish to proceed?';
                                }

                                showCupertinoCustomDialogue(
                                  context: context,
                                  title: isMuted ? 'Unmute user' : 'Mute user',
                                  description: description,
                                  buttonText: isMuted ? 'Unmute' : 'Mute',
                                  buttonTextColor: isMuted ? kGreen : kRed,
                                  onClicked: () {
                                    context.read<ProfileCubit>().setMuteStatus(
                                          pubkey: state.user.pubKey,
                                          onSuccess: () =>
                                              Navigator.pop(context),
                                        );
                                  },
                                );
                              },
                              itemTheme: PullDownMenuItemTheme(
                                textStyle: textStyle?.copyWith(
                                  color: state.mutes.contains(state.user.pubKey)
                                      ? Theme.of(context).primaryColorDark
                                      : kRed,
                                ),
                              ),
                              iconWidget: SvgPicture.asset(
                                state.mutes.contains(state.user.pubKey)
                                    ? FeatureIcons.unmute
                                    : FeatureIcons.mute,
                                height: 20,
                                width: 20,
                                colorFilter: ColorFilter.mode(
                                  state.mutes.contains(state.user.pubKey)
                                      ? Theme.of(context).primaryColorDark
                                      : kRed,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                        ];
                      },
                      buttonBuilder: (context, showMenu) => IconButton(
                        onPressed: showMenu,
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColorLight,
                        ),
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: Theme.of(context).primaryColorDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              centerTitle: false,
              stretchModes: [
                StretchMode.zoomBackground,
              ],
              background: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) => SizedBox(
                          height: constraints.maxHeight,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (state.user.banner.isNotEmpty) {
                                      final imageProvider =
                                          CachedNetworkImageProvider(
                                        state.user.banner,
                                      );

                                      showImageViewer(
                                        context,
                                        imageProvider,
                                        doubleTapZoomable: true,
                                        swipeDismissible: true,
                                      );
                                    }
                                  },
                                  child: ArticleThumbnail(
                                    image: state.user.banner,
                                    placeholder: state.user.bannerPlaceholder,
                                    width: double.infinity,
                                    height: constraints.maxHeight,
                                    radius: 0,
                                    isRound: false,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: kDefaultPadding / 2,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final isDisabled = state.profileStatus !=
                                              ProfileStatus.available ||
                                          state.userStatus !=
                                              UserStatus.UsingPrivKey ||
                                          state.isSameArticleAuthor;

                                      return AbsorbPointer(
                                        absorbing: isDisabled,
                                        child: NewBorderedIconButton(
                                          onClicked: () {
                                            if (state.userStatus !=
                                                UserStatus.UsingPrivKey) {
                                            } else {
                                              context
                                                  .read<ProfileCubit>()
                                                  .setFollowingState();
                                            }
                                          },
                                          icon: state.isFollowingAuthor
                                              ? FeatureIcons.userFollowed
                                              : FeatureIcons.userToFollow,
                                          buttonStatus: isDisabled
                                              ? ButtonStatus.disabled
                                              : state.isFollowingAuthor
                                                  ? ButtonStatus.active
                                                  : ButtonStatus.inactive,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(
                                    width: kDefaultPadding / 4,
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final isDisabled = (state.profileStatus !=
                                              ProfileStatus.available ||
                                          !state.canBeZapped);

                                      return AbsorbPointer(
                                        absorbing: isDisabled,
                                        child: NewBorderedIconButton(
                                          onClicked: () {
                                            context
                                                .read<LightningZapsCubit>()
                                                .resetInvoice();

                                            showModalBottomSheet(
                                              context: context,
                                              elevation: 0,
                                              builder: (_) {
                                                return SetZapsView(
                                                  author: state.user,
                                                  isZapSplit: false,
                                                  zapSplits: [],
                                                );
                                              },
                                              isScrollControlled: true,
                                              useRootNavigator: true,
                                              useSafeArea: true,
                                              backgroundColor: Theme.of(context)
                                                  .scaffoldBackgroundColor,
                                            );
                                          },
                                          icon: FeatureIcons.zaps,
                                          buttonStatus: isDisabled
                                              ? ButtonStatus.disabled
                                              : ButtonStatus.inactive,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(
                                    width: kDefaultPadding / 4,
                                  ),
                                  if (getUserStatus() ==
                                      UserStatus.UsingPrivKey) ...[
                                    NewBorderedIconButton(
                                      onClicked: () {
                                        context
                                            .read<DmsCubit>()
                                            .updateReadedTime(
                                              state.user.pubKey,
                                            );
                                        Navigator.pushNamed(
                                          context,
                                          DmDetails.routeName,
                                          arguments: [
                                            state.user.pubKey,
                                          ],
                                        );
                                      },
                                      icon: FeatureIcons.startDms,
                                      buttonStatus: ButtonStatus.inactive,
                                    ),
                                    const SizedBox(
                                      width: kDefaultPadding / 4,
                                    ),
                                  ],
                                  NewBorderedIconButton(
                                    onClicked: () {
                                      Navigator.push(
                                        context,
                                        createViewFromBottom(
                                          ProfileShareView(
                                            userModel: state.user,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: '',
                                    iconData: CupertinoIcons.qrcode,
                                    buttonStatus: ButtonStatus.inactive,
                                  ),
                                  const SizedBox(
                                    width: kDefaultPadding / 2,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: kDefaultPadding / 2,
                            ),
                            child: ProfilePicture2(
                              size: 80,
                              image: state.user.picture,
                              placeHolder: state.user.picturePlaceholder,
                              padding: 0,
                              strokeWidth: 3,
                              strokeColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                              onClicked: () {
                                if (state.user.picture.isNotEmpty) {
                                  final imageProvider =
                                      CachedNetworkImageProvider(
                                    state.user.picture,
                                  );

                                  showImageViewer(
                                    context,
                                    imageProvider,
                                    doubleTapZoomable: true,
                                    swipeDismissible: true,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class UserStatsRow extends StatelessWidget {
  const UserStatsRow({
    Key? key,
    required this.icon,
    required this.firstTitle,
    required this.firstValue,
    required this.secondtitle,
    required this.secondValue,
  }) : super(key: key);

  final String icon;
  final String firstTitle;
  final String firstValue;
  final String secondtitle;
  final String secondValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          icon,
          width: 25,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodySmall,
                  children: [
                    TextSpan(
                      text: firstValue,
                    ),
                    TextSpan(
                      text: ' ${firstTitle}',
                      style: TextStyle(
                        color: kDimGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodySmall,
                  children: [
                    TextSpan(
                      text: secondValue,
                    ),
                    TextSpan(
                      text: ' ${secondtitle}',
                      style: TextStyle(
                        color: kDimGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
