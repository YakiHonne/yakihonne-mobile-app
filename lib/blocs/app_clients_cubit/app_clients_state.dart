// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'app_clients_cubit.dart';

class AppClientsState extends Equatable {
  final Map<String, AppClientModel> appClients;

  AppClientsState({
    required this.appClients,
  });

  @override
  List<Object> get props => [appClients];

  AppClientsState copyWith({
    Map<String, AppClientModel>? appClients,
  }) {
    return AppClientsState(
      appClients: appClients ?? this.appClients,
    );
  }
}
