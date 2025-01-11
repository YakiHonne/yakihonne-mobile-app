// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/models/points_system_models.dart';
import 'package:yakihonne/utils/utils.dart';

class TierView extends StatelessWidget {
  const TierView({
    Key? key,
    required this.tier,
  }) : super(key: key);

  final PointSystemTier tier;

  @override
  Widget build(BuildContext context) {
    final stats = tier.getStats();
    final isUnlocked = stats['isUnlocked'];
    final levelsToNextTier = stats['levelsToNextTier'];
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
        children: [
          Image.asset(
            tier.icon,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          if (isUnlocked) ...[
            Text(
              '🎉',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Text(
              'Unlocked',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: kGreen,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ] else ...[
            Text(
              '🔒',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Locked',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: kDimGrey,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            'Level ${tier.level}',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          if (!isUnlocked) ...[
            LinearProgressIndicator(
              value: tier.level / tier.min,
              color: kRed,
              minHeight: 5,
              backgroundColor: kBlack.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(
                kDefaultPadding / 2,
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Text(
              '${levelsToNextTier} levels required',
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: kOrange,
                  ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
          ...tier.description
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 10),
                  child: Text(
                    e,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: kDimGrey,
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              .toList(),
          TextButton.icon(
            onPressed: () {
              openWebPage(
                url: pointsSystemUrl,
                inAppWebView: true,
              );
            },
            icon: Text(
              "See more",
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontStyle: FontStyle.italic,
                    color: kRed,
                  ),
              textAlign: TextAlign.left,
            ),
            label: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: kRed,
            ),
            style: TextButton.styleFrom(
              backgroundColor: kTransparent,
              visualDensity: VisualDensity(
                vertical: -2,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Got it!'),
            ),
          ),
        ],
      ),
    );
  }
}
