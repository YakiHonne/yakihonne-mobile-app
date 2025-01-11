// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'smart_widgets_cubit.dart';

class SmartWidgetsState extends Equatable {
  final List<SmartWidgetModel> widgets;
  final bool isLoading;
  final UpdatingState loadingState;
  final List<String> mutes;

  SmartWidgetsState({
    required this.widgets,
    required this.isLoading,
    required this.loadingState,
    required this.mutes,
  });

  @override
  List<Object> get props => [
        widgets,
        isLoading,
        loadingState,
        mutes,
      ];

  SmartWidgetsState copyWith({
    List<SmartWidgetModel>? widgets,
    bool? isLoading,
    UpdatingState? loadingState,
    List<String>? mutes,
  }) {
    return SmartWidgetsState(
      widgets: widgets ?? this.widgets,
      isLoading: isLoading ?? this.isLoading,
      loadingState: loadingState ?? this.loadingState,
      mutes: mutes ?? this.mutes,
    );
  }
}
