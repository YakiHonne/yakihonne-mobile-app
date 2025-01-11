import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/utils/utils.dart';

const consumablePointsPerks = [
  "1- Submit your content for attestation",
  "2- Redeem points to publish flash news",
  "3- Redeem points for SATs (Random thresholds are selected and you will be notified whenever redemption is available)"
];

class ConsumablePointsView extends StatelessWidget {
  const ConsumablePointsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Container(
      width: isTablet ? 50.w : double.infinity,
      margin: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "YakiHonne's Consumable points",
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Text(
            "Soon users will be able to use the consumable points in the following set of activities:",
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          ...consumablePointsPerks
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: kDefaultPadding / 8,
                  ),
                  child: Text(
                    e,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: kWhite,
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.start,
                  ),
                ),
              )
              .toList(),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Text(
            "Start earning and make the most of your Yaki Points! 🎉",
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: kGreen,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Got it!',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
