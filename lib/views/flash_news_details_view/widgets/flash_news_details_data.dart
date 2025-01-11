// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:numeral/numeral.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/flash_news_details_cubit/flash_news_details_cubit.dart';
import 'package:yakihonne/blocs/single_event_cubit/single_event_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/article_view/widgets/article_report.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_tags_row.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/un_flashnews_details.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/uncensored_note_component.dart';
import 'package:yakihonne/views/widgets/comment_box_view.dart';
import 'package:yakihonne/views/widgets/comment_main_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/widgets/share_view.dart';
import 'package:yakihonne/views/widgets/voters_view.dart';
import 'package:yakihonne/views/widgets/zappers_view.dart';
import 'package:yakihonne/views/zap_view/set_zaps_view.dart';

class FlashNewsDetailsData extends HookWidget {
  const FlashNewsDetailsData({
    Key? key,
    required this.mainFlashNews,
    this.trySearch,
  }) : super(key: key);

  final MainFlashNews mainFlashNews;
  final bool? trySearch;

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: kDefaultPadding,
            ),
          ),
          SliverToBoxAdapter(
            child: BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
              selector: (state) =>
                  state.authors[mainFlashNews.flashNews.pubkey],
              builder: (context, user) {
                final author = user ??
                    emptyUserModel.copyWith(
                      pubKey: mainFlashNews.flashNews.pubkey,
                      picturePlaceholder: getRandomPlaceholder(
                        input: mainFlashNews.flashNews.pubkey,
                        isPfp: true,
                      ),
                    );
                return Row(
                  children: [
                    ProfilePicture2(
                      size: 40,
                      image: author.picture,
                      placeHolder: author.picturePlaceholder,
                      padding: 0,
                      strokeWidth: 0,
                      reduceSize: true,
                      strokeColor: kTransparent,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'By ${getAuthorName(author)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            '${dateFormat4.format(mainFlashNews.flashNews.createdAt)}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    BlocBuilder<FlashNewsDetailsCubit, FlashNewsDetailsState>(
                      builder: (context, state) {
                        return PullDownButton(
                          animationBuilder: (context, state, child) {
                            return child;
                          },
                          routeTheme: PullDownMenuRouteTheme(
                            backgroundColor:
                                Theme.of(context).primaryColorLight,
                          ),
                          itemBuilder: (context) {
                            final textStyle =
                                Theme.of(context).textTheme.labelMedium;

                            return [
                              if (state.userStatus ==
                                  UserStatus.UsingPrivKey) ...[
                                PullDownMenuItem(
                                  title: 'Bookmark',
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      elevation: 0,
                                      builder: (_) {
                                        return AddBookmarkView(
                                          kind: EventKind.TEXT_NOTE,
                                          identifier:
                                              mainFlashNews.flashNews.id,
                                          eventPubkey:
                                              mainFlashNews.flashNews.pubkey,
                                          image: '',
                                        );
                                      },
                                      isScrollControlled: true,
                                      useRootNavigator: true,
                                      useSafeArea: true,
                                      backgroundColor: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    );
                                  },
                                  itemTheme: PullDownMenuItemTheme(
                                    textStyle: textStyle,
                                  ),
                                  iconWidget:
                                      BlocBuilder<ThemeCubit, ThemeState>(
                                    builder: (context, themeState) {
                                      final isDark = themeState.theme ==
                                          AppTheme.purpleDark;

                                      return SvgPicture.asset(
                                        state.bookmarks.contains(state
                                                .mainFlashNews.flashNews.id)
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
                              ],
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
                                          'kind': EventKind.TEXT_NOTE,
                                          'id': mainFlashNews.flashNews.id,
                                          'createdAt':
                                              mainFlashNews.flashNews.createdAt,
                                          'textContentType':
                                              TextContentType.flashnews,
                                        },
                                        pubkey: mainFlashNews.flashNews.pubkey,
                                        title: mainFlashNews.flashNews.content,
                                        description: '',
                                        kindText: 'Flash news',
                                        icon: FeatureIcons.flashNews,
                                        upvotes: state.votes.values
                                            .where((element) => element.vote)
                                            .toList()
                                            .length,
                                        downvotes: state.votes.values
                                            .where((element) => !element.vote)
                                            .toList()
                                            .length,
                                        onShare: () {
                                          RenderBox? box;
                                          if (ResponsiveBreakpoints.of(context)
                                              .largerThan(MOBILE)) {
                                            box = context.findRenderObject()
                                                as RenderBox?;
                                          }

                                          context
                                              .read<FlashNewsDetailsCubit>()
                                              .shareLink(box);
                                        },
                                      );
                                    },
                                    isScrollControlled: true,
                                    useRootNavigator: true,
                                    useSafeArea: true,
                                    backgroundColor: Theme.of(context)
                                        .scaffoldBackgroundColor,
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
                              if (state.canBeZapped)
                                PullDownMenuItem(
                                  title: 'Zap',
                                  onTap: () {
                                    showModalBottomSheet(
                                      elevation: 0,
                                      context: context,
                                      builder: (_) {
                                        return SetZapsView(
                                          author: author,
                                          eventId: mainFlashNews.flashNews.id,
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
                                  itemTheme: PullDownMenuItemTheme(
                                    textStyle: textStyle,
                                  ),
                                  iconWidget: SvgPicture.asset(
                                    FeatureIcons.zap,
                                    height: 20,
                                    width: 20,
                                    colorFilter: ColorFilter.mode(
                                      Theme.of(context).primaryColorDark,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              if (state.userStatus == UserStatus.UsingPrivKey)
                                PullDownMenuItem(
                                  onTap: () {
                                    if (state.reports
                                        .contains(state.currentUserPubkey)) {
                                      singleSnackBar(
                                        context: context,
                                        message:
                                            'You have already reported this article.',
                                        color: kOrange,
                                        backGroundColor: kOrangeSide,
                                        icon: ToastsIcons.warning,
                                      );
                                    } else {
                                      showModalBottomSheet(
                                        context: context,
                                        elevation: 0,
                                        builder: (_) {
                                          return BlocProvider.value(
                                            value: context
                                                .read<FlashNewsDetailsCubit>(),
                                            child: ArticleReports(
                                              title: 'Current flash news',
                                              isArticle: false,
                                              onReport: (reason, comment) {
                                                context
                                                    .read<
                                                        FlashNewsDetailsCubit>()
                                                    .report(
                                                      reason: reason,
                                                      comment: comment,
                                                      onSuccess: () {
                                                        Navigator.pop(context);
                                                      },
                                                    );
                                              },
                                            ),
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
                                  title: 'Report',
                                  isDestructive: true,
                                  iconWidget: SvgPicture.asset(
                                    FeatureIcons.report,
                                    height: 20,
                                    width: 20,
                                    colorFilter: ColorFilter.mode(
                                      kRed,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  itemTheme: PullDownMenuItemTheme(
                                    textStyle: textStyle,
                                  ),
                                ),
                            ];
                          },
                          buttonBuilder: (context, showMenu) => IconButton(
                            onPressed: showMenu,
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).primaryColorLight,
                            ),
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: Theme.of(context).primaryColorDark,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          if (mainFlashNews.flashNews.tags.isNotEmpty ||
              mainFlashNews.flashNews.isImportant) ...[
            SliverToBoxAdapter(
              child: const SizedBox(
                height: kDefaultPadding / 2,
              ),
            ),
            SliverToBoxAdapter(
              child: FlashTagsRow(
                isImportant: mainFlashNews.flashNews.isImportant,
                tags: mainFlashNews.flashNews.tags,
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: kDefaultPadding / 2,
              ),
              child: linkifiedText(
                context: context,
                text: mainFlashNews.flashNews.content,
                onClicked: () {},
              ),
            ),
          ),
          if (mainFlashNews.sealedNote != null || trySearch != null) ...[
            SliverToBoxAdapter(
              child: SealedComponent(
                mainFlashNews: mainFlashNews,
                trySearch: trySearch,
              ),
            ),
          ],
          BlocBuilder<FlashNewsDetailsCubit, FlashNewsDetailsState>(
            builder: (context, state) {
              return SliverToBoxAdapter(
                child: Builder(
                  builder: (context) {
                    final calculatedVotes = getVotes(
                      votes: state.votes,
                      pubkey: state.userStatus == UserStatus.UsingPrivKey
                          ? state.currentUserPubkey
                          : null,
                    );

                    final zaps = Numeral(
                      state.zaps.values.toList().fold(
                            0.0,
                            (previous, current) => previous + current,
                          ),
                    );

                    return Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Row(
                              children: [
                                CustomIconButton(
                                  backgroundColor: kTransparent,
                                  icon: FeatureIcons.zap,
                                  onLongPress: () {
                                    showModalBottomSheet(
                                      context: context,
                                      elevation: 0,
                                      builder: (_) {
                                        return ZappersView(
                                          zappers: state.zaps,
                                        );
                                      },
                                      isScrollControlled: true,
                                      useRootNavigator: true,
                                      useSafeArea: true,
                                      backgroundColor: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    );
                                  },
                                  onClicked: () {},
                                  value: zaps.toString(),
                                  size: 22,
                                ),
                                const SizedBox(
                                  width: kDefaultPadding / 4,
                                ),
                                CustomIconButton(
                                  backgroundColor: kTransparent,
                                  icon: FeatureIcons.comments,
                                  onClicked: () {
                                    if (state.userStatus ==
                                        UserStatus.UsingPrivKey)
                                      showModalBottomSheet(
                                        context: context,
                                        elevation: 0,
                                        builder: (_) {
                                          return CommentBoxView(
                                            commentId: '',
                                            commentPubkey: state
                                                .mainFlashNews.flashNews.pubkey,
                                            commentContent: state.mainFlashNews
                                                .flashNews.content,
                                            commentDate: state.mainFlashNews
                                                .flashNews.createdAt,
                                            kind: EventKind.TEXT_NOTE,
                                            shareableLink: createShareableLink(
                                              EventKind.TEXT_NOTE,
                                              state.mainFlashNews.flashNews
                                                  .pubkey,
                                              state.mainFlashNews.flashNews.id,
                                            ),
                                            onAddComment: (commentContent,
                                                mentions, commentId) {
                                              context
                                                  .read<FlashNewsDetailsCubit>()
                                                  .addComment(
                                                    content: commentContent,
                                                    replyCommentId: commentId,
                                                    mentions: mentions,
                                                    onSuccess: () {
                                                      Navigator.pop(context);
                                                    },
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
                                  },
                                  value: getCommentsCount(state.comments)
                                      .toString(),
                                  size: 22,
                                ),
                                const SizedBox(
                                  width: kDefaultPadding / 4,
                                ),
                                CustomIconButton(
                                  backgroundColor: kTransparent,
                                  onLongPress: () {
                                    showModalBottomSheet(
                                      context: context,
                                      elevation: 0,
                                      builder: (_) {
                                        final upvotes = state.votes.entries
                                            .where((element) =>
                                                element.value.vote);

                                        return VotersView(
                                          voters: Map<String,
                                              VoteModel>.fromEntries(
                                            upvotes,
                                          ),
                                          title: 'Upvoters',
                                        );
                                      },
                                      isScrollControlled: true,
                                      useRootNavigator: true,
                                      useSafeArea: true,
                                      backgroundColor: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    );
                                  },
                                  icon: calculatedVotes[1]
                                      ? FeatureIcons.upvoteFilled
                                      : FeatureIcons.upvote,
                                  onClicked: () {
                                    context
                                        .read<FlashNewsDetailsCubit>()
                                        .setVote(
                                          upvote: true,
                                          eventId: mainFlashNews.flashNews.id,
                                          eventPubkey:
                                              mainFlashNews.flashNews.pubkey,
                                        );
                                  },
                                  value: calculatedVotes[0].toString(),
                                  size: 22,
                                ),
                                const SizedBox(
                                  width: kDefaultPadding / 4,
                                ),
                                CustomIconButton(
                                  backgroundColor: kTransparent,
                                  onLongPress: () {
                                    showModalBottomSheet(
                                      context: context,
                                      elevation: 0,
                                      builder: (_) {
                                        final downvotes = state.votes.entries
                                            .where((element) =>
                                                !element.value.vote);

                                        return VotersView(
                                          voters: Map<String,
                                              VoteModel>.fromEntries(
                                            downvotes,
                                          ),
                                          title: 'Downvoters',
                                        );
                                      },
                                      isScrollControlled: true,
                                      useRootNavigator: true,
                                      useSafeArea: true,
                                      backgroundColor: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    );
                                  },
                                  icon: calculatedVotes[3]
                                      ? FeatureIcons.downvoteFilled
                                      : FeatureIcons.downvote,
                                  onClicked: () {
                                    context
                                        .read<FlashNewsDetailsCubit>()
                                        .setVote(
                                          upvote: false,
                                          eventId: mainFlashNews.flashNews.id,
                                          eventPubkey:
                                              mainFlashNews.flashNews.pubkey,
                                        );
                                  },
                                  value: calculatedVotes[2].toString(),
                                  size: 22,
                                ),
                                const SizedBox(
                                  width: kDefaultPadding / 4,
                                ),
                                CustomIconButton(
                                  backgroundColor: kTransparent,
                                  onLongPress: () {},
                                  icon: FeatureIcons.report,
                                  onClicked: () {},
                                  value: state.reports.length.toString(),
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 2,
                        ),
                        if (mainFlashNews.flashNews.source.isNotEmpty) ...[
                          CustomIconButton(
                            backgroundColor:
                                Theme.of(context).primaryColorLight,
                            icon: FeatureIcons.globe,
                            onClicked: () {
                              openWebPage(url: mainFlashNews.flashNews.source);
                            },
                            size: 22,
                          ),
                        ]
                      ],
                    );
                  },
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Divider(
              height: kDefaultPadding * 2,
            ),
          ),
          BlocBuilder<FlashNewsDetailsCubit, FlashNewsDetailsState>(
            builder: (context, state) {
              if (state.comments.isEmpty ||
                  rootComments(comments: state.comments)) {
                return SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No comments can be found',
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 4,
                      ),
                      Text(
                        'Be the first to comment on this flash news !',
                        style:
                            Theme.of(context).textTheme.bodySmall!.copyWith(),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                );
              } else {
                return FlashNewsMainComments(
                  comments: state.comments,
                  authorPubkey: state.mainFlashNews.flashNews.pubkey,
                  kind: EventKind.TEXT_NOTE,
                  shareableLink: createShareableLink(
                    EventKind.TEXT_NOTE,
                    state.mainFlashNews.flashNews.pubkey,
                    state.mainFlashNews.flashNews.id,
                  ),
                  onAddComment: (commentContent, mentions, commentId) {
                    context.read<FlashNewsDetailsCubit>().addComment(
                          content: commentContent,
                          replyCommentId: commentId,
                          mentions: mentions,
                          onSuccess: () {
                            Navigator.pop(context);
                          },
                        );
                  },
                  onDeleteComment: (commentId) {
                    context
                        .read<FlashNewsDetailsCubit>()
                        .deleteComment(commentId: commentId);
                  },
                  currentUserPubkey: state.currentUserPubkey,
                  userStatus: state.userStatus,
                  mutes: state.mutes,
                  scrollController: scrollController,
                );
              }
            },
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: kBottomNavigationBarHeight,
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> getVotes({
    required Map<String, VoteModel>? votes,
    required String? pubkey,
  }) {
    int calculatedUpvotes = 0;
    int calculatedDownvotes = 0;
    bool userUpvote = false;
    bool userDownvote = false;

    if (votes == null) {
      return [
        calculatedUpvotes,
        userUpvote,
        calculatedDownvotes,
        userDownvote,
      ];
    }

    votes.forEach(
      (key, value) {
        if (value.vote) {
          calculatedUpvotes++;
          if (pubkey != null && key == pubkey) {
            userUpvote = true;
          }
        } else {
          calculatedDownvotes++;
          if (pubkey != null && key == pubkey) {
            userDownvote = true;
          }
        }
      },
    );

    return [
      calculatedUpvotes,
      userUpvote,
      calculatedDownvotes,
      userDownvote,
    ];
  }
}

class SealedComponent extends StatelessWidget {
  SealedComponent({
    Key? key,
    required this.mainFlashNews,
    this.trySearch,
    this.isComponent,
    this.hideSealed,
  }) {
    if (trySearch != null && mainFlashNews.sealedNote == null) {
      singleEventCubit.getSealedEventOverHttp(mainFlashNews.flashNews.id);
    }
  }

  final MainFlashNews mainFlashNews;
  final bool? trySearch;
  final bool? isComponent;
  final bool? hideSealed;

  @override
  Widget build(BuildContext context) {
    if (mainFlashNews.sealedNote != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!mainFlashNews.sealedNote!.uncensoredNote.leading &&
                hideSealed == null) ...[
              UncensoredNoteComponent(
                note: mainFlashNews.sealedNote!.uncensoredNote,
                flashNewsPubkey: mainFlashNews.flashNews.pubkey,
                userStatus: getUserStatus(),
                isUncensoredNoteAuthor: false,
                sealedNote: mainFlashNews.sealedNote,
                isComponent: isComponent ?? true,
                isSealed: true,
                sealDisable: false,
                onDelete: (id) {},
                onLike: () {},
                onDislike: () {},
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
            ],
            RoundedTextButtonWithArrow(
              text: 'See all uncensored notes',
              buttonColor: kBlue,
              textColor: kWhite,
              onClicked: () {
                Navigator.pushNamed(
                  context,
                  UnFlashNewsDetails.routeName,
                  arguments: UnFlashNews(
                    flashNews: mainFlashNews.flashNews,
                    sealedNote: mainFlashNews.sealedNote,
                    uncensoredNotes: [],
                    isSealed: true,
                  ),
                );
              },
            ),
          ],
        ),
      );
    } else if (trySearch != null) {
      return BlocBuilder<SingleEventCubit, SingleEventState>(
        builder: (context, state) {
          final sealedNote = state.sealedNotes[mainFlashNews.flashNews.id];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sealedNote != null &&
                    !sealedNote.uncensoredNote.leading &&
                    hideSealed == null) ...[
                  UncensoredNoteComponent(
                    note: sealedNote.uncensoredNote,
                    flashNewsPubkey: mainFlashNews.flashNews.pubkey,
                    userStatus: getUserStatus(),
                    isUncensoredNoteAuthor: false,
                    sealedNote: sealedNote,
                    isComponent: isComponent ?? true,
                    isSealed: true,
                    sealDisable: false,
                    onDelete: (id) {},
                    onLike: () {},
                    onDislike: () {},
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 4,
                  ),
                ],
                RoundedTextButtonWithArrow(
                  text: 'See all uncensored notes',
                  buttonColor: kBlue,
                  textColor: kWhite,
                  onClicked: () {
                    Navigator.pushNamed(
                      context,
                      UnFlashNewsDetails.routeName,
                      arguments: UnFlashNews(
                        flashNews: mainFlashNews.flashNews,
                        sealedNote: sealedNote,
                        uncensoredNotes: [],
                        isSealed: sealedNote != null,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
        bloc: singleEventCubit,
      );
    } else {
      return SizedBox.shrink();
    }
  }
}
