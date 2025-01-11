import 'package:flutter/material.dart';
import 'package:yakihonne/utils/utils.dart';

class DisabledZapsView extends StatelessWidget {
  const DisabledZapsView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
      child: Container(
        width: 100.w,
        margin: const EdgeInsets.all(kDefaultPadding),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding * 2),
          color: Theme.of(context).primaryColorLight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Text(
                    "Apple's zaps limitations",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  Text(
                    'Apple does not allow in any form the direct content zaps but it still can be used in the profile screen.',
                    style: TextStyle(
                      color: kDimGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Close',
                    ),
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
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
