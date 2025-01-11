// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/properties_cubit/update_relays_cubit/update_relays_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';

class RelaysList extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final searchController = useState('');

    return BlocBuilder<UpdateRelaysCubit, UpdateRelaysState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.60,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Scrollbar(
              controller: scrollController,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Center(
                        child: ModalBottomSheetHandle(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(
                          kDefaultPadding / 2,
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search relay',
                          ),
                          onChanged: (text) {
                            searchController.value = text;
                          },
                        ),
                      ),
                    ),
                    SliverList.builder(
                      itemBuilder: (context, index) {
                        final relay = state.onlineRelays[index];
                        final isDisplayed = (searchController.value
                                    .trim()
                                    .isNotEmpty &&
                                !relay
                                    .contains(searchController.value.trim())) ||
                            constantRelays.contains(relay);
                        if (isDisplayed) {
                          return SizedBox.shrink();
                        } else {
                          final isAdding = !state.relays.contains(relay);

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding / 2,
                            ),
                            child: RelayListTile(
                              title: relay,
                              isAdding: isAdding,
                              isFirstlyDisplayed: false,
                              isEnabled: !constantRelays.contains(relay),
                              onClicked: () {
                                context
                                    .read<UpdateRelaysCubit>()
                                    .setRelay(relay, textfield: true);
                              },
                            ),
                          );
                        }
                      },
                      itemCount: state.onlineRelays.length,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OnlineRelayCard extends StatelessWidget {
  const OnlineRelayCard({
    super.key,
    required this.relay,
    required this.onDelete,
    required this.isAdding,
    required this.isEnabled,
  });

  final String relay;
  final Function() onDelete;
  final bool isAdding;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 4,
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(
          width: 0.5,
          color: isAdding ? kTransparent : kGreen,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              relay,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(
              isAdding ? FeatureIcons.add : FeatureIcons.trash,
              width: 25,
              height: 25,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RelayListTile extends StatelessWidget {
  const RelayListTile({
    super.key,
    required this.title,
    required this.isEnabled,
    required this.onClicked,
    required this.isAdding,
    required this.isFirstlyDisplayed,
  });

  final String title;
  final bool isEnabled;
  final bool isAdding;
  final bool isFirstlyDisplayed;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).primaryColorLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        side: BorderSide(
          color: (isFirstlyDisplayed || isAdding) ? kTransparent : kGreen,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isEnabled
                      ? null
                      : context.read<ThemeCubit>().state.theme ==
                              AppTheme.purpleDark
                          ? kLightPurple
                          : kPurple,
                ),
              ),
            ),
            Visibility(
              visible: isEnabled,
              replacement: SizedBox(
                width: 45,
                height: 45,
              ),
              child: IconButton(
                onPressed: onClicked,
                icon: SvgPicture.asset(
                  isAdding ? FeatureIcons.add : FeatureIcons.trash,
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
