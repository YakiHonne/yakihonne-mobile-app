// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'add_curation_cubit.dart';

class AddCurationState extends Equatable {
  final File? localImage;
  final bool isLocalImage;
  final bool isImageSelected;
  final String imageLink;
  final String title;
  final String description;
  final bool isArticlesCuration;
  final CurationPublishSteps curationPublishSteps;
  final List<String> selectedRelays;
  final List<String> totalRelays;

  final bool isZapSplitEnabled;
  final List<ZapSplit> zapsSplits;

  AddCurationState({
    this.localImage,
    required this.isLocalImage,
    required this.isImageSelected,
    required this.imageLink,
    required this.title,
    required this.description,
    required this.isArticlesCuration,
    required this.curationPublishSteps,
    required this.selectedRelays,
    required this.totalRelays,
    required this.isZapSplitEnabled,
    required this.zapsSplits,
  });

  @override
  List<Object> get props => [
        isLocalImage,
        isImageSelected,
        imageLink,
        curationPublishSteps,
        selectedRelays,
        totalRelays,
        title,
        description,
        isZapSplitEnabled,
        isArticlesCuration,
        zapsSplits,
      ];

  AddCurationState copyWith({
    File? localImage,
    bool? isLocalImage,
    bool? isImageSelected,
    String? imageLink,
    String? title,
    String? description,
    bool? isArticlesCuration,
    CurationPublishSteps? curationPublishSteps,
    List<String>? selectedRelays,
    List<String>? totalRelays,
    bool? isZapSplitEnabled,
    List<ZapSplit>? zapsSplits,
  }) {
    return AddCurationState(
      localImage: localImage ?? this.localImage,
      isLocalImage: isLocalImage ?? this.isLocalImage,
      isImageSelected: isImageSelected ?? this.isImageSelected,
      imageLink: imageLink ?? this.imageLink,
      title: title ?? this.title,
      description: description ?? this.description,
      isArticlesCuration: isArticlesCuration ?? this.isArticlesCuration,
      curationPublishSteps: curationPublishSteps ?? this.curationPublishSteps,
      selectedRelays: selectedRelays ?? this.selectedRelays,
      totalRelays: totalRelays ?? this.totalRelays,
      isZapSplitEnabled: isZapSplitEnabled ?? this.isZapSplitEnabled,
      zapsSplits: zapsSplits ?? this.zapsSplits,
    );
  }
}
