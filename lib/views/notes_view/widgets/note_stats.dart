import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yakihonne/blocs/notes_events_cubit/notes_events_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/notes_view/notes_view.dart';
import 'package:yakihonne/views/widgets/comment_box_view.dart';
import 'package:yakihonne/views/widgets/note_stats.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/widgets/share_view.dart';
import 'package:yakihonne/views/widgets/zappers_view.dart';
import 'package:yakihonne/views/zap_view/set_zaps_view.dart';

class NoteStats extends HookWidget {
  const NoteStats({
    Key? key,
    required this.note,
    required this.selfStats,
    required this.onComment,
    required this.onUpvote,
    required this.onRepost,
  }) : super(key: key);

  final DetailedNoteModel note;
  final bool selfStats;
  final Function() onComment;
  final Function() onUpvote;
  final Function() onRepost;

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      notesEventsCubit.getNoteStats(note.id, selfStats);
    });

    return BlocBuilder<NotesEventsCubit, NotesEventsState>(
      buildWhen: (previous, current) =>
          previous.refresher != current.refresher ||
          previous.mutes != current.mutes,
      builder: (context, state) {
        List<Event> comments = [];
        bool selfComment = false;
        List<Event> quotes = [];
        bool selfQuote = false;
        List<Event> upvotes = [];
        bool selfUpvote = false;
        List<Event> reposts = [];
        bool selfRepost = false;
        List<Map<String, double>> zaps = [];
        bool selfZaps = false;

        final events = state.notesStats[note.id] ?? {};

        for (final event in events.values) {
          if (!nostrRepository.mutes.contains(event.pubkey)) {
            if (event.isQuote()) {
              quotes.add(event);
              if (isUsingPrivatekey() &&
                  event.pubkey == nostrRepository.usm!.pubKey) {
                selfQuote = true;
              }
            } else if ((event.kind == EventKind.TEXT_NOTE &&
                    event.isSimpleNote()) ||
                event.kind == EventKind.REPOST ||
                event.kind == EventKind.ZAP ||
                event.kind == EventKind.REACTION) {
              for (final tag in event.tags) {
                if (canAddNote(tag, note.id) &&
                    event.kind == EventKind.TEXT_NOTE) {
                  comments.add(event);
                  if (isUsingPrivatekey() &&
                      event.pubkey == nostrRepository.usm!.pubKey) {
                    selfComment = true;
                  }
                } else if (tag.first == 'e' &&
                    tag.length > 1 &&
                    tag[1] == note.id &&
                    (event.kind == EventKind.REACTION ||
                        event.kind == EventKind.REPOST)) {
                  if (event.kind == EventKind.REACTION) {
                    upvotes.add(event);
                  } else if (event.kind == EventKind.REPOST) {
                    reposts.add(event);
                  }

                  if (isUsingPrivatekey() &&
                      event.pubkey == nostrRepository.usm!.pubKey) {
                    if (event.kind == EventKind.REACTION) {
                      selfUpvote = true;
                    } else if (event.kind == EventKind.REPOST) {
                      selfRepost = true;
                    }
                  }
                }
              }
            }
          }
        }

        if (notesEventsCubit.zaps[note.id] != null) {
          notesEventsCubit.zaps[note.id]!.forEach(
            (key, value) {
              if (!nostrRepository.mutes.contains(key)) {
                zaps.add({key: value});

                if (isUsingPrivatekey() && key == nostrRepository.usm!.pubKey) {
                  selfZaps = true;
                }
              }
            },
          );
        }

        return Row(
          children: [
            CustomIconButton(
              backgroundColor: kTransparent,
              icon: FeatureIcons.comments,
              onLongPress: () {},
              onClicked: () {
                if (isUsingPrivatekey())
                  showModalBottomSheet(
                    context: context,
                    elevation: 0,
                    builder: (_) {
                      return CommentBoxView(
                        commentId: '',
                        commentPubkey: note.pubkey,
                        commentContent: note.content,
                        commentDate: note.createdAt,
                        isNote: true,
                        kind: EventKind.TEXT_NOTE,
                        shareableLink: createShareableLink(
                          EventKind.TEXT_NOTE,
                          note.pubkey,
                          note.id,
                        ),
                        onAddComment: (commentContent, mentions, commentId) {
                          notesEventsCubit.addComment(
                            content: commentContent,
                            replyNote: note,
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
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
              },
              iconColor:
                  selfComment ? kOrange : Theme.of(context).primaryColorDark,
              textColor:
                  selfComment ? kOrange : Theme.of(context).primaryColorDark,
              value: comments.length.toString(),
              size: 16,
            ),
            SizedBox(width: kDefaultPadding / 4),
            CustomIconButton(
              backgroundColor: kTransparent,
              icon: selfUpvote ? FeatureIcons.heartFilled : FeatureIcons.heart,
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  elevation: 0,
                  builder: (_) {
                    return NetStatsView(
                      events: upvotes,
                      type: NoteStatType.reaction,
                    );
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              onClicked: () {
                if (isUsingPrivatekey()) notesEventsCubit.onSetVote(note);
              },
              value: upvotes.length.toString(),
              iconColor:
                  selfUpvote ? kOrange : Theme.of(context).primaryColorDark,
              textColor:
                  selfUpvote ? kOrange : Theme.of(context).primaryColorDark,
              size: 16,
            ),
            SizedBox(width: kDefaultPadding / 4),
            CustomIconButton(
              backgroundColor: kTransparent,
              icon: FeatureIcons.refresh,
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  elevation: 0,
                  builder: (_) {
                    return NetStatsView(
                      events: reposts,
                      type: NoteStatType.repost,
                    );
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              onClicked: () {
                if (isUsingPrivatekey())
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) {
                      return NoteOptions(
                        note: note,
                        onSuccess: () {
                          Navigator.pop(context);
                        },
                      );
                    },
                    backgroundColor: kTransparent,
                    useRootNavigator: true,
                    elevation: 0,
                    useSafeArea: true,
                  );
              },
              value: reposts.length.toString(),
              iconColor:
                  selfRepost ? kOrange : Theme.of(context).primaryColorDark,
              textColor:
                  selfRepost ? kOrange : Theme.of(context).primaryColorDark,
              size: 16,
            ),
            SizedBox(width: kDefaultPadding / 4),
            CustomIconButton(
              backgroundColor: kTransparent,
              icon: FeatureIcons.quote,
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  elevation: 0,
                  builder: (_) {
                    return NetStatsView(
                      events: quotes,
                      type: NoteStatType.quote,
                    );
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              onClicked: () {
                if (isUsingPrivatekey())
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) {
                      return NoteOptions(
                        note: note,
                        onSuccess: () {
                          Navigator.pop(context);
                        },
                      );
                    },
                    backgroundColor: kTransparent,
                    useRootNavigator: true,
                    elevation: 0,
                    useSafeArea: true,
                  );
              },
              value: quotes.length.toString(),
              iconColor:
                  selfQuote ? kOrange : Theme.of(context).primaryColorDark,
              textColor:
                  selfQuote ? kOrange : Theme.of(context).primaryColorDark,
              size: 16,
            ),
            SizedBox(width: kDefaultPadding / 4),
            CustomIconButton(
              backgroundColor: kTransparent,
              icon: selfZaps ? FeatureIcons.zapFilled : FeatureIcons.zap,
              onLongPress: () {
                final noteZaps = notesEventsCubit.zaps[note.id];

                if (noteZaps != null && noteZaps.isNotEmpty) {
                  showModalBottomSheet(
                    context: context,
                    elevation: 0,
                    builder: (_) {
                      return ZappersView(
                        zappers: noteZaps,
                      );
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                }
              },
              onClicked: () {
                if (isUsingPrivatekey())
                  showModalBottomSheet(
                    elevation: 0,
                    context: context,
                    builder: (_) {
                      return SetZapsView(
                        author: authorsCubit.state.authors[note.pubkey] ??
                            emptyUserModel.copyWith(
                              pubKey: note.pubkey,
                              picturePlaceholder: getRandomPlaceholder(
                                  input: note.pubkey, isPfp: true),
                            ),
                        eventId: note.id,
                        isZapSplit: false,
                        zapSplits: [],
                      );
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
              },
              value: zaps.length.toString(),
              iconColor:
                  selfZaps ? kOrange : Theme.of(context).primaryColorDark,
              textColor:
                  selfZaps ? kOrange : Theme.of(context).primaryColorDark,
              size: 16,
            ),
            Expanded(child: SizedBox()),
            PullDownButton(
              animationBuilder: (context, state, child) {
                return child;
              },
              routeTheme: PullDownMenuRouteTheme(
                backgroundColor: Theme.of(context).primaryColorLight,
              ),
              itemBuilder: (context) {
                final textStyle = Theme.of(context).textTheme.labelMedium;

                return [
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
                              'id': note.id,
                              'createdAt': note.createdAt,
                              'textContentType': TextContentType.note,
                            },
                            pubkey: note.pubkey,
                            title: note.content,
                            description: '',
                            kindText: 'Note',
                            icon: FeatureIcons.note,
                            upvotes: 0,
                            downvotes: 0,
                            onShare: () {
                              RenderBox? box;

                              if (ResponsiveBreakpoints.of(context)
                                  .largerThan(MOBILE)) {
                                box = context.findRenderObject() as RenderBox?;
                              }

                              Share.share(
                                externalShearableLink(
                                  kind: EventKind.TEXT_NOTE,
                                  pubkey: note.pubkey,
                                  id: note.id,
                                  textContentType: TextContentType.note,
                                ),
                                subject:
                                    'Check out www.yakihonne.com for more notes.',
                                sharePositionOrigin: box != null
                                    ? box.localToGlobal(Offset.zero) & box.size
                                    : null,
                              );
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
                  if (isUsingPrivatekey())
                    PullDownMenuItem(
                      title: 'Bookmark note',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          elevation: 0,
                          builder: (_) {
                            return AddBookmarkView(
                              kind: EventKind.TEXT_NOTE,
                              identifier: note.id,
                              eventPubkey: note.pubkey,
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
                      itemTheme: PullDownMenuItemTheme(
                        textStyle: textStyle,
                      ),
                      iconWidget: BlocBuilder<ThemeCubit, ThemeState>(
                        builder: (context, themeState) {
                          final isDark =
                              themeState.theme == AppTheme.purpleDark;

                          return SvgPicture.asset(
                            notesEventsCubit.state.bookmarks.contains(note.id)
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
                  PullDownMenuItem(
                    title: 'Copy note id',
                    onTap: () {
                      Clipboard.setData(
                        new ClipboardData(
                          text: Nip19.encodeNote(
                            note.id,
                          ),
                        ),
                      );
                      BotToastUtils.showSuccess('Note id was copied! 👏');
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
                    title:
                        state.mutes.contains(note.pubkey) ? 'Unmute' : 'Mute',
                    onTap: () {
                      final isMuted = state.mutes.contains(note.pubkey);
                      String description = '';
                      final user = authorsCubit.getAuthor(note.pubkey) ??
                          emptyUserModel.copyWith(
                            pubKey: note.pubkey,
                            name: note.pubkey.nineCharacters(),
                          );

                      if (isUsingPrivatekey()) {
                        description =
                            'You are about to ${isMuted ? 'unmute' : 'mute'} "${user.name}", do you wish to proceed?';
                      } else {
                        description =
                            'You are about to ${isMuted ? 'unmute' : 'mute'} "${user.name}". ${!isMuted ? "This will be stored locally while you are not connected or using a public key," : ""} do you wish to proceed?';
                      }

                      showCupertinoCustomDialogue(
                        context: context,
                        title: isMuted ? 'Unmute user' : 'Mute user',
                        description: description,
                        buttonText: isMuted ? 'Unmute' : 'Mute',
                        buttonTextColor: isMuted ? kGreen : kRed,
                        onClicked: () {
                          context.read<NotesEventsCubit>().setMuteStatus(
                                pubkey: user.pubKey,
                                onSuccess: () => Navigator.pop(context),
                              );
                        },
                      );
                    },
                    itemTheme: PullDownMenuItemTheme(
                      textStyle: textStyle,
                    ),
                    iconWidget: SvgPicture.asset(
                      !state.mutes.contains(note.pubkey)
                          ? FeatureIcons.mute
                          : FeatureIcons.unmute,
                      height: 20,
                      width: 20,
                      colorFilter: ColorFilter.mode(
                        !state.mutes.contains(note.pubkey)
                            ? kRed
                            : Theme.of(context).primaryColorDark,
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
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  visualDensity: VisualDensity(
                    horizontal: -4,
                    vertical: -1,
                  ),
                ),
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: Theme.of(context).primaryColorDark,
                  size: 20,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
