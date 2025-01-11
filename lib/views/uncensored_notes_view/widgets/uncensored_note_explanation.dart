import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';

class UncensoredNoteExplanation extends StatelessWidget {
  const UncensoredNoteExplanation({super.key});
  static const routeName = '/uncensoredNoteExplanationView';
  static Route route() {
    return CupertinoPageRoute(
      builder: (_) => UncensoredNoteExplanation(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Explanation',
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(kDefaultPadding / 1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              color: Theme.of(context).primaryColorLight,
            ),
            child: Column(
              children: [
                Text(
                  'Read about Uncensored Notes',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Text(
                  "We've made an article for you to help you understand our purpose",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: kDimGrey,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                TextButton(
                  onPressed: () {
                    openWebPage(
                      url:
                          'https://yakihonne.com/article/naddr1qq252nj4w4kkvan8dpuxx6f5x3n9xstk23tkyq3qyzvxlwp7wawed5vgefwfmugvumtp8c8t0etk3g8sky4n0ndvyxesxpqqqp65wpcr66x',
                    );
                  },
                  child: Text(
                    'Read article',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium!
                        .copyWith(color: kWhite),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity(
                      vertical: -2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Container(
            padding: const EdgeInsets.all(kDefaultPadding / 1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              color: Theme.of(context).primaryColorLight,
            ),
            child: Column(
              children: [
                Text(
                  'Uncensored notes values',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Row(
                  children: [
                    DotContainer(color: kDimGrey),
                    Text(
                      'Contribute to build understanding',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Row(
                  children: [
                    DotContainer(color: kDimGrey),
                    Text(
                      'Act in good faith',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Row(
                  children: [
                    DotContainer(color: kDimGrey),
                    Text(
                      'Be helpful, even to those who disagree',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                TextButton(
                  onPressed: () {
                    openWebPage(
                      url:
                          'https://yakihonne.com/article/naddr1qq2kw52htue8wez8wd9nj36pwucyx33hwsmrgq3qyzvxlwp7wawed5vgefwfmugvumtp8c8t0etk3g8sky4n0ndvyxesxpqqqp65w6998qf',
                    );
                  },
                  child: Text(
                    'Read more',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium!
                        .copyWith(color: kWhite),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity(
                      vertical: -2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
