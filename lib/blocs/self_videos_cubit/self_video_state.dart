// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'self_video_cubit.dart';

class SelfVideoState extends Equatable {
  final UserStatus userStatus;
  final List<VideoModel> videos;
  final bool isVideosLoading;
  final String chosenRelay;
  final Set<String> relays;
  final Map<String, Set<String>> videosAvailability;
  final bool videoAvailabilityToggle;
  final VideoFilter videoFilter;
  final Map<String, int> relaysColors;

  SelfVideoState({
    required this.userStatus,
    required this.videos,
    required this.isVideosLoading,
    required this.chosenRelay,
    required this.relays,
    required this.videosAvailability,
    required this.videoAvailabilityToggle,
    required this.videoFilter,
    required this.relaysColors,
  });

  @override
  List<Object> get props => [
        userStatus,
        videos,
        isVideosLoading,
        chosenRelay,
        relays,
        videosAvailability,
        videoAvailabilityToggle,
        videoFilter,
        relaysColors,
      ];

  SelfVideoState copyWith({
    UserStatus? userStatus,
    List<VideoModel>? videos,
    bool? isVideosLoading,
    String? chosenRelay,
    Set<String>? relays,
    Map<String, Set<String>>? videosAvailability,
    bool? videoAvailabilityToggle,
    VideoFilter? videoFilter,
    Map<String, int>? relaysColors,
  }) {
    return SelfVideoState(
      userStatus: userStatus ?? this.userStatus,
      videos: videos ?? this.videos,
      isVideosLoading: isVideosLoading ?? this.isVideosLoading,
      chosenRelay: chosenRelay ?? this.chosenRelay,
      relays: relays ?? this.relays,
      videosAvailability: videosAvailability ?? this.videosAvailability,
      videoAvailabilityToggle:
          videoAvailabilityToggle ?? this.videoAvailabilityToggle,
      videoFilter: videoFilter ?? this.videoFilter,
      relaysColors: relaysColors ?? this.relaysColors,
    );
  }
}
