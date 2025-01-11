import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'curation_state.dart';

class CurationCubit extends Cubit<CurationState> {
  CurationCubit({
    required this.nostrRepository,
    required this.curation,
  }) : super(
          CurationState(
            curation: curation,
            isArticlesCuration: curation.isArticleCuration(),
            isArticleLoading: true,
            userStatus: getUserStatus(),
            votes: {},
            mutes: nostrRepository.mutes.toList(),
            articles: [],
            currentUserPubkey: nostrRepository.user.pubKey,
            canBeZapped: false,
            isValidUser: nostrRepository.usm != null &&
                nostrRepository.usm!.isUsingPrivKey,
            isSameCurationAuthor: nostrRepository.usm != null &&
                nostrRepository.usm!.isUsingPrivKey &&
                curation.pubKey == nostrRepository.usm!.pubKey,
            comments: [],
            zaps: {},
            reports: {},
            videos: [],
            isBookmarked: getBookmarkIds(nostrRepository.bookmarksLists)
                .contains(curation.identifier),
          ),
        ) {
    muteListSubscription = nostrRepository.mutesStream.listen(
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

  final NostrDataRepository nostrRepository;
  late StreamSubscription muteListSubscription;
  final Curation curation;
  Set<String> requests = {};

  void initView() {
    setAuthor();
    getStats();
    getItems();
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
      eventPubkey: curation.pubKey,
      identifier: curation.identifier,
      kind: curation.kind,
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

  void getStats() {
    NostrFunctionsRepository.getStats(
      identifier: curation.identifier,
      eventKind: curation.kind,
      eventPubkey: curation.pubKey,
      isEtag: false,
    ).listen(
      (data) {
        if (data is Map<String, Map<String, VoteModel>>) {
          final votes = Map<String, VoteModel>.from(state.votes)
            ..addAll(data[curation.identifier] ?? {});

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

  void getItems() {
    List<String> itemsIds = [];

    if (curation.eventsIds.isEmpty) {
      emit(
        state.copyWith(
          isArticleLoading: false,
        ),
      );

      return;
    }

    for (final eventId in curation.eventsIds) {
      if (curation.isArticleCuration()
          ? eventId.kind == EventKind.LONG_FORM
          : (eventId.kind == EventKind.VIDEO_HORIZONTAL ||
              eventId.kind == EventKind.VIDEO_VERTICAL)) {
        if (!itemsIds.contains(eventId.identifier)) {
          itemsIds.add(eventId.identifier);
        }
      }
    }

    if (itemsIds.isNotEmpty) {
      if (curation.isArticleCuration()) {
        NostrFunctionsRepository.getArticles(articlesIds: itemsIds).listen(
          (articles) {
            emit(
              state.copyWith(
                isArticleLoading: false,
                articles: articles,
              ),
            );
          },
          onDone: () {
            emit(
              state.copyWith(
                isArticleLoading: false,
              ),
            );
          },
        ).onDone(() {
          emit(
            state.copyWith(
              isArticleLoading: false,
            ),
          );
        });
      } else {
        NostrFunctionsRepository.getVideos(
          loadHorizontal: true,
          loadVertical: true,
          videosIds: itemsIds,
          onAllVideos: (videos) {
            emit(
              state.copyWith(
                isArticleLoading: false,
                videos: videos,
              ),
            );
          },
          onHorizontalVideos: (hVideos) {},
          onVerticalVideos: (vVideos) {},
          onDone: () {
            emit(
              state.copyWith(
                isArticleLoading: false,
              ),
            );
          },
        );
      }
    }
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
        kind: curation.kind,
        identifier: curation.identifier,
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

  void addComment({
    required String content,
    required String replyCommentId,
    required List<String> mentions,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    final comment = await NostrFunctionsRepository.addComment(
      eventId: curation.eventId,
      eventPubkey: curation.pubKey,
      eventKind: EventKind.TEXT_NOTE,
      selectedEventKind: curation.kind,
      identifier: curation.identifier,
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

  void setAuthor() {
    final authors = authorsCubit.getAuthorsByPubkeys([curation.pubKey]);

    if (authors.isNotEmpty) {
      final author = authors[curation.pubKey]!;

      if (!isClosed)
        emit(
          state.copyWith(
            canBeZapped: author.lud16.isNotEmpty &&
                nostrRepository.usm != null &&
                nostrRepository.usm!.isUsingPrivKey &&
                curation.pubKey != nostrRepository.usm!.pubKey,
          ),
        );

      return;
    } else {}

    NostrFunctionsRepository.getUserMetaData(
      pubkey: curation.pubKey,
    ).listen(
      (author) {
        emit(
          state.copyWith(
            canBeZapped: author.lud16.isNotEmpty &&
                nostrRepository.usm != null &&
                nostrRepository.usm!.isUsingPrivKey &&
                curation.pubKey != nostrRepository.usm!.pubKey,
          ),
        );
      },
    );
  }

  void shareLink(RenderBox? renderBox) {
    Share.share(
      externalShearableLink(
        kind: curation.kind,
        pubkey: curation.pubKey,
        id: curation.identifier,
      ),
      subject: 'Check out www.yakihonne.com for me more articles.',
      sharePositionOrigin: renderBox != null
          ? renderBox.localToGlobal(Offset.zero) & renderBox.size
          : null,
    );
  }

  @override
  Future<void> close() {
    NostrConnect.sharedInstance.closeRequests(requests.toList());
    muteListSubscription.cancel();
    return super.close();
  }
}
