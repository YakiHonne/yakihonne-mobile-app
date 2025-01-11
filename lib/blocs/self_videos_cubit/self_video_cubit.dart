import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';

part 'self_video_state.dart';

class SelfVideoCubit extends Cubit<SelfVideoState> {
  SelfVideoCubit()
      : super(
          SelfVideoState(
            userStatus: getUserStatus(),
            videos: [],
            isVideosLoading: true,
            chosenRelay: '',
            relays: nostrRepository.relays,
            videosAvailability: {},
            videoFilter: VideoFilter.All,
            videoAvailabilityToggle: true,
            relaysColors: {},
          ),
        ) {
    setRelaysColors();

    if (nostrRepository.usm != null) {
      getVideos(
        relay: '',
      );
    }

    userSubcription = nostrRepository.userModelStream.listen(
      (user) {
        if (user == null) {
          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: UserStatus.notConnected,
                videos: [],
                isVideosLoading: false,
                videosAvailability: {},
              ),
            );
        } else {
          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: user.isUsingPrivKey
                    ? UserStatus.UsingPrivKey
                    : UserStatus.UsingPubKey,
              ),
            );

          getVideos(
            relay: '',
          );
        }
      },
    );

    refreshSelfArticles = nostrRepository.refreshSelfArticlesStream.listen(
      (user) {
        getVideos(relay: state.chosenRelay);
      },
    );
  }

  late StreamSubscription userSubcription;
  late StreamSubscription refreshSelfArticles;
  Timer? articlesTimer;
  Set<String> requests = {};

  void setRelaysColors() {
    Map<String, int> colors = {};

    nostrRepository.relays.toList().forEach(
      (element) {
        colors[element] = randomColor().value;
      },
    );

    emit(
      state.copyWith(
        relaysColors: colors,
      ),
    );
  }

  void setVideoFilter(VideoFilter videoFilter) {
    if (state.videoFilter != videoFilter) {
      getVideos(relay: state.chosenRelay, videoFilter: videoFilter);
    }
  }

  void getVideos({
    required String relay,
    VideoFilter? videoFilter,
  }) {
    articlesTimer?.cancel();

    if (!isClosed)
      emit(
        state.copyWith(
          isVideosLoading: true,
          videos: [],
          chosenRelay: relay,
          videosAvailability: {},
          videoFilter: videoFilter,
        ),
      );

    NostrFunctionsRepository.getVideos(
      pubkeys: [nostrRepository.user.pubKey],
      loadHorizontal: videoFilter != VideoFilter.vertical,
      loadVertical: videoFilter != VideoFilter.horizontal,
      relay: relay.isEmpty ? null : relay,
      onAllVideos: (videos) {
        if (state.videoFilter == VideoFilter.All) {
          if (!isClosed)
            emit(
              state.copyWith(
                videos: videos,
                isVideosLoading: false,
              ),
            );
        }
      },
      onHorizontalVideos: (videos) {
        if (state.videoFilter == VideoFilter.horizontal) {
          emit(
            state.copyWith(
              videos: videos,
              isVideosLoading: false,
            ),
          );
        }
      },
      onVerticalVideos: (videos) {
        if (state.videoFilter == VideoFilter.vertical) {
          emit(
            state.copyWith(
              videos: videos,
              isVideosLoading: false,
            ),
          );
        }
      },
      onDone: () {
        emit(
          state.copyWith(
            isVideosLoading: false,
          ),
        );
      },
    );
  }

  void deleteVideo(String eventId, Function() onSuccess) async {
    final _cancel = BotToast.showLoading();

    final isSuccessful =
        await NostrFunctionsRepository.deleteEvent(eventId: eventId);

    if (isSuccessful) {
      onSuccess.call();
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }

    _cancel.call();
  }

  @override
  Future<void> close() {
    NostrConnect.sharedInstance.closeRequests(requests.toList());
    userSubcription.cancel();
    refreshSelfArticles.cancel();
    return super.close();
  }
}
