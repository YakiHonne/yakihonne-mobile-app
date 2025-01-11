import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/utils.dart';

part 'videos_state.dart';

class VideosCubit extends Cubit<VideosState> {
  VideosCubit({required bool isHorizontal})
      : super(
          VideosState(
            isHorizontalLoading: true,
            isVerticalLoading: true,
            horizontalVideos: [],
            verticalVideos: [],
            loadingHorizontalState: UpdatingState.success,
            loadingVerticalState: UpdatingState.success,
            isHorizontalVideoSelected: isHorizontal,
          ),
        );

  void initView({required bool loadHorizontal, required bool loadVertical}) {
    emit(
      state.copyWith(
        isHorizontalLoading: loadHorizontal ? loadHorizontal : null,
        loadingHorizontalState: loadHorizontal ? UpdatingState.success : null,
        isVerticalLoading: loadVertical ? loadVertical : null,
        loadingVerticalState: loadVertical ? UpdatingState.success : null,
      ),
    );

    NostrFunctionsRepository.getVideos(
      loadHorizontal: loadHorizontal,
      loadVertical: loadVertical,
      limit: 20,
      onHorizontalVideos: (videos) {
        sort(videos);
        authorsCubit.getAuthors(videos.map((e) => e.pubkey).toList());
        if (!isClosed)
          emit(
            state.copyWith(
              isHorizontalLoading: false,
              horizontalVideos: videos,
            ),
          );
      },
      onVerticalVideos: (videos) {
        sort(videos);
        authorsCubit.getAuthors(videos.map((e) => e.pubkey).toList());
        if (!isClosed)
          emit(
            state.copyWith(
              isVerticalLoading: false,
              verticalVideos: videos,
            ),
          );
      },
      onDone: () {
        for (final e in state.horizontalVideos) {
          nostrRepository.videos[e.identifier] = e;
        }

        if (!isClosed)
          emit(
            state.copyWith(
              isVerticalLoading: false,
              isHorizontalLoading: false,
            ),
          );
      },
    );
  }

  void loadMore() {
    final hor = state.isHorizontalVideoSelected;

    if (hor && state.horizontalVideos.isEmpty ||
        !hor && state.verticalVideos.isEmpty) {
      emit(
        state.copyWith(
          loadingHorizontalState: hor ? UpdatingState.idle : null,
          loadingVerticalState: !hor ? UpdatingState.idle : null,
        ),
      );

      return;
    }

    emit(
      state.copyWith(
        loadingHorizontalState: hor ? UpdatingState.progress : null,
        loadingVerticalState: !hor ? UpdatingState.progress : null,
      ),
    );

    final createdAt = hor
        ? state.horizontalVideos.last.createdAt
        : state.verticalVideos.last.createdAt;

    final oldVideos = hor
        ? List<VideoModel>.from(state.horizontalVideos)
        : List<VideoModel>.from(state.verticalVideos);
    List<VideoModel> onGoingVideo = [];

    NostrFunctionsRepository.getVideos(
      loadHorizontal: hor,
      loadVertical: !hor,
      limit: 20,
      until: createdAt.toSecondsSinceEpoch() - 1,
      onHorizontalVideos: (videos) {
        onGoingVideo = videos;
        sort(onGoingVideo);
        authorsCubit.getAuthors(videos.map((e) => e.pubkey).toList());
        final updateVideos = [...oldVideos, ...onGoingVideo];
        emit(
          state.copyWith(
            loadingHorizontalState: UpdatingState.success,
            horizontalVideos: updateVideos,
          ),
        );
      },
      onVerticalVideos: (videos) {
        onGoingVideo = videos;
        sort(onGoingVideo);
        authorsCubit.getAuthors(videos.map((e) => e.pubkey).toList());
        emit(
          state.copyWith(
            loadingVerticalState: UpdatingState.success,
            verticalVideos: oldVideos..insertAll(0, onGoingVideo),
          ),
        );
      },
      onDone: () {
        if (onGoingVideo.isNotEmpty && hor) {
          for (final e in onGoingVideo) {
            nostrRepository.videos[e.identifier] = e;
          }
        } else if (onGoingVideo.isEmpty) {
          emit(
            state.copyWith(
              loadingVerticalState: !hor ? UpdatingState.idle : null,
              loadingHorizontalState: hor ? UpdatingState.idle : null,
            ),
          );
        }
      },
    );
  }

  void setIsHorizontal(bool isHorizontal) {
    emit(
      state.copyWith(
        isHorizontalVideoSelected: isHorizontal,
      ),
    );
  }

  void shareLink(RenderBox? renderBox, VideoModel video) {
    Share.share(
      externalShearableLink(
        kind: video.kind,
        pubkey: video.pubkey,
        id: video.identifier,
      ),
      subject: 'Check out www.yakihonne.com for me more videos.',
      sharePositionOrigin: renderBox != null
          ? renderBox.localToGlobal(Offset.zero) & renderBox.size
          : null,
    );
  }

  void sort(List<VideoModel> videos) {
    videos.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );
  }
}
