import 'package:flutter/material.dart';
import 'package:yakihonne/models/points_system_models.dart';
import 'package:yakihonne/utils/utils.dart';

class OneTimeRewardContainer extends StatelessWidget {
  const OneTimeRewardContainer({
    super.key,
    required this.standard,
    required this.count,
    required this.total,
    required this.isCompleted,
    required this.standardAction,
    required this.remainingAttempts,
  });

  final PointStandard standard;
  final int count;
  final int total;
  final bool isCompleted;
  final PointAction? standardAction;
  final int remainingAttempts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        color: Theme.of(context).primaryColorLight,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  standard.displayName,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Text(
                '${count}',
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w800,
                      color: kOrange,
                    ),
              ),
              Text(
                ' / ${total}',
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              if (isCompleted)
                Icon(
                  Icons.check_circle,
                  size: 15,
                  color: kGreen,
                ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 3,
          ),
          LinearProgressIndicator(
            value: (standardAction?.count ?? 0) / standard.count,
            color: kRed,
            backgroundColor: kBlack.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(
              kDefaultPadding / 2,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 3,
          ),
          Row(
            children: [
              Text(
                'Attempts remained ',
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: kDimGrey,
                    ),
              ),
              Text(
                '(${remainingAttempts.toString()})',
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: remainingAttempts != 0 ? kGreen : kRed,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
