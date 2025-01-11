// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'write_flash_news_cubit.dart';

class WriteFlashNewsState extends Equatable {
  final FlashNewsPublishSteps flashNewsPublishSteps;
  final String content;
  final List<String> selectedRelays;
  final List<String> totalRelays;
  final List<String> keywords;
  final List<String> suggestions;
  final bool isImportant;
  final String source;
  final FlashNewsKinds flashNewsKinds;
  final Article? article;
  final Curation? curation;
  final bool updateKind;
  final bool isEventConfirmation;

  WriteFlashNewsState({
    required this.flashNewsPublishSteps,
    required this.content,
    required this.selectedRelays,
    required this.totalRelays,
    required this.keywords,
    required this.suggestions,
    required this.isImportant,
    required this.source,
    required this.flashNewsKinds,
    required this.updateKind,
    required this.isEventConfirmation,
    this.article,
    this.curation,
  });

  @override
  List<Object> get props => [
        flashNewsPublishSteps,
        content,
        selectedRelays,
        totalRelays,
        keywords,
        suggestions,
        isImportant,
        source,
        flashNewsKinds,
        updateKind,
        isEventConfirmation,
      ];

  WriteFlashNewsState copyWith({
    FlashNewsPublishSteps? flashNewsPublishSteps,
    String? content,
    List<String>? selectedRelays,
    List<String>? totalRelays,
    List<String>? keywords,
    List<String>? suggestions,
    bool? isImportant,
    String? source,
    FlashNewsKinds? flashNewsKinds,
    Article? article,
    Curation? curation,
    bool? updateKind,
    bool? isEventConfirmation,
  }) {
    return WriteFlashNewsState(
      flashNewsPublishSteps:
          flashNewsPublishSteps ?? this.flashNewsPublishSteps,
      content: content ?? this.content,
      selectedRelays: selectedRelays ?? this.selectedRelays,
      totalRelays: totalRelays ?? this.totalRelays,
      keywords: keywords ?? this.keywords,
      suggestions: suggestions ?? this.suggestions,
      isImportant: isImportant ?? this.isImportant,
      source: source ?? this.source,
      flashNewsKinds: flashNewsKinds ?? this.flashNewsKinds,
      updateKind: updateKind ?? this.updateKind,
      isEventConfirmation: isEventConfirmation ?? this.isEventConfirmation,
      article: article,
      curation: curation,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'flashNewsPublishSteps': flashNewsPublishSteps,
      'content': content,
      'selectedRelays': selectedRelays,
      'totalRelays': totalRelays,
      'keywords': keywords,
      'suggestions': suggestions,
      'isImportant': isImportant,
      'source': source,
      'flashNewsKinds': flashNewsKinds,
      'article': article,
      'curation': curation,
      'updateKind': updateKind,
      'isEventConfirmation': isEventConfirmation,
    };
  }
}
