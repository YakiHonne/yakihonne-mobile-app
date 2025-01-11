import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/enums.dart';
import 'package:yakihonne/utils/static_properties.dart';
import 'package:yakihonne/utils/void_components.dart';

part 'buzz_feed_details_state.dart';

class BuzzFeedDetailsCubit extends Cubit<BuzzFeedDetailsState> {
  BuzzFeedDetailsCubit({
    required BuzzFeedModel buzzFeedModel,
  }) : super(
          BuzzFeedDetailsState(
            aiFeedModel: buzzFeedModel,
            mutes: nostrRepository.mutes.toList(),
            votes: {},
            currentUserPubkey: nostrRepository.user.pubKey,
            comments: [],
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            isSubscribed: getUserStatus() == UserStatus.UsingPrivKey &&
                List<String>.from(nostrRepository.userTopics).contains(
                  buzzFeedModel.sourceName,
                ),
          ),
        ) {
    initView();

    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        if (!isClosed)
          emit(
            state.copyWith(
              bookmarks: getBookmarkIds(bookmarks).toSet(),
            ),
          );
      },
    );

    muteListSubcription = nostrRepository.mutesStream.listen(
      (mutes) {
        if (!isClosed)
          emit(
            state.copyWith(
              mutes: mutes.toList(),
            ),
          );
      },
    );

    userTopicsSubscription = nostrRepository.userTopicsStream.listen(
      (topics) {
        if (!isClosed)
          emit(
            state.copyWith(
              isSubscribed: topics.contains(buzzFeedModel.sourceName),
            ),
          );
      },
    );
  }

  late StreamSubscription bookmarksSubscription;
  late StreamSubscription muteListSubcription;
  late StreamSubscription userTopicsSubscription;

  void initView() {
    NostrFunctionsRepository.getStats(
      eventKind: EventKind.TEXT_NOTE,
      eventPubkey: state.aiFeedModel.pubkey,
      eventIds: [state.aiFeedModel.id],
      isEtag: true,
    ).listen(
      (data) {
        if (data is Map<String, Map<String, VoteModel>>) {
          final votes = Map<String, VoteModel>.from(state.votes)
            ..addAll(data[state.aiFeedModel.id] ?? {});

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
        }
      },
      onDone: () {
        getAuthors();
      },
    );
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
        eventPubkey: eventPubkey,
        isEtag: true,
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

  void addComment({
    required String content,
    required String replyCommentId,
    required List<String> mentions,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    final comment = await NostrFunctionsRepository.addComment(
      eventId: state.aiFeedModel.id,
      eventPubkey: state.aiFeedModel.pubkey,
      eventKind: EventKind.TEXT_NOTE,
      isEtag: true,
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

  void shareLink(RenderBox? renderBox) {
    Share.share(
      externalShearableLink(
        kind: EventKind.TEXT_NOTE,
        pubkey: state.aiFeedModel.pubkey,
        id: state.aiFeedModel.id,
        textContentType: TextContentType.buzzFeed,
      ),
      subject: 'Check out www.yakihonne.com for more flash news.',
      sharePositionOrigin: renderBox != null
          ? renderBox.localToGlobal(Offset.zero) & renderBox.size
          : null,
    );
  }

  @override
  Future<void> close() {
    bookmarksSubscription.cancel();
    muteListSubcription.cancel();
    userTopicsSubscription.cancel();
    return super.close();
  }
}
