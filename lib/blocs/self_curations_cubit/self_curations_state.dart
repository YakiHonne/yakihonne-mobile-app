// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'self_curations_cubit.dart';

class SelfCurationsState extends Equatable {
  final bool isActualUser;
  final bool isUserConnected;
  final List<Curation> curations;
  final bool isCurationsLoading;
  final String chosenRelay;
  final Set<String> relays;
  final bool curationAvailabilityToggle;
  final Map<String, int> relaysColors;
  final bool onRefresh;
  final bool isArticleCurations;

  SelfCurationsState({
    required this.isActualUser,
    required this.isUserConnected,
    required this.curations,
    required this.isCurationsLoading,
    required this.chosenRelay,
    required this.relays,
    required this.curationAvailabilityToggle,
    required this.relaysColors,
    required this.onRefresh,
    required this.isArticleCurations,
  });

  @override
  List<Object> get props => [
        isActualUser,
        isUserConnected,
        curations,
        isCurationsLoading,
        curationAvailabilityToggle,
        relaysColors,
        chosenRelay,
        relays,
        onRefresh,
        isArticleCurations,
      ];

  SelfCurationsState copyWith({
    bool? isActualUser,
    bool? isUserConnected,
    List<Curation>? curations,
    bool? isCurationsLoading,
    String? chosenRelay,
    Set<String>? relays,
    bool? curationAvailabilityToggle,
    Map<String, int>? relaysColors,
    bool? onRefresh,
    bool? isArticleCurations,
  }) {
    return SelfCurationsState(
      isActualUser: isActualUser ?? this.isActualUser,
      isUserConnected: isUserConnected ?? this.isUserConnected,
      curations: curations ?? this.curations,
      isCurationsLoading: isCurationsLoading ?? this.isCurationsLoading,
      chosenRelay: chosenRelay ?? this.chosenRelay,
      relays: relays ?? this.relays,
      curationAvailabilityToggle:
          curationAvailabilityToggle ?? this.curationAvailabilityToggle,
      relaysColors: relaysColors ?? this.relaysColors,
      onRefresh: onRefresh ?? this.onRefresh,
      isArticleCurations: isArticleCurations ?? this.isArticleCurations,
    );
  }
}
