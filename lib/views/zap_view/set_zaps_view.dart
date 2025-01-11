// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:numeral/numeral.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/lightning_zaps_cubit/lightning_zaps_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/properties_view/widgets/zaps_configurations.dart';
import 'package:yakihonne/views/wallet_balance_view/widgets/wallet_options_view.dart';
import 'package:yakihonne/views/widgets/custom_drop_down.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/modal_with_blur.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class SetZapsView extends HookWidget {
  final bool isZapSplit;
  final UserModel author;
  final List<ZapSplit> zapSplits;
  final String? lnbc;
  final String? eventId;
  final String? aTag;
  final String? pollOption;
  final Function()? onSuccess;
  final num? valMax;
  final num? valMin;

  SetZapsView({
    required this.isZapSplit,
    required this.author,
    required this.zapSplits,
    this.eventId,
    this.aTag,
    this.pollOption,
    this.onSuccess,
    this.valMax,
    this.valMin,
    this.lnbc,
  }) {
    authorsCubit.getAuthors(zapSplits.map((e) => e.pubkey).toList());
  }

  final _formKey = GlobalKey<FormState>();
  final gK = GlobalKey<FormFieldState>();

  @override
  Widget build(BuildContext context) {
    final isWalletListCollapsed = useState(true);
    final commentTextEditingController = useTextEditingController();
    final valueTextController = useTextEditingController(
      text: valMin != null && valMin != -1 ? valMin.toString() : '0',
    );

    final val = useState(
      valMin != null && valMin != -1 ? valMin.toString() : '0',
    );

    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final pageController = usePageController(
      viewportFraction: isTablet ? 1 / 2 : 0.90,
    );

    useEffect(
      () {
        return () {
          lightningZapsCubit.resetInvoice();
        };
      },
      [],
    );

    return BlocBuilder<LightningZapsCubit, LightningZapsState>(
      builder: (context, state) {
        return Container(
          padding: MediaQuery.of(context).viewInsets.copyWith(
                left: kDefaultPadding / 2,
                right: kDefaultPadding / 2,
              ),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(kDefaultPadding),
              topRight: Radius.circular(kDefaultPadding),
            ),
          ),
          height: lnbc == null
              ? isTablet
                  ? 60.h
                  : 90.h
              : isTablet
                  ? 40.h
                  : 40.h,
          child: SafeArea(
            child: Column(
              children: [
                Center(
                  child: ModalBottomSheetHandle(),
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Expanded(
                  child: ListView(
                    physics: ClampingScrollPhysics(),
                    padding:
                        EdgeInsets.symmetric(horizontal: isTablet ? 10.w : 0),
                    children: [
                      if (isZapSplit)
                        Text(
                          'Zap splits',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  ProfilePicture2(
                                    size: 55,
                                    image: nostrRepository.user.picture,
                                    placeHolder:
                                        nostrRepository.user.picturePlaceholder,
                                    padding: 0,
                                    strokeWidth: 0,
                                    strokeColor: kTransparent,
                                    onClicked: () {},
                                  ),
                                  const SizedBox(
                                    height: kDefaultPadding / 2,
                                  ),
                                  Text(
                                    getAuthorName(nostrRepository.user),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: kDimGrey,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (author.pubKey.isNotEmpty) ...[
                              Expanded(child: ArrowAnimation()),
                              Expanded(
                                child: Column(
                                  children: [
                                    ProfilePicture2(
                                      size: 55,
                                      image: author.picture,
                                      placeHolder: author.picturePlaceholder,
                                      padding: 0,
                                      strokeWidth: 0,
                                      strokeColor: kTransparent,
                                      onClicked: () {},
                                    ),
                                    const SizedBox(
                                      height: kDefaultPadding / 2,
                                    ),
                                    Text(
                                      getAuthorName(author),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall!
                                          .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: kDimGrey,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ]
                          ],
                        ),
                      if (state.wallets.isNotEmpty) ...[
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        WalletsCustomDropDown(
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
                            lightningZapsCubit.setSelectedWallet(
                              walletId ?? '',
                              () {
                                gK.currentState?.reset();
                              },
                            );
                          },
                        ),
                      ] else ...[
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        ExternalWalletContainer(
                          isWalletListCollapsed: isWalletListCollapsed,
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding / 2),
                            color: Theme.of(context).primaryColorLight,
                          ),
                          padding: const EdgeInsets.all(kDefaultPadding / 2),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  SizedBox(
                                    height: 28,
                                    width: 50,
                                  ),
                                  Positioned(
                                    right: 2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: SvgPicture.asset(
                                        FeatureIcons.alby,
                                        width: 25,
                                        height: 25,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: SvgPicture.asset(
                                      FeatureIcons.nwc,
                                      width: 25,
                                      height: 25,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                width: kDefaultPadding / 2,
                              ),
                              Expanded(child: Text('Add wallet')),
                              CustomIconButton(
                                onClicked: () {
                                  showBlurredModal(
                                    context: context,
                                    view: WalletOptions(),
                                  );
                                },
                                icon: FeatureIcons.add,
                                size: 15,
                                vd: -2,
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (lnbc == null) ...[
                        const SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            controller: valueTextController,
                            onChanged: (value) {
                              valueTextController.text = value;
                              val.value = value;
                            },
                            decoration: InputDecoration(
                              suffixText: 'SATS',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (sats) {
                              final sts = int.tryParse(sats ?? '');

                              if (sts == null || sts == 0) {
                                valueTextController.text = '0';
                                val.value = '0';
                                return 'A minimum amount of 1 is required';
                              }

                              final checkMax = (valMax != null &&
                                  valMax != -1 &&
                                  sts > valMax!);

                              final checkMin = valMin != null &&
                                  valMin != -1 &&
                                  sts < valMin!;

                              if (checkMax || checkMin) {
                                valueTextController.text = '0';
                                val.value = '0';
                                return 'The value should be between the min and max sats amount';
                              }

                              return null;
                            },
                          ),
                        ),
                      ],
                      if (valMax != null || valMin != null) ...[
                        SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ValSatsContainer(
                                onClicked: () {
                                  valueTextController.text = valMin.toString();
                                  val.value = valMin.toString();
                                },
                                isSelected: int.tryParse(val.value) == valMin,
                                title: 'Min sats',
                                val: valMin == -1
                                    ? 'N/A'
                                    : valMin!.toStringAsFixed(0),
                              ),
                            ),
                            SizedBox(
                              width: kDefaultPadding / 2,
                            ),
                            Expanded(
                              child: ValSatsContainer(
                                onClicked: () {
                                  valueTextController.text = valMax.toString();
                                  val.value = valMax.toString();
                                },
                                isSelected: int.tryParse(val.value) == valMax,
                                title: 'Max sats',
                                val: valMax == -1
                                    ? 'N/A'
                                    : valMax!.toStringAsFixed(0),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                      ],
                      if (lnbc == null && pollOption == null) ...[
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          primary: false,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                          ),
                          itemBuilder: (context, index) {
                            return SetZapContainer(
                              index: index,
                              isSelected: state.selectedIndex == index,
                              onTap: () {
                                if (state.selectedIndex == index) {
                                  valueTextController.text = '0';
                                  val.value = '0';
                                } else {
                                  valueTextController.text = state
                                      .zapsValues[index.toString()]!['value'];
                                  val.value = state
                                      .zapsValues[index.toString()]!['value'];
                                }

                                context
                                    .read<LightningZapsCubit>()
                                    .selectZapContainer(index);
                              },
                            );
                          },
                          itemCount: 8,
                        ),
                        const SizedBox(height: kDefaultPadding),
                        Padding(
                          padding: const EdgeInsets.all(kDefaultPadding / 4),
                          child: TextField(
                            controller: commentTextEditingController,
                            decoration: InputDecoration(
                              hintText: 'Write a comment (optional)',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  commentTextEditingController.clear();
                                },
                                icon: Icon(Icons.close),
                              ),
                            ),
                          ),
                        ),
                        if (isZapSplit) ...[
                          const SizedBox(height: kDefaultPadding),
                          SizedBox(
                            height: 140,
                            child: PageView.builder(
                              controller: pageController,
                              itemBuilder: (context, index) {
                                final zap = zapSplits[index];

                                return BlocBuilder<AuthorsCubit, AuthorsState>(
                                  builder: (context, authorState) {
                                    final author =
                                        authorState.authors[zap.pubkey] ??
                                            emptyUserModel.copyWith(
                                              pubKey: zap.pubkey,
                                              picturePlaceholder:
                                                  getRandomPlaceholder(
                                                input: zap.pubkey,
                                                isPfp: true,
                                              ),
                                            );

                                    return Container(
                                      padding: const EdgeInsets.all(
                                        kDefaultPadding / 2,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: kDefaultPadding / 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            Theme.of(context).primaryColorLight,
                                        borderRadius: BorderRadius.circular(
                                            kDefaultPadding),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ProfilePicture2(
                                                size: 25,
                                                image: author.picture,
                                                placeHolder:
                                                    author.picturePlaceholder,
                                                padding: 0,
                                                strokeWidth: 1,
                                                strokeColor: kPurple,
                                                onClicked: () {},
                                              ),
                                              const SizedBox(
                                                width: kDefaultPadding / 2,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Split zaps with',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall!
                                                          .copyWith(
                                                            color: kDimGrey,
                                                          ),
                                                    ),
                                                    Text(
                                                      getAuthorName(author),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall!
                                                          .copyWith(
                                                            color: kRed,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '${getspecificZapValue(
                                                  currentZapValue: num.tryParse(
                                                        val.value,
                                                      ) ??
                                                      0,
                                                  zaps: zapSplits,
                                                  currentZap: zap,
                                                ).toString()} Sats',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium!
                                                    .copyWith(
                                                      color: kOrange,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: kDefaultPadding / 2,
                                          ),
                                          if (!author.canBeZapped())
                                            Text(
                                              'This user cannot be zapped',
                                            )
                                          else
                                            Builder(builder: (context) {
                                              if (!state.isLnurlAvailable) {
                                                return Text(
                                                  'Waiting for the generation of invoices.',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                );
                                              } else if (state
                                                      .invoices[zap.pubkey] !=
                                                  null) {
                                                final invoice =
                                                    state.invoices[zap.pubkey]!;
                                                return Column(
                                                  children: [
                                                    Text(
                                                      'An invoice for ${getAuthorName(author)} has been generated',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelMedium!,
                                                    ),
                                                    const SizedBox(
                                                      height:
                                                          kDefaultPadding / 2,
                                                    ),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child:
                                                              TextButton.icon(
                                                            onPressed: () {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) {
                                                                  return AlertDialog(
                                                                    icon: PrettyQrView
                                                                        .data(
                                                                      data:
                                                                          invoice,
                                                                      decoration:
                                                                          PrettyQrDecoration(
                                                                        shape:
                                                                            PrettyQrRoundedSymbol(
                                                                          color:
                                                                              Theme.of(context).primaryColorLight,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    title: Text(
                                                                      'Scan the QR code',
                                                                      style: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .bodyMedium!
                                                                          .copyWith(
                                                                            color:
                                                                                Theme.of(context).primaryColorLight,
                                                                          ),
                                                                    ),
                                                                    backgroundColor:
                                                                        Theme.of(context)
                                                                            .primaryColorDark,
                                                                  );
                                                                },
                                                              );
                                                            },
                                                            icon: SvgPicture
                                                                .asset(
                                                              FeatureIcons.qr,
                                                              width: 20,
                                                              height: 20,
                                                              colorFilter:
                                                                  ColorFilter
                                                                      .mode(
                                                                Theme.of(
                                                                        context)
                                                                    .scaffoldBackgroundColor,
                                                                BlendMode.srcIn,
                                                              ),
                                                            ),
                                                            label: Text(
                                                              'QR code',
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .labelMedium!
                                                                  .copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .scaffoldBackgroundColor,
                                                                  ),
                                                            ),
                                                            style: TextButton
                                                                .styleFrom(
                                                              backgroundColor:
                                                                  Theme.of(
                                                                          context)
                                                                      .primaryColorDark,
                                                              visualDensity:
                                                                  VisualDensity(
                                                                horizontal: -2,
                                                                vertical: -2,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width:
                                                              kDefaultPadding /
                                                                  2,
                                                        ),
                                                        Expanded(
                                                          child: TextButton(
                                                            onPressed: () {
                                                              Clipboard.setData(
                                                                new ClipboardData(
                                                                  text: invoice,
                                                                ),
                                                              );

                                                              singleSnackBar(
                                                                context:
                                                                    context,
                                                                message:
                                                                    'Invoice code copied!',
                                                                color: kGreen,
                                                                backGroundColor:
                                                                    kGreenSide,
                                                                icon: ToastsIcons
                                                                    .success,
                                                              );
                                                            },
                                                            style: TextButton
                                                                .styleFrom(
                                                              backgroundColor:
                                                                  Theme.of(
                                                                          context)
                                                                      .primaryColorDark,
                                                              visualDensity:
                                                                  VisualDensity(
                                                                horizontal: -2,
                                                                vertical: -2,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              'Copy invoice',
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .labelMedium!
                                                                  .copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .scaffoldBackgroundColor,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                );
                                              } else {
                                                return Text(
                                                  'Could not create an invoice for this user.',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                );
                                              }
                                            })
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              itemCount: zapSplits.length,
                            ),
                          ),
                        ],
                      ]
                    ],
                  ),
                ),
                if (lnbc != null)
                  Builder(
                    builder: (context) {
                      double amount = -1;

                      try {
                        final req = Bolt11PaymentRequest(lnbc!);

                        amount = (req.amount.toDouble() * 100000000)
                            .round()
                            .toDouble();
                      } catch (_) {}

                      return SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            lightningZapsCubit
                                .handleWalletZapWithExternalInvoice(
                              invoice: lnbc!,
                            );
                          },
                          child: Text(
                              'Pay ${amount == -1 ? 'N/A' : amount.toStringAsFixed(0)} sats'),
                        ),
                      );
                    },
                  )
                else if (isZapSplit)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 4,
                      horizontal: isTablet ? 10.w : 0,
                    ),
                    child: Builder(builder: (context) {
                      if (!state.isLnurlAvailable) {
                        return SizedBox(
                          width: double.infinity,
                          child: AbsorbPointer(
                            absorbing: state.isLoading,
                            child: TextButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  context
                                      .read<LightningZapsCubit>()
                                      .getInvoices(
                                        currentZapValue: num.parse(
                                          val.value,
                                        ),
                                        zapSplits: zapSplits,
                                        comment:
                                            commentTextEditingController.text,
                                        eventId: eventId,
                                        aTag: aTag,
                                      );
                                }
                              },
                              child: state.isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: kWhite,
                                      ),
                                    )
                                  : Text('Generate invoices'),
                            ),
                          ),
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: AbsorbPointer(
                                absorbing: state.isLoading,
                                child: TextButton.icon(
                                  onPressed: () {
                                    context
                                        .read<LightningZapsCubit>()
                                        .handleWalletZapSplit(
                                      onFinished: () {
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                  icon: state.isLoading
                                      ? const SizedBox.shrink()
                                      : SvgPicture.asset(
                                          FeatureIcons.zaps,
                                          width: 25,
                                          height: 25,
                                          colorFilter: ColorFilter.mode(
                                            kWhite,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                  label: state.isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: kWhite,
                                          ),
                                        )
                                      : Text('Zap'),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                context
                                    .read<LightningZapsCubit>()
                                    .resetInvoice();
                              },
                              icon: Icon(Icons.close_rounded),
                            ),
                          ],
                        );
                      }
                    }),
                  )
                else
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 4,
                      horizontal: isTablet ? 10.w : 0,
                    ),
                    child: Builder(builder: (context) {
                      if (!state.isLnurlAvailable) {
                        return SizedBox(
                          width: double.infinity,
                          child: Row(
                            children: [
                              Expanded(
                                child: AbsorbPointer(
                                  absorbing: state.isLoading,
                                  child: TextButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        context
                                            .read<LightningZapsCubit>()
                                            .generateZapInvoice(
                                              sats: int.parse(
                                                val.value,
                                              ),
                                              user: author,
                                              comment:
                                                  commentTextEditingController
                                                      .text,
                                              eventId: eventId,
                                              onFailure: (message) {
                                                singleSnackBar(
                                                  context: context,
                                                  message: message,
                                                  color: kRed,
                                                  backGroundColor: kRedSide,
                                                  icon: ToastsIcons.error,
                                                );
                                              },
                                            );
                                      }
                                    },
                                    child: state.isLoading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: kWhite,
                                            ),
                                          )
                                        : Text('Get invoice'),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: kDefaultPadding / 4,
                              ),
                              Expanded(
                                child: AbsorbPointer(
                                  absorbing: state.isLoading,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        final amount = int.parse(
                                          val.value,
                                        );

                                        context
                                            .read<LightningZapsCubit>()
                                            .handleWalletZap(
                                              sats: amount,
                                              user: author,
                                              eventId: eventId,
                                              aTag: aTag,
                                              pollOption: pollOption,
                                              comment:
                                                  commentTextEditingController
                                                      .text,
                                              onFinished: (ok) {
                                                Navigator.pop(context);
                                              },
                                              onSuccess: (preimage) {
                                                singleSnackBar(
                                                  context: context,
                                                  message:
                                                      'User was zapped successfuly',
                                                  color: kGreen,
                                                  backGroundColor: kGreenSide,
                                                  icon: ToastsIcons.success,
                                                );
                                                onSuccess?.call();
                                                Navigator.pop(context);
                                              },
                                              onFailure: (message) {
                                                singleSnackBar(
                                                  context: context,
                                                  message: message,
                                                  color: kRed,
                                                  backGroundColor: kRedSide,
                                                  icon: ToastsIcons.error,
                                                );
                                              },
                                            );
                                      }
                                    },
                                    icon: state.isLoading
                                        ? const SizedBox.shrink()
                                        : SvgPicture.asset(
                                            FeatureIcons.zaps,
                                            width: 25,
                                            height: 25,
                                            colorFilter: ColorFilter.mode(
                                              kWhite,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                    label: state.isLoading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: kWhite,
                                            ),
                                          )
                                        : Text('Zap'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Column(
                          children: [
                            DottedCopyContainer(
                              lnurl: state.lnurl,
                            ),
                            const SizedBox(
                              height: kDefaultPadding / 2,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            icon: PrettyQrView.data(
                                              data: state.lnurl,
                                              decoration: PrettyQrDecoration(
                                                shape: PrettyQrRoundedSymbol(
                                                  color: Theme.of(context)
                                                      .primaryColorLight,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              'Scan the QR code',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .copyWith(
                                                    color: Theme.of(context)
                                                        .primaryColorLight,
                                                  ),
                                            ),
                                            backgroundColor: Theme.of(context)
                                                .primaryColorDark,
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
                                    label: Text('QR code'),
                                  ),
                                ),
                                const SizedBox(
                                  width: kDefaultPadding / 2,
                                ),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(
                                        new ClipboardData(text: state.lnurl),
                                      );

                                      singleSnackBar(
                                        context: context,
                                        message: 'Invoice code copied!',
                                        color: kGreen,
                                        backGroundColor: kGreenSide,
                                        icon: ToastsIcons.success,
                                      );
                                    },
                                    icon: SvgPicture.asset(
                                      FeatureIcons.copy,
                                      width: 25,
                                      height: 25,
                                      colorFilter: ColorFilter.mode(
                                        kWhite,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    label: Text('Copy'),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    context
                                        .read<LightningZapsCubit>()
                                        .resetInvoice();
                                  },
                                  icon: Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    }),
                  ),
              ],
            ),
          ),
        );
      },
    );
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
}

class ValSatsContainer extends StatelessWidget {
  const ValSatsContainer({
    Key? key,
    required this.val,
    required this.isSelected,
    required this.title,
    required this.onClicked,
  }) : super(key: key);

  final String val;
  final bool isSelected;
  final String title;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: val == 'N/A' ? null : onClicked,
      child: Container(
        padding: const EdgeInsets.all(
          kDefaultPadding / 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          border: Border.all(
            color:
                isSelected ? Theme.of(context).primaryColorDark : kTransparent,
          ),
          color: Theme.of(context).primaryColorLight,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: kDimGrey,
                  ),
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Text(
              val,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class DottedCopyContainer extends StatelessWidget {
  const DottedCopyContainer({
    super.key,
    required this.lnurl,
  });

  final String lnurl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(
          new ClipboardData(text: lnurl),
        );
        singleSnackBar(
          context: context,
          message: 'Invoice code copied!',
          color: kGreen,
          backGroundColor: kGreenSide,
          icon: ToastsIcons.success,
        );
      },
      child: DottedBorder(
        color: Theme.of(context).primaryColorDark,
        strokeCap: StrokeCap.round,
        borderType: BorderType.RRect,
        radius: Radius.circular(kDefaultPadding - 5),
        dashPattern: [4],
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: Text(
            lnurl,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class SetZapContainer extends StatelessWidget {
  const SetZapContainer({
    Key? key,
    required this.index,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  final int index;
  final bool isSelected;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LightningZapsCubit, LightningZapsState>(
      builder: (context, state) {
        final zap = state.zapsValues.values.toList()[index];
        final icon = zap['icon'];
        final value = zap['value'];
        final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              color: Theme.of(context).primaryColorLight,
              border: Border.all(
                color: isSelected ? kPurple : kTransparent,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            margin: const EdgeInsets.all(5),
            child: LayoutBuilder(builder: (context, constraints) {
              return SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: SvgPicture.asset(
                        icon,
                      ),
                    ),
                    const Divider(),
                    Flexible(
                      child: Text(
                        Numeral(num.parse(value.toString())).toString(),
                        style: isTablet
                            ? Theme.of(context).textTheme.titleMedium
                            : Theme.of(context).textTheme.labelMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class ArrowAnimation extends HookWidget {
  const ArrowAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 2, milliseconds: 500),
    )..repeat(reverse: false);

    final opacityAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(0.0, 0.5, curve: Curves.easeInOut),
        ),
      ),
    );

    final positionAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(controller),
    );

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          SizedBox(
            width: constraints.maxWidth,
            height: 34,
          ),
          Positioned(
            left: positionAnimation * (constraints.maxWidth * 0.5),
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: constraints.maxWidth / 1.5,
              child: Opacity(
                opacity: opacityAnimation <= 0.5
                    ? opacityAnimation
                    : 1 - opacityAnimation,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 30,
                        color: kDimGrey,
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 40,
                        color: Theme.of(context).primaryColorDark,
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 30,
                        color: kDimGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
