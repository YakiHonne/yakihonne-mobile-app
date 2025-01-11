// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/blocs/uncensored_notes_cubit/un_flash_news_details_cubit/un_flash_news_details_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_tags_row.dart';
import 'package:yakihonne/views/search_view/search_view.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/un_flashnews_add_note.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/un_flashnews_add_rating.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/uncensored_note_component.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/widgets/share_view.dart';

class UnFlashNewsDetails extends HookWidget {
  const UnFlashNewsDetails({
    Key? key,
    required this.unFlashNews,
  }) : super(key: key);

  static const routeName = '/unFlashNewsDetails';
  static Route route(RouteSettings settings) {
    final unFlashNews = settings.arguments as UnFlashNews;

    return CupertinoPageRoute(
      builder: (_) => UnFlashNewsDetails(unFlashNews: unFlashNews),
    );
  }

  final UnFlashNews unFlashNews;

  @override
  Widget build(BuildContext context) {
    final index = useState(0);
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return BlocProvider(
      create: (context) => UnFlashNewsDetailsCubit(
        unFlashNews: unFlashNews,
      ),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Details',
          notElevated: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ),
                  BlocBuilder<UnFlashNewsDetailsCubit, UnFlashNewsDetailsState>(
                    builder: (context, unState) {
                      return SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: BlocSelector<AuthorsCubit,
                                      AuthorsState, UserModel?>(
                                    selector: (state) => state
                                        .authors[unFlashNews.flashNews.pubkey],
                                    builder: (context, user) {
                                      final author = user ??
                                          emptyUserModel.copyWith(
                                            pubKey:
                                                unFlashNews.flashNews.pubkey,
                                            picturePlaceholder:
                                                getRandomPlaceholder(
                                              input:
                                                  unFlashNews.flashNews.pubkey,
                                              isPfp: true,
                                            ),
                                          );
                                      return Row(
                                        children: [
                                          ProfilePicture2(
                                            size: 25,
                                            image: author.picture,
                                            placeHolder:
                                                author.picturePlaceholder,
                                            padding: 0,
                                            strokeWidth: 1,
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
                                            width: kDefaultPadding / 2,
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'By: ',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelMedium!,
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        getAuthorName(author),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelMedium!
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  'On: ${dateFormat4.format(
                                                    unFlashNews
                                                        .flashNews.createdAt,
                                                  )}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall!
                                                      .copyWith(
                                                        color: kOrange,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PullDownButton(
                                            animationBuilder:
                                                (context, state, child) {
                                              return child;
                                            },
                                            routeTheme: PullDownMenuRouteTheme(
                                              backgroundColor: Theme.of(context)
                                                  .primaryColorLight,
                                            ),
                                            itemBuilder: (context) {
                                              final textStyle =
                                                  Theme.of(context)
                                                      .textTheme
                                                      .labelMedium;

                                              return [
                                                if (unState.userStatus ==
                                                    UserStatus.UsingPrivKey)
                                                  PullDownMenuItem(
                                                    title: 'Bookmark',
                                                    onTap: () {
                                                      showModalBottomSheet(
                                                        context: context,
                                                        elevation: 0,
                                                        builder: (_) {
                                                          return AddBookmarkView(
                                                            kind: EventKind
                                                                .TEXT_NOTE,
                                                            identifier:
                                                                unFlashNews
                                                                    .flashNews
                                                                    .id,
                                                            eventPubkey:
                                                                unFlashNews
                                                                    .flashNews
                                                                    .pubkey,
                                                            image: '',
                                                          );
                                                        },
                                                        isScrollControlled:
                                                            true,
                                                        useRootNavigator: true,
                                                        useSafeArea: true,
                                                        backgroundColor: Theme
                                                                .of(context)
                                                            .scaffoldBackgroundColor,
                                                      );
                                                    },
                                                    itemTheme:
                                                        PullDownMenuItemTheme(
                                                      textStyle: textStyle,
                                                    ),
                                                    iconWidget: BlocBuilder<
                                                        ThemeCubit, ThemeState>(
                                                      builder: (context,
                                                          themeState) {
                                                        final isDark =
                                                            themeState.theme ==
                                                                AppTheme
                                                                    .purpleDark;

                                                        return SvgPicture.asset(
                                                          unState.isBookmarked
                                                              ? isDark
                                                                  ? FeatureIcons
                                                                      .bookmarkFilledWhite
                                                                  : FeatureIcons
                                                                      .bookmarkFilledBlack
                                                              : isDark
                                                                  ? FeatureIcons
                                                                      .bookmarkEmptyWhite
                                                                  : FeatureIcons
                                                                      .bookmarkEmptyBlack,
                                                        );
                                                      },
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
                                                          image: '',
                                                          placeholder: '',
                                                          data: {
                                                            'kind': EventKind
                                                                .TEXT_NOTE,
                                                            'id': unFlashNews
                                                                .flashNews.id,
                                                            'createdAt':
                                                                unFlashNews
                                                                    .flashNews
                                                                    .createdAt,
                                                            'textContentType':
                                                                TextContentType
                                                                    .uncensoredNote,
                                                            if (unFlashNews
                                                                .isSealed)
                                                              'sealedNote':
                                                                  unFlashNews
                                                                      .sealedNote,
                                                          },
                                                          pubkey: unFlashNews
                                                              .flashNews.pubkey,
                                                          title: unFlashNews
                                                              .flashNews
                                                              .content,
                                                          description: '',
                                                          kindText:
                                                              'Flash news',
                                                          icon: FeatureIcons
                                                              .flashNews,
                                                          upvotes: 0,
                                                          downvotes: 0,
                                                          onShare: () {
                                                            RenderBox? box;
                                                            if (ResponsiveBreakpoints
                                                                    .of(context)
                                                                .largerThan(
                                                                    MOBILE)) {
                                                              box = context
                                                                      .findRenderObject()
                                                                  as RenderBox?;
                                                            }

                                                            shareLink(
                                                              renderBox: box,
                                                              pubkey:
                                                                  unFlashNews
                                                                      .flashNews
                                                                      .pubkey,
                                                              id: unFlashNews
                                                                  .flashNews.id,
                                                              kind: EventKind
                                                                  .TEXT_NOTE,
                                                              textContentType:
                                                                  TextContentType
                                                                      .uncensoredNote,
                                                            );
                                                          },
                                                        );
                                                      },
                                                      isScrollControlled: true,
                                                      useRootNavigator: true,
                                                      useSafeArea: true,
                                                      backgroundColor: Theme.of(
                                                              context)
                                                          .scaffoldBackgroundColor,
                                                    );
                                                  },
                                                  itemTheme:
                                                      PullDownMenuItemTheme(
                                                    textStyle: textStyle,
                                                  ),
                                                  iconWidget: SvgPicture.asset(
                                                    FeatureIcons.link,
                                                    height: 20,
                                                    width: 20,
                                                    colorFilter:
                                                        ColorFilter.mode(
                                                      Theme.of(context)
                                                          .primaryColorDark,
                                                      BlendMode.srcIn,
                                                    ),
                                                  ),
                                                ),
                                              ];
                                            },
                                            buttonBuilder:
                                                (context, showMenu) =>
                                                    IconButton(
                                              onPressed: showMenu,
                                              padding: EdgeInsets.zero,
                                              style: IconButton.styleFrom(
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .primaryColorLight,
                                              ),
                                              icon: Icon(
                                                Icons.more_vert_rounded,
                                                color: Theme.of(context)
                                                    .primaryColorDark,
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
                            if (unFlashNews.flashNews.tags.isNotEmpty ||
                                unFlashNews.flashNews.isImportant) ...[
                              const SizedBox(
                                height: kDefaultPadding / 2,
                              ),
                              FlashTagsRow(
                                isImportant: unFlashNews.flashNews.isImportant,
                                tags: unFlashNews.flashNews.tags,
                              ),
                            ],
                            const SizedBox(
                              height: kDefaultPadding / 2,
                            ),
                            linkifiedText(
                              context: context,
                              text: unFlashNews.flashNews.content,
                            ),
                            const SizedBox(
                              height: kDefaultPadding / 4,
                            ),
                            Row(
                              children: [
                                if (unFlashNews.flashNews.source.isNotEmpty)
                                  CustomIconButton(
                                    backgroundColor:
                                        Theme.of(context).primaryColorLight,
                                    icon: FeatureIcons.globe,
                                    onClicked: () {
                                      openWebPage(
                                        url: unFlashNews.flashNews.source,
                                      );
                                    },
                                    size: 22,
                                  ),
                                Spacer(),
                                Expanded(
                                  child: BlocBuilder<UnFlashNewsDetailsCubit,
                                      UnFlashNewsDetailsState>(
                                    builder: (context, state) {
                                      if (state.writingNoteStatus ==
                                          WritingNoteStatus.canBeWritten) {
                                        return Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () {
                                              showModalBottomSheet(
                                                context: context,
                                                elevation: 0,
                                                builder: (_) {
                                                  return BlocProvider.value(
                                                    value: context.read<
                                                        UnFlashNewsDetailsCubit>(),
                                                    child: UnFlashNewsAddNote(
                                                      onAdd: (content, source,
                                                          isCorrect) {
                                                        context
                                                            .read<
                                                                UnFlashNewsDetailsCubit>()
                                                            .addUncensoredNotes(
                                                              content: content,
                                                              source: source,
                                                              isCorrect:
                                                                  isCorrect,
                                                              onSuccess: () =>
                                                                  Navigator.pop(
                                                                      context),
                                                            );
                                                      },
                                                    ),
                                                  );
                                                },
                                                isScrollControlled: true,
                                                useRootNavigator: true,
                                                useSafeArea: true,
                                                backgroundColor: Theme.of(
                                                  context,
                                                ).scaffoldBackgroundColor,
                                              );
                                            },
                                            icon: Icon(
                                              Icons.add,
                                              size: 17,
                                              color: Theme.of(context)
                                                  .primaryColorLight,
                                            ),
                                            label: Text(
                                              'Add note',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium!
                                                  .copyWith(
                                                    color: Theme.of(context)
                                                        .primaryColorLight,
                                                  ),
                                            ),
                                            style: TextButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .primaryColorDark,
                                            ),
                                          ),
                                        );
                                      } else {
                                        return SizedBox.shrink();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: kDefaultPadding / 2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SliverToBoxAdapter(
                    child: BlocBuilder<UnFlashNewsDetailsCubit,
                        UnFlashNewsDetailsState>(
                      builder: (context, state) {
                        if (state.writingNoteStatus ==
                            WritingNoteStatus.alreadyWritten) {
                          return Container(
                            padding: const EdgeInsets.all(
                              kDefaultPadding / 2,
                            ),
                            margin: const EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                kDefaultPadding,
                              ),
                              color: kGreenSide,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: kGreen,
                                  size: 20,
                                ),
                                const SizedBox(
                                  width: kDefaultPadding / 4,
                                ),
                                Flexible(
                                  child: Text(
                                    'You have already contributed!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium!
                                        .copyWith(
                                          color: kGreen,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                  if (unFlashNews.isSealed) ...[
                    BlocBuilder<UnFlashNewsDetailsCubit,
                        UnFlashNewsDetailsState>(
                      builder: (context, state) {
                        return SliverToBoxAdapter(
                          child: UncensoredNoteComponent(
                            note: unFlashNews.sealedNote!.uncensoredNote,
                            isComponent: true,
                            isSealed: true,
                            sealDisable: true,
                            userStatus: state.userStatus,
                            onLike: () {},
                            onDislike: () {},
                            onDelete: (ratingNoteId) {},
                            sealedNote: unFlashNews.sealedNote,
                            flashNewsPubkey: unFlashNews.flashNews.pubkey,
                            isUncensoredNoteAuthor:
                                state.userStatus == UserStatus.UsingPrivKey &&
                                    nostrRepository.user.pubKey ==
                                        unFlashNews
                                            .sealedNote!.uncensoredNote.pubKey,
                          ),
                        );
                      },
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: kDefaultPadding,
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: Divider(
                      height: kDefaultPadding,
                      thickness: 0.5,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: kDefaultPadding / 2,
                        top: kDefaultPadding / 4,
                      ),
                      child: Text(
                        'Notes from the community',
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ),
                  SliverAppBar(
                    pinned: true,
                    automaticallyImplyLeading: false,
                    leadingWidth: 0,
                    backgroundColor: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withValues(alpha: 1),
                    toolbarHeight: 45,
                    titleSpacing: 0,
                    actions: [const SizedBox.shrink()],
                    elevation: 0,
                    title: SizedBox(
                      width: double.infinity,
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
                              FeatureIcons.uncensoredNote,
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
                            text: 'Ongoing',
                            height: 50,
                          ),
                          Tab(
                            icon: Icon(
                              CupertinoIcons.clear_circled,
                              size: 18,
                            ),
                            text: 'Not helpful',
                            height: 50,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ),
                ];
              },
              body:
                  BlocBuilder<UnFlashNewsDetailsCubit, UnFlashNewsDetailsState>(
                builder: (context, state) {
                  if (state.loading) {
                    return SearchLoading();
                  } else {
                    List<UncensoredNote> filteredUncensoredNotes =
                        state.uncensoredNotes;

                    List<String> notHelpfulIds = state.notHelpFulNotes
                        .map((e) => e.uncensoredNote.id)
                        .toList();

                    if (index.value == 1) {
                      filteredUncensoredNotes =
                          filteredUncensoredNotes.where((element) {
                        return notHelpfulIds.contains(element.id);
                      }).toList();
                    } else if (state.notHelpFulNotes.isNotEmpty) {
                      filteredUncensoredNotes =
                          filteredUncensoredNotes.where((element) {
                        return !notHelpfulIds.contains(element.id);
                      }).toList();
                    }

                    if (filteredUncensoredNotes.isEmpty) {
                      return ListView(
                        children: [
                          const SizedBox(
                            height: kDefaultPadding,
                          ),
                          Image.asset(
                            Images.chilling,
                            width: 150,
                            height: 150,
                          ),
                          const SizedBox(
                            height: kDefaultPadding / 2,
                          ),
                          Text(
                            "It's quiet here! No community notes yet.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: kDimGrey,
                                ),
                          ),
                        ],
                      );
                    }

                    if (isMobile) {
                      return ListView.separated(
                        separatorBuilder: (context, index) => const SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                        itemBuilder: (context, index) {
                          final note = filteredUncensoredNotes[index];
                          final isNoteSealedNotHelpful = state.notHelpFulNotes
                              .where((element) =>
                                  element.uncensoredNote.id == note.id)
                              .toList();

                          return getComponent(
                            context: context,
                            note: note,
                            sealedNotHelpful: isNoteSealedNotHelpful,
                            isSealed: state.isSealed,
                            userStatus: state.userStatus,
                          );
                        },
                        itemCount: filteredUncensoredNotes.length,
                      );
                    } else {
                      return MasonryGridView.builder(
                        gridDelegate:
                            SliverSimpleGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                        ),
                        mainAxisSpacing: kDefaultPadding / 2,
                        crossAxisSpacing: kDefaultPadding / 2,
                        itemBuilder: (context, index) {
                          final note = filteredUncensoredNotes[index];
                          final isNoteSealedNotHelpful = state.notHelpFulNotes
                              .where((element) =>
                                  element.uncensoredNote.id == note.id)
                              .toList();

                          return getComponent(
                            context: context,
                            note: note,
                            sealedNotHelpful: isNoteSealedNotHelpful,
                            isSealed: state.isSealed,
                            userStatus: state.userStatus,
                          );
                        },
                        itemCount: filteredUncensoredNotes.length,
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getComponent({
    required BuildContext context,
    required UncensoredNote note,
    required List<SealedNote> sealedNotHelpful,
    required bool isSealed,
    required UserStatus userStatus,
  }) {
    return UncensoredNoteComponent(
      note: note,
      isComponent: true,
      isSealed: sealedNotHelpful.isNotEmpty,
      sealDisable: isSealed,
      userStatus: userStatus,
      onLike: () {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) {
            return UnFlashNewsAddRating(
              isUpvote: true,
              uncensoredNoteId: note.id,
              onSuccess: () {
                context.read<UnFlashNewsDetailsCubit>().getUncensoredNotes();
                Navigator.pop(context);
              },
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      onDislike: () {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) {
            return UnFlashNewsAddRating(
              isUpvote: false,
              uncensoredNoteId: note.id,
              onSuccess: () {
                context.read<UnFlashNewsDetailsCubit>().getUncensoredNotes();
                Navigator.pop(context);
              },
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      onDelete: (ratingNoteId) {
        showCupertinoDeletionDialogue(
          context: context,
          title: 'Undo rating',
          description:
              'You are about to undo your rating, do you wish to proceed?',
          buttonText: 'undo',
          onDelete: () {
            context.read<UnFlashNewsDetailsCubit>().deleteRating(
                  uncensoredNoteId: note.id,
                  ratingId: ratingNoteId,
                  onSuccess: () {
                    context
                        .read<UnFlashNewsDetailsCubit>()
                        .getUncensoredNotes();
                    Navigator.pop(context);
                  },
                );
          },
        );
      },
      sealedNote: sealedNotHelpful.isEmpty ? null : sealedNotHelpful.first,
      flashNewsPubkey: unFlashNews.flashNews.pubkey,
      isUncensoredNoteAuthor: userStatus == UserStatus.UsingPrivKey &&
          nostrRepository.user.pubKey == note.pubKey,
    );
  }

  Color getColor({
    required BuildContext context,
    required int index,
    required int selectedIndex,
  }) {
    if (index == 0 && selectedIndex == 0 ||
        index == 1 && selectedIndex == 1 ||
        index == 2 && selectedIndex == 2) {
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
