// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'update_relays_cubit.dart';

class UpdateRelaysState extends Equatable {
  final List<String> relays;
  final List<String> activeRelays;
  final List<String> pendingRelays;
  final List<String> userRelays;
  final List<String> onlineRelays;
  final bool isSameRelays;

  UpdateRelaysState({
    required this.relays,
    required this.activeRelays,
    required this.pendingRelays,
    required this.userRelays,
    required this.onlineRelays,
    required this.isSameRelays,
  });

  @override
  List<Object> get props => [
        activeRelays,
        relays,
        isSameRelays,
        onlineRelays,
        activeRelays,
        pendingRelays,
        userRelays,
      ];

  UpdateRelaysState copyWith({
    List<String>? relays,
    List<String>? activeRelays,
    List<String>? pendingRelays,
    List<String>? userRelays,
    List<String>? onlineRelays,
    bool? isSameRelays,
  }) {
    return UpdateRelaysState(
      relays: relays ?? this.relays,
      activeRelays: activeRelays ?? this.activeRelays,
      pendingRelays: pendingRelays ?? this.pendingRelays,
      userRelays: userRelays ?? this.userRelays,
      onlineRelays: onlineRelays ?? this.onlineRelays,
      isSameRelays: isSameRelays ?? this.isSameRelays,
    );
  }
}
