// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/flash_news_cubit/flash_news_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/nostr/nips/nip_019.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_tags_row.dart';
import 'package:yakihonne/views/home_view/home_view.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/un_flashnews_add_note.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/un_flashnews_details.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/uncensored_note_component.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class FlashNewsTimelineContainer extends StatelessWidget {
  const FlashNewsTimelineContainer({
    Key? key,
    required this.mainFlashNews,
    required this.date,
    required this.onClicked,
    required this.isFirst,
    required this.isLast,
  }) : super(key: key);

  final MainFlashNews mainFlashNews;
  final String date;
  final Function() onClicked;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                SizedBox(
                  height: kDefaultPadding / 2.5,
                  width: 16,
                  child: !isFirst
                      ? VerticalDivider(
                          color: kTransparent,
                        )
                      : null,
                ),
                DotContainer(
                  color: kDimGrey,
                  isNotMarging: false,
                  size: 8,
                ),
                if (!isLast) VerticalDivider(),
              ],
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dateFormat7.format(mainFlashNews.flashNews.createdAt),
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: kDimGrey,
                                  ),
                        ),
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      TransparentTextButtonWithIcon(
                        onClicked: onClicked,
                        text: 'details',
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 4,
                  ),
                  BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
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
                            size: 25,
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
                          Text(
                            'By: ',
                            style: Theme.of(context).textTheme.labelMedium!,
                          ),
                          Expanded(
                            child: Text(
                              author.name.isEmpty
                                  ? Nip19.encodePubkey(
                                      mainFlashNews.flashNews.pubkey,
                                    ).substring(0, 10)
                                  : author.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (mainFlashNews.flashNews.tags.isNotEmpty ||
                      mainFlashNews.flashNews.isImportant) ...[
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    FlashTagsRow(
                      isImportant: mainFlashNews.flashNews.isImportant,
                      tags: mainFlashNews.flashNews.tags,
                    ),
                  ],
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  linkifiedText(
                    context: context,
                    text: mainFlashNews.flashNews.content,
                    onClicked: onClicked,
                    isKeepAlive: true,
                  ),
                  if (mainFlashNews.sealedNote != null) ...[
                    if (mainFlashNews.sealedNote != null &&
                        !mainFlashNews.sealedNote!.uncensoredNote.leading) ...[
                      const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                      UncensoredNoteComponent(
                        note: mainFlashNews.sealedNote!.uncensoredNote,
                        flashNewsPubkey: mainFlashNews.flashNews.pubkey,
                        userStatus: getUserStatus(),
                        isUncensoredNoteAuthor: false,
                        sealedNote: mainFlashNews.sealedNote,
                        isComponent: true,
                        isSealed: true,
                        sealDisable: false,
                        onDelete: (id) {},
                        onLike: () {},
                        onDislike: () {},
                      ),
                    ],
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
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
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                  ],
                  BlocBuilder<FlashNewsCubit, FlashNewsState>(
                    builder: (context, state) {
                      final calculatedVotes = getVotes(
                        votes: state.votes[mainFlashNews.flashNews.id],
                        pubkey: state.userStatus == UserStatus.UsingPrivKey
                            ? state.currentUserPubkey
                            : null,
                      );

                      return Row(
                        children: [
                          CustomIconButton(
                            backgroundColor: kTransparent,
                            icon: calculatedVotes[1]
                                ? FeatureIcons.upvoteFilled
                                : FeatureIcons.upvote,
                            onClicked: () {
                              if (state.userStatus == UserStatus.UsingPrivKey)
                                context.read<FlashNewsCubit>().setVote(
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
                            icon: calculatedVotes[3]
                                ? FeatureIcons.downvoteFilled
                                : FeatureIcons.downvote,
                            onClicked: () {
                              if (state.userStatus == UserStatus.UsingPrivKey)
                                context.read<FlashNewsCubit>().setVote(
                                      upvote: false,
                                      eventId: mainFlashNews.flashNews.id,
                                      eventPubkey:
                                          mainFlashNews.flashNews.pubkey,
                                    );
                            },
                            value: calculatedVotes[2].toString(),
                            size: 22,
                          ),
                          Spacer(),
                          if (state.userStatus == UserStatus.UsingPrivKey)
                            IconButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  elevation: 0,
                                  builder: (_) {
                                    return AddBookmarkView(
                                      kind: EventKind.TEXT_NOTE,
                                      identifier: mainFlashNews.flashNews.id,
                                      eventPubkey:
                                          mainFlashNews.flashNews.pubkey,
                                      image: '',
                                    );
                                  },
                                  isScrollControlled: true,
                                  useRootNavigator: true,
                                  useSafeArea: true,
                                  backgroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                );
                              },
                              icon: BlocBuilder<ThemeCubit, ThemeState>(
                                builder: (context, themeState) {
                                  final isDark =
                                      themeState.theme == AppTheme.purpleDark;

                                  return SvgPicture.asset(
                                    state.bookmarks.contains(
                                            mainFlashNews.flashNews.id)
                                        ? isDark
                                            ? FeatureIcons.bookmarkFilledWhite
                                            : FeatureIcons.bookmarkFilledBlack
                                        : isDark
                                            ? FeatureIcons.bookmarkEmptyWhite
                                            : FeatureIcons.bookmarkEmptyBlack,
                                  );
                                },
                              ),
                            ),
                          if (mainFlashNews.flashNews.source.isNotEmpty) ...[
                            CustomIconButtonWithTooltip(
                              message:
                                  'This is the source provided to back up this flash news.',
                              backgroundColor:
                                  Theme.of(context).primaryColorLight,
                              icon: FeatureIcons.globe,
                              onClicked: () {
                                openWebPage(
                                    url: mainFlashNews.flashNews.source);
                              },
                              size: 22,
                            ),
                            const SizedBox(
                              width: kDefaultPadding / 4,
                            ),
                          ],
                          Builder(builder: (context) {
                            final addUnStatus =
                                mainFlashNews.canAddUncensoredNote();
                            if (addUnStatus == AddUncensoredNote.disabled) {
                              return SizedBox.shrink();
                            }

                            return CustomIconButtonWithTooltip(
                              message:
                                  'You can write uncensored notes for this flash news.',
                              backgroundColor:
                                  addUnStatus == AddUncensoredNote.enabled
                                      ? Theme.of(context).primaryColorLight
                                      : kGreen,
                              icon: addUnStatus == AddUncensoredNote.enabled
                                  ? FeatureIcons.addUncensoredNote
                                  : ToastsIcons.check,
                              iconColor:
                                  addUnStatus == AddUncensoredNote.enabled
                                      ? Theme.of(context).primaryColorDark
                                      : kWhite,
                              onClicked: () {
                                if (addUnStatus == AddUncensoredNote.enabled) {
                                  showModalBottomSheet(
                                    context: context,
                                    elevation: 0,
                                    builder: (_) {
                                      return BlocProvider.value(
                                        value: context.read<FlashNewsCubit>(),
                                        child: UnFlashNewsAddNote(
                                          onAdd: (content, source, isCorrect) {
                                            context
                                                .read<FlashNewsCubit>()
                                                .addUncensoredNote(
                                                  flashNews:
                                                      mainFlashNews.flashNews,
                                                  content: content,
                                                  source: source,
                                                  isCorrect: isCorrect,
                                                  onSuccess: () {
                                                    Navigator.pop(context);

                                                    context
                                                        .read<FlashNewsCubit>()
                                                        .updateFlashNews(
                                                          mainFlashNews:
                                                              mainFlashNews,
                                                          date: date,
                                                        );

                                                    Navigator.pushNamed(
                                                      context,
                                                      UnFlashNewsDetails
                                                          .routeName,
                                                      arguments: UnFlashNews(
                                                        flashNews: mainFlashNews
                                                            .flashNews,
                                                        uncensoredNotes: [],
                                                        isSealed: false,
                                                      ),
                                                    );
                                                  },
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
                                } else {
                                  BotToastUtils.showSuccess(
                                    'You have already submitted an uncensored note to this flash news!',
                                  );
                                }
                              },
                              size: 22,
                            );
                          }),
                        ],
                      );
                    },
                  ),
                  if (!isLast)
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool canAddUncensoredNote() {
    return mainFlashNews.sealedNote == null &&
        isUsingPrivatekey() &&
        nostrRepository.usm!.pubKey != mainFlashNews.flashNews.pubkey;
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

class RoundedTextButtonWithArrow extends StatelessWidget {
  const RoundedTextButtonWithArrow({
    Key? key,
    required this.text,
    required this.onClicked,
    this.buttonColor,
    this.textColor,
  }) : super(key: key);

  final String text;
  final Color? buttonColor;
  final Color? textColor;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onClicked,
      icon: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: textColor ?? Theme.of(context).primaryColorDark,
            ),
      ),
      label: Icon(
        Icons.keyboard_arrow_right_rounded,
      ),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity(
          vertical: -2,
        ),
        backgroundColor: buttonColor ?? Theme.of(context).primaryColorLight,
      ),
    );
  }
}

class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    Key? key,
    required this.onClicked,
    required this.icon,
    required this.size,
    required this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.value,
    this.onLongPress,
    this.vd,
  }) : super(key: key);

  final Function() onClicked;
  final Function()? onLongPress;
  final String icon;
  final double size;
  final Color backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final String? value;
  final double? vd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: IconButton(
        onPressed: onClicked,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: vd != null
              ? VisualDensity(
                  vertical: vd!,
                  horizontal: vd!,
                )
              : null,
        ),
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon,
              width: size,
              height: size,
              colorFilter: ColorFilter.mode(
                iconColor ?? Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
            if (value != null) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 4),
                child: Text(
                  value!,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CustomIconButtonWithTooltip extends StatelessWidget {
  const CustomIconButtonWithTooltip({
    Key? key,
    required this.onClicked,
    required this.message,
    required this.icon,
    required this.size,
    required this.backgroundColor,
    this.iconColor,
    this.value,
  }) : super(key: key);

  final Function() onClicked;
  final String message;
  final String icon;
  final double size;
  final Color backgroundColor;
  final Color? iconColor;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      textStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
      child: IconButton(
        onPressed: onClicked,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon,
              width: size,
              height: size,
              colorFilter: ColorFilter.mode(
                iconColor ?? Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
            if (value != null) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 4),
                child: Text(
                  value!,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
