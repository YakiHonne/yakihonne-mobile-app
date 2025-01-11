import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'article_state.dart';

class ArticleCubit extends Cubit<ArticleState> {
  ArticleCubit({
    required this.nostrRepository,
    required this.article,
    required this.localDatabaseRepository,
  }) : super(
          ArticleState(
            article: article,
            mutes: nostrRepository.mutes.toList(),
            currentUserPubkey: nostrRepository.user.pubKey,
            canBeZapped: false,
            userStatus: getUserStatus(),
            author: emptyUserModel.copyWith(
              pubKey: article.pubkey,
              picturePlaceholder:
                  getRandomPlaceholder(input: article.pubkey, isPfp: true),
            ),
            isSameArticleAuthor: article.pubkey == nostrRepository.user.pubKey,
            votes: {},
            comments: [],
            zaps: {},
            reports: {},
            isFollowingAuthor: false,
            isBookmarked: getBookmarkIds(nostrRepository.bookmarksLists)
                .contains(article.identifier),
            isLoading: true,
          ),
        ) {
    if (article.client.isEmpty ||
        !article.client.startsWith(EventKind.APPLICATION_INFO.toString())) {
      identifier = '';
    } else {
      appClientsCubit.getAppClient(article.client);

      final splits = article.client.split(':');
      if (splits.length > 2) {
        identifier = splits[2];
      }
    }

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
                  user.isUsingPrivKey && article.pubkey == user.pubKey,
            ),
          );
      }
    });

    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        final isBookmarked = getBookmarkIds(nostrRepository.bookmarksLists)
            .contains(article.identifier);

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
              isFollowingAuthor: followings.contains(article.pubkey),
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

  final NostrDataRepository nostrRepository;
  final LocalDatabaseRepository localDatabaseRepository;
  late StreamSubscription followingsSubscription;
  late StreamSubscription bookmarksSubscription;
  late StreamSubscription mutesSubscription;
  late StreamSubscription userSubscription;
  final Article article;
  String identifier = '';
  Set<String> requests = {};

  void emptyArticleState() {
    ArticleState(
      article: article,
      mutes: nostrRepository.mutes.toList(),
      userStatus: getUserStatus(),
      currentUserPubkey: nostrRepository.user.pubKey,
      canBeZapped: false,
      author: emptyUserModel.copyWith(
        pubKey: article.pubkey,
        picturePlaceholder:
            getRandomPlaceholder(input: article.pubkey, isPfp: true),
      ),
      isSameArticleAuthor: nostrRepository.usm != null &&
          nostrRepository.usm!.isUsingPrivKey &&
          article.pubkey == nostrRepository.usm!.pubKey,
      votes: {},
      comments: [],
      zaps: {},
      reports: {},
      isFollowingAuthor: false,
      isBookmarked: getBookmarkIds(nostrRepository.bookmarksLists)
          .contains(article.identifier),
      isLoading: true,
    );
  }

  void initView() {
    setAuthor();
    getStats();
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
      kind: EventKind.LONG_FORM,
      eventPubkey: state.article.pubkey,
      identifier: article.identifier,
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
      identifier: article.identifier,
      eventKind: EventKind.LONG_FORM,
      eventPubkey: article.pubkey,
      isEtag: false,
    ).listen(
      (data) {
        if (data is Map<String, Map<String, VoteModel>>) {
          final votes = Map<String, VoteModel>.from(state.votes)
            ..addAll(data[state.article.identifier] ?? {});

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
        identifier: article.identifier,
        kind: EventKind.LONG_FORM,
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

  void addComment({
    required String content,
    required String replyCommentId,
    required List<String> mentions,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();
    final comment = await NostrFunctionsRepository.addComment(
      eventId: state.article.articleId,
      eventPubkey: state.article.pubkey,
      eventKind: EventKind.TEXT_NOTE,
      selectedEventKind: EventKind.LONG_FORM,
      identifier: state.article.identifier,
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

  void setFollowingState() async {
    final _cancel = BotToast.showLoading();

    await NostrFunctionsRepository.setFollowingEvent(
      isFollowingAuthor: state.isFollowingAuthor,
      targetPubkey: state.article.pubkey,
    );

    _cancel.call();
  }

  void setAuthor() {
    bool isFollowing = false;
    final authors = authorsCubit.getAuthorsByPubkeys([state.article.pubkey]);

    if (authors.isNotEmpty) {
      final author = authors[state.article.pubkey]!;

      if (state.userStatus == UserStatus.UsingPrivKey &&
          article.pubkey != state.currentUserPubkey) {
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
                state.article.pubkey != nostrRepository.usm!.pubKey,
          ),
        );

      return;
    }

    NostrFunctionsRepository.getUserMetaData(
      pubkey: article.pubkey,
    ).listen(
      (author) {
        if (state.userStatus == UserStatus.UsingPrivKey &&
            article.pubkey != state.currentUserPubkey) {
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
                state.article.pubkey != nostrRepository.usm!.pubKey,
          ),
        );
      },
    );
  }

  void shareLink(RenderBox? renderBox) {
    Share.share(
      externalShearableLink(
        kind: EventKind.LONG_FORM,
        pubkey: state.article.pubkey,
        id: state.article.identifier,
      ),
      subject: 'Check out www.yakihonne.com for me more articles.',
      sharePositionOrigin: renderBox != null
          ? renderBox.localToGlobal(Offset.zero) & renderBox.size
          : null,
    );
  }

  @override
  Future<void> close() {
    followingsSubscription.cancel();
    bookmarksSubscription.cancel();
    userSubscription.cancel();
    mutesSubscription.cancel();
    NostrConnect.sharedInstance.closeRequests(requests.toList());
    return super.close();
  }
}
