import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/wallet_balance_view/widgets/wallet_options_view.dart';
import 'package:yakihonne/views/widgets/modal_with_blur.dart';

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
              width: 130,
              height: 130,
              margin: const EdgeInsets.all(kDefaultPadding / 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColorLight,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                FeatureIcons.walletAdd,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
                width: 55,
                height: 55,
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  FeatureIcons.alby,
                  width: 35,
                  height: 35,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  FeatureIcons.nwc,
                  fit: BoxFit.scaleDown,
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
              showBlurredModal(
                context: context,
                view: WalletOptions(),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: kTransparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  FeatureIcons.addRaw,
                  width: 20,
                  height: 20,
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Text(
                  'Add wallet',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: kBlack,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
