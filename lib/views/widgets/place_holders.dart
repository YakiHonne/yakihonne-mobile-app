import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:yakihonne/utils/utils.dart';

class SkeletonSelector extends StatelessWidget {
  const SkeletonSelector({
    super.key,
    required this.placeHolderWidget,
  });

  final Widget placeHolderWidget;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return isTablet
        ? Padding(
            padding: const EdgeInsets.all(
              kDefaultPadding / 2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: placeHolderWidget,
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Expanded(
                  child: placeHolderWidget,
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(
              kDefaultPadding / 2,
            ),
            child: placeHolderWidget,
          );
  }
}

class CurationSkeleton extends StatelessWidget {
  const CurationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(kDefaultPadding),
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? kDefaultPadding / 2 : kDefaultPadding,
        vertical: (kDefaultPadding / 2) + kDefaultPadding,
      ),
      child: Skeletonizer(
        enabled: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Skeleton.shade(
                  shade: true,
                  child: Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      color: kWhite,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This is a big title',
                        style: Theme.of(context).textTheme.labelSmall!,
                      ),
                      Text(
                        'This is the curation detailes',
                        style: Theme.of(context).textTheme.labelSmall!,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
              ],
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Text(
              lorem,
              style: Theme.of(context).textTheme.labelMedium!,
              maxLines: 2,
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Text(
              lorem,
              style: Theme.of(context).textTheme.labelSmall!,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

class ArticleSkeleton extends StatelessWidget {
  const ArticleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Skeletonizer(
        enabled: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton.shade(
                  shade: true,
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: kWhite,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This is a big title',
                        style: Theme.of(context).textTheme.labelSmall!,
                      ),
                      Text(
                        'This is a detailes',
                        style: Theme.of(context).textTheme.labelSmall!,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                Text(
                  'This is',
                  style: Theme.of(context).textTheme.labelSmall!,
                ),
              ],
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Text(
                        lorem,
                        style: Theme.of(context).textTheme.labelMedium!,
                        maxLines: 2,
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                      Text(
                        lorem,
                        style: Theme.of(context).textTheme.labelSmall!,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Expanded(
                  flex: 4,
                  child: Skeleton.shade(
                    shade: true,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: kWhite,
                          borderRadius: BorderRadius.circular(kDefaultPadding),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Row(
              children: [
                Skeleton.shade(
                  shade: true,
                  child: Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      color: kWhite,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This is a big title',
                        style: Theme.of(context).textTheme.labelSmall!,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                Text(
                  'This is a detailes',
                  style: Theme.of(context).textTheme.labelSmall!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CurationArticleSkeleton extends StatelessWidget {
  const CurationArticleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(
        kDefaultPadding / 1.5,
      ),
      margin: EdgeInsets.symmetric(
          horizontal: isTablet ? kDefaultPadding / 2 : kDefaultPadding),
      child: Skeletonizer(
        enabled: true,
        child: Row(
          children: [
            Skeleton.shade(
              shade: true,
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: kWhite,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This is a big title',
                    style: Theme.of(context).textTheme.labelSmall!,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Text(
                    lorem,
                    style: Theme.of(context).textTheme.labelSmall!,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchProfileSkeleton extends StatelessWidget {
  const SearchProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      width: 300,
      margin: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 3,
        horizontal: kDefaultPadding / 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        color: Theme.of(context).primaryColorLight,
      ),
      child: Skeletonizer(
        enabled: true,
        child: Row(
          children: [
            Skeleton.shade(
              shade: true,
              child: Container(
                height: 55,
                width: 55,
                decoration: BoxDecoration(
                  color: kWhite,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lorem,
                    style: Theme.of(context).textTheme.labelSmall!,
                    maxLines: 1,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Text(
                    'This is a big title',
                    style: Theme.of(context).textTheme.labelSmall!,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeProfileSkeleton extends StatelessWidget {
  const HomeProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      margin: EdgeInsets.symmetric(
        vertical: kDefaultPadding / 2,
        horizontal: isTablet ? kDefaultPadding / 2 : kDefaultPadding,
      ),
      child: Skeletonizer(
        enabled: true,
        child: Row(
          children: [
            Skeleton.shade(
              shade: true,
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: kWhite,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lorem,
                    style: Theme.of(context).textTheme.labelMedium!,
                    maxLines: 1,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Text(
                    'This is a big title',
                    style: Theme.of(context).textTheme.labelMedium!,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
