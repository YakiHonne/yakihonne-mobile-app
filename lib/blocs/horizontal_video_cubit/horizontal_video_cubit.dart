import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'horizontal_video_state.dart';

class HorizontalVideoCubit extends Cubit<HorizontalVideoState> {
  HorizontalVideoCubit({required VideoModel video})
      : super(
          HorizontalVideoState(
            author: emptyUserModel.copyWith(
              pubKey: video.pubkey,
              picturePlaceholder:
                  getRandomPlaceholder(input: video.pubkey, isPfp: true),
            ),
            mutes: nostrRepository.mutes.toList(),
            currentUserPubkey: nostrRepository.user.pubKey,
            canBeZapped: false,
            userStatus: getUserStatus(),
            isSameArticleAuthor: video.pubkey == nostrRepository.user.pubKey,
            votes: {},
            comments: [],
            zaps: {},
            reports: {},
            isFollowingAuthor: false,
            isBookmarked: getBookmarkIds(nostrRepository.bookmarksLists)
                .contains(video.identifier),
            isLoading: true,
            video: video,
            viewsCount: [],
          ),
        ) {
    userSubscription = nostrRepository.userModelStream.listen((user) {
      if (user == null || !user.isUsingPrivKey) {
        if (!isClosed)
          emit(
            state.copyWith(
              isSameArticleAuthor: false,
            ),
          );
      } else {
        if (!isClosed)
          emit(
            state.copyWith(
              isSameArticleAuthor:
                  user.isUsingPrivKey && video.pubkey == user.pubKey,
            ),
          );
      }
    });

    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        final isBookmarked = getBookmarkIds(nostrRepository.bookmarksLists)
            .contains(video.identifier);

        if (!isClosed)
          emit(
            state.copyWith(
              isBookmarked: isBookmarked,
            ),
          );
      },
    );

    followingsSubscription = nostrRepository.followingsStream.listen(
      (followings) {
        if (!isClosed)
          emit(
            state.copyWith(
              isFollowingAuthor: followings.contains(video.pubkey),
            ),
          );
      },
    );

    mutesSubscription = nostrRepository.mutesStream.listen(
      (mutes) {
        if (!isClosed)
          emit(
            state.copyWith(
              mutes: mutes.toList(),
            ),
          );
      },
    );
  }

  late StreamSubscription followingsSubscription;
  late StreamSubscription bookmarksSubscription;
  late StreamSubscription mutesSubscription;
  late StreamSubscription userSubscription;

  void initView() {
    setAuthor();
    getStats();
    setVideoView();
  }

  void setAuthor() {
    bool isFollowing = false;
    final authors = authorsCubit.getAuthorsByPubkeys([state.video.pubkey]);

    if (authors.isNotEmpty) {
      final author = authors[state.video.pubkey]!;

      if (state.userStatus == UserStatus.UsingPrivKey &&
          state.video.pubkey != state.currentUserPubkey) {
        for (final profile in nostrRepository.user.followings) {
          if (profile.key == author.pubKey) {
            isFollowing = true;
            break;
          }
        }
      }

      if (!isClosed)
        emit(
          state.copyWith(
            author: author,
            isFollowingAuthor: isFollowing,
            canBeZapped: author.lud16.isNotEmpty &&
                nostrRepository.usm != null &&
                nostrRepository.usm!.isUsingPrivKey &&
                state.video.pubkey != nostrRepository.usm!.pubKey,
          ),
        );

      return;
    }

    NostrFunctionsRepository.getUserMetaData(
      pubkey: state.video.pubkey,
    ).listen(
      (author) {
        if (state.userStatus == UserStatus.UsingPrivKey &&
            state.video.pubkey != state.currentUserPubkey) {
          for (final profile in nostrRepository.user.followings) {
            if (profile.key == author.pubKey) {
              isFollowing = true;
              break;
            }
          }
        }

        emit(
          state.copyWith(
            author: author,
            isFollowingAuthor: isFollowing,
            canBeZapped: author.lud16.isNotEmpty &&
                nostrRepository.usm != null &&
                nostrRepository.usm!.isUsingPrivKey &&
                state.video.pubkey != nostrRepository.usm!.pubKey,
          ),
        );
      },
    );
  }

  void setVideoView() async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!isClosed) if (getUserStatus() == UserStatus.UsingPrivKey) {
      final ec = EventCoordinates(
        state.video.kind,
        state.video.pubkey,
        state.video.identifier,
        null,
      );

      final event = await Event.genEvent(
        kind: EventKind.VIDEO_VIEW,
        tags: [
          ['a', ec.toString()],
          ['d', ec.toString()],
        ],
        content: '',
        pubkey: nostrRepository.usm!.pubKey,
        privkey: nostrRepository.usm!.privKey,
      );

      if (event == null) {
        return;
      }

      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: true,
      );

      if (isSuccessful &&
          !state.viewsCount.contains(nostrRepository.usm!.pubKey)) {
        final views = List<String>.from(state.viewsCount)
          ..add(nostrRepository.usm!.pubKey);

        emit(
          state.copyWith(
            viewsCount: views,
          ),
        );
      }
    }
  }

  void getStats() {
    NostrFunctionsRepository.getStats(
      identifier: state.video.identifier,
      eventKind: state.video.kind,
      eventPubkey: state.video.pubkey,
      isEtag: false,
      getViews: true,
    ).listen(
      (data) {
        if (data is Map<String, Map<String, VoteModel>>) {
          final votes = Map<String, VoteModel>.from(state.votes)
            ..addAll(
              data[state.video.identifier] ?? {},
            );

          emit(
            state.copyWith(
              votes: votes,
            ),
          );
        } else if (data is Map<String, Comment>) {
          emit(
            state.copyWith(
              comments: data.values.toList(),
            ),
          );
        } else if (data is Map<String, double>) {
          emit(
            state.copyWith(
              zaps: data,
            ),
          );
        } else if (data is Set<String>) {
          emit(
            state.copyWith(
              reports: data,
            ),
          );
        } else if (data is List<String>) {
          emit(
            state.copyWith(
              viewsCount: data,
            ),
          );
        }
      },
      onDone: () {
        getAuthors();
      },
    );
  }

  void getAuthors() {
    Set<String> authors = {};

    state.comments.forEach((comment) {
      authors.add(comment.pubKey);
    });

    state.votes.values.forEach((voteModel) {
      authors.add(voteModel.pubkey);
    });

    authorsCubit.getAuthors(authors.toList());
  }

  void setFollowingState() async {
    final _cancel = BotToast.showLoading();

    await NostrFunctionsRepository.setFollowingEvent(
      isFollowingAuthor: state.isFollowingAuthor,
      targetPubkey: state.video.pubkey,
    );

    _cancel.call();
  }

  void report({
    required String reason,
    required String comment,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    final isSuccessful = await NostrFunctionsRepository.report(
      comment: comment,
      reason: reason,
      isEtag: false,
      kind: state.video.kind,
      eventPubkey: state.video.pubkey,
      identifier: state.video.identifier,
    );

    if (isSuccessful) {
      emit(
        state.copyWith(
          reports: Set.from(state.reports)..add(nostrRepository.usm!.pubKey),
        ),
      );
      BotToastUtils.showSuccess('You report has been submitted');
      onSuccess.call();
    } else {
      BotToastUtils.showError('Error occured while submit a report');
    }

    _cancel.call();
  }

  void addComment({
    required String content,
    required String replyCommentId,
    required List<String> mentions,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    final comment = await NostrFunctionsRepository.addComment(
      eventId: state.video.videoId,
      eventPubkey: state.video.pubkey,
      eventKind: state.video.kind,
      selectedEventKind: state.video.kind,
      identifier: state.video.identifier,
      isEtag: false,
      content: content,
      replyCommentId: replyCommentId,
      mentions: mentions,
    );

    if (comment != null) {
      onSuccess.call();
      emit(
        state.copyWith(
          comments: List.from(state.comments)..add(comment),
        ),
      );
    } else {
      BotToastUtils.showError('Error occured while posting a comment');
    }

    _cancel.call();
  }

  void deleteComment({
    required String commentId,
  }) async {
    final _cancel = BotToast.showLoading();

    final isSuccessful = await NostrFunctionsRepository.deleteEvent(
      eventId: commentId,
    );

    if (isSuccessful) {
      emit(
        state.copyWith(
          comments: List.from(state.comments)
            ..removeWhere((element) => element.id == commentId),
        ),
      );
    } else {
      BotToastUtils.showError('Error occured while deleting a comment');
    }

    _cancel.call();
  }

  void setVote({
    required bool upvote,
    required String eventId,
    required String eventPubkey,
  }) async {
    final _cancel = BotToast.showLoading();

    final currentVoteModel = state.votes[state.currentUserPubkey];

    if (currentVoteModel == null || upvote != currentVoteModel.vote) {
      final addingEventId = await NostrFunctionsRepository.addVote(
        eventId: eventId,
        upvote: upvote,
        identifier: state.video.identifier,
        kind: state.video.kind,
        eventPubkey: eventPubkey,
        isEtag: false,
      );

      if (addingEventId != null) {
        if (currentVoteModel != null) {
          await NostrFunctionsRepository.deleteEvent(
            eventId: currentVoteModel.eventId,
          );
        }

        Map<String, VoteModel> newMap = Map.from(state.votes);

        newMap[state.currentUserPubkey] = VoteModel(
          eventId: addingEventId,
          pubkey: state.currentUserPubkey,
          vote: upvote,
        );

        emit(
          state.copyWith(votes: newMap),
        );
      } else {
        BotToastUtils.showError('Vote could not be submitted');
      }
    } else {
      final isSuccessful = await NostrFunctionsRepository.deleteEvent(
        eventId: currentVoteModel.eventId,
      );

      if (isSuccessful) {
        Map<String, VoteModel> newMap = Map.from(state.votes);

        newMap.remove(currentVoteModel.pubkey);

        emit(
          state.copyWith(
            votes: newMap,
          ),
        );
      } else {
        BotToastUtils.showError('Vote could not be submitted');
      }
    }

    _cancel.call();
  }

  void shareLink(RenderBox? renderBox) {
    Share.share(
      externalShearableLink(
        kind: state.video.kind,
        pubkey: state.video.pubkey,
        id: state.video.identifier,
      ),
      subject: 'Check out www.yakihonne.com for more videos.',
      sharePositionOrigin: renderBox != null
          ? renderBox.localToGlobal(Offset.zero) & renderBox.size
          : null,
    );
  }

  @override
  Future<void> close() {
    followingsSubscription.cancel();
    bookmarksSubscription.cancel();
    mutesSubscription.cancel();
    userSubscription.cancel();
    return super.close();
  }
}
