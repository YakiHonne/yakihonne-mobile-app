// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'self_smart_widgets_cubit.dart';

class SelfSmartWidgetsState extends Equatable {
  final UserStatus userStatus;
  final List<SmartWidgetModel> widgets;
  final bool isWidgetsLoading;
  final String chosenRelay;
  final Set<String> relays;

  SelfSmartWidgetsState({
    required this.userStatus,
    required this.widgets,
    required this.isWidgetsLoading,
    required this.chosenRelay,
    required this.relays,
  });

  @override
  List<Object> get props => [
        userStatus,
        widgets,
        isWidgetsLoading,
        chosenRelay,
        relays,
      ];

  SelfSmartWidgetsState copyWith({
    UserStatus? userStatus,
    List<SmartWidgetModel>? widgets,
    bool? isWidgetsLoading,
    String? chosenRelay,
    Set<String>? relays,
  }) {
    return SelfSmartWidgetsState(
      userStatus: userStatus ?? this.userStatus,
      widgets: widgets ?? this.widgets,
      isWidgetsLoading: isWidgetsLoading ?? this.isWidgetsLoading,
      chosenRelay: chosenRelay ?? this.chosenRelay,
      relays: relays ?? this.relays,
    );
  }
}
