import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:yakihonne/blocs/relays_progress_cubit/relays_progress_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';

class RelaysProgressBar extends StatefulWidget {
  const RelaysProgressBar({
    super.key,
  });

  @override
  State<RelaysProgressBar> createState() => _RelaysProgressBarState();
}

class _RelaysProgressBarState extends State<RelaysProgressBar> {
  AnimationController? animationController;
  double progressValue = 0;

  @override
  void dispose() {
    if (animationController != null && !animationController!.isDismissed)
      animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RelaysProgressCubit, RelaysProgressState>(
      listenWhen: (previous, current) =>
          previous.isProgressVisible != current.isProgressVisible,
      listener: (context, state) {
        if (animationController != null) {
          if (state.isProgressVisible) {
            animationController!.forward();
          } else {
            animationController!.reverse();
          }
        }
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: FadeInDown(
          manualTrigger: true,
          duration: const Duration(milliseconds: 300),
          controller: (controller) {
            animationController = controller;
          },
          child: Padding(
            padding: const EdgeInsets.only(
              top: kToolbarHeight + kDefaultPadding / 2,
            ),
            child: Column(
              children: [
                GestureDetector(
                  onVerticalDragStart: (details) {
                    context.read<RelaysProgressCubit>().dismissProgressBar();
                  },
                  child: Material(
                    elevation: 10,
                    borderRadius: BorderRadius.circular(300),
                    child: Container(
                      padding: const EdgeInsets.all(
                        kDefaultPadding / 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColorLight,
                        borderRadius: BorderRadius.circular(300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BlocBuilder<RelaysProgressCubit, RelaysProgressState>(
                            builder: (context, state) {
                              return Stack(
                                children: [
                                  SizedBox(
                                    height: 35,
                                    width: 35,
                                    child: CircularProgressIndicator(
                                      strokeCap: StrokeCap.round,
                                      value: progressValue =
                                          state.successfulRelays.length /
                                              (state.totalRelays.length == 0
                                                  ? 1
                                                  : state.totalRelays.length),
                                      backgroundColor: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        "${state.successfulRelays.length}/${state.totalRelays.length}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ),
                                  )
                                ],
                              );
                            },
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 1.5,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Successful relays',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              GestureDetector(
                                onTap: () => context
                                    .read<RelaysProgressCubit>()
                                    .setRelaysListVisibility(true),
                                child: Text(
                                  'details',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        decoration: TextDecoration.underline,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 1.5,
                          ),
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: IconButton(
                              onPressed: () {
                                context
                                    .read<RelaysProgressCubit>()
                                    .dismissProgressBar();
                              },
                              icon: Icon(
                                Icons.close,
                                size: 20,
                              ),
                              style: IconButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                visualDensity: VisualDensity(
                                  horizontal: -4,
                                  vertical: -4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                BlocBuilder<RelaysProgressCubit, RelaysProgressState>(
                  builder: (context, state) {
                    return Visibility(
                      visible: state.isRelaysVisible,
                      maintainAnimation: true,
                      maintainState: true,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: state.isRelaysVisible ? 1 : 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding,
                            vertical: kDefaultPadding / 2,
                          ),
                          child: Material(
                            elevation: 10,
                            borderRadius:
                                BorderRadius.circular(kDefaultPadding),
                            color: Theme.of(context).primaryColorLight,
                            child: Container(
                              height: 40.h,
                              padding:
                                  const EdgeInsets.all(kDefaultPadding / 2),
                              child: MediaQuery.removePadding(
                                context: context,
                                removeBottom: true,
                                removeLeft: true,
                                removeRight: true,
                                removeTop: true,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: state.totalRelays.isEmpty
                                          ? EmptyList(
                                              description:
                                                  'No relays can be found',
                                              icon: FeatureIcons.relays,
                                            )
                                          : ScrollShadow(
                                              color: Theme.of(context)
                                                  .primaryColorLight,
                                              child: ListView(
                                                padding: const EdgeInsets.all(
                                                  kDefaultPadding,
                                                ),
                                                children: state.totalRelays
                                                    .map(
                                                      (e) => relayStatus(
                                                        relay: e,
                                                        isSuccessful: state
                                                            .successfulRelays
                                                            .contains(e),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(
                                      height: kDefaultPadding / 2,
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context
                                            .read<RelaysProgressCubit>()
                                            .setRelaysListVisibility(false);
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).primaryColorDark,
                                        visualDensity: VisualDensity(
                                          vertical: -2,
                                          horizontal: -2,
                                        ),
                                      ),
                                      child: Text(
                                        'Dismiss',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium!
                                            .copyWith(
                                              color: Theme.of(context)
                                                  .scaffoldBackgroundColor,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget relayStatus({required String relay, required bool isSuccessful}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            isSuccessful ? Images.ok : Images.forbidden,
            width: 30,
            height: 30,
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          Flexible(
            child: Text(
              relay.split('wss://')[1],
            ),
          ),
        ],
      ),
    );
  }
}
