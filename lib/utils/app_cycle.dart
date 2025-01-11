import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';

class YakihonneCycle with WidgetsBindingObserver {
  BuildContext buildContext;
  late AppLifecycleState _state;
  AppLifecycleState get state => _state;

  YakihonneCycle({required this.buildContext}) {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        {
          connecRelays();
          break;
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
    }
  }

  void connecRelays() {
    NostrConnect.sharedInstance.connectRelays(
      nostrRepository.relays.toList(),
      fromIdleState: true,
    );
  }
}

class AppLifecycleNotifier {
  final _lifecycleController = StreamController<AppLifecycleState>.broadcast();

  Stream<AppLifecycleState> get lifecycleStream => _lifecycleController.stream;

  AppLifecycleNotifier() {
    WidgetsBinding.instance.addObserver(AppLifecycleObserver(this));
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(AppLifecycleObserver(this));
    _lifecycleController.close();
  }
}

class AppLifecycleObserver extends WidgetsBindingObserver {
  final AppLifecycleNotifier _appLifecycleNotifier;

  AppLifecycleObserver(this._appLifecycleNotifier);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _appLifecycleNotifier._lifecycleController.add(state);
  }
}
