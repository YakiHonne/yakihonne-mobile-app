// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/write_article_view/widgets/article_details.dart';

class ArticleSelectedRelays extends StatelessWidget {
  const ArticleSelectedRelays({
    Key? key,
    required this.totaRelays,
    required this.selectedRelays,
    required this.onToggle,
    required this.onDeleteDraft,
    required this.isDraft,
    required this.deleteDraft,
    required this.isForwardedAsDraft,
    required this.isDraftShown,
  }) : super(key: key);

  final List<String> totaRelays;
  final List<String> selectedRelays;
  final Function(String) onToggle;
  final Function() onDeleteDraft;
  final bool isDraft;
  final bool deleteDraft;
  final bool isForwardedAsDraft;
  final bool isDraftShown;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return FadeInRight(
      duration: const Duration(milliseconds: 300),
      child: ListView(
        padding: EdgeInsets.all(isTablet ? 10.w : kDefaultPadding / 2),
        children: [
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            '(for more custom relays, check your settings)',
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          ResponsiveBreakpoints.of(context).largerThan(MOBILE)
              ? MasonryGridView.builder(
                  gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  shrinkWrap: true,
                  primary: false,
                  crossAxisSpacing: kDefaultPadding / 2,
                  itemCount: totaRelays.length,
                  itemBuilder: (context, index) {
                    final relay = totaRelays[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding / 4,
                      ),
                      child: ArticleCheckBoxListTile(
                        isEnabled: !mandatoryRelays.contains(relay),
                        onToggle: () => onToggle(relay),
                        status: selectedRelays.contains(relay) ||
                            mandatoryRelays.contains(relay),
                        text: relay.split('wss://')[1],
                        textColor: mandatoryRelays.contains(relay)
                            ? context.read<ThemeCubit>().state.theme ==
                                    AppTheme.purpleDark
                                ? kLightPurple
                                : kPurple
                            : null,
                      ),
                    );
                  },
                )
              : Column(
                  children: totaRelays
                      .map(
                        (relay) => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: kDefaultPadding / 4,
                          ),
                          child: ArticleCheckBoxListTile(
                            isEnabled: !mandatoryRelays.contains(relay),
                            onToggle: () => onToggle(relay),
                            status: selectedRelays.contains(relay) ||
                                mandatoryRelays.contains(relay),
                            text: relay.split('wss://')[1],
                            textColor: mandatoryRelays.contains(relay)
                                ? context.read<ThemeCubit>().state.theme ==
                                        AppTheme.purpleDark
                                    ? kLightPurple
                                    : kPurple
                                : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
          if (isDraftShown && isDraft && !isForwardedAsDraft)
            Column(
              children: [
                SizedBox(
                  height: kDefaultPadding / 3,
                ),
                ArticleCheckBoxListTile(
                  isEnabled: true,
                  status: deleteDraft,
                  text: 'Publish and remove the draft',
                  onToggle: onDeleteDraft,
                )
              ],
            ),
        ],
      ),
    );
  }
}
