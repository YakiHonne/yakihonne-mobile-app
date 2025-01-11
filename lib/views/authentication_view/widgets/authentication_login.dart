import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/authentication_cubit/authentication_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/points_management_view/widgets/points_login_popup.dart';
import 'package:yakihonne/views/widgets/modal_with_blur.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class AuthenticationLogin extends HookWidget {
  AuthenticationLogin({super.key});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final keyController = useTextEditingController();

    return ResponsiveBreakpoints.of(context).largerThan(MOBILE)
        ? TabletAuthenticationLogin(
            formKey: _formKey,
            keyController: keyController,
          )
        : MobileAuthenticationLogin(
            formKey: _formKey,
            keyController: keyController,
          );
  }
}

class TabletAuthenticationLogin extends StatelessWidget {
  const TabletAuthenticationLogin({
    super.key,
    required GlobalKey<FormState> formKey,
    required this.keyController,
  }) : _formKey = formKey;

  final GlobalKey<FormState> _formKey;
  final TextEditingController keyController;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Theme.of(context).primaryColorDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding,
                      ),
                      Text(
                        'Enter your key',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: kDimGrey,
                            ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 1.5,
                      ),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: keyController,
                          decoration:
                              InputDecoration(hintText: 'npub, nsec or hex'),
                          validator: fieldValidator,
                        ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 1.5,
                      ),
                      Text(
                        'Only the secret key can be used to publish (sign events), everything else logs you in read-only mode.',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: kDimGrey,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 1.5,
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthenticationCubit>().login(
                                      key: keyController.text.trim(),
                                      onFail: (message) {
                                        singleSnackBar(
                                          context: context,
                                          message: message,
                                          color: kRed,
                                          backGroundColor: kRedSide,
                                          icon: ToastsIcons.error,
                                        );
                                      },
                                      onSuccess: () {
                                        Navigator.pop(context);
                                        if (isUsingPrivatekey()) {
                                          showBlurredModal(
                                            context: context,
                                            view: PointsLoginPopup(),
                                          );
                                        }
                                      },
                                      onAccountDeleted: () {
                                        showDeletedAccountDialogue(
                                          context: context,
                                        );
                                      },
                                    );
                              }
                            },
                            child: Text('Login'),
                          ),
                          Visibility(
                            visible: Platform.isAndroid,
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: kDefaultPadding / 2,
                                ),
                                TextButton(
                                  onPressed: () {
                                    context
                                        .read<AuthenticationCubit>()
                                        .loginWithAmber(onSuccess: () {
                                      Navigator.pop(context);

                                      showBlurredModal(
                                        context: context,
                                        view: PointsLoginPopup(),
                                      );
                                    });
                                  },
                                  child: Text('Login with Amber'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: kDefaultPadding * 2,
                      ),
                      Text(
                        'Or create an account',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Theme.of(context).primaryColorDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding,
                      ),
                      Text(
                        'Generate a public / private key pair. Do not share your private key with anyone, this acts as your password. Once lost, it cannot be “reset” or recovered. Keep safe!',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: kDimGrey,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 1.5,
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<AuthenticationCubit>().generateKeys();

                          context
                              .read<AuthenticationCubit>()
                              .updateAuthenticationViews(
                                AuthenticationViews.generateKeys,
                              );
                        },
                        child: Text('Generate keys'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    Images.signup1,
                    fit: BoxFit.cover,
                  ),
                ),
                Align(
                  alignment: Alignment(0.98, -0.98),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: kLightGrey,
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      color: kBlack,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MobileAuthenticationLogin extends StatelessWidget {
  const MobileAuthenticationLogin({
    super.key,
    required GlobalKey<FormState> formKey,
    required this.keyController,
  }) : _formKey = formKey;

  final GlobalKey<FormState> _formKey;
  final TextEditingController keyController;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: IconButton.styleFrom(
                backgroundColor: kLightGrey,
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
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
              ),
              child: FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Theme.of(context).primaryColorDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding,
                      ),
                      Text(
                        'Enter your key',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: kDimGrey,
                            ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 1.5,
                      ),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: keyController,
                          decoration:
                              InputDecoration(hintText: 'npub, nsec or hex'),
                          validator: fieldValidator,
                        ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 1.5,
                      ),
                      Text(
                        'Only the secret key can be used to publish (sign events), everything else logs you in read-only mode.',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: kDimGrey,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 1.5,
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthenticationCubit>().login(
                                      key: keyController.text.trim(),
                                      onFail: (message) {
                                        singleSnackBar(
                                          context: context,
                                          message: message,
                                          color: kRed,
                                          backGroundColor: kRedSide,
                                          icon: ToastsIcons.error,
                                        );
                                      },
                                      onSuccess: () {
                                        Navigator.pop(context);
                                        if (isUsingPrivatekey()) {
                                          showBlurredModal(
                                            context: context,
                                            view: PointsLoginPopup(),
                                          );
                                        }
                                      },
                                      onAccountDeleted: () {
                                        showDeletedAccountDialogue(
                                          context: context,
                                        );
                                      },
                                    );
                              }
                            },
                            child: Text('Login'),
                          ),
                          Visibility(
                            visible: Platform.isAndroid,
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: kDefaultPadding / 2,
                                ),
                                TextButton(
                                  onPressed: () {
                                    context
                                        .read<AuthenticationCubit>()
                                        .loginWithAmber(onSuccess: () {
                                      Navigator.pop(context);

                                      showBlurredModal(
                                        context: context,
                                        view: PointsLoginPopup(),
                                      );
                                    });
                                  },
                                  child: Text('Login with Amber'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: kDefaultPadding * 2,
                      ),
                      Text(
                        'Or create an account',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Theme.of(context).primaryColorDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding,
                      ),
                      Text(
                        'Generate a public / private key pair. Do not share your private key with anyone, this acts as your password. Once lost, it cannot be “reset” or recovered. Keep safe!',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: kDimGrey,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 1.5,
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<AuthenticationCubit>().generateKeys();

                          context
                              .read<AuthenticationCubit>()
                              .updateAuthenticationViews(
                                AuthenticationViews.generateKeys,
                              );
                        },
                        child: Text('Generate keys'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
