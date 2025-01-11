// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'notifications_cubit.dart';

class NotificationsState extends Equatable {
  final List<Event> events;
  final int index;
  final bool isRead;
  final UserStatus userStatus;

  NotificationsState({
    required this.events,
    required this.index,
    required this.isRead,
    required this.userStatus,
  });

  @override
  List<Object> get props => [
        events,
        index,
        isRead,
        userStatus,
      ];

  NotificationsState copyWith({
    List<Event>? events,
    int? index,
    bool? isRead,
    UserStatus? userStatus,
  }) {
    return NotificationsState(
      events: events ?? this.events,
      index: index ?? this.index,
      isRead: isRead ?? this.isRead,
      userStatus: userStatus ?? this.userStatus,
    );
  }
}
