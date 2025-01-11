// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/blocs/uncensored_notes_cubit/uncensored_notes_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_tags_row.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/un_flashnews_add_rating.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/uncensored_note_component.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/widgets/share_view.dart';

class UnFlashNewsContainer extends StatelessWidget {
  const UnFlashNewsContainer({
    Key? key,
    required this.unNewFlashNews,
    required this.userStatus,
    required this.isBookmarked,
    required this.onClicked,
    required this.onRefresh,
  }) : super(key: key);

  final UnFlashNews unNewFlashNews;
  final UserStatus userStatus;
  final bool isBookmarked;
  final Function() onClicked;
  final Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding),
          color: Theme.of(context).primaryColorLight,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(kDefaultPadding / 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BlocSelector<AuthorsCubit, AuthorsState,
                            UserModel?>(
                          selector: (state) =>
                              state.authors[unNewFlashNews.flashNews.pubkey],
                          builder: (context, user) {
                            final author = user ??
                                emptyUserModel.copyWith(
                                  pubKey: unNewFlashNews.flashNews.pubkey,
                                  picturePlaceholder: getRandomPlaceholder(
                                    input: unNewFlashNews.flashNews.pubkey,
                                    isPfp: true,
                                  ),
                                );
                            return Row(
                              children: [
                                ProfilePicture2(
                                  size: 25,
                                  image: author.picture,
                                  placeHolder: author.picturePlaceholder,
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
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'On: ${dateFormat4.format(
                                          unNewFlashNews.flashNews.createdAt,
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
                                  animationBuilder: (context, state, child) {
                                    return child;
                                  },
                                  routeTheme: PullDownMenuRouteTheme(
                                    backgroundColor: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                  ),
                                  itemBuilder: (context) {
                                    final textStyle =
                                        Theme.of(context).textTheme.labelMedium;

                                    return [
                                      if (userStatus == UserStatus.UsingPrivKey)
                                        PullDownMenuItem(
                                          title: 'Bookmark',
                                          onTap: () {
                                            showModalBottomSheet(
                                              context: context,
                                              elevation: 0,
                                              builder: (_) {
                                                return AddBookmarkView(
                                                  kind: EventKind.TEXT_NOTE,
                                                  identifier: unNewFlashNews
                                                      .flashNews.id,
                                                  eventPubkey: unNewFlashNews
                                                      .flashNews.pubkey,
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
                                          iconWidget: BlocBuilder<ThemeCubit,
                                              ThemeState>(
                                            builder: (context, themeState) {
                                              final isDark = themeState.theme ==
                                                  AppTheme.purpleDark;

                                              return SvgPicture.asset(
                                                isBookmarked
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
                                                  'kind': EventKind.TEXT_NOTE,
                                                  'id': unNewFlashNews
                                                      .flashNews.id,
                                                  'createdAt': unNewFlashNews
                                                      .flashNews.createdAt,
                                                  'textContentType':
                                                      TextContentType
                                                          .uncensoredNote,
                                                  if (unNewFlashNews.isSealed)
                                                    'sealedNote': unNewFlashNews
                                                        .sealedNote,
                                                },
                                                pubkey: unNewFlashNews
                                                    .flashNews.pubkey,
                                                title: unNewFlashNews
                                                    .flashNews.content,
                                                description: '',
                                                kindText: 'Flash news',
                                                icon: FeatureIcons.flashNews,
                                                upvotes: 0,
                                                downvotes: 0,
                                                onShare: () {
                                                  RenderBox? box;
                                                  if (ResponsiveBreakpoints.of(
                                                          context)
                                                      .largerThan(MOBILE)) {
                                                    box = context
                                                            .findRenderObject()
                                                        as RenderBox?;
                                                  }

                                                  shareLink(
                                                    renderBox: box,
                                                    pubkey: unNewFlashNews
                                                        .flashNews.pubkey,
                                                    id: unNewFlashNews
                                                        .flashNews.id,
                                                    kind: EventKind.TEXT_NOTE,
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
                                            backgroundColor: Theme.of(context)
                                                .scaffoldBackgroundColor,
                                          );
                                        },
                                        itemTheme: PullDownMenuItemTheme(
                                          textStyle: textStyle,
                                        ),
                                        iconWidget: SvgPicture.asset(
                                          FeatureIcons.link,
                                          height: 20,
                                          width: 20,
                                          colorFilter: ColorFilter.mode(
                                            Theme.of(context).primaryColorDark,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                    ];
                                  },
                                  buttonBuilder: (context, showMenu) =>
                                      IconButton(
                                    onPressed: showMenu,
                                    padding: EdgeInsets.zero,
                                    style: IconButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                    icon: Icon(
                                      Icons.more_vert_rounded,
                                      color: Theme.of(context).primaryColorDark,
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
                  if (unNewFlashNews.flashNews.tags.isNotEmpty ||
                      unNewFlashNews.flashNews.isImportant) ...[
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    FlashTagsRow(
                      isImportant: unNewFlashNews.flashNews.isImportant,
                      tags: unNewFlashNews.flashNews.tags,
                    ),
                  ],
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  linkifiedText(
                    context: context,
                    text: unNewFlashNews.flashNews.content,
                    onClicked: onClicked,
                    isKeepAlive: true,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 4,
                  ),
                  if (unNewFlashNews.isSealed) ...[
                    UncensoredNoteComponent(
                      userStatus: userStatus,
                      sealDisable: false,
                      note: unNewFlashNews.sealedNote!.uncensoredNote,
                      isSealed: true,
                      isComponent: false,
                      sealedNote: unNewFlashNews.sealedNote,
                      flashNewsPubkey: unNewFlashNews.flashNews.pubkey,
                      onLike: () {},
                      onDislike: () {},
                      onDelete: (ratingNoteId) {},
                      isUncensoredNoteAuthor: userStatus ==
                              UserStatus.UsingPrivKey &&
                          nostrRepository.user.pubKey ==
                              unNewFlashNews.sealedNote!.uncensoredNote.pubKey,
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ] else if (unNewFlashNews.uncensoredNotes.isNotEmpty) ...[
                    ListView.separated(
                      separatorBuilder: (context, index) => const SizedBox(
                        height: kDefaultPadding / 4,
                      ),
                      shrinkWrap: true,
                      primary: false,
                      itemBuilder: (context, index) {
                        final note = unNewFlashNews.uncensoredNotes[index];

                        return UncensoredNoteComponent(
                          userStatus: userStatus,
                          note: note,
                          sealDisable: false,
                          isSealed: false,
                          isComponent: false,
                          sealedNote: unNewFlashNews.sealedNote,
                          flashNewsPubkey: unNewFlashNews.flashNews.pubkey,
                          onLike: () {
                            showModalBottomSheet(
                              context: context,
                              elevation: 0,
                              builder: (_) {
                                return UnFlashNewsAddRating(
                                  isUpvote: true,
                                  uncensoredNoteId: note.id,
                                  onSuccess: () {
                                    onRefresh.call();
                                    Navigator.pop(context);
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
                          onDislike: () {
                            showModalBottomSheet(
                              context: context,
                              elevation: 0,
                              builder: (_) {
                                return UnFlashNewsAddRating(
                                  isUpvote: false,
                                  uncensoredNoteId: note.id,
                                  onSuccess: () {
                                    onRefresh.call();
                                    Navigator.pop(context);
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
                          onDelete: (ratingNoteId) {
                            showCupertinoDeletionDialogue(
                              context: context,
                              title: 'Undo rating',
                              description:
                                  'You are about to undo your rating, do you wish to proceed?',
                              buttonText: 'undo',
                              onDelete: () {
                                context
                                    .read<UncensoredNotesCubit>()
                                    .deleteRating(
                                      uncensoredNoteId: note.id,
                                      ratingId: ratingNoteId,
                                      onSuccess: () {
                                        onRefresh.call();
                                        Navigator.pop(context);
                                      },
                                    );
                              },
                            );
                          },
                          isUncensoredNoteAuthor:
                              userStatus == UserStatus.UsingPrivKey &&
                                  nostrRepository.user.pubKey == note.pubKey,
                        );
                      },
                      itemCount: unNewFlashNews.uncensoredNotes.length,
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ],

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (unNewFlashNews.flashNews.source.isNotEmpty) ...[
                        CustomIconButton(
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          icon: FeatureIcons.globe,
                          onClicked: () {
                            openWebPage(url: unNewFlashNews.flashNews.source);
                          },
                          size: 22,
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 2,
                        ),
                      ],
                      Expanded(
                        child: RoundedTextButtonWithArrow(
                          text: 'See all uncensored notes',
                          buttonColor: kBlue,
                          textColor: kWhite,
                          onClicked: onClicked,
                        ),
                      ),
                    ],
                  ),
                  // const SizedBox(
                  //   height: kDefaultPadding / 2,
                  // ),
                  // SealedUncensoredNoteContainer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
