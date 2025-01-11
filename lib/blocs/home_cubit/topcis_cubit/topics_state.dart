// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'topics_cubit.dart';

class TopicsState extends Equatable {
  final List<String> activeTopics;
  final List<String> generalTopics;
  final bool isSameTopics;
  final List<String> suggestions;

  TopicsState({
    required this.activeTopics,
    required this.generalTopics,
    required this.isSameTopics,
    required this.suggestions,
  });

  @override
  List<Object> get props => [
        activeTopics,
        generalTopics,
        isSameTopics,
        suggestions,
      ];

  TopicsState copyWith({
    List<String>? activeTopics,
    List<String>? generalTopics,
    bool? isSameTopics,
    List<String>? suggestions,
  }) {
    return TopicsState(
      activeTopics: activeTopics ?? this.activeTopics,
      generalTopics: generalTopics ?? this.generalTopics,
      isSameTopics: isSameTopics ?? this.isSameTopics,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}
