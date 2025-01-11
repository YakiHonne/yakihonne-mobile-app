import 'package:flutter/material.dart';
import 'package:yakihonne/models/points_system_models.dart';
import 'package:yakihonne/utils/utils.dart';

class RepeatedReward extends StatelessWidget {
  const RepeatedReward({
    super.key,
    required this.standard,
    required this.cooldownVal,
    required this.collectedPoints,
  });

  final PointStandard standard;
  final int cooldownVal;
  final int collectedPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        color: Theme.of(context).primaryColorLight,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      standard.displayName,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.labelSmall,
                        children: [
                          TextSpan(
                            text: 'Gain ',
                          ),
                          TextSpan(
                            text: '${standard.points.first.toString()} xp',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: kOrange,
                                ),
                          ),
                          TextSpan(
                            text: ' for ${standard.displayName}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
              ),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: cooldownVal == -1
                            ? 1
                            : cooldownVal.toDouble() /
                                Duration(seconds: standard.cooldown).inMinutes,
                        color: kGreen,
                        strokeCap: StrokeCap.round,
                        backgroundColor: kBlack.withValues(alpha: 0.3),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (cooldownVal == -1)
                            SvgPicture.asset(
                              FeatureIcons.infinity,
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
                            )
                          else ...[
                            Text(
                              cooldownVal.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                            ),
                            const SizedBox(
                              height: kDefaultPadding / 8,
                            ),
                            Text(
                              'min',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    height: 1,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            VerticalDivider(
              width: 0,
            ),
            Padding(
              padding: const EdgeInsets.all(
                kDefaultPadding / 2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    collectedPoints.toString(),
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: kOrange,
                        ),
                  ),
                  Text(
                    'points',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
