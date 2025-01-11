import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityRepository {
  ConnectivityRepository() {
    connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      hasConnection = result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi;
      connectionChangeController.sink.add(hasConnection);
    });
  }

  final connectivity = Connectivity();
  bool hasConnection = true;

  StreamController<bool> connectionChangeController =
      StreamController.broadcast();

  Stream<bool> get connectivityChangeStream =>
      connectionChangeController.stream;

  Future<bool> checkConnectionEnabled() async {
    var connectivityResult = await connectivity.checkConnectivity();
    hasConnection = connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi;
    return hasConnection;
  }

  Future<bool> checkInternetConnection() async {
    bool previousConnection = hasConnection;

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        hasConnection = true;
      } else {
        hasConnection = false;
      }
    } on SocketException catch (_) {
      hasConnection = false;
    }

    if (previousConnection != hasConnection) {
      connectionChangeController.add(hasConnection);
    }

    return hasConnection;
  }
}
