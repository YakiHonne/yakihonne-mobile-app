// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/lightning_zaps_cubit/lightning_zaps_cubit.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/wallet_balance_view/widgets/empty_wallets.dart';
import 'package:yakihonne/views/wallet_balance_view/widgets/user_to_zap_view.dart';
import 'package:yakihonne/views/wallet_balance_view/widgets/wallet_options_view.dart';
import 'package:yakihonne/views/widgets/custom_drop_down.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/modal_with_blur.dart';
import 'package:yakihonne/views/widgets/no_content_widgets.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class InternalWalletsView extends HookWidget {
  InternalWalletsView({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final gK = GlobalKey<FormFieldState>();
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final iwto = useState(InternalWalletTransactionOption.none);

    useMemoized(
      () {
        lightningZapsCubit.getTransactions();
        lightningZapsCubit.getWalletBalanceInUSD();
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      child: BlocBuilder<LightningZapsCubit, LightningZapsState>(
        builder: (context, state) {
          if (state.userStatus == UserStatus.notConnected) {
            return NotConnectedWidget();
          } else if (state.userStatus == UserStatus.UsingPubKey) {
            return NoPrivateWidget(
              title: 'Private key required!',
              description:
                  "It seems that you don't own this account, please reconnect with the secret key to commit actions on this account.",
              icon: PagesIcons.noPrivate,
              buttonText: 'Logout',
              onClicked: () {
                context.read<MainCubit>().disconnect();
              },
            );
          } else if (state.wallets.isEmpty) {
            return DisconnectedWallet();
          }

          return RefreshIndicator(
            onRefresh: () async {
              lightningZapsCubit.setSelectedWallet(
                state.selectedWalletId,
                () {},
              );
            },
            color: Theme.of(context).primaryColorDark,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 2,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select your wallet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        CustomIconButton(
                          onClicked: () {
                            showBlurredModal(
                              context: context,
                              view: WalletOptions(),
                            );
                          },
                          icon: FeatureIcons.addRaw,
                          size: 15,
                          backgroundColor: Theme.of(context).primaryColorLight,
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.wallets.isNotEmpty)
                  SliverToBoxAdapter(
                    child: WalletsCustomDropDown(
                      list: state.wallets.values.toList(),
                      defaultValue: state.selectedWalletId,
                      formKey: gK,
                      onDelete: (walletId) {
                        Navigator.pop(gK.currentContext!);

                        lightningZapsCubit.removeWallet(walletId, () {
                          gK.currentState?.reset();
                        });
                      },
                      onChanged: (walletId) {
                        lightningZapsCubit.setSelectedWallet(walletId ?? '',
                            () {
                          gK.currentState?.reset();
                        });
                      },
                    ),
                  ),
                WallatBalanceContainer(
                  setOption: (option) => iwto.value = option,
                ),
                Builder(
                  builder: (context) {
                    if (iwto.value == InternalWalletTransactionOption.none) {
                      return SliverToBoxAdapter();
                    } else if (iwto.value ==
                        InternalWalletTransactionOption.receive) {
                      return ReceiveInvoiceContainer(
                        resetIwto: () =>
                            iwto.value = InternalWalletTransactionOption.none,
                      );
                    } else {
                      return SendSatsContainer(
                        resetIwto: () =>
                            iwto.value = InternalWalletTransactionOption.none,
                      );
                    }
                  },
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                      Text(
                        'Recent transactions',
                        style:
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  color: kDimGrey,
                                ),
                      ),
                      SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                    ],
                  ),
                ),
                BlocBuilder<LightningZapsCubit, LightningZapsState>(
                  builder: (context, state) {
                    if (state.searchResultsType == SearchResultsType.loading) {
                      return SliverToBoxAdapter(
                        child: SpinKitFadingCircle(
                          color: Theme.of(context).primaryColorDark,
                          size: 20,
                        ),
                      );
                    } else if (state.searchResultsType ==
                        SearchResultsType.content) {
                      final ids = state.transactions;

                      if (ids.isEmpty) {
                        return SliverToBoxAdapter(
                          child: EmptyList(
                            description: 'No transactions can be found',
                            icon: FeatureIcons.zap,
                          ),
                        );
                      } else {
                        if (isTablet) {
                          return SliverGrid.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: kDefaultPadding / 2,
                              mainAxisSpacing: kDefaultPadding / 2,
                              mainAxisExtent: 75,
                            ),
                            itemBuilder: (context, index) {
                              final zap = state.transactions[index];

                              return InternalWalletZapContainer(zap: zap);
                            },
                            itemCount: state.transactions.length,
                          );
                        } else {
                          return SliverList.separated(
                            itemBuilder: (context, index) {
                              final zap = state.transactions[index];

                              return InternalWalletZapContainer(zap: zap);
                            },
                            itemCount: ids.length,
                            separatorBuilder: (context, index) => SizedBox(
                              height: kDefaultPadding / 2,
                            ),
                          );
                        }
                      }
                    } else {
                      return SliverToBoxAdapter(
                        child: Text(
                          'Select a wallet to obtain latest transactions.',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      );
                    }
                  },
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: kBottomNavigationBarHeight,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SendSatsContainer extends HookWidget {
  const SendSatsContainer({
    Key? key,
    required this.resetIwto,
  }) : super(key: key);

  final Function() resetIwto;

  @override
  Widget build(BuildContext context) {
    final messageController = useTextEditingController();
    final amountController = useTextEditingController();
    final invoiceController = useTextEditingController();
    final toggleSatsMode = useState(true);
    final userToZap = useState<UserModel?>(null);

    final searchAuthorFunc = useCallback(() {
      showModalBottomSheet(
        context: context,
        builder: (_) {
          return UserToZap(
            onUserSelected: (user) {
              userToZap.value = user;
              String la = (user.lud16.isNotEmpty ? user.lud16 : user.lud06)
                  .toLowerCase();

              if (la.contains("@") || la.startsWith('lnurl')) {
                invoiceController.text = la;
              }

              Navigator.pop(context);
            },
          );
        },
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    });

    return SliverToBoxAdapter(
      child: Column(
        children: [
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Send',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              CustomIconButton(
                onClicked: resetIwto,
                icon: FeatureIcons.closeRaw,
                size: 20,
                vd: -2,
                backgroundColor: Theme.of(context).primaryColorLight,
              ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding / 1.2),
              color: Theme.of(context).primaryColorLight,
            ),
            padding: const EdgeInsets.all(kDefaultPadding / 4),
            child: Row(
              children: [
                const SizedBox(
                  width: kDefaultPadding / 1.6,
                ),
                Expanded(
                  child: Text(
                    'Use invoice',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: CupertinoSwitch(
                    value: toggleSatsMode.value,
                    activeTrackColor: kOrangeContrasted,
                    onChanged: (val) {
                      toggleSatsMode.value = val;
                      userToZap.value = null;
                      invoiceController.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          TextFormField(
            controller: invoiceController,
            decoration: InputDecoration(
              hintText: toggleSatsMode.value ? 'Invoice' : 'Lightning address',
              hintStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: kDimGrey,
                  ),
            ),
          ),
          if (!toggleSatsMode.value) ...[
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            TextFormField(
              controller: amountController,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                hintText: 'Amount in sats',
                hintStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: kDimGrey,
                    ),
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            GestureDetector(
              onTap: searchAuthorFunc,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 1.2),
                  color: Theme.of(context).primaryColorLight,
                ),
                padding: const EdgeInsets.all(kDefaultPadding / 6),
                child: userToZap.value != null
                    ? Row(
                        children: [
                          const SizedBox(
                            width: kDefaultPadding / 1.6,
                          ),
                          ProfilePicture2(
                            size: 25,
                            image: userToZap.value!.picture,
                            placeHolder: userToZap.value!.picturePlaceholder,
                            padding: 0,
                            strokeWidth: 0,
                            reduceSize: true,
                            strokeColor: kTransparent,
                            onClicked: () {},
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 2,
                          ),
                          Expanded(
                            child: Text(
                              getAuthorDisplayName(userToZap.value!),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          CustomIconButton(
                            onClicked: () {
                              userToZap.value = null;
                              invoiceController.clear();
                            },
                            icon: FeatureIcons.closeRaw,
                            size: 20,
                            backgroundColor:
                                Theme.of(context).primaryColorLight,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const SizedBox(
                            width: kDefaultPadding / 1.6,
                          ),
                          Expanded(
                            child: Text(
                              'Select a user to zap (optional)',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          CustomIconButton(
                            onClicked: searchAuthorFunc,
                            icon: FeatureIcons.user,
                            size: 20,
                            backgroundColor:
                                Theme.of(context).primaryColorLight,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            TextFormField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'Message (optional)',
                hintStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: kDimGrey,
                    ),
              ),
            ),
          ],
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          BlocBuilder<LightningZapsCubit, LightningZapsState>(
            builder: (context, s) {
              return SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    final text = invoiceController.text.trim().toLowerCase();

                    if (toggleSatsMode.value) {
                      context.read<LightningZapsCubit>().sendUsingInvoice(
                            invoice: text,
                            onSuccess: () {
                              resetIwto.call();
                              context
                                  .read<LightningZapsCubit>()
                                  .getTransactions();
                            },
                          );
                    } else {
                      context
                          .read<LightningZapsCubit>()
                          .sendUsingLightningAddress(
                            lightningAddress: text,
                            sats: int.tryParse(amountController.text) ?? 0,
                            message: messageController.text,
                            onSuccess: () {
                              resetIwto.call();
                              context
                                  .read<LightningZapsCubit>()
                                  .getTransactions();
                            },
                          );
                    }
                  },
                  child: s.isLoading
                      ? SpinKitChasingDots(color: kWhite, size: 20)
                      : Text(
                          'Send',
                          style:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    color: kWhite,
                                  ),
                        ),
                  style: TextButton.styleFrom(
                    backgroundColor: kOrangeContrasted,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ReceiveInvoiceContainer extends HookWidget {
  const ReceiveInvoiceContainer({
    Key? key,
    required this.resetIwto,
  }) : super(key: key);

  final Function() resetIwto;

  @override
  Widget build(BuildContext context) {
    final messageController = useTextEditingController();
    final amountController = useTextEditingController();
    final invoice = useState('');
    final bool isDisabled = (nostrRepository.user.lud06.isEmpty &&
        nostrRepository.user.lud16.isEmpty);

    return SliverToBoxAdapter(
      child: Column(
        children: [
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Generate invoice',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              CustomIconButton(
                onClicked: resetIwto,
                icon: FeatureIcons.closeRaw,
                size: 20,
                vd: -2,
                backgroundColor: Theme.of(context).primaryColorLight,
              ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          TextFormField(
            controller: messageController,
            decoration: InputDecoration(
              hintText: 'Message (optional)',
              hintStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: kDimGrey,
                  ),
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          TextFormField(
            controller: amountController,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              hintText: 'Amount in sats',
              hintStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: kDimGrey,
                  ),
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          invoice.value.isNotEmpty
              ? Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                icon: PrettyQrView.data(
                                  data: invoice.value,
                                  decoration: PrettyQrDecoration(
                                    shape: PrettyQrRoundedSymbol(
                                      color:
                                          Theme.of(context).primaryColorLight,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  'Scan the QR code',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color:
                                            Theme.of(context).primaryColorLight,
                                      ),
                                ),
                                backgroundColor:
                                    Theme.of(context).primaryColorDark,
                              );
                            },
                          );
                        },
                        icon: SvgPicture.asset(
                          FeatureIcons.qr,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            kWhite,
                            BlendMode.srcIn,
                          ),
                        ),
                        label: Text(
                          'QR code',
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: kWhite,
                                  ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: kOrangeContrasted,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 4,
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            new ClipboardData(
                              text: invoice.value,
                            ),
                          );
                          BotToastUtils.showSuccess('Invoice code copied!');
                        },
                        icon: Icon(
                          Icons.copy,
                          color: kWhite,
                          size: 20,
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: kOrangeContrasted,
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Copy invoice',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(color: kWhite),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 4,
                    ),
                    CustomIconButton(
                      onClicked: () {
                        messageController.clear();
                        amountController.clear();
                        invoice.value = '';
                      },
                      icon: FeatureIcons.closeRaw,
                      size: 20,
                      iconColor: kWhite,
                      backgroundColor: kRed,
                    ),
                  ],
                )
              : BlocBuilder<LightningZapsCubit, LightningZapsState>(
                  builder: (context, s) {
                    return SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async {
                          if (isDisabled) {
                            BotToastUtils.showWarning(
                              'Ensure that your lightning address is well set',
                            );
                          } else {
                            final receivedInvoice =
                                await lightningZapsCubit.makeInvoice(
                              sats: int.tryParse(amountController.text) ?? 0,
                              message: messageController.text,
                            );

                            if (receivedInvoice != null) {
                              invoice.value = receivedInvoice;
                            } else {
                              BotToastUtils.showError(
                                'Error occured while generating invoice',
                              );
                            }
                          }
                        },
                        child: s.isLoading
                            ? SpinKitChasingDots(
                                color: kWhite,
                                size: 20,
                              )
                            : Text(
                                'Generate invoice',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(
                                      color: kWhite,
                                    ),
                              ),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              isDisabled ? kDimGrey : kOrangeContrasted,
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
        ],
      ),
    );
  }
}

class InternalWalletZapContainer extends HookWidget {
  const InternalWalletZapContainer({
    required this.zap,
  });

  final WalletTransactionModel zap;

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      authorsCubit.getAuthor(zap.pubkey);
    });

    final isMessageHidden = useState(true);

    return BlocBuilder<AuthorsCubit, AuthorsState>(
      builder: (context, state) {
        final user = state.authors[zap.pubkey] ??
            emptyUserModel.copyWith(
              pubKey: zap.pubkey,
              picturePlaceholder:
                  getRandomPlaceholder(input: zap.pubkey, isPfp: true),
            );

        return Container(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
            borderRadius: BorderRadius.circular(
              kDefaultPadding / 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        margin: zap.pubkey.isNotEmpty
                            ? const EdgeInsets.only(bottom: 5, right: 5)
                            : null,
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                        child: zap.pubkey.isNotEmpty
                            ? ProfilePicture2(
                                size: 50,
                                image: user.picture,
                                placeHolder: user.picturePlaceholder,
                                padding: 0,
                                strokeWidth: 0,
                                reduceSize: true,
                                strokeColor: kTransparent,
                                onClicked: () {
                                  openProfileFastAccess(
                                    context: context,
                                    pubkey: user.pubKey,
                                  );
                                },
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                ),
                                child: Center(
                                  child: Icon(
                                    zap.isIncoming
                                        ? CupertinoIcons.arrow_down_left
                                        : CupertinoIcons.arrow_up_right,
                                    color: zap.isIncoming ? kGreen : kRed,
                                    size: 25,
                                  ),
                                ),
                              ),
                      ),
                      if (zap.pubkey.isNotEmpty)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).scaffoldBackgroundColor,
                            ),
                            child: Center(
                              child: Icon(
                                zap.isIncoming
                                    ? CupertinoIcons.arrow_down_left
                                    : CupertinoIcons.arrow_up_right,
                                color: zap.isIncoming ? kGreen : kRed,
                                size: 15,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'On ${dateFormat4.format(zap.createdAt)}',
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: kDimGrey,
                                  ),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              if (zap.pubkey.isNotEmpty) ...[
                                TextSpan(
                                  text: getAuthorDisplayName(user),
                                  style:
                                      Theme.of(context).textTheme.labelLarge!,
                                ),
                                TextSpan(
                                  text: zap.isIncoming
                                      ? ' sent you '
                                      : ' received from you ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(
                                        color: kDimGrey,
                                      ),
                                ),
                                TextSpan(
                                  text: '${zap.amount.toStringAsFixed(0)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(
                                        color: kOrangeContrasted,
                                      ),
                                ),
                                TextSpan(
                                  text: ' Sats',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(
                                        color: kDimGrey,
                                      ),
                                ),
                              ] else ...[
                                TextSpan(
                                  text: zap.isIncoming
                                      ? 'You received '
                                      : 'You sent ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(
                                        color: kDimGrey,
                                      ),
                                ),
                                TextSpan(
                                  text: '${zap.amount.toStringAsFixed(0)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(
                                        color: kOrangeContrasted,
                                      ),
                                ),
                                TextSpan(
                                  text: ' Sats',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(
                                        color: kDimGrey,
                                      ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (zap.message.isNotEmpty) ...[
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    ),
                    CustomIconButton(
                      onClicked: () {
                        isMessageHidden.value = !isMessageHidden.value;
                      },
                      icon: FeatureIcons.messageNotif,
                      size: 20,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ]
                ],
              ),
              if (!isMessageHidden.value) ...[
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      kDefaultPadding / 2,
                    ),
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  padding: const EdgeInsets.all(kDefaultPadding / 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comment',
                        style:
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  color: kDimGrey,
                                ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 4,
                      ),
                      Text(
                        zap.message,
                        style:
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  color: Theme.of(context).primaryColorDark,
                                ),
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        );
      },
    );
  }
}

class WallatBalanceContainer extends StatelessWidget {
  const WallatBalanceContainer({
    Key? key,
    required this.setOption,
  }) : super(key: key);

  final Function(InternalWalletTransactionOption) setOption;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LightningZapsCubit, LightningZapsState>(
      builder: (context, state) {
        return SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff12c2e9),
                  Color(0xffc471ed),
                  Color(0xfff64f59),
                ],
              ),
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            ),
            padding: const EdgeInsets.all(1),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              ),
              padding: const EdgeInsets.all(kDefaultPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BALANCE',
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 8,
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${state.balance != -1 ? state.balance : 'N/A'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge!
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                      color: kOrangeContrasted,
                                    ),
                              ),
                            ),
                            const SizedBox(
                              width: kDefaultPadding / 3,
                            ),
                            SvgPicture.asset(
                              FeatureIcons.sats,
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 8,
                        ),
                        Row(
                          children: [
                            Text(
                              '~ \$${state.isWalletHidden ? '*****' : state.balanceInUSD == -1 ? 'N/A' : state.balanceInUSD.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              ' USD',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    color: kDimGrey,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: 120,
                        child: TextButton(
                          onPressed: () {
                            setOption
                                .call(InternalWalletTransactionOption.receive);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: kDimBgGrey,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Receive'),
                              const SizedBox(
                                width: kDefaultPadding / 8,
                              ),
                              Icon(
                                CupertinoIcons.arrow_down_left,
                                size: 15,
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                      SizedBox(
                        width: 120,
                        child: TextButton(
                          onPressed: () {
                            setOption
                                .call(InternalWalletTransactionOption.send);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: kOrangeContrasted,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Send'),
                              const SizedBox(
                                width: kDefaultPadding / 8,
                              ),
                              Icon(
                                CupertinoIcons.arrow_up_right,
                                size: 15,
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
