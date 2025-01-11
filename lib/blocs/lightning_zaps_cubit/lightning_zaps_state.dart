// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'lightning_zaps_cubit.dart';

class LightningZapsState extends Equatable {
  final Map<String, Map<String, dynamic>> zapsValues;
  final int selectedIndex;
  final String lnurl;
  final bool isLnurlAvailable;
  final bool isLoading;
  final bool confirmPayment;
  final Map<String, String?> invoices;
  final num toBeZappedValue;
  final UserStatus userStatus;
  final Map<String, WalletModel> wallets;
  final String selectedWalletId;
  final int balance;
  final num balanceInUSD;
  final bool isWalletHidden;
  final int maxAmount;
  final List<WalletTransactionModel> transactions;
  final String defaultExternalWallet;
  final SearchResultsType searchResultsType;
  final bool shouldPopView;

  LightningZapsState({
    required this.zapsValues,
    required this.selectedIndex,
    required this.lnurl,
    required this.isLnurlAvailable,
    required this.isLoading,
    required this.confirmPayment,
    required this.invoices,
    required this.toBeZappedValue,
    required this.userStatus,
    required this.wallets,
    required this.selectedWalletId,
    required this.balance,
    required this.balanceInUSD,
    required this.isWalletHidden,
    required this.maxAmount,
    required this.transactions,
    required this.defaultExternalWallet,
    required this.searchResultsType,
    required this.shouldPopView,
  });

  @override
  List<Object?> get props => [
        zapsValues,
        selectedIndex,
        lnurl,
        isLnurlAvailable,
        isLoading,
        confirmPayment,
        invoices,
        toBeZappedValue,
        userStatus,
        wallets,
        selectedWalletId,
        balance,
        maxAmount,
        transactions,
        defaultExternalWallet,
        searchResultsType,
        shouldPopView,
        balanceInUSD,
        isWalletHidden,
      ];

  LightningZapsState copyWith({
    Map<String, Map<String, dynamic>>? zapsValues,
    int? selectedIndex,
    String? lnurl,
    bool? isLnurlAvailable,
    bool? isLoading,
    bool? confirmPayment,
    Map<String, String?>? invoices,
    num? toBeZappedValue,
    UserStatus? userStatus,
    Map<String, WalletModel>? wallets,
    String? selectedWalletId,
    int? balance,
    num? balanceInUSD,
    bool? isWalletHidden,
    int? maxAmount,
    List<WalletTransactionModel>? transactions,
    String? defaultExternalWallet,
    SearchResultsType? searchResultsType,
    bool? shouldPopView,
  }) {
    return LightningZapsState(
      zapsValues: zapsValues ?? this.zapsValues,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      lnurl: lnurl ?? this.lnurl,
      isLnurlAvailable: isLnurlAvailable ?? this.isLnurlAvailable,
      isLoading: isLoading ?? this.isLoading,
      confirmPayment: confirmPayment ?? this.confirmPayment,
      invoices: invoices ?? this.invoices,
      toBeZappedValue: toBeZappedValue ?? this.toBeZappedValue,
      userStatus: userStatus ?? this.userStatus,
      wallets: wallets ?? this.wallets,
      selectedWalletId: selectedWalletId ?? this.selectedWalletId,
      balance: balance ?? this.balance,
      balanceInUSD: balanceInUSD ?? this.balanceInUSD,
      isWalletHidden: isWalletHidden ?? this.isWalletHidden,
      maxAmount: maxAmount ?? this.maxAmount,
      transactions: transactions ?? this.transactions,
      defaultExternalWallet:
          defaultExternalWallet ?? this.defaultExternalWallet,
      searchResultsType: searchResultsType ?? this.searchResultsType,
      shouldPopView: shouldPopView ?? this.shouldPopView,
    );
  }
}
