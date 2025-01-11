import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:bloc/bloc.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
// import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/points_system_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/wallet_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/nostr/zaps/zap_action.dart';
import 'package:yakihonne/repositories/http_functions_repository.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_connect_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/app_cycle.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';

part 'lightning_zaps_state.dart';

class LightningZapsCubit extends Cubit<LightningZapsState>
    with WidgetsBindingObserver {
  LightningZapsCubit({
    required this.localDatabaseRepository,
    required this.nostrRepository,
  }) : super(
          LightningZapsState(
            zapsValues: defaultZaps,
            selectedIndex: -1,
            lnurl: '',
            isLnurlAvailable: false,
            isLoading: false,
            confirmPayment: false,
            invoices: {},
            toBeZappedValue: 0,
            userStatus: getUserStatus(),
            wallets: {},
            selectedWalletId: '',
            balance: -1,
            maxAmount: -1,
            defaultExternalWallet: '',
            transactions: [],
            searchResultsType: SearchResultsType.noSearch,
            shouldPopView: true,
            balanceInUSD: -1,
            isWalletHidden: false,
          ),
        ) {
    _userStatusStream = nostrRepository.userModelStream.listen(
      (user) {
        if (user == null) {
          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: UserStatus.notConnected,
              ),
            );
        } else {
          if (!isClosed)
            emit(
              state.copyWith(
                userStatus: user.isUsingPrivKey
                    ? UserStatus.UsingPrivKey
                    : UserStatus.UsingPubKey,
              ),
            );
        }
      },
    );
  }

  final NostrDataRepository nostrRepository;
  final LocalDatabaseRepository localDatabaseRepository;
  late StreamSubscription _sub;
  late StreamSubscription _userStatusStream;
  Map<String, List<WalletModel>> globalWallets = {};
  StreamSubscription? _appLifeCycle;
  List<ZapsToPoints> zapsToPoints = [];

  Set<String> requests = {};
  int index = -1;
  final _appLifecycleNotifier = AppLifecycleNotifier();

  static const NWC_GET_BALANCE = 'get_balance';
  static const NWC_PAY_INVOICE = 'pay_invoice';
  static const NWC_MULTI_PAY_INVOICE = 'multi_pay_invoice';
  static const NWC_TRANSACTIONS_LIST = 'list_transactions';
  static const NWC_MAKE_INVOICE = 'make_invoice';
  static const YAKIHONNE_NWC_LINK =
      'https://nwc.getalby.com/apps/new?c=Yakihonne';

  void deleteWalletConfiguration() {
    if (!isClosed)
      emit(
        LightningZapsState(
          zapsValues: defaultZaps,
          userStatus: getUserStatus(),
          selectedIndex: -1,
          lnurl: '',
          confirmPayment: false,
          isLnurlAvailable: false,
          isLoading: false,
          invoices: {},
          toBeZappedValue: 0,
          wallets: {},
          selectedWalletId: '',
          balance: -1,
          maxAmount: -1,
          defaultExternalWallet: '',
          transactions: [],
          searchResultsType: SearchResultsType.noSearch,
          shouldPopView: state.shouldPopView,
          balanceInUSD: -1,
          isWalletHidden: false,
        ),
      );
  }

  // ** init wallet cubit
  Future<void> init() async {
    final results = await Future.wait(
      [
        localDatabaseRepository.getZapsConfiguration(),
        localDatabaseRepository.getWallets(),
        localDatabaseRepository.getDefaultWallet(),
      ],
    );

    final zaps = results[0] as Map<String, Map<String, dynamic>>;
    final stringifiedWallets = results[1] as String;
    final defaultWallet = results[2] as String;

    String selectedWalletId = localDatabaseRepository.getSelectedWalletId();

    Map<String, WalletModel> wallets = {};

    if (stringifiedWallets.isNotEmpty) {
      final gw = jsonDecode(stringifiedWallets) as Map;

      for (final item in gw.entries) {
        globalWallets[item.key] = (item.value as List).map(
          (e) {
            if (e['kind'] == 1) {
              return NostrWalletConnectModel.fromMap(e);
            } else {
              return AlbyConnectModel.fromMap(e);
            }
          },
        ).toList();
      }

      final selectedWallets = globalWallets[nostrRepository.usm?.pubKey];

      if (selectedWallets != null && selectedWallets.isNotEmpty) {
        for (final w in selectedWallets) {
          wallets[w.id] = w;
        }
      }
    }

    if (selectedWalletId.isEmpty && wallets.isNotEmpty) {
      selectedWalletId = wallets.entries.first.key;
      localDatabaseRepository.setSelectedWalletId(wallets.entries.first.key);
    }

    final selectedWallet = wallets[selectedWalletId];

    if (selectedWallet != null) {
      if (selectedWallet is NostrWalletConnectModel) {
        requestNwcBalance(selectedWallet);
      } else {
        requestAlbyBalance(selectedWallet as AlbyConnectModel);
      }
    }

    emit(
      state.copyWith(
        selectedWalletId: selectedWalletId,
        wallets: wallets,
        zapsValues: zaps,
        defaultExternalWallet: defaultWallet,
      ),
    );
  }

  void switchWallets() {
    final selectedWallets = globalWallets[nostrRepository.usm?.pubKey];

    if (selectedWallets != null && selectedWallets.isNotEmpty) {
      Map<String, WalletModel> wallets = {};
      for (final w in selectedWallets) {
        wallets[w.id] = w;
      }

      emit(
        state.copyWith(
          wallets: wallets,
        ),
      );

      setSelectedWallet(
        wallets.entries.first.key,
        () {},
      );
    } else {
      emit(
        state.copyWith(
          wallets: {},
          selectedWalletId: '',
        ),
      );

      saveWalletsToSecureStorage();
    }
  }

  Future<void> initUniLinks() async {
    final _appLinks = AppLinks();

    _sub = _appLinks.uriLinkStream.listen((uri) {
      final stringifiedUri = uri.toString();
      final details = Uri.parse(stringifiedUri);

      if (details.scheme == 'nostr+walletconnect') {
        addNwc(stringifiedUri);
      } else if (stringifiedUri.contains('yakihonne.com/wallet/alby')) {
        if (stringifiedUri.contains('code')) {
          addAlby(stringifiedUri);
        } else {}
      }
    }, onError: (err) {
      Logger().i(err);
    });
  }

  // ** Wallet UI related functions
  void toggleWallet() {
    emit(
      state.copyWith(
        isWalletHidden: !state.isWalletHidden,
      ),
    );
  }

  void getWalletBalanceInUSD() {
    if (state.balance == -1) {
      emit(
        state.copyWith(
          balanceInUSD: -1,
        ),
      );
    } else {
      getSatsToUsd();
    }
  }

  void getSatsToUsd() async {
    final res = await HttpFunctionsRepository.get(
      'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd',
    );

    if (res != null) {
      final btcInUSD = (res['bitcoin']?['usd'] as num?) ?? -1;
      if (btcInUSD == -1) {
        emit(
          state.copyWith(
            balanceInUSD: -1,
          ),
        );
      } else {
        final availableBTC = state.balance / 100000000;

        emit(
          state.copyWith(
            balanceInUSD: availableBTC * btcInUSD,
          ),
        );
      }
    }
  }

  // ** handle default external wallet settings
  void setDefaultZapsValues() {
    localDatabaseRepository.setZaps(defaultZaps);

    if (!isClosed)
      emit(
        state.copyWith(
          zapsValues: defaultZaps,
        ),
      );
  }

  void updateZap({required int index, required Map<String, dynamic> value}) {
    final updatedZapsMap =
        Map<String, Map<String, dynamic>>.from(state.zapsValues);
    updatedZapsMap[index.toString()] = value;

    if (!isClosed)
      emit(
        state.copyWith(
          zapsValues: updatedZapsMap,
        ),
      );

    localDatabaseRepository.setZaps(updatedZapsMap);
  }

  void setDefaultWallet(String defaultWallet) {
    if (!isClosed)
      emit(
        state.copyWith(
          defaultExternalWallet: defaultWallet,
        ),
      );

    localDatabaseRepository.setDefaultWallet(defaultWallet);
  }

  // ** launch wallet deeplink
  void launchUrl(bool isNwc) async {
    try {
      launchUrlString(
        isNwc ? YAKIHONNE_NWC_LINK : getYakihonneAlbyApiLink(),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      Logger().i(e);
    }
  }

  String getYakihonneAlbyApiLink() {
    return 'https://getalby.com/oauth?client_id=${dotenv.env['CLIENT_ID']}&response_type=code&redirect_uri=$albyRedirectUri&scope=account:read%20invoices:create%20invoices:read%20transactions:read%20balance:read%20payments:send';
  }

// ** handle zap splits
  void resetInvoice() {
    _appLifeCycle?.cancel();
    _appLifeCycle = null;
    index = -1;
    zapsToPoints.clear();

    if (!isClosed)
      emit(
        state.copyWith(
          lnurl: '',
          isLnurlAvailable: false,
          selectedIndex: -1,
          confirmPayment: false,
          invoices: {},
          isLoading: false,
        ),
      );
  }

  void getInvoices({
    required num currentZapValue,
    required List<ZapSplit> zapSplits,
    required String comment,
    String? eventId,
    String? aTag,
  }) async {
    try {
      if (!isClosed)
        emit(
          state.copyWith(
            isLoading: true,
          ),
        );

      zapsToPoints.clear();
      List<Future<String?>> futures = zapSplits.map(
        (e) {
          final satsAmount = getspecificZapValue(
            currentZapValue: currentZapValue,
            zaps: zapSplits,
            currentZap: e,
          );

          final author = authorsCubit.state.authors[e.pubkey] ??
              emptyUserModel.copyWith(
                pubKey: e.pubkey,
                picturePlaceholder: getRandomPlaceholder(
                  input: e.pubkey,
                  isPfp: true,
                ),
              );

          zapsToPoints.add(
            ZapsToPoints(
              pubkey: author.pubKey,
              actionTimeStamp: currentUnixTimestampSeconds(),
              sats: satsAmount,
              eventId: eventId,
            ),
          );

          return ZapAction.genInvoiceCode(
            satsAmount,
            author,
            nostrRepository.usm!,
            nostrRepository.relays.toList(),
            eventId: eventId,
            aTag: aTag,
            comment: comment.isEmpty ? null : comment,
          );
        },
      ).toList();

      final res = await Future.wait(futures);

      Map<String, String?> invoices = {};

      for (int i = 0; i < zapSplits.length; i++) {
        invoices[zapSplits[i].pubkey] = res[i];
      }

      if (!isClosed)
        emit(
          state.copyWith(
            isLoading: false,
            isLnurlAvailable: true,
            invoices: invoices,
            toBeZappedValue: currentZapValue,
          ),
        );
    } catch (_) {
      lg.i(_);
    }
  }

  num getspecificZapValue({
    required num currentZapValue,
    required List<ZapSplit> zaps,
    required ZapSplit currentZap,
  }) {
    if (zaps.isEmpty) {
      return 0;
    }

    num total = 0;
    zaps.forEach((zap) {
      total += zap.percentage;
    });

    if (total == 0) {
      return 0;
    } else {
      return ((currentZap.percentage * 100 / total).round()) *
          currentZapValue /
          100;
    }
  }

  // ** wallets handling (add & delete)
  void verifyUri(String uri) {
    if (uri.isEmpty ||
        !uri.contains('nostr+walletconnect') ||
        !uri.contains('wss://relay.getalby.com')) {
      BotToastUtils.showError('Invalid pairing scret');
      return;
    }

    addNwc(uri);
  }

  Future<String?> checkAlbyWalletBeforeRequest({
    required AlbyConnectModel albyConnectModel,
  }) async {
    if ((currentUnixTimestampSeconds()) >
        (albyConnectModel.createdAt + albyConnectModel.expiry)) {
      final data = await HttpFunctionsRepository.handleAlbyApiToken(
        code: albyConnectModel.refreshToken,
        isRefreshing: true,
      );

      if (data.isNotEmpty) {
        final newAlbyConnetModel = albyConnectModel.copyWith(
          accessToken: data['token'],
          refreshToken: data['refreshToken'],
          expiry: data['expiresIn'],
          createAt: data['createdAt'],
        );

        final updateWallets = Map<String, WalletModel>.from(state.wallets);
        updateWallets[newAlbyConnetModel.id] = newAlbyConnetModel;

        emit(
          state.copyWith(
            wallets: updateWallets,
            selectedWalletId: newAlbyConnetModel.id,
          ),
        );

        globalWallets[nostrRepository.usm!.pubKey] =
            updateWallets.values.toList();
        saveWalletsToSecureStorage();
        return newAlbyConnetModel.accessToken;
      } else {
        BotToastUtils.showError('Error occured while refreshing the token');
        return null;
      }
    } else {
      return albyConnectModel.accessToken;
    }
  }

  void addAlby(String uri) async {
    final details = Uri.parse(uri);
    final code = details.queryParameters['code'];
    if (code != null) {
      final data = await HttpFunctionsRepository.handleAlbyApiToken(
        code: code,
        isRefreshing: false,
      );

      if (data.isNotEmpty) {
        final lud16 = await HttpFunctionsRepository.getAlbyLightningAddress(
          token: data['token'],
        );

        final albyConnetModel = AlbyConnectModel(
          id: Uuid().v4(),
          kind: AlbyConnectKind,
          lud16: lud16,
          accessToken: data['token'],
          refreshToken: data['refreshToken'],
          expiry: data['expiresIn'],
          createdAt: data['createdAt'],
        );

        final updateWallets = Map<String, WalletModel>.from(state.wallets);

        updateWallets[albyConnetModel.id] = albyConnetModel;

        emit(
          state.copyWith(
            wallets: updateWallets,
            selectedWalletId: albyConnetModel.id,
            shouldPopView: !state.shouldPopView,
          ),
        );

        globalWallets[nostrRepository.usm!.pubKey] =
            updateWallets.values.toList();

        saveWalletsToSecureStorage();
        requestAlbyBalance(albyConnetModel);
        getTransactions();
      } else {
        BotToastUtils.showError('Error occured while setting up the token');
      }
    }
  }

  void addNwc(String uri) async {
    final details = Uri.parse(uri);

    final walletPubKey = details.host;
    final relay = details.queryParameters['relay'];
    final secret = details.queryParameters['secret'];
    final lud16 = details.queryParameters['lud16'];

    final nostrWalletConnecModel = NostrWalletConnectModel(
      id: Uuid().v4(),
      kind: NostrWalletConnectKind,
      connectionString: uri,
      relay: relay ?? '',
      secret: secret ?? '',
      walletPubkey: walletPubKey,
      lud16: lud16 ?? '',
      permissions: [],
    );

    BotToastUtils.showSuccess(
      'Nostr wallet connect has been initialized',
    );

    emit(
      state.copyWith(
        shouldPopView: !state.shouldPopView,
      ),
    );

    getNwcInfos(nostrWalletConnecModel);
  }

  void setSelectedWallet(String walletId, Function() onSuccess) async {
    final selectedWallet = state.wallets[walletId];

    if (state.wallets[walletId] != null) {
      emit(
        state.copyWith(
          selectedWalletId: walletId,
        ),
      );

      if (selectedWallet!.kind == 1) {
        requestNwcBalance(selectedWallet as NostrWalletConnectModel);
      } else {
        requestAlbyBalance(selectedWallet as AlbyConnectModel);
      }

      getTransactions();
      saveWalletsToSecureStorage();
      onSuccess.call();
    }
  }

  void removeWallet(String walletId, Function() onSuccess) async {
    try {
      final updatedWallet = Map<String, WalletModel>.from(state.wallets);
      updatedWallet.remove(walletId);

      if (walletId == state.selectedWalletId) {
        if (updatedWallet.isEmpty) {
          emit(
            state.copyWith(
              wallets: {},
              selectedWalletId: '',
              balance: -1,
              balanceInUSD: -1,
              transactions: [],
              searchResultsType: SearchResultsType.noSearch,
            ),
          );
        } else {
          emit(
            state.copyWith(
              wallets: updatedWallet,
              selectedWalletId: updatedWallet.entries.first.key,
            ),
          );

          final selectedWallet = updatedWallet.entries.first.value;

          if (selectedWallet is NostrWalletConnectModel) {
            requestNwcBalance(selectedWallet);
          } else {
            requestAlbyBalance(selectedWallet as AlbyConnectModel);
          }

          getTransactions();
        }
      } else {
        emit(
          state.copyWith(
            wallets: updatedWallet,
          ),
        );
      }

      globalWallets[nostrRepository.usm!.pubKey] =
          updatedWallet.values.toList();
      saveWalletsToSecureStorage();
      onSuccess.call();
    } catch (e) {
      lg.i(e);
    }
  }

  // ** Wallet info
  void getNwcInfos(NostrWalletConnectModel nostrWalletConnectModel) async {
    await NostrConnect.sharedInstance
        .connect(nostrWalletConnectModel.relay)
        .then(
      (_) {
        final request = NostrConnect.sharedInstance.addSubscription(
          [
            Filter(
              kinds: [EventKind.NWC_INFO],
              authors: [nostrWalletConnectModel.walletPubkey],
            ),
          ],
          [nostrWalletConnectModel.relay],
          eventCallBack: (event, relay) {
            if (event.kind == EventKind.NWC_INFO) {
              final permissions = event.content.split(' ');
              final updateWallets =
                  Map<String, WalletModel>.from(state.wallets);

              updateWallets[nostrWalletConnectModel.id] =
                  nostrWalletConnectModel.copyWith(
                permissions: permissions,
              );

              emit(
                state.copyWith(
                  wallets: updateWallets,
                  selectedWalletId: nostrWalletConnectModel.id,
                ),
              );

              globalWallets[nostrRepository.usm!.pubKey] =
                  updateWallets.values.toList();

              saveWalletsToSecureStorage();
              requestNwcBalance(nostrWalletConnectModel);
              getTransactions();
            }
          },
          eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
            NostrConnect.sharedInstance.closeSubscription(requestId, relay);
          },
        );

        requests.add(request);
      },
    );
  }

  void saveWalletsToSecureStorage() {
    try {
      final updateGlobal = <String, List<dynamic>>{};

      for (final item in globalWallets.entries) {
        updateGlobal[item.key] = item.value.map((e) {
          if (e is AlbyConnectModel) {
            return e.toMap();
          } else if (e is NostrWalletConnectModel) {
            return e.toMap();
          }
        }).toList();
      }

      localDatabaseRepository.setUserWallets(jsonEncode(updateGlobal));
      localDatabaseRepository.setSelectedWalletId(state.selectedWalletId);
    } catch (e) {
      lg.i(e);
    }
  }

  // ** wallet transactions
  Future<void> getTransactions() async {
    if (state.selectedWalletId.isNotEmpty) {
      emit(
        state.copyWith(
          searchResultsType: SearchResultsType.loading,
          transactions: [],
        ),
      );

      final selectedWallet = state.wallets[state.selectedWalletId];
      if (selectedWallet is NostrWalletConnectModel) {
        final data = await requesNWCtData(
          '{"method":"$NWC_TRANSACTIONS_LIST","params" : {"limit": 50}}',
          selectedWallet,
        );

        if (data['result'] != null &&
            ((data['result']['transactions'] as List?)?.isNotEmpty ?? false) &&
            data['result_type'] == NWC_TRANSACTIONS_LIST) {
          final transactions = getNwcWalletTransactions(
            data['result']['transactions'],
          );

          emit(
            state.copyWith(
              transactions: transactions,
              searchResultsType: SearchResultsType.content,
            ),
          );
        }
      } else if (selectedWallet is AlbyConnectModel) {
        final token = await checkAlbyWalletBeforeRequest(
          albyConnectModel: selectedWallet,
        );

        if (token != null) {
          final transactions =
              await HttpFunctionsRepository.getAlbyTransactions(token: token);

          emit(
            state.copyWith(
              transactions: transactions,
              searchResultsType: SearchResultsType.content,
            ),
          );
        }
      } else {
        BotToastUtils.showError('Error while using wallet!');
        emit(
          state.copyWith(
            searchResultsType: SearchResultsType.content,
          ),
        );
      }
    }
  }

  Future<void> sendUsingLightningAddress({
    required String lightningAddress,
    required int sats,
    required String message,
    UserModel? user,
    required Function() onSuccess,
  }) async {
    if (sats == 0 ||
        (!lightningAddress.contains('@') &&
            !lightningAddress.startsWith('lnurl'))) {
      BotToastUtils.showError('Make sure you submit a valid data');
      return;
    }

    final invoice = await ZapAction.genInvoiceCode(
      sats,
      user != null
          ? user.copyWith(
              lud16: lightningAddress,
              lud06: lightningAddress,
            )
          : emptyUserModel.copyWith(
              lud16: lightningAddress,
              lud06: lightningAddress,
            ),
      nostrRepository.usm!,
      nostrRepository.relays.toList(),
      comment: message.isEmpty ? null : message,
      removeNostrEvent: user == null,
    );

    if (invoice == null) {
      BotToastUtils.showError('Error occured while generating invoice');
    } else {
      sendUsingInvoice(invoice: invoice, onSuccess: onSuccess);
    }
  }

  Future<void> sendUsingInvoice({
    required String invoice,
    required Function() onSuccess,
  }) async {
    if (invoice.isNotEmpty && invoice.startsWith('lnbc')) {
      if (state.selectedWalletId.isNotEmpty) {
        emit(
          state.copyWith(
            isLoading: true,
          ),
        );

        final selectedWallet = state.wallets[state.selectedWalletId];

        if (selectedWallet is NostrWalletConnectModel) {
          final data = await requesNWCtData(
            '{"method":"$NWC_PAY_INVOICE","params" : {"invoice": "$invoice"}}',
            selectedWallet,
          );

          if (data['result'] != null &&
              data['result']['preimage'] != null &&
              (data['result']['preimage'] as String).isNotEmpty) {
            BotToastUtils.showSuccess('Payment succeeded!');
            onSuccess.call();
          } else {
            BotToastUtils.showError('Payment failed!');
          }
        } else if (selectedWallet is AlbyConnectModel) {
          final token = await checkAlbyWalletBeforeRequest(
            albyConnectModel: selectedWallet,
          );
          if (token != null) {
            final data = await HttpFunctionsRepository.sendAlbyPayment(
              token: token,
              invoice: invoice,
            );

            if (data.isNotEmpty) {
              onSuccess.call();
            }
          }
        } else {
          BotToastUtils.showError('Error while using wallet!');
        }

        emit(
          state.copyWith(
            isLoading: false,
          ),
        );
      }
    } else {
      BotToastUtils.showError('Make sure you submit a valid invoice');
    }
  }

  Future<String?> makeInvoice({
    required int sats,
    required String message,
  }) async {
    if (sats == 0) {
      return null;
    }

    if (state.selectedWalletId.isNotEmpty) {
      emit(
        state.copyWith(
          isLoading: true,
        ),
      );

      final selectedWallet = state.wallets[state.selectedWalletId];

      if (selectedWallet is NostrWalletConnectModel) {
        final requestString = message.isEmpty
            ? '{"method":"$NWC_MAKE_INVOICE","params":{"amount":${sats * 1000}}}'
            : '{"method":"$NWC_MAKE_INVOICE","params":{"amount":${sats * 1000},"description":"$message"}}';

        final data = await requesNWCtData(requestString, selectedWallet);

        emit(
          state.copyWith(
            isLoading: false,
          ),
        );

        if (data['result'] != null && data['result_type'] == NWC_MAKE_INVOICE) {
          return data['result']['invoice'];
        }

        return null;
      } else if (selectedWallet is AlbyConnectModel) {
        final token = await checkAlbyWalletBeforeRequest(
          albyConnectModel: selectedWallet,
        );

        String? invoice;

        if (token != null) {
          invoice = await HttpFunctionsRepository.getAlbyInvoice(
            token: token,
            amount: sats,
            message: message,
          );
        }

        emit(
          state.copyWith(
            isLoading: false,
          ),
        );

        return invoice;
      } else {
        BotToastUtils.showError('Error while using wallet!');
        return null;
      }
    }

    return null;
  }

  Future<void> requestAlbyBalance(AlbyConnectModel albyConnectModel) async {
    final token = await checkAlbyWalletBeforeRequest(
      albyConnectModel: albyConnectModel,
    );

    if (token != null) {
      final balance = await HttpFunctionsRepository.getAlbyBalance(
        token: token,
      );

      if (balance >= 0) {
        emit(
          state.copyWith(
            balance: balance.toInt(),
            maxAmount: balance.toInt(),
          ),
        );

        getWalletBalanceInUSD();
      } else {
        emit(
          state.copyWith(
            balance: -1,
            maxAmount: -1,
          ),
        );
      }
    }
  }

  Future<void> requestNwcBalance(
    NostrWalletConnectModel nostrWalletConnectModel,
  ) async {
    final data = await requesNWCtData(
      '{"method":"get_balance"}',
      nostrWalletConnectModel,
    );

    if (data['result'] != null && data['result_type'] == NWC_GET_BALANCE) {
      emit(
        state.copyWith(
          balance: ((data['result']['balance'] / 1000) as num).toInt(),
          maxAmount: ((data['result']['max_amount'] / 1000) as num).toInt(),
        ),
      );

      getWalletBalanceInUSD();
    } else {
      emit(
        state.copyWith(
          balance: -1,
          maxAmount: -1,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> requesNWCtData(
    String request,
    NostrWalletConnectModel nostrWalletConnectModel,
  ) async {
    if (StringUtil.isNotBlank((nostrWalletConnectModel).walletPubkey) &&
        StringUtil.isNotBlank(nostrWalletConnectModel.relay) &&
        StringUtil.isNotBlank(nostrWalletConnectModel.secret)) {
      if (NostrConnect
              .sharedInstance.webSockets[nostrWalletConnectModel.relay] ==
          null) {
        await NostrConnect.sharedInstance
            .connect(nostrWalletConnectModel.relay);
      }

      var agreement = Nip4.getAgreement(nostrWalletConnectModel.secret);

      var encrypted = Nip4.encryptData(
        request,
        agreement,
        nostrWalletConnectModel.walletPubkey,
      );

      var tags = [
        ['p', nostrWalletConnectModel.walletPubkey]
      ];

      final event = Event.from(
        kind: EventKind.NWC_REQUEST,
        tags: tags,
        content: encrypted,
        privkey: nostrWalletConnectModel.secret,
      );

      return await getNWCData(event, nostrWalletConnectModel);
    } else {
      return {};
    }
  }

  Future<Map<String, dynamic>> getNWCData(
    Event toBeSentEvent,
    NostrWalletConnectModel nostrWalletConnectModel,
  ) async {
    final completer = Completer<Map<String, dynamic>>();

    final filter = Filter(
      kinds: [EventKind.NWC_RESPONSE],
      authors: [
        nostrWalletConnectModel.walletPubkey,
      ],
      p: [
        Keychain.getPublicKey(nostrWalletConnectModel.secret),
      ],
      e: [
        toBeSentEvent.id,
      ],
    );

    bool isDataProvided = false;
    Map<String, dynamic> data = {};

    final requestId = NostrConnect.sharedInstance.addSubscription(
      [filter],
      [nostrWalletConnectModel.relay],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.NWC_RESPONSE) {
          var agreement = Nip4.getAgreement(nostrWalletConnectModel.secret);

          final encryptedData = Nip4.decryptData(
            event.content,
            agreement,
            event.pubkey,
          );

          isDataProvided = true;
          data = jsonDecode(encryptedData);
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {},
    );

    NostrConnect.sharedInstance.sendEvent(
      toBeSentEvent,
      [nostrWalletConnectModel.relay],
      sendCallBack: (ok, relay, unCompletedRelays) {},
    );

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (timer.tick >= 10 || isDataProvided) {
        timer.cancel();
        closeConnections(
          requestId: requestId,
          relay: nostrWalletConnectModel.relay,
        );
        completer.complete(data);
      }
    });

    return completer.future;
  }

  // ** Close connections

  void closeConnections({String? requestId, required String relay}) {
    if (requestId != null) {
      NostrConnect.sharedInstance.closeRequests([requestId]);
    }

    NostrConnect.sharedInstance.closeConnect([relay]);
  }

  // ** handle zap splits
  void handleWalletZapSplit({
    required Function() onFinished,
  }) {
    if (state.selectedWalletId.isNotEmpty) {
      final selectedWallet = state.wallets[state.selectedWalletId];
      if (selectedWallet != null) {
        if (state.balance > 0 && state.toBeZappedValue > (state.balance)) {
          BotToastUtils.showError('Not enough balance to make this payment.');
          return;
        }

        if (state.maxAmount > 0 && state.toBeZappedValue > state.maxAmount) {
          BotToastUtils.showError(
            'Payment Surpasses the maximum amount allowed.',
          );

          return;
        }

        if (selectedWallet is NostrWalletConnectModel) {
          if (!selectedWallet.permissions.contains(NWC_PAY_INVOICE)) {
            BotToastUtils.showError(
              'Permission to pay invoices is not granted.',
            );
            return;
          }
        }

        handleInternalWalletZapSplit(
          onFinished: onFinished,
          walletModel: selectedWallet,
        );
      } else {
        BotToastUtils.showError(
          'Error while using wallet.',
        );
      }
    } else {
      index = 0;
      handleExternalWalleZapSplit(
        onFinished: onFinished,
      );
    }
  }

  void handleInternalWalletZapSplit({
    required Function() onFinished,
    required WalletModel walletModel,
  }) async {
    if (!isClosed)
      emit(
        state.copyWith(
          isLoading: true,
        ),
      );

    final invoices = state.invoices.values.toList();

    List<Map<String, dynamic>> invoicesList = [];

    if (walletModel is NostrWalletConnectModel) {
      for (int i = 0; i < invoices.length; i++) {
        final invoice = invoices[i];
        if (!StringUtil.isBlank(invoice)) {
          final data = await requesNWCtData(
            '{"method":"$NWC_PAY_INVOICE", "params": { "invoice": "$invoice"}}',
            walletModel,
          );

          invoicesList.add(data);
        }
      }
    } else {
      final token = await checkAlbyWalletBeforeRequest(
        albyConnectModel: walletModel as AlbyConnectModel,
      );

      if (token != null) {
        for (int i = 0; i < invoices.length; i++) {
          final invoice = invoices[i];
          if (!StringUtil.isBlank(invoice)) {
            final data = await HttpFunctionsRepository.sendAlbyPayment(
              token: token,
              invoice: invoice!,
            );

            if (data.isNotEmpty) {
              invoicesList.add(data);
            }
          }
        }
      }
    }

    bool partiallyBeenZapped = false;
    int paidInvoices = 0;

    if (invoicesList.isNotEmpty) {
      for (final resp in invoicesList) {
        if (walletModel is NostrWalletConnectModel) {
          if (resp.isNotEmpty &&
              resp['result'] != null &&
              resp['result']['preimage'] != null) {
            partiallyBeenZapped = true;
            paidInvoices++;
          }
        } else {
          if (resp.isNotEmpty &&
              resp['payment_preimage'] != null &&
              (resp['payment_preimage'] as String).isNotEmpty) {
            partiallyBeenZapped = true;
            paidInvoices++;
          }
        }
      }

      if (paidInvoices == invoices.length) {
        BotToastUtils.showSuccess('All the users have been zapped!');
        pointsManagementCubit.checkZapsToPoints(zapsToPoints: zapsToPoints);
      } else if (partiallyBeenZapped) {
        BotToastUtils.showWarning('Partial users are zapped!');
        pointsManagementCubit.checkZapsToPoints(zapsToPoints: zapsToPoints);
      } else {
        BotToastUtils.showError('No user has been zapped!');
      }
    } else {
      BotToastUtils.showError('Error occured while zapping users');
    }

    onFinished.call();

    if (!isClosed)
      emit(
        state.copyWith(
          isLoading: false,
        ),
      );
  }

  void handleExternalWalleZapSplit({
    required Function() onFinished,
  }) {
    if (state.defaultExternalWallet.isEmpty) {
      BotToastUtils.showError('Select a default wallet in the settings.');
      return;
    }

    if (!isClosed)
      emit(
        state.copyWith(
          isLoading: true,
        ),
      );

    final invoices = state.invoices.values.toList();
    for (int i = 0; i < invoices.length; i++) {
      if (!StringUtil.isBlank(invoices[i])) {
        index = i;
        break;
      }
    }

    if (index == -1) {
      BotToastUtils.showError('No invoices are available');
      emit(
        state.copyWith(
          isLoading: false,
        ),
      );
      return;
    }

    pointsManagementCubit.checkZapsToPoints(zapsToPoints: zapsToPoints);

    ZapAction.handleExternalZap(
      invoices[index],
      specifiedWallet: wallets[state.defaultExternalWallet]!['deeplink'],
    );

    _appLifeCycle = _appLifecycleNotifier.lifecycleStream.listen(
      (appState) {
        if (appState == AppLifecycleState.resumed) {
          if (index == (invoices.length - 1)) {
            index = -1;
            _appLifeCycle?.cancel();
            _appLifeCycle = null;
            emit(
              state.copyWith(
                isLoading: false,
              ),
            );

            BotToastUtils.showSuccess('Process has been completed');
            onFinished.call();
            return;
          } else {
            for (int i = index + 1; i < invoices.length; i++) {
              index = i;

              if (!StringUtil.isBlank(invoices[i])) {
                ZapAction.handleExternalZap(
                  invoices[index],
                  specifiedWallet:
                      wallets[state.defaultExternalWallet]!['deeplink'],
                );

                return;
              }
            }
          }
        }
      },
    );
  }

  // ** handle zap
  void handleWalletZapWithExternalInvoice({
    required String invoice,
  }) async {
    if (state.selectedWalletId.isNotEmpty) {
      final selectedWallet = state.wallets[state.selectedWalletId];
      if (selectedWallet != null) {
        final _cancel = BotToast.showLoading();
        if (selectedWallet is NostrWalletConnectModel) {
          final data = await requesNWCtData(
            '{"method":"$NWC_PAY_INVOICE","params" : {"invoice": "$invoice"}}',
            selectedWallet,
          );

          if (data.isNotEmpty &&
              data['result'] != null &&
              data['result']['preimage'] != null) {
            BotToastUtils.showSuccess(
              'Invoice has been paid successfuly',
            );
          } else {
            BotToastUtils.showError('Error occured while paying using invoice');
          }
        } else {
          final token = await checkAlbyWalletBeforeRequest(
            albyConnectModel: selectedWallet as AlbyConnectModel,
          );

          if (token != null) {
            final data = await HttpFunctionsRepository.sendAlbyPayment(
              token: token,
              invoice: invoice,
            );

            if (data.isNotEmpty) {
              BotToastUtils.showSuccess(
                'Invoice has been paid successfuly',
              );
            } else {
              BotToastUtils.showError(
                'Error occured while paying using invoice',
              );
            }
          }
        }

        _cancel.call();
      } else {
        BotToastUtils.showError(
          'Error while using wallet.',
        );
      }
    } else {
      try {
        await ZapAction.handleExternalZap(
          invoice,
          specifiedWallet: wallets[state.defaultExternalWallet]!['deeplink'],
        );
      } catch (_) {
        BotToastUtils.showError(
          'Error while using external wallet.',
        );
      }
    }
  }

  void handleWalletZap({
    required num sats,
    required UserModel user,
    required String comment,
    required Function(String) onFailure,
    required Function(String) onSuccess,
    required Function(String) onFinished,
    String? eventId,
    String? aTag,
    String? pollOption,
    String? invoice,
  }) {
    if (state.selectedWalletId.isNotEmpty) {
      final selectedWallet = state.wallets[state.selectedWalletId];
      if (selectedWallet != null) {
        if (sats > (state.balance)) {
          BotToastUtils.showError(
            'Not enough balance to make this payment.',
          );
          return;
        }

        if (state.maxAmount != 0 && sats > state.maxAmount) {
          BotToastUtils.showError(
            'Payment Surpasses the maximum amount allowed.',
          );
          return;
        }

        if (selectedWallet is NostrWalletConnectModel) {
          if (!selectedWallet.permissions.contains(NWC_PAY_INVOICE)) {
            BotToastUtils.showError(
              'Permission to pay invoices is not granted.',
            );
            return;
          }
        }

        handleInternalWalletZap(
          sats: sats,
          user: user,
          comment: comment,
          eventId: eventId,
          aTag: aTag,
          onFailure: onFailure,
          onSuccess: onSuccess,
          walletModel: selectedWallet,
          pollOption: pollOption,
        );
      } else {
        BotToastUtils.showError(
          'Error while using wallet.',
        );
      }
    } else {
      handleExternalWalletZap(
        sats: sats,
        user: user,
        comment: comment,
        eventId: eventId,
        onFailure: onFailure,
        onFinished: onFinished,
        pollOption: pollOption,
      );
    }
  }

  Future<void> handleInternalWalletZap({
    required num sats,
    required UserModel user,
    required String comment,
    required WalletModel walletModel,
    required Function(String) onFailure,
    required Function(String) onSuccess,
    String? eventId,
    String? aTag,
    String? pollOption,
    String? externalInvoice,
  }) async {
    emit(
      state.copyWith(
        isLoading: true,
      ),
    );

    final invoice = externalInvoice ??
        await ZapAction.genInvoiceCode(
          sats,
          user,
          nostrRepository.usm!,
          nostrRepository.relays.toList(),
          comment: comment.isEmpty ? null : comment,
          eventId: eventId,
          aTag: aTag,
          pollOption: pollOption,
        );

    if (invoice != null) {
      if (walletModel is NostrWalletConnectModel) {
        final data = await requesNWCtData(
          '{"method":"$NWC_PAY_INVOICE","params" : {"invoice": "$invoice"}}',
          walletModel,
        );

        if (data.isNotEmpty &&
            data['result'] != null &&
            data['result']['preimage'] != null) {
          pointsManagementCubit.sendZapsPoints(sats);
          onSuccess.call(data['result']['preimage']);
        } else {
          onFailure.call(
            data['error']['message'] ?? 'Error occured while sending sats',
          );
        }
      } else {
        final token = await checkAlbyWalletBeforeRequest(
          albyConnectModel: walletModel as AlbyConnectModel,
        );

        if (token != null) {
          final data = await HttpFunctionsRepository.sendAlbyPayment(
            token: token,
            invoice: invoice,
          );

          if (data.isNotEmpty) {
            pointsManagementCubit.sendZapsPoints(sats);
            onSuccess.call(data['payment_preimage']);
          } else {
            onFailure.call('Error occured while sending sats');
          }
        }
      }
    } else {
      BotToastUtils.showError('Error occured while generating invoice');
    }

    emit(
      state.copyWith(
        isLoading: false,
      ),
    );
  }

  void selectZapContainer(int index) {
    if (state.selectedIndex == index) {
      if (!isClosed)
        emit(
          state.copyWith(
            selectedIndex: -1,
          ),
        );
    } else {
      if (!isClosed)
        emit(
          state.copyWith(
            selectedIndex: index,
          ),
        );
    }
  }

  void handleExternalWalletZap({
    required num sats,
    required UserModel user,
    required String comment,
    required Function(String) onFailure,
    required Function(String) onFinished,
    String? eventId,
    String? aTag,
    String? pollOption,
    String? externalInvoice,
  }) async {
    if (state.defaultExternalWallet.isEmpty) {
      onFailure.call('Select a default wallet in the settings.');
      return;
    }

    if (!isClosed)
      emit(
        state.copyWith(
          isLoading: true,
        ),
      );

    await ZapAction.handleZap(
      sats,
      user,
      comment: comment.isEmpty ? null : comment,
      eventId: eventId,
      aTag: aTag,
      pollOption: pollOption,
      nostrRepository.usm!,
      nostrRepository.relays.toList(),
      specifiedWallet: wallets[state.defaultExternalWallet]!['deeplink'],
      onZapped: (invoice) {
        if (!isClosed)
          emit(
            state.copyWith(
              isLoading: false,
              confirmPayment: true,
            ),
          );

        pointsManagementCubit.checkZapsToPoints(
          zapsToPoints: [
            ZapsToPoints(
              pubkey: user.pubKey,
              actionTimeStamp: currentUnixTimestampSeconds(),
              sats: sats,
              eventId: eventId,
            ),
          ],
        );

        onFinished.call(invoice);
      },
    );
  }

  void generateZapInvoice({
    required int sats,
    required UserModel user,
    required String comment,
    required Function(String) onFailure,
    Function(String)? onSuccess,
    String? eventId,
    bool? removeNostrEvent,
  }) async {
    if (sats == 0) {
      BotToastUtils.showError('Set a sats amount greater than 0');
      return;
    }

    if (!isClosed)
      emit(
        state.copyWith(
          isLoading: true,
        ),
      );

    final code = await ZapAction.genInvoiceCode(
      sats,
      user,
      eventId: eventId,
      comment: comment.isEmpty ? null : comment,
      nostrRepository.usm!,
      nostrRepository.relays.toList(),
      removeNostrEvent: removeNostrEvent,
    );

    if (!isClosed)
      emit(
        state.copyWith(
          isLoading: false,
        ),
      );

    if (code == null) {
      onFailure.call('An error occured while generating invoice');
      return;
    }

    if (!isClosed)
      emit(
        state.copyWith(
          lnurl: code,
          isLnurlAvailable: true,
          confirmPayment: true,
        ),
      );

    pointsManagementCubit.checkZapsToPoints(
      zapsToPoints: [
        ZapsToPoints(
          pubkey: user.pubKey,
          actionTimeStamp: currentUnixTimestampSeconds(),
          sats: sats,
          eventId: eventId,
        ),
      ],
    );

    onSuccess?.call(code);
  }

  @override
  Future<void> close() {
    _sub.cancel();
    _userStatusStream.cancel();
    return super.close();
  }
}
