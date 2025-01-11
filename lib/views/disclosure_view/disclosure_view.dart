import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/disclosure_cubit/disclosure_cubit.dart';
import 'package:yakihonne/blocs/routing_cubit/routing_cubit.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/disclosure_view/widgets/set_anaytics_status.dart';

class DisclosureView extends StatelessWidget {
  const DisclosureView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DisclosureCubit(
        localDatabaseRepository: context.read<LocalDatabaseRepository>(),
      ),
      child: Scaffold(
        bottomNavigationBar: BottomAppBar(
          height: kBottomNavigationBarHeight,
          color: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
          child: BlocBuilder<DisclosureCubit, DisclosureState>(
            builder: (context, state) {
              return RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall!
                      .copyWith(fontSize: 8),
                  children: [
                    TextSpan(
                      text: state.isAnalyticsEnabled
                          ? 'We collect anonymised usage data and crash analytics to improve the app experience. '
                          : 'You share no usage data with us at the moment. ',
                    ),
                    TextSpan(
                      text:
                          "${state.isAnalyticsEnabled ? "Don't " : ''}want to share anayltics?",
                      style: TextStyle(
                        color: kOrange,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          showModalBottomSheet(
                            context: context,
                            elevation: 0,
                            builder: (_) {
                              return BlocProvider.value(
                                value: context.read<DisclosureCubit>(),
                                child: SetAnalyticsStatus(),
                              );
                            },
                            useRootNavigator: true,
                            useSafeArea: true,
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                          );
                        },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    LogosIcons.logoMarkPurple,
                    width: 50,
                    height: 50,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColorDark,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: kDefaultPadding),
                  Text(
                    "YakiHonne's note",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: kDefaultPadding / 2),
                  Text(
                    "Our app guarantees the utmost privacy by securely storing sensitive data locally on users' devices, employing stringent encryption. Rest assured, we uphold a strict no-sharing policy, ensuring that sensitive information remains confidential and never leaves the user's device.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: kDefaultPadding),
                  BlocBuilder<DisclosureCubit, DisclosureState>(
                    builder: (context, state) {
                      return TextButton(
                        onPressed: () {
                          setAnalyticsState(state.isAnalyticsEnabled);
                          context.read<RoutingCubit>().setMainView();
                        },
                        child: Text('Proceed'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void setAnalyticsState(bool isAnalyticsEnabled) {
    FirebaseAnalytics.instance
        .setAnalyticsCollectionEnabled(isAnalyticsEnabled);
    FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(isAnalyticsEnabled);
  }
}
