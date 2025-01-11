// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'write_video_cubit.dart';

class WriteVideoState extends Equatable {
  final List<String> selectedRelays;
  final List<String> totalRelays;
  final List<String> tags;
  final List<String> suggestions;
  final VideoPublishSteps videoPublishSteps;
  final String videoUrl;
  final String title;
  final String summary;
  final String contentWarning;
  final String mimeType;
  final bool isUpdating;
  final bool isZapSplitEnabled;
  final List<ZapSplit> zapsSplits;
  final File? localImage;
  final bool isLocalImage;
  final bool isImageSelected;
  final String imageLink;
  final bool isHorizontal;

  WriteVideoState({
    required this.selectedRelays,
    required this.totalRelays,
    required this.tags,
    required this.suggestions,
    required this.videoPublishSteps,
    required this.videoUrl,
    required this.title,
    required this.summary,
    required this.contentWarning,
    required this.mimeType,
    required this.isUpdating,
    required this.isZapSplitEnabled,
    required this.zapsSplits,
    required this.isLocalImage,
    required this.isImageSelected,
    required this.imageLink,
    required this.isHorizontal,
    this.localImage,
  });

  @override
  List<Object> get props => [
        selectedRelays,
        totalRelays,
        tags,
        suggestions,
        videoPublishSteps,
        videoUrl,
        title,
        summary,
        imageLink,
        contentWarning,
        mimeType,
        isUpdating,
        isZapSplitEnabled,
        zapsSplits,
        isLocalImage,
        isImageSelected,
        isHorizontal,
      ];

  WriteVideoState copyWith({
    List<String>? selectedRelays,
    List<String>? totalRelays,
    List<String>? tags,
    List<String>? suggestions,
    VideoPublishSteps? videoPublishSteps,
    String? videoUrl,
    String? title,
    String? summary,
    String? contentWarning,
    String? mimeType,
    bool? isUpdating,
    bool? isZapSplitEnabled,
    List<ZapSplit>? zapsSplits,
    File? localImage,
    bool? isLocalImage,
    bool? isImageSelected,
    String? imageLink,
    bool? isHorizontal,
  }) {
    return WriteVideoState(
      selectedRelays: selectedRelays ?? this.selectedRelays,
      totalRelays: totalRelays ?? this.totalRelays,
      tags: tags ?? this.tags,
      suggestions: suggestions ?? this.suggestions,
      videoPublishSteps: videoPublishSteps ?? this.videoPublishSteps,
      videoUrl: videoUrl ?? this.videoUrl,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      contentWarning: contentWarning ?? this.contentWarning,
      mimeType: mimeType ?? this.mimeType,
      isUpdating: isUpdating ?? this.isUpdating,
      isZapSplitEnabled: isZapSplitEnabled ?? this.isZapSplitEnabled,
      zapsSplits: zapsSplits ?? this.zapsSplits,
      localImage: localImage ?? this.localImage,
      isLocalImage: isLocalImage ?? this.isLocalImage,
      isImageSelected: isImageSelected ?? this.isImageSelected,
      imageLink: imageLink ?? this.imageLink,
      isHorizontal: isHorizontal ?? this.isHorizontal,
    );
  }
}
