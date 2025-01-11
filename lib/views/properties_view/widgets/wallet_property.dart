import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/lightning_zaps_cubit/lightning_zaps_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';

class WalletView extends StatelessWidget {
  const WalletView({super.key});

  static const routeName = '/walletView';
  static Route route() {
    return CupertinoPageRoute(
      builder: (_) => WalletView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'My wallet',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: BlocBuilder<LightningZapsCubit, LightningZapsState>(
            builder: (context, state) {
              if (!state.isLoading) {
                return Center(child: DisconnectedWallet());
              } else {
                return ConnectedWallet(
                  lud16: '',
                  relay: '',
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class ConnectedWallet extends StatelessWidget {
  const ConnectedWallet({
    super.key,
    required this.relay,
    required this.lud16,
  });

  final String relay;
  final String lud16;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            margin: const EdgeInsets.all(kDefaultPadding / 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColorLight,
              border: Border.all(color: kGreen, width: 5),
            ),
            child: SvgPicture.asset(
              FeatureIcons.walletAvailable,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Text(
            'Currently used wallet',
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              color: Theme.of(context).primaryColorLight,
            ),
            padding: const EdgeInsets.all(kDefaultPadding),
            width: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
                ? 50.w
                : null,
            child: Column(
              children: [
                Text(relay),
                Divider(
                  height: kDefaultPadding * 2,
                ),
                Text(lud16),
              ],
            ),
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          TextButton(
            onPressed: () {
              // context.read<LightningZapsCubit>().removeNwc();
            },
            child: Text(
              'Disconnect wallet',
            ),
          ),
        ],
      ),
    );
  }
}

class DisconnectedWallet extends HookWidget {
  const DisconnectedWallet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          children: [
            SizedBox(
              width: 140,
              height: 140,
            ),
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(25),
              margin: const EdgeInsets.all(kDefaultPadding / 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColorLight,
              ),
              child: SvgPicture.asset(
                FeatureIcons.walletAdd,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
                width: 40,
                height: 40,
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(25),
                margin: const EdgeInsets.all(kDefaultPadding / 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: SvgPicture.asset(
                  FeatureIcons.nwc,
                  width: 35,
                  height: 35,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        Text(
          'To be able to send zaps, please make sure to connect your bitcoin lightning wallet.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange,
                Colors.yellow,
              ],
            ),
            borderRadius: BorderRadius.circular(kDefaultPadding),
          ),
          child: TextButton(
            onPressed: () {
              // context.read<LightningZapsCubit>().launchUrl();
            },
            style: TextButton.styleFrom(
              backgroundColor: kTransparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  FeatureIcons.alby,
                  width: 35,
                  height: 35,
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Text(
                  'Connect with nwc',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: kBlack,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding * 1.5,
        ),
        Text(
          'Note: the attached wallet will be used as a default to send zaps & all the data related to your wallet will be safely and securely stored locally and are never shared outside the confines of the application',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
