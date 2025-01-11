import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'flash_news_details_state.dart';

class FlashNewsDetailsCubit extends Cubit<FlashNewsDetailsState> {
  FlashNewsDetailsCubit({required MainFlashNews flashNews})
      : super(
          FlashNewsDetailsState(
            mainFlashNews: flashNews,
            canBeZapped: false,
            comments: [],
            votes: {},
            zaps: {},
            reports: {},
            mutes: nostrRepository.mutes.toList(),
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            currentUserPubkey: nostrRepository.user.pubKey,
            userStatus: getUserStatus(),
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
  }

  late StreamSubscription bookmarksSubscription;
  late StreamSubscription muteListSubcription;

  void initView() {
    final auth =
        authorsCubit.getSpecificAuthor(state.mainFlashNews.flashNews.pubkey);

    if (auth != null) {
      emit(
        state.copyWith(
          canBeZapped: auth.lud16.isNotEmpty &&
              nostrRepository.usm != null &&
              nostrRepository.usm!.isUsingPrivKey &&
              auth.pubKey != nostrRepository.usm!.pubKey,
        ),
      );
    }

    NostrFunctionsRepository.getStats(
      eventKind: EventKind.TEXT_NOTE,
      eventPubkey: state.mainFlashNews.flashNews.pubkey,
      eventIds: [state.mainFlashNews.flashNews.id],
      isEtag: true,
    ).listen(
      (data) {
        if (data is Map<String, Map<String, VoteModel>>) {
          final votes = Map<String, VoteModel>.from(state.votes)
            ..addAll(data[state.mainFlashNews.flashNews.id] ?? {});
          if (!isClosed)
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
      eventId: state.mainFlashNews.flashNews.id,
      eventPubkey: state.mainFlashNews.flashNews.pubkey,
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

  void report({
    required String reason,
    required String comment,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    final isSuccessful = await NostrFunctionsRepository.report(
      comment: comment,
      reason: reason,
      isEtag: true,
      eventPubkey: state.mainFlashNews.flashNews.pubkey,
      eventId: state.mainFlashNews.flashNews.id,
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
        pubkey: state.mainFlashNews.flashNews.pubkey,
        id: state.mainFlashNews.flashNews.id,
        textContentType: TextContentType.flashnews,
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
    return super.close();
  }
}
