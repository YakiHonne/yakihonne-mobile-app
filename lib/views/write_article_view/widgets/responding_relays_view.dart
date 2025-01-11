// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/utils/utils.dart';

class RespondingRelaysView extends StatelessWidget {
  const RespondingRelaysView({
    Key? key,
    required this.successfulRelays,
    required this.unsuccessfulRelays,
    required this.index,
  }) : super(key: key);

  final List<String> successfulRelays;
  final List<String> unsuccessfulRelays;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(
            alpha: 0.85,
          ),
      bottomNavigationBar: Container(
        height:
            kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
          left: kDefaultPadding,
          right: kDefaultPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              child: Text(
                'Done!',
                style: TextStyle(
                  color: kWhite,
                  height: 1,
                ),
              ),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
                if (index != -1) {
                  context.read<MainCubit>().updateIndex(index);
                }
              },
            ),
          ],
        ),
      ),
      body: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 5,
          sigmaY: 5,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(kDefaultPadding),
            children: [
              if (successfulRelays.isNotEmpty) ...[
                Text(
                  'Successful relays',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                ...successfulRelays.map(
                  (relay) => relayStatus(
                    relay: relay,
                    isSuccessful: true,
                  ),
                ),
              ],
              if (unsuccessfulRelays.isNotEmpty) ...[
                const SizedBox(
                  height: kDefaultPadding * 2,
                ),
                Text(
                  'Unsuccessful relays',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                ...unsuccessfulRelays.map(
                  (relay) => relayStatus(
                    relay: relay,
                    isSuccessful: false,
                  ),
                ),
              ],
            ],
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
