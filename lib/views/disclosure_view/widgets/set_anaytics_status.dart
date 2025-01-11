import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:yakihonne/blocs/disclosure_cubit/disclosure_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';

class SetAnalyticsStatus extends StatelessWidget {
  const SetAnalyticsStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalBottomSheetHandle(),
              const SizedBox(
                height: kDefaultPadding,
              ),
              Text(
                "YakiHonne's improvements",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
              Text(
                ANALYTICS_DATA,
                style: Theme.of(context).textTheme.labelSmall!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "YakiHonne's analytics & crashlytics",
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 4,
                  ),
                  BlocBuilder<DisclosureCubit, DisclosureState>(
                    builder: (context, state) {
                      return Transform.scale(
                        scale: 0.8,
                        child: CupertinoSwitch(
                          value: state.isAnalyticsEnabled,
                          onChanged: (isToggled) {
                            Logger().i(isToggled);
                            context
                                .read<DisclosureCubit>()
                                .setAnalyticsStatus(isToggled);

                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  final ANALYTICS_DATA =
      "Collecting anonymized usage data is vital for refining our app's features and user experience. It enables us to identify user preferences, enhance popular features, and make informed optimizations, ensuring a more personalized and efficient app for our users.";
}
