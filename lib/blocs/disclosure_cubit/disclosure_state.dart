// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'disclosure_cubit.dart';

class DisclosureState extends Equatable {
  final bool isAnalyticsEnabled;

  DisclosureState({
    required this.isAnalyticsEnabled,
  });

  @override
  List<Object> get props => [isAnalyticsEnabled];

  DisclosureState copyWith({
    bool? isAnalyticsEnabled,
  }) {
    return DisclosureState(
      isAnalyticsEnabled: isAnalyticsEnabled ?? this.isAnalyticsEnabled,
    );
  }
}
