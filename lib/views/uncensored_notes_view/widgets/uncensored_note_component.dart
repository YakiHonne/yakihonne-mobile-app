// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/home_view/home_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';

class UncensoredNoteComponent extends HookWidget {
  const UncensoredNoteComponent({
    Key? key,
    required this.note,
    required this.flashNewsPubkey,
    required this.userStatus,
    required this.isUncensoredNoteAuthor,
    required this.isComponent,
    required this.isSealed,
    required this.sealDisable,
    required this.onDelete,
    required this.onLike,
    required this.onDislike,
    this.sealedNote,
  }) : super(key: key);

  final UncensoredNote note;
  final String flashNewsPubkey;
  final SealedNote? sealedNote;
  final UserStatus userStatus;
  final bool isUncensoredNoteAuthor;
  final bool isComponent;
  final bool isSealed;
  final bool sealDisable;
  final Function(String) onDelete;
  final Function() onLike;
  final Function() onDislike;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        border: Border.all(
          color: isUncensoredNoteAuthor
              ? Theme.of(context).primaryColorDark
              : kTransparent,
          width: 1,
        ),
        color: isComponent
            ? Theme.of(context).primaryColorLight
            : Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            child: isSealed
                ? Builder(builder: (context) {
                    final color = sealedNote!.isHelpful ? kGreen : kRed;

                    return Row(
                      children: [
                        Icon(
                          sealedNote!.isHelpful
                              ? CupertinoIcons.check_mark_circled
                              : CupertinoIcons.clear_circled,
                          color: color,
                          size: 18,
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        Expanded(
                          child: Text(
                            sealedNote!.isHelpful
                                ? 'Rated helpful'
                                : 'Rated not helpful',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                          ),
                        ),
                        InfoRoundedContainer(
                          tag: 'Sealed',
                          color: color,
                          textColor: kWhite,
                          onClicked: () {},
                        ),
                      ],
                    );
                  })
                : Row(
                    children: [
                      DotContainer(
                        color: kDimGrey,
                        isNotMarging: true,
                        size: 5,
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                      Expanded(
                        child: Text(
                          'Needs more rating',
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      if (isUncensoredNoteAuthor) ...[
                        SvgPicture.asset(
                          FeatureIcons.user,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColorDark,
                            BlendMode.srcIn,
                          ),
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                      ],
                      InfoRoundedContainer(
                        tag: 'Not sealed ${sealDisable ? '' : 'yet'}',
                        color: kDimGrey,
                        textColor: kBlack,
                        onClicked: () {},
                      ),
                    ],
                  ),
          ),
          Divider(
            height: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Posted on ${dateFormat4.format(note.createdAt)}',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: kDimGrey,
                            ),
                      ),
                    ),
                    if (note.source.isNotEmpty)
                      TransparentTextButtonWithIcon(
                        onClicked: () {
                          openWebPage(url: note.source);
                        },
                        text: 'source',
                        iconWidget: SvgPicture.asset(
                          FeatureIcons.globe,
                          width: 15,
                          height: 15,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColorDark,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(
                  height: kDefaultPadding / 2,
                ),
                linkifiedText(
                  context: context,
                  text: note.content,
                ),
              ],
            ),
          ),
          if (getUserStatus() == UserStatus.UsingPrivKey) ...[
            if (!isSealed && !sealDisable) ...[
              Divider(
                height: 0,
              ),
              Builder(
                builder: (context) {
                  final ratingNote =
                      getRating(userStatus: userStatus, note: note);

                  final isFlashNewsAuthor =
                      userStatus == UserStatus.UsingPrivKey &&
                          nostrRepository.user.pubKey == flashNewsPubkey;

                  return Padding(
                    padding: const EdgeInsets.all(kDefaultPadding / 2),
                    child: isFlashNewsAuthor
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: kDefaultPadding / 6,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.timer,
                                    color: kOrange,
                                    size: 18,
                                  ),
                                  const SizedBox(
                                    width: kDefaultPadding / 4,
                                  ),
                                  Text(
                                    'this note is awaiting community rating.',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : isUncensoredNoteAuthor
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: kDefaultPadding / 6,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.timer,
                                        color: kOrange,
                                        size: 18,
                                      ),
                                      const SizedBox(
                                        width: kDefaultPadding / 4,
                                      ),
                                      Text(
                                        'Your note is awaiting community rating.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ratingNote != null
                                ? rating_timer_widget(
                                    ratingNote: ratingNote,
                                    onDelete: onDelete,
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Do you find this helpful?',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium!
                                              .copyWith(
                                                color: kDimGrey,
                                              ),
                                        ),
                                      ),
                                      CustomIconButton(
                                        backgroundColor: isComponent
                                            ? Theme.of(context)
                                                .scaffoldBackgroundColor
                                            : Theme.of(context)
                                                .primaryColorLight,
                                        icon: FeatureIcons.like,
                                        onClicked: onLike,
                                        size: 22,
                                      ),
                                      const SizedBox(
                                        width: kDefaultPadding / 4,
                                      ),
                                      CustomIconButton(
                                        backgroundColor: isComponent
                                            ? Theme.of(context)
                                                .scaffoldBackgroundColor
                                            : Theme.of(context)
                                                .primaryColorLight,
                                        icon: FeatureIcons.dislike,
                                        onClicked: onDislike,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                  );
                },
              )
            ] else if (isSealed) ...[
              Divider(
                height: 0,
              ),
              Padding(
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      FeatureIcons.tag,
                      width: 20,
                      height: 20,
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
                          Text(
                            'Top reasons selected by raters:',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(
                            height: kDefaultPadding / 6,
                          ),
                          ScrollShadow(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: SizedBox(
                              height: 17,
                              child: sealedNote!.reasons.isEmpty
                                  ? Text(
                                      'No reasons are specified!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    )
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      separatorBuilder: (context, index) =>
                                          DotContainer(
                                        color: kOrange,
                                        size: 4,
                                      ),
                                      itemBuilder: (context, index) {
                                        final reason =
                                            sealedNote!.reasons[index];

                                        return Text(
                                          reason,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        );
                                      },
                                      itemCount: sealedNote!.reasons.length,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ]
        ],
      ),
    );
  }

  NotesRating? getRating({
    required UserStatus userStatus,
    required UncensoredNote note,
  }) {
    if (userStatus != UserStatus.UsingPrivKey) {
      return null;
    } else {
      final rating = note.ratings.where((element) {
        return element.pubKey == nostrRepository.user.pubKey;
      }).toList();

      if (rating.isEmpty) {
        return null;
      }

      return rating.first;
    }
  }
}

class rating_timer_widget extends HookWidget {
  const rating_timer_widget({
    super.key,
    required this.ratingNote,
    required this.onDelete,
  });

  final NotesRating ratingNote;
  final Function(String ratingNoteId) onDelete;

  @override
  Widget build(BuildContext context) {
    final timerShown = useState(
      DateTime.now().difference(ratingNote.createdAt).inSeconds < 350,
    );

    final timerText = useState('');
    final IsMounted = useIsMounted();

    useMemoized(() {
      if (timerShown.value) {
        final topDate = ratingNote.createdAt
            .add(Duration(minutes: 5))
            .toSecondsSinceEpoch();

        return Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            if (!IsMounted()) {
              timer.cancel();
              return;
            }

            if (timerShown.value) {
              final currentTime =
                  topDate - DateTime.now().toSecondsSinceEpoch();
              timerText.value = currentTime.formattedSeconds();
              if (currentTime <= 0) {
                timerShown.value = false;
                timer.cancel();
              }
            }
          },
        );
      }
    });

    return Builder(
      builder: (context) {
        return Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.check_mark_circled,
                    color: kOrange,
                    size: 18,
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 4,
                  ),
                  Text(
                    'You rated this as ',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    '${ratingNote.ratingValue ? 'helpful' : 'not helpful'}',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            if (timerShown.value) ...[
              Column(
                children: [
                  TransparentTextButton(
                    onClicked: () {
                      onDelete.call(ratingNote.id);
                    },
                    text: 'Undo',
                    underlined: true,
                  ),
                  Text(
                    '${timerText.value}',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ]
          ],
        );
      },
    );
  }
}
