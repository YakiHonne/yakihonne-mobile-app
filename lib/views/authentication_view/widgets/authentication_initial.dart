import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/authentication_cubit/authentication_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/authentication_view/widgets/eula_view.dart';

class AuthenticationInitial extends StatelessWidget {
  const AuthenticationInitial({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          height: 100.h,
          foregroundDecoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kBlack,
                kTransparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: [0.2, 0.8],
            ),
          ),
          child: Image.asset(
            Images.signup2,
            fit: BoxFit.cover,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: kWhite,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    color: kBlack,
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(kDefaultPadding),
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Welcome to Yakihonne',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    color: kWhite,
                                    fontWeight: FontWeight.w800,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        Text(
                          'Enjoy the experience of owning your own data!',
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: kLightGrey,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(fontSize: 8),
                            children: [
                              TextSpan(
                                text: 'By continuing you agree with our\n',
                              ),
                              TextSpan(
                                text: 'End User Licence Agreement (EULA)',
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
                                        return EulaView();
                                      },
                                      useRootNavigator: true,
                                      useSafeArea: true,
                                      isScrollControlled: true,
                                      backgroundColor: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        TextButton.icon(
                            onPressed: () {
                              context
                                  .read<AuthenticationCubit>()
                                  .updateAuthenticationViews(
                                      AuthenticationViews.login);
                            },
                            icon: Text(
                              'Join us',
                            ),
                            label: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 15,
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: kTransparent,
                            )),
                        const SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
