import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/nostr/event.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required this.nostrRepository,
    required this.authorId,
  }) : super(
          ProfileState(
            profileStatus: ProfileStatus.loading,
            notesLoading: UpdatingState.success,
            isRelaysLoading: true,
            isFlashNewsLoading: true,
            isVideoLoading: true,
            isNotesLoading: true,
            mutes: nostrRepository.mutes.toList(),
            userRelays: [],
            videos: [],
            notes: [],
            isArticlesLoading: true,
            canBeZapped: false,
            isFollowingAuthor: false,
            isNip05: false,
            userStatus: getUserStatus(),
            isSameArticleAuthor: nostrRepository.usm != null &&
                nostrRepository.usm!.isUsingPrivKey &&
                authorId == nostrRepository.usm!.pubKey,
            articles: [],
            curations: nostrRepository.curationsMemBox.getCurations.values
                .where((curation) => curation.pubKey == authorId)
                .toList(),
            followers: {},
            followings: {},
            followersLength: 0,
            followingsLength: 0,
            sentZaps: 0,
            receivedZaps: 0,
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            flashNews: [],
            activeRelays: NostrConnect.sharedInstance.activeRelays(),
            ownRelays: NostrConnect.sharedInstance.relays(),
            user: emptyUserModel.copyWith(
              pubKey: authorId,
              picturePlaceholder: getRandomPlaceholder(
                input: authorId,
                isPfp: true,
              ),
            ),
            ratingImpact: 0,
            writingImpact: 0,
            negativeWritingImpact: 0,
            ongoingWritingImpact: 0,
            positiveRatingImpactH: 0,
            positiveRatingImpactNh: 0,
            positiveWritingImpact: 0,
            negativeRatingImpactH: 0,
            negativeRatingImpactNh: 0,
            ongoingRatingImpact: 0,
          ),
        ) {
    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        if (!isClosed)
          emit(
            state.copyWith(
              bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            ),
          );
      },
    );

    mutesListSubscription = nostrRepository.mutesStream.listen(
      (mutes) {
        if (!isClosed)
          emit(
            state.copyWith(
              mutes: mutes.toList(),
            ),
          );
      },
    );

    followingsSubscription = nostrRepository.followingsStream.listen(
      (followings) {
        Set<String>? followingsList = nostrRepository.usm != null &&
                nostrRepository.usm!.isUsingPrivKey &&
                authorId == nostrRepository.usm!.pubKey
            ? followings.toSet()
            : null;

        if (!isClosed)
          emit(
            state.copyWith(
              isFollowingAuthor: followings.contains(authorId),
              followings: followingsList,
              followingsLength: followingsList?.length,
            ),
          );
      },
    );
  }

  final NostrDataRepository nostrRepository;
  late StreamSubscription followingsSubscription;
  late StreamSubscription bookmarksSubscription;
  late StreamSubscription mutesListSubscription;

  final String authorId;
  Set<String> requests = {};

  void emitEmptyState() {
    if (!isClosed)
      emit(
        ProfileState(
          profileStatus: ProfileStatus.loading,
          notesLoading: UpdatingState.idle,
          isVideoLoading: true,
          isRelaysLoading: true,
          isFlashNewsLoading: true,
          isNotesLoading: true,
          userRelays: [],
          flashNews: [],
          videos: [],
          notes: [],
          mutes: nostrRepository.mutes.toList(),
          isArticlesLoading: true,
          canBeZapped: false,
          isFollowingAuthor: false,
          isNip05: false,
          userStatus: nostrRepository.usm == null
              ? UserStatus.notConnected
              : nostrRepository.usm!.isUsingPrivKey
                  ? UserStatus.UsingPrivKey
                  : UserStatus.UsingPubKey,
          isSameArticleAuthor: nostrRepository.usm != null &&
              nostrRepository.usm!.isUsingPrivKey &&
              authorId == nostrRepository.usm!.pubKey,
          articles: [],
          curations: nostrRepository.curationsMemBox.getCurations.values
              .where((curation) => curation.pubKey == authorId)
              .toList(),
          followers: {},
          followings: {},
          followersLength: 0,
          followingsLength: 0,
          sentZaps: 0,
          receivedZaps: 0,
          bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
          activeRelays: NostrConnect.sharedInstance.activeRelays(),
          ownRelays: NostrConnect.sharedInstance.relays(),
          user: emptyUserModel
            ..copyWith(
              pubKey: authorId,
              picturePlaceholder:
                  getRandomPlaceholder(input: authorId, isPfp: true),
            ),
          ratingImpact: 0,
          writingImpact: 0,
          negativeWritingImpact: 0,
          ongoingWritingImpact: 0,
          positiveRatingImpactH: 0,
          positiveRatingImpactNh: 0,
          positiveWritingImpact: 0,
          negativeRatingImpactH: 0,
          negativeRatingImpactNh: 0,
          ongoingRatingImpact: 0,
        ),
      );
  }

  void initView() {
    getUserInfos();
    getImpacts();
  }

  void getImpacts() async {
    try {
      final response = await HttpFunctionsRepository.getImpacts(authorId);

      emit(
        state.copyWith(
          writingImpact: response['writing'],
          ratingImpact: response['rating'],
          negativeWritingImpact: response['negativeWriting'],
          ongoingWritingImpact: response['ongoingWriting'],
          positiveRatingImpactH: response['positiveRatingH'],
          positiveRatingImpactNh: response['positiveRatingNh'],
          positiveWritingImpact: response['positiveWriting'],
        ),
      );
    } catch (_) {}
  }

  void setMuteStatus({
    required String pubkey,
    required Function() onSuccess,
  }) async {
    final _cancel = BotToast.showLoading();

    final result = await NostrFunctionsRepository.setMuteList(pubkey);
    _cancel();

    if (result) {
      final hasBeenMuted = nostrRepository.mutes.contains(state.user.pubKey);

      BotToastUtils.showSuccess(
        hasBeenMuted ? 'User has been muted' : 'User has been unmuted',
      );

      onSuccess.call();
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }
  }

  void getMoreNotes() {
    if (state.notes.isNotEmpty) {
      List<DetailedNoteModel> oldNotes = state.notes;
      List<Event> newNotes = [];

      emit(
        state.copyWith(
          notesLoading: UpdatingState.progress,
        ),
      );

      NostrFunctionsRepository.getDetailedNotes(
        kinds: [EventKind.TEXT_NOTE],
        onNotesFunc: (notes) {
          newNotes = notes;
        },
        pubkeys: [authorId],
        until: oldNotes.last.createdAt.toSecondsSinceEpoch() - 1,
        limit: 20,
        onDone: () {
          final updateNotes =
              newNotes.map((e) => DetailedNoteModel.fromEvent(e)).toList();

          emit(
            state.copyWith(
              notes: [...oldNotes, ...updateNotes],
              notesLoading:
                  newNotes.isEmpty ? UpdatingState.idle : UpdatingState.success,
            ),
          );
        },
      );
    }
  }

  void shareLink(RenderBox? renderBox) {
    Share.share(
      externalShearableLink(
        kind: EventKind.METADATA,
        pubkey: '',
        id: state.user.pubKey,
      ),
      subject: 'Check out www.yakihonne.com for me more.',
      sharePositionOrigin: renderBox != null
          ? renderBox.localToGlobal(Offset.zero) & renderBox.size
          : null,
    );
  }

  void getUserInfos() async {
    final author = authorsCubit.getAuthor(authorId);

    bool isFollowing = false;
    getUserReceivedZaps();

    if (author != null) {
      NostrFunctionsRepository.checkNip05ValidityFromData(
        nip05: author.nip05,
        pubkey: author.pubKey,
      );

      emit(
        state.copyWith(
          user: author,
          profileStatus: ProfileStatus.available,
        ),
      );

      final user = author;

      if (!state.isNip05 && user.nip05.isNotEmpty) {
        bool? authorNip05 = authorsCubit.state.nip05Validations[authorId];

        if (authorNip05 == null || !authorNip05) {
          await NostrFunctionsRepository.checkNip05ValidityFromData(
            pubkey: authorId,
            nip05: user.nip05,
          );

          authorNip05 = authorsCubit.state.nip05Validations[authorId];
        }

        emit(
          state.copyWith(
            isNip05: authorNip05 != null && authorNip05,
          ),
        );
      }

      if (state.userStatus == UserStatus.UsingPrivKey) {
        for (final profile in nostrRepository.user.followings) {
          if (profile.key == user.pubKey) {
            isFollowing = true;
            break;
          }
        }
      }

      if (!isClosed)
        emit(
          state.copyWith(
            user: user,
            isFollowingAuthor: isFollowing,
            profileStatus: ProfileStatus.available,
            canBeZapped: (user.lud16.isNotEmpty || user.lud06.isNotEmpty) &&
                nostrRepository.usm != null &&
                nostrRepository.usm!.isUsingPrivKey &&
                user.pubKey != nostrRepository.usm!.pubKey,
          ),
        );
    }

    final requestId = NostrFunctionsRepository.getUserProfile(
      authorPubkey: authorId,
      followersFunc: (followers) {
        if (!isClosed)
          emit(
            state.copyWith(
              followers: followers,
              followersLength: followers.length,
            ),
          );
      },
      flashNewsFunc: (flashNews) {
        emit(
          state.copyWith(
            flashNews: flashNews,
            isFlashNewsLoading: false,
          ),
        );
      },
      curationsFunc: (curations) {
        emit(
          state.copyWith(
            curations: curations,
          ),
        );
      },
      videosFunc: (videos) {
        emit(
          state.copyWith(
            videos: videos,
            isVideoLoading: false,
          ),
        );
      },
      notesFunc: (notes) {
        emit(
          state.copyWith(
            notes: notes,
            isNotesLoading: false,
          ),
        );
      },
      articleFunc: (articles) {
        emit(
          state.copyWith(
            articles: articles,
            isArticlesLoading: false,
          ),
        );
      },
      relaysFunc: (relays) {
        if (!isClosed)
          emit(
            state.copyWith(
              userRelays: relays.toList(),
              isRelaysLoading: false,
            ),
          );
      },
      followingsFunc: (followings) {
        if (!isClosed)
          emit(
            state.copyWith(
              followingsLength: followings.length,
              followings: followings,
            ),
          );
      },
      zaps: (zaps) {
        if (!isClosed)
          emit(
            state.copyWith(
              receivedZaps: zaps,
            ),
          );
      },
      onDone: () {
        if (!isClosed)
          emit(
            state.copyWith(
              isArticlesLoading: false,
              isFlashNewsLoading: false,
              isRelaysLoading: false,
              isVideoLoading: false,
              isNotesLoading: false,
            ),
          );
      },
    );

    requests.add(requestId);
  }

  void canBeZapped(UserModel user) {
    bool isFollowing = false;

    if (!state.isNip05 && user.nip05.isNotEmpty) {
      final authorNip05 = authorsCubit.state.nip05Validations[authorId];

      emit(
        state.copyWith(
          isNip05: authorNip05 != null && authorNip05,
        ),
      );
    }

    if (state.userStatus == UserStatus.UsingPrivKey) {
      for (final profile in nostrRepository.user.followings) {
        if (profile.key == user.pubKey) {
          isFollowing = true;
          break;
        }
      }
    }

    emit(
      state.copyWith(
        user: user,
        isFollowingAuthor: isFollowing,
        profileStatus: ProfileStatus.available,
        canBeZapped: (user.lud16.isNotEmpty || user.lud06.isNotEmpty) &&
            nostrRepository.usm != null &&
            nostrRepository.usm!.isUsingPrivKey &&
            user.pubKey != nostrRepository.usm!.pubKey,
      ),
    );
  }

  Future<void> addRelay({required String newRelay}) async {
    String relay = newRelay.removeLastBackSlashes();

    if (state.activeRelays.contains(relay)) {
      BotToastUtils.showError('Relay already in use');
      return;
    }

    final _cancel = BotToast.showLoading();

    final isSuccessful = await NostrFunctionsRepository.connectToRelay(relay);

    if (isSuccessful) {
      await NostrConnect.sharedInstance.connect(relay);
      setRelays();
    } else {
      BotToastUtils.showError(
        'Error occured while conneting to relay.',
      );
    }

    _cancel.call();
  }

  void setRelays() {
    final allRelays = NostrConnect.sharedInstance.relays();
    final activeRelays = NostrConnect.sharedInstance.activeRelays();

    if (!isClosed)
      emit(
        state.copyWith(
          ownRelays: allRelays,
          activeRelays: activeRelays,
        ),
      );
  }

  void setFollowingState() async {
    final _cancel = BotToast.showLoading();

    await NostrFunctionsRepository.setFollowingEvent(
      isFollowingAuthor: state.isFollowingAuthor,
      targetPubkey: authorId,
    );

    _cancel.call();
  }

  void getUserReceivedZaps() async {
    final zaps = await HttpFunctionsRepository.getUserReceivedZaps(authorId);
    if (!isClosed)
      emit(
        state.copyWith(
          sentZaps: zaps,
        ),
      );
  }

  @override
  Future<void> close() {
    followingsSubscription.cancel();
    bookmarksSubscription.cancel();
    mutesListSubscription.cancel();
    NostrConnect.sharedInstance.closeRequests(requests.toList());
    return super.close();
  }
}
