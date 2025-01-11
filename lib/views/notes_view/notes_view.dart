// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/notes_cubit/notes_cubit.dart';
import 'package:yakihonne/blocs/notes_events_cubit/notes_events_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/event.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/dm_view/widgets/camera_options_view.dart';
import 'package:yakihonne/views/note_view/note_view.dart';
import 'package:yakihonne/views/notes_view/widgets/note_stats.dart';
import 'package:yakihonne/views/profile_view/profile_view.dart';
import 'package:yakihonne/views/search_view/search_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/classic_footer.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/write_note_view/write_note_view.dart';

class NotesView extends StatefulWidget {
  const NotesView({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> with TickerProviderStateMixin {
  final refreshController = RefreshController();
  late TabController tabController;
  late bool isConnected;
  int index = 0;
  NotesType notesType = NotesType.followings;

  @override
  void initState() {
    isConnected = isUsingPrivatekey();
    notesType = isConnected ? NotesType.followings : NotesType.trending;
    tabController = TabController(
      length: isConnected ? 4 : 3,
      initialIndex: 0,
      vsync: this,
    );

    super.initState();
  }

  void onRefresh({required Function onInit}) {
    refreshController.resetNoData();
    onInit.call();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocProvider(
      create: (context) => NotesCubit(),
      child: BlocConsumer<NotesCubit, NotesState>(
        listenWhen: (previous, current) =>
            previous.loadingMoreState != current.loadingMoreState,
        listener: (context, state) {
          if (state.loadingMoreState == UpdatingState.success) {
            refreshController.loadComplete();
          } else if (state.loadingMoreState == UpdatingState.idle) {
            refreshController.loadNoData();
          }
        },
        builder: (context, state) {
          return NestedScrollView(
            controller: widget.scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  leadingWidth: 0,
                  elevation: 5,
                  floating: true,
                  actions: [const SizedBox.shrink()],
                  titleSpacing: 0,
                  toolbarHeight: 38,
                  flexibleSpace: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TabBar(
                          labelStyle:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                          dividerColor: Theme.of(context).primaryColorLight,
                          controller: tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding / 1.5,
                          ),
                          unselectedLabelStyle:
                              Theme.of(context).textTheme.labelMedium,
                          onTap: (index) {
                            isConnected = isUsingPrivatekey();
                            if (isConnected) {
                              notesType = index == 0
                                  ? NotesType.followings
                                  : index == 1
                                      ? NotesType.trending
                                      : index == 2
                                          ? NotesType.widgets
                                          : NotesType.universal;
                            } else {
                              notesType = index == 0
                                  ? NotesType.trending
                                  : index == 1
                                      ? NotesType.widgets
                                      : NotesType.universal;
                            }

                            context
                                .read<NotesCubit>()
                                .getNotes(false, notesType);
                          },
                          tabs: [
                            if (isConnected)
                              Tab(
                                height: 35,
                                child: TabTextRow(
                                  icon: FeatureIcons.followings,
                                  title: 'Followings',
                                ),
                              ),
                            Tab(
                              height: 35,
                              child: TabTextRow(
                                icon: FeatureIcons.trending,
                                title: 'Trending',
                              ),
                            ),
                            Tab(
                              height: 35,
                              child: TabTextRow(
                                icon: FeatureIcons.smartWidget,
                                title: 'Widget notes',
                              ),
                            ),
                            Tab(
                              height: 35,
                              child: TabTextRow(
                                icon: FeatureIcons.globe,
                                title: 'Universal',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: BlocBuilder<NotesCubit, NotesState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return SearchLoading();
                } else if (state.detailedNotes.isEmpty) {
                  return EmptyList(
                    description: 'No notes can be found!',
                    icon: FeatureIcons.addUncensoredNote,
                  );
                } else {
                  return SmartRefresher(
                    scrollController: widget.scrollController,
                    controller: refreshController,
                    enablePullDown: true,
                    enablePullUp: true,
                    header: const MaterialClassicHeader(
                      color: kPurple,
                    ),
                    footer: const RefresherClassicFooter(),
                    onLoading: () =>
                        context.read<NotesCubit>().getNotes(true, notesType),
                    onRefresh: () => onRefresh(
                      onInit: () =>
                          context.read<NotesCubit>().getNotes(false, notesType),
                    ),
                    child: isTablet
                        ? MasonryGridView.count(
                            crossAxisCount: 2,
                            itemCount: state.detailedNotes.length,
                            crossAxisSpacing: kDefaultPadding / 2,
                            padding: const EdgeInsets.all(kDefaultPadding),
                            itemBuilder: (context, index) {
                              final event = state.detailedNotes[index];

                              if (event.kind == EventKind.REPOST) {
                                return RepostNoteContainer(event: event);
                              } else {
                                return DetailedNoteContainer(
                                  note: DetailedNoteModel.fromEvent(event),
                                  selfStats: true,
                                  isMain: false,
                                  addLine: false,
                                );
                              }
                            },
                          )
                        : ListView.separated(
                            controller: widget.scrollController,
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                              height: kDefaultPadding / 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding / 2,
                              vertical: kDefaultPadding / 2,
                            ),
                            itemBuilder: (context, index) {
                              final event = state.detailedNotes[index];

                              if (event.kind == EventKind.REPOST) {
                                return RepostNoteContainer(event: event);
                              } else {
                                return DetailedNoteContainer(
                                  key: Key(event.id),
                                  note: DetailedNoteModel.fromEvent(event),
                                  selfStats: true,
                                  isMain: false,
                                  addLine: false,
                                );
                              }
                            },
                            itemCount: state.detailedNotes.length,
                          ),
                  );
                }
              },
            ),
          );
        },
      ),
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

class TabTextRow extends StatelessWidget {
  const TabTextRow({
    Key? key,
    required this.title,
    required this.icon,
  }) : super(key: key);

  final String title;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          icon,
          width: 18,
          height: 18,
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
            title,
            maxLines: 1,
            overflow: TextOverflow.fade,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}

class NotesHeader extends HookWidget {
  const NotesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final index = useState(0);

    return BlocBuilder<NotesCubit, NotesState>(
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
                      text: 'Trending',
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
                      text: 'Universal',
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
                      text: 'Followings',
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

class RepostNoteContainer extends StatelessWidget {
  const RepostNoteContainer({
    Key? key,
    required this.event,
  }) : super(key: key);

  final Event event;

  @override
  Widget build(BuildContext context) {
    final originalEvent = getRepostedEvent();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
          selector: (state) => authorsCubit.getAuthor(event.pubkey),
          builder: (context, user) {
            final author = user ??
                emptyUserModel.copyWith(
                  pubKey: event.pubkey,
                  picturePlaceholder:
                      getRandomPlaceholder(input: event.pubkey, isPfp: true),
                );

            return GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                ProfileView.routeName,
                arguments: author.pubKey,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                  vertical: kDefaultPadding / 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(300),
                  color: Theme.of(context).primaryColorLight,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProfilePicture2(
                      size: 16,
                      image: author.picture,
                      placeHolder: author.picturePlaceholder,
                      padding: 0,
                      strokeWidth: 0,
                      reduceSize: true,
                      strokeColor: kWhite,
                      onClicked: () {
                        openProfileFastAccess(
                          context: context,
                          pubkey: author.pubKey,
                        );
                      },
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 4,
                    ),
                    Text(
                      getAuthorName(author),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 4,
                    ),
                    SvgPicture.asset(
                      FeatureIcons.refresh,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).primaryColorDark,
                        BlendMode.srcIn,
                      ),
                      width: 15,
                      height: 15,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        if (originalEvent != null && originalEvent is Event)
          DetailedNoteContainer(
            note: DetailedNoteModel.fromEvent(originalEvent),
            selfStats: true,
            isMain: false,
            addLine: false,
          )
        else if (originalEvent != null)
          BlocSelector<NotesEventsCubit, NotesEventsState, Event?>(
            selector: (state) =>
                singleEventCubit.getEvent(originalEvent, false),
            builder: (context, event) {
              if (event == null) {
                return Container();
              } else {
                return DetailedNoteContainer(
                  note: DetailedNoteModel.fromEvent(event),
                  selfStats: true,
                  isMain: false,
                  addLine: false,
                );
              }
            },
          )
        else
          Container(),
      ],
    );
  }

  dynamic getRepostedEvent() {
    try {
      if (event.content.isNotEmpty) {
        return Event.fromJson(jsonDecode(event.content));
      } else {
        String? id;

        for (final tag in event.tags) {
          if (tag.first == 'e' && tag.length > 2) {
            id = tag[1];
          }
        }

        if (id != null) {
          return id;
        }
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}

class DetailedNoteContainer extends HookWidget {
  const DetailedNoteContainer({
    Key? key,
    required this.note,
    required this.isMain,
    required this.addLine,
    required this.selfStats,
  }) : super(key: key);

  final DetailedNoteModel note;
  final bool isMain;
  final bool addLine;
  final bool selfStats;

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      authorsCubit.getAuthor(note.pubkey);
    });

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isMain
          ? () {}
          : () {
              Navigator.pushNamed(context, NoteView.routeName, arguments: note);
            },
      child: BlocBuilder<AuthorsCubit, AuthorsState>(
        builder: (context, state) {
          final author = state.authors[note.pubkey] ??
              emptyUserModel.copyWith(
                pubKey: note.pubkey,
                picturePlaceholder:
                    getRandomPlaceholder(input: note.pubkey, isPfp: true),
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        ProfilePicture2(
                          image: author.picture,
                          placeHolder: author.picturePlaceholder,
                          size: 35,
                          padding: 0,
                          strokeWidth: 0,
                          strokeColor: kTransparent,
                          onClicked: () {
                            openProfileFastAccess(
                              context: context,
                              pubkey: author.pubKey,
                            );
                          },
                        ),
                        if (addLine) ...[
                          const SizedBox(
                            height: kDefaultPadding / 2,
                          ),
                          Expanded(
                            child: VerticalDivider(),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  getAuthorName(author),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if ((authorsCubit.state
                                          .nip05Validations[author.pubKey] ??
                                      false) &&
                                  !isMain)
                                Flexible(
                                  child: Text(
                                    ' @${getAuthorDisplayName(author)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(color: kRed),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              DotContainer(
                                color: Theme.of(context).primaryColorDark,
                                size: 4,
                              ),
                              Text(
                                StringUtil.getLastDate(note.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(color: kDimGrey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          if (isMain)
                            if (authorsCubit
                                    .state.nip05Validations[author.pubKey] ??
                                false)
                              Text(
                                '@${getAuthorName(author)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(color: kRed),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          if (!isMain) ...[
                            const SizedBox(
                              height: kDefaultPadding / 4,
                            ),
                            linkifiedText(
                              context: context,
                              onClicked: () => Navigator.pushNamed(
                                context,
                                NoteView.routeName,
                                arguments: note,
                              ),
                              text: note.content.trim(),
                              isKeepAlive: true,
                            ),
                            NoteStats(
                              note: note,
                              selfStats: selfStats,
                              onComment: () {},
                              onRepost: () {},
                              onUpvote: () {},
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isMain) ...[
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                linkifiedText(
                  context: context,
                  onClicked: isMain
                      ? () {}
                      : () => Navigator.pushNamed(
                            context,
                            NoteView.routeName,
                            arguments: note,
                          ),
                  text: note.content.trim(),
                  isKeepAlive: true,
                ),
                NoteStats(
                  note: note,
                  selfStats: selfStats,
                  onComment: () {},
                  onRepost: () {},
                  onUpvote: () {},
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class NoteOptions extends StatelessWidget {
  const NoteOptions({
    Key? key,
    required this.note,
    required this.onSuccess,
  }) : super(key: key);

  final DetailedNoteModel note;
  final Function() onSuccess;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
      child: Container(
        width: 100.w,
        margin: const EdgeInsets.all(kDefaultPadding),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding * 2),
          color: Theme.of(context).primaryColorLight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalBottomSheetHandle(),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: PickChoice(
                      pubkey: '',
                      replyId: '',
                      onSuccess: () {},
                      onFailed: () {},
                      onClicked: () {
                        Navigator.pop(context);
                        notesEventsCubit.repostNote(note);
                      },
                      icon: FeatureIcons.refresh,
                      title: 'Repost',
                      mediaType: MediaType.cameraImage,
                    ),
                  ),
                  VerticalDivider(
                    indent: kDefaultPadding / 2,
                    endIndent: kDefaultPadding / 2,
                  ),
                  Expanded(
                    child: PickChoice(
                      pubkey: '',
                      replyId: '',
                      onSuccess: () {},
                      onFailed: () {},
                      onClicked: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          elevation: 0,
                          builder: (_) {
                            return WriteNoteView(
                              quotedNote: note,
                            );
                          },
                          isScrollControlled: true,
                          useRootNavigator: true,
                          useSafeArea: true,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                        );
                      },
                      icon: FeatureIcons.quote,
                      title: 'Quote',
                      mediaType: MediaType.cameraImage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
              ),
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: kWhite,
                      ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: kRed,
                ),
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
        ),
      ),
    );
  }
}
