// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'write_smart_widget_cubit.dart';

class WriteSmartWidgetState extends Equatable {
  final SmartWidgetPublishSteps smartWidgetPublishSteps;
  final String title;
  final String summary;
  final SmartWidgetContainer smartWidgetContainer;
  final bool smartWidgetUpdate;
  final bool toggleDisplay;
  final bool isOnboarding;

  WriteSmartWidgetState({
    required this.smartWidgetPublishSteps,
    required this.title,
    required this.summary,
    required this.smartWidgetContainer,
    required this.smartWidgetUpdate,
    required this.toggleDisplay,
    required this.isOnboarding,
  });

  @override
  List<Object> get props => [
        smartWidgetPublishSteps,
        title,
        summary,
        smartWidgetContainer,
        smartWidgetUpdate,
        toggleDisplay,
        isOnboarding,
      ];

  WriteSmartWidgetState copyWith({
    SmartWidgetPublishSteps? smartWidgetPublishSteps,
    String? title,
    String? summary,
    SmartWidgetContainer? smartWidgetContainer,
    bool? smartWidgetUpdate,
    bool? toggleDisplay,
    bool? isOnboarding,
  }) {
    return WriteSmartWidgetState(
      smartWidgetPublishSteps:
          smartWidgetPublishSteps ?? this.smartWidgetPublishSteps,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      smartWidgetContainer: smartWidgetContainer ?? this.smartWidgetContainer,
      smartWidgetUpdate: smartWidgetUpdate ?? this.smartWidgetUpdate,
      toggleDisplay: toggleDisplay ?? this.toggleDisplay,
      isOnboarding: isOnboarding ?? this.isOnboarding,
    );
  }
}
