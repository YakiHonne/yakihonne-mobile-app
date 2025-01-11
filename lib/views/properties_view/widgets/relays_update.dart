import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/properties_cubit/update_relays_cubit/update_relays_cubit.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/properties_view/widgets/properties_relay_list.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class RelayUpdateView extends HookWidget {
  RelayUpdateView({super.key});

  static const routeName = '/relayUpdateView';
  static Route route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (_) => RelayUpdateView(),
    );
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final addRelayState = useState('');
    final addRelayController = useTextEditingController();

    List<Widget> widgets = [];

    Widget addingRelayManually = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instant connect to relay',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: kDimGrey,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Builder(builder: (context) {
          return Form(
            key: _formKey,
            child: TextFormField(
              controller: addRelayController,
              decoration: InputDecoration(
                hintText: 'wss://sort.relay.com',
                suffixIcon: addRelayState.value.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<UpdateRelaysCubit>().setRelay(
                              addRelayState.value,
                              textfield: true,
                              onSuccess: () {
                                context.read<UpdateRelaysCubit>().updateRelays(
                                  onFailure: (message) {
                                    singleSnackBar(
                                      context: context,
                                      message: message,
                                      color: kRed,
                                      backGroundColor: kRedSide,
                                      icon: ToastsIcons.error,
                                    );
                                  },
                                  onSuccess: (message) {
                                    addRelayController.clear();
                                    singleSnackBar(
                                      context: context,
                                      message: message,
                                      color: kGreen,
                                      backGroundColor: kGreenSide,
                                      icon: ToastsIcons.success,
                                    );
                                  },
                                );
                              },
                            );
                          }
                        },
                        icon: Icon(Icons.add_rounded),
                      )
                    : null,
              ),
              onChanged: (relay) {
                addRelayState.value = relay;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Invalid relay url';
                }

                return null;
              },
            ),
          );
        }),
      ],
    );

    Widget relaysList = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Used relays',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: kDimGrey,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            BlocBuilder<UpdateRelaysCubit, UpdateRelaysState>(
              buildWhen: (previous, current) =>
                  previous.isSameRelays != current.isSameRelays,
              builder: (context, state) {
                if (state.isSameRelays) {
                  return SizedBox.shrink();
                }

                return IconButton(
                  onPressed: () {
                    context.read<UpdateRelaysCubit>().updateRelays(
                      onFailure: (message) {
                        singleSnackBar(
                          context: context,
                          message: message,
                          color: kRed,
                          backGroundColor: kRedSide,
                          icon: ToastsIcons.error,
                        );
                      },
                      onSuccess: (message) {
                        singleSnackBar(
                          context: context,
                          message: message,
                          color: kGreen,
                          backGroundColor: kGreenSide,
                          icon: ToastsIcons.success,
                        );
                      },
                    );
                  },
                  icon: Icon(
                    Icons.cloud_upload_outlined,
                    color: kGreen,
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  ),
                );
              },
            ),
            Builder(builder: (context) {
              return IconButton(
                onPressed: () {
                  context.read<UpdateRelaysCubit>().setOnlineRelays();

                  showModalBottomSheet(
                    context: context,
                    elevation: 0,
                    builder: (_) {
                      return BlocProvider.value(
                        value: context.read<UpdateRelaysCubit>(),
                        child: RelaysList(),
                      );
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
                icon: Icon(Icons.add_rounded),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                ),
              );
            }),
          ],
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Container(
          padding: const EdgeInsets.all(kDefaultPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          ),
          child: Column(
            children: [
              BlocBuilder<UpdateRelaysCubit, UpdateRelaysState>(
                builder: (context, state) {
                  return ListView.separated(
                    shrinkWrap: true,
                    primary: false,
                    padding: EdgeInsets.zero,
                    separatorBuilder: (context, index) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(left: kDefaultPadding + 3),
                        child: Divider(
                          height: kDefaultPadding / 1.5,
                        ),
                      );
                    },
                    itemBuilder: (context, index) {
                      final relay = state.relays[index];

                      return RelayUpdateContainer(
                        canBeDeleted: !constantRelays.contains(relay),
                        isActive: state.activeRelays.contains(relay),
                        relay: relay,
                        onDelete: () {
                          context.read<UpdateRelaysCubit>().setRelay(relay);
                        },
                        isPending: state.pendingRelays.contains(relay),
                      );
                    },
                    itemCount: state.relays.length,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );

    widgets.addAll(
      [
        addingRelayManually,
        const SizedBox(
          height: kDefaultPadding,
        ),
        relaysList,
      ],
    );

    return BlocProvider(
      create: (context) => UpdateRelaysCubit(
        nostrRepository: context.read<NostrDataRepository>(),
      ),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Relays',
        ),
        body: ListView(
          padding: const EdgeInsets.all(kDefaultPadding),
          children: widgets,
        ),
      ),
    );
  }
}

class RelayUpdateContainer extends StatelessWidget {
  const RelayUpdateContainer({
    Key? key,
    required this.relay,
    required this.isActive,
    required this.canBeDeleted,
    required this.onDelete,
    required this.isPending,
  }) : super(key: key);

  final String relay;
  final bool isActive;
  final bool isPending;
  final bool canBeDeleted;
  final Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DotContainer(
          color: isPending
              ? kDimGrey
              : isActive
                  ? kGreen
                  : kRed,
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
        Visibility(
          visible: canBeDeleted,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Row(
            children: [
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.remove_circle_outline_outlined,
                  color: kRed,
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
