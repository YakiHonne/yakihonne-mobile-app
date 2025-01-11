import 'package:flutter/material.dart';
import 'package:yakihonne/utils/utils.dart';

class SealedUncensoredNoteContainer extends StatelessWidget {
  const SealedUncensoredNoteContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultPadding),
        border: Border.all(
          color: Theme.of(context).primaryColorDark,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColorLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(kDefaultPadding),
                topRight: Radius.circular(kDefaultPadding),
              ),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  FeatureIcons.uncensoredNote,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Expanded(
                  child: Text(
                    readers,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 1.5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Uncensored note',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColorLight,
                        visualDensity: VisualDensity(
                          vertical: -2,
                        ),
                      ),
                      icon: Text(
                        'Source',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: kGreen,
                            ),
                      ),
                      label: SvgPicture.asset(
                        FeatureIcons.globe,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          kGreen,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Text(
                  lorem,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
