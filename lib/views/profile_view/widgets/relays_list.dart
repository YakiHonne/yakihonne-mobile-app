// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:yakihonne/blocs/profile_cubit/profile_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';

class ProfileRelays extends StatelessWidget {
  const ProfileRelays({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.60,
          maxChildSize: 0.7,
          expand: false,
          builder: (_, controller) => SafeArea(
            child: Column(
              children: [
                ModalBottomSheetHandle(),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(
                          'Profile recommended relays - ',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Text(
                          state.userRelays.length.toString().padLeft(2, '0'),
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                if (state.isRelaysLoading)
                  SpinKitSpinningLines(
                    size: 25,
                    color: Theme.of(context).primaryColorDark,
                  )
                else if (state.userRelays.isEmpty)
                  EmptyList(
                    description: 'No relays for this user were found.',
                    icon: FeatureIcons.relays,
                  )
                else
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                      ),
                      alignment: Alignment.topCenter,
                      child: ScrollShadow(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          primary: false,
                          shrinkWrap: true,
                          controller: controller,
                          separatorBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                left: kDefaultPadding + 3,
                              ),
                              child: Divider(
                                height: kDefaultPadding / 1.5,
                              ),
                            );
                          },
                          itemBuilder: (context, index) {
                            final relay = state.userRelays[index];

                            return ProfileRelayContainer(
                              canBeAdded: !state.ownRelays
                                  .contains(relay.removeLastBackSlashes()),
                              isActive: state.activeRelays
                                  .contains(relay.removeLastBackSlashes()),
                              isEnabled:
                                  state.userStatus == UserStatus.UsingPrivKey,
                              relay: relay,
                              onAddRelay: () {
                                context
                                    .read<ProfileCubit>()
                                    .addRelay(newRelay: relay);
                              },
                            );
                          },
                          itemCount: state.userRelays.length,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProfileRelayContainer extends StatelessWidget {
  const ProfileRelayContainer({
    Key? key,
    required this.relay,
    required this.isActive,
    required this.canBeAdded,
    required this.onAddRelay,
    required this.isEnabled,
  }) : super(key: key);

  final String relay;
  final bool isActive;
  final bool canBeAdded;
  final Function() onAddRelay;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DotContainer(
          color: isActive ? kGreen : kRed,
          isNotMarging: true,
          size: 8,
        ),
        const SizedBox(
          width: kDefaultPadding - 5,
        ),
        Expanded(
          child: Text(
            relay,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        if (!canBeAdded)
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.check_circle,
              color: kGreen,
              size: 20,
            ),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
            ),
          )
        else
          Visibility(
            visible: canBeAdded && isEnabled,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Row(
              children: [
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                IconButton(
                  onPressed: onAddRelay,
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: kOrange,
                    size: 20,
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
