import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:yakihonne/models/app_client_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';

part 'app_clients_state.dart';

class AppClientsCubit extends Cubit<AppClientsState> {
  AppClientsCubit({
    required this.nostrRepository,
  }) : super(
          AppClientsState(
            appClients: {},
          ),
        );

  final NostrDataRepository nostrRepository;

  void getAppClient(
    String client,
  ) {
    try {
      if (client.startsWith(EventKind.APPLICATION_INFO.toString())) {
        final eventCoordinate = Nip33.getEventCoordinates(['a', client, '']);

        if (state.appClients[eventCoordinate.identifier] != null) {
          return;
        }

        Map<String, AppClientModel> appClients = state.appClients;

        NostrConnect.sharedInstance.addSubscription(
          [
            Filter(
              kinds: [EventKind.APPLICATION_INFO],
              d: [eventCoordinate.identifier],
            ),
          ],
          [],
          eventCallBack: (event, relay) {
            if (event.kind == EventKind.APPLICATION_INFO) {
              final appClient = AppClientModel.fromEvent(event);
              final oldAppClient = appClients[appClient.identifier];

              if (oldAppClient == null ||
                  oldAppClient.createdAt.compareTo(appClient.createdAt) < 1) {
                appClients[appClient.identifier] = appClient;
              }
            }
          },
          eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
            if (ok.status && appClients.isNotEmpty) {
              emit(
                state.copyWith(
                  appClients: appClients,
                ),
              );
            }
          },
        );
      }
    } catch (e) {
      Logger().i(e);
    }
  }

  void getYakiHonneApp() {
    Map<String, AppClientModel> appClients = state.appClients;

    NostrConnect.sharedInstance.addSubscription(
      [
        Filter(
          kinds: [EventKind.APPLICATION_INFO],
          authors: [yakihonneHex],
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.APPLICATION_INFO) {
          final appClient = AppClientModel.fromEvent(event);
          final oldAppClient = appClients[appClient.identifier];

          if (oldAppClient == null ||
              oldAppClient.createdAt.compareTo(appClient.createdAt) < 1) {
            appClients[appClient.identifier] = appClient;
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        if (ok.status && appClients.isNotEmpty) {
          emit(
            state.copyWith(
              appClients: appClients,
            ),
          );
        }
      },
    );
  }
}
