import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/lightning_zaps_cubit/lightning_zaps_cubit.dart';
import 'package:yakihonne/blocs/write_flash_news_cubit/write_flash_news_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/write_flash_news_view/widgets/flash_news_content.dart';
import 'package:yakihonne/views/write_flash_news_view/widgets/flash_news_publish.dart';
import 'package:yakihonne/views/write_flash_news_view/widgets/flash_news_selected_relays.dart';

class WriteFlashNewsView extends StatelessWidget {
  const WriteFlashNewsView({super.key});
  static const routeName = '/writeFlashNews';
  static Route route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (_) => WriteFlashNewsView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocProvider(
      create: (context) => WriteFlashNewsCubit(),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: BlocBuilder<WriteFlashNewsCubit, WriteFlashNewsState>(
            builder: (context, state) {
              return AppBar(
                leading: IconButton(
                  onPressed: () {
                    showCupertinoCustomDialogue(
                      context: context,
                      title: 'Exit',
                      description:
                          'You are about the exit the flash news screen, do you wish to proceed?',
                      buttonText: 'exit',
                      buttonTextColor: kRed,
                      onClicked: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                    );
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                  ),
                ),
                title: Column(
                  children: [
                    Text(
                      '${state.flashNewsPublishSteps == FlashNewsPublishSteps.content ? 'Flash news content' : state.flashNewsPublishSteps == FlashNewsPublishSteps.relays ? 'Select your relays' : 'Pay & publish'}',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      '${state.flashNewsPublishSteps == FlashNewsPublishSteps.content ? 'Set Swift Breaking Moments' : state.flashNewsPublishSteps == FlashNewsPublishSteps.relays ? 'list of available relays' : "let's get into it"}',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: kDimGrey,
                          ),
                    ),
                  ],
                ),
                centerTitle: true,
              );
            },
          ),
        ),
        bottomNavigationBar:
            BlocBuilder<WriteFlashNewsCubit, WriteFlashNewsState>(
          builder: (context, state) {
            final step = state.flashNewsPublishSteps ==
                    FlashNewsPublishSteps.content
                ? 1
                : state.flashNewsPublishSteps == FlashNewsPublishSteps.relays
                    ? 2
                    : 3;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 2,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(
                      begin: 0,
                      end: step / 3,
                    ),
                    builder: (context, value, _) =>
                        LinearProgressIndicator(value: value),
                  ),
                ),
                _bottomNavBar(context, state, isTablet),
              ],
            );
          },
        ),
        body: BlocBuilder<WriteFlashNewsCubit, WriteFlashNewsState>(
          builder: (context, state) {
            return getView(state.flashNewsPublishSteps);
          },
        ),
      ),
    );
  }

  Container _bottomNavBar(
      BuildContext context, WriteFlashNewsState state, bool isTablet) {
    return Container(
      height:
          kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        left: kDefaultPadding / 2,
        right: kDefaultPadding / 2,
        bottom: MediaQuery.of(context).padding.bottom / 2,
      ),
      child: Center(
        child: state.flashNewsPublishSteps != FlashNewsPublishSteps.payment
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Visibility(
                    visible: state.flashNewsPublishSteps !=
                        FlashNewsPublishSteps.content,
                    child: IconButton(
                      onPressed: () {
                        context.read<WriteFlashNewsCubit>().setFlashNewsStep(
                              FlashNewsPublishSteps.content,
                            );
                      },
                      icon: Icon(
                        Icons.keyboard_arrow_left_rounded,
                        color: kWhite,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: kPurple,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (state.flashNewsPublishSteps ==
                          FlashNewsPublishSteps.content) {
                        context.read<WriteFlashNewsCubit>().setFlashNewsStep(
                              FlashNewsPublishSteps.relays,
                            );
                      } else {
                        context.read<LightningZapsCubit>().resetInvoice();

                        context.read<WriteFlashNewsCubit>().setFlashNewsStep(
                              FlashNewsPublishSteps.payment,
                            );
                      }
                    },
                    child: Text(
                      'Next',
                    ),
                  ),
                ],
              )
            : BlocBuilder<LightningZapsCubit, LightningZapsState>(
                builder: (context, lightningState) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 4,
                      horizontal: isTablet ? 10.w : 0,
                    ),
                    child: Builder(
                      builder: (context) {
                        if (!lightningState.isLnurlAvailable) {
                          return SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    context
                                        .read<WriteFlashNewsCubit>()
                                        .setFlashNewsStep(
                                          FlashNewsPublishSteps.relays,
                                        );
                                  },
                                  icon: Icon(
                                    Icons.keyboard_arrow_left_rounded,
                                    color: kWhite,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: kPurple,
                                  ),
                                ),
                                Expanded(
                                  child: AbsorbPointer(
                                    absorbing: lightningState.isLoading,
                                    child: TextButton(
                                      onPressed: () async {
                                        final event = await context
                                            .read<WriteFlashNewsCubit>()
                                            .createEvent();

                                        if (event != null) {
                                          context
                                              .read<LightningZapsCubit>()
                                              .generateZapInvoice(
                                                sats: (nostrRepository
                                                            .flashNewsPrice +
                                                        (state.isImportant
                                                            ? nostrRepository
                                                                .importantTagPrice
                                                            : 0))
                                                    .toInt(),
                                                onSuccess: (code) {
                                                  context
                                                      .read<
                                                          WriteFlashNewsCubit>()
                                                      .setPendingFlashNews(
                                                          code);
                                                },
                                                user: emptyUserModel.copyWith(
                                                  lud16: nostrRepository
                                                      .yakihonneWallet,
                                                  pubKey: yakihonneHex,
                                                  picturePlaceholder:
                                                      getRandomPlaceholder(
                                                    input: yakihonneHex,
                                                    isPfp: true,
                                                  ),
                                                ),
                                                comment:
                                                    '${nostrRepository.user.name.isNotEmpty ? nostrRepository.user.name : 'unknown'} has paid for a flash news',
                                                eventId: event.eventId,
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
                                      child: lightningState.isLoading
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
                                    absorbing: lightningState.isLoading,
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        final event = await context
                                            .read<WriteFlashNewsCubit>()
                                            .createEvent();

                                        if (event != null) {
                                          context
                                              .read<LightningZapsCubit>()
                                              .handleWalletZap(
                                                sats: (nostrRepository
                                                            .flashNewsPrice +
                                                        (state.isImportant
                                                            ? nostrRepository
                                                                .importantTagPrice
                                                            : 0))
                                                    .toInt(),
                                                user: emptyUserModel.copyWith(
                                                  lud16: nostrRepository
                                                      .yakihonneWallet,
                                                  pubKey: yakihonneHex,
                                                  picturePlaceholder:
                                                      getRandomPlaceholder(
                                                    input: yakihonneHex,
                                                    isPfp: true,
                                                  ),
                                                ),
                                                comment:
                                                    '${nostrRepository.user.name.isNotEmpty ? nostrRepository.user.name : 'unknown'} has paid for a flash news',
                                                eventId: event.eventId,
                                                onFinished: (invoice) {
                                                  context
                                                      .read<
                                                          WriteFlashNewsCubit>()
                                                      .setPendingFlashNews(
                                                        invoice,
                                                      );
                                                },
                                                onSuccess: (invoice) {
                                                  context
                                                      .read<
                                                          WriteFlashNewsCubit>()
                                                      .submitEvent(
                                                        () => Navigator.pop(
                                                            context),
                                                      );
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
                                      icon: lightningState.isLoading
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
                                      label: lightningState.isLoading
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: kWhite,
                                              ),
                                            )
                                          : Text('Pay'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  context
                                      .read<WriteFlashNewsCubit>()
                                      .setFlashNewsStep(
                                        FlashNewsPublishSteps.relays,
                                      );
                                },
                                icon: Icon(
                                  Icons.keyboard_arrow_left_rounded,
                                  color: kWhite,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: kPurple,
                                ),
                              ),
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          icon: PrettyQrView.data(
                                            data: lightningState.lnurl,
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
                                      Theme.of(context).primaryColorDark,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  label: Text('QR code'),
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
                                        text: lightningState.lnurl,
                                      ),
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
                          );
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget getView(FlashNewsPublishSteps flashNewsPublishSteps) {
    if (flashNewsPublishSteps == FlashNewsPublishSteps.content) {
      return FlashNewsContent();
    } else if (flashNewsPublishSteps == FlashNewsPublishSteps.relays) {
      return BlocBuilder<WriteFlashNewsCubit, WriteFlashNewsState>(
        builder: (context, state) {
          return FlashNewsSelectedRelays(
            selectedRelays: state.selectedRelays,
            totaRelays: state.totalRelays,
            onToggle: (relay) {
              if (!mandatoryRelays.contains(relay)) {
                context.read<WriteFlashNewsCubit>().setRelaySelection(relay);
              }
            },
          );
        },
      );
    } else {
      return FlashNewsPublish();
    }
  }
}
