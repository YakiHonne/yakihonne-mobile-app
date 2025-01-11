import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/authentication_cubit/authentication_cubit.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/authentication_view/widgets/authentication_image.dart';
import 'package:yakihonne/views/authentication_view/widgets/authentication_initial.dart';
import 'package:yakihonne/views/authentication_view/widgets/authentication_keys.dart';
import 'package:yakihonne/views/authentication_view/widgets/authentication_login.dart';
import 'package:yakihonne/views/authentication_view/widgets/authentication_name.dart';

class AuthenticationView extends StatelessWidget {
  AuthenticationView({super.key}) {
    FirebaseAnalytics.instance
        .setCurrentScreen(screenName: 'Authentication screen');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthenticationCubit(
        nostrRepository: context.read<NostrDataRepository>(),
        context: context,
      ),
      child: Container(
        width: double.infinity,
        height:
            ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 60.h : 80.h,
        alignment: Alignment.center,
        margin: const EdgeInsets.all(kDefaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(kDefaultPadding),
        ),
        child: BlocBuilder<AuthenticationCubit, AuthenticationState>(
          builder: (context, state) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: getCurrentView(
                  mainView: state.signupView,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget getCurrentView({
    required AuthenticationViews mainView,
  }) {
    if (mainView == AuthenticationViews.initial) {
      return const AuthenticationInitial(
        key: Key('initial'),
      );
    } else if (mainView == AuthenticationViews.login) {
      return AuthenticationLogin(
        key: Key('login'),
      );
    } else if (mainView == AuthenticationViews.generateKeys) {
      return AuthenticationKeys(
        key: Key('keys'),
      );
    } else if (mainView == AuthenticationViews.pictureSelection) {
      return AuthenticationImage();
    } else if (mainView == AuthenticationViews.nameSelection) {
      return AuthenticationName();
    } else {
      return Container();
    }
  }
}
