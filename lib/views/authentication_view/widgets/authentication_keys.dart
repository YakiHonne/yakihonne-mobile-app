import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/authentication_cubit/authentication_cubit.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class AuthenticationKeys extends StatelessWidget {
  const AuthenticationKeys({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBreakpoints.of(context).largerThan(MOBILE)
        ? TabletAuthenticationKeys()
        : MobileAuthenticationKeys();
  }
}

class TabletAuthenticationKeys extends StatelessWidget {
  const TabletAuthenticationKeys({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: FadeInUp(
              duration: const Duration(milliseconds: 300),
              child: Scrollbar(
                child: Padding(
                  padding: EdgeInsets.all(kDefaultPadding),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save your keys!',
                          style:
                              Theme.of(context).textTheme.titleLarge!.copyWith(
                                    color: Theme.of(context).primaryColorDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        Text(
                          'Your private key is your password. If you lose this key, you will lose access to your account! Copy it and keep it in a safe place. There is no way to reset your private key.',
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: kDimGrey,
                                  ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        BlocBuilder<AuthenticationCubit, AuthenticationState>(
                          builder: (context, state) {
                            return Column(
                              children: [
                                DottedContainer(
                                  title: 'Your secret key',
                                  onClicked: () {
                                    Clipboard.setData(
                                      new ClipboardData(
                                        text: Nip19.encodePrivkey(
                                          state.authPrivKey,
                                        ),
                                      ),
                                    );

                                    singleSnackBar(
                                      context: context,
                                      message: 'Private key was copied! 👏',
                                      color: kGreen,
                                      backGroundColor: kGreenSide,
                                      icon: ToastsIcons.success,
                                    );
                                  },
                                  value: state.authPrivKey,
                                ),
                                const SizedBox(
                                  height: kDefaultPadding,
                                ),
                                DottedContainer(
                                  title: 'Your public key',
                                  onClicked: () {
                                    Clipboard.setData(
                                      new ClipboardData(
                                        text: Nip19.encodePrivkey(
                                          state.authPubKey,
                                        ),
                                      ),
                                    );

                                    singleSnackBar(
                                      context: context,
                                      message: 'Public key was copied! 👏',
                                      color: kGreen,
                                      backGroundColor: kGreenSide,
                                      icon: ToastsIcons.success,
                                    );
                                  },
                                  value: state.authPubKey,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 1.5,
                        ),
                        TextButton(
                          onPressed: () {
                            context
                                .read<AuthenticationCubit>()
                                .updateAuthenticationViews(
                                    AuthenticationViews.pictureSelection);
                          },
                          child: Text('Keys are saved! Let me in!'),
                        ),
                        const SizedBox(
                          height: kDefaultPadding * 2,
                        ),
                        Text(
                          'Or login',
                          style:
                              Theme.of(context).textTheme.titleLarge!.copyWith(
                                    color: Theme.of(context).primaryColorDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        Text(
                          'You can login now if you have created already an account or use an extension to access your account securely',
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: kDimGrey,
                                    height: 1.5,
                                  ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 1.5,
                        ),
                        TextButton(
                          onPressed: () {
                            context
                                .read<AuthenticationCubit>()
                                .selectPicture(0);
                            context
                                .read<AuthenticationCubit>()
                                .updateAuthenticationViews(
                                    AuthenticationViews.login);
                          },
                          child: Text('Login'),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                      ],
                    ),
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
                    Images.onboarding4,
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

class MobileAuthenticationKeys extends StatelessWidget {
  const MobileAuthenticationKeys({
    super.key,
  });

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
            child: FadeInUp(
              duration: const Duration(milliseconds: 300),
              child: Scrollbar(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    kDefaultPadding,
                    0,
                    kDefaultPadding,
                    kDefaultPadding,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save your keys!',
                          style:
                              Theme.of(context).textTheme.titleLarge!.copyWith(
                                    color: Theme.of(context).primaryColorDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        Text(
                          'Your private key is your password. If you lose this key, you will lose access to your account! Copy it and keep it in a safe place. There is no way to reset your private key.',
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: kDimGrey,
                                  ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        BlocBuilder<AuthenticationCubit, AuthenticationState>(
                          builder: (context, state) {
                            return Column(
                              children: [
                                DottedContainer(
                                  title: 'Your secret key',
                                  onClicked: () {
                                    Clipboard.setData(
                                      new ClipboardData(
                                        text: state.authPrivKey,
                                      ),
                                    );

                                    singleSnackBar(
                                      context: context,
                                      message: 'Private key was copied! 👏',
                                      color: kGreen,
                                      backGroundColor: kGreenSide,
                                      icon: ToastsIcons.success,
                                    );
                                  },
                                  value: state.authPrivKey,
                                ),
                                const SizedBox(
                                  height: kDefaultPadding,
                                ),
                                DottedContainer(
                                  title: 'Your public key',
                                  onClicked: () {
                                    Clipboard.setData(
                                      new ClipboardData(
                                        text: state.authPubKey,
                                      ),
                                    );

                                    singleSnackBar(
                                      context: context,
                                      message: 'Public key was copied! 👏',
                                      color: kGreen,
                                      backGroundColor: kGreenSide,
                                      icon: ToastsIcons.success,
                                    );
                                  },
                                  value: state.authPubKey,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 1.5,
                        ),
                        TextButton(
                          onPressed: () {
                            context
                                .read<AuthenticationCubit>()
                                .updateAuthenticationViews(
                                    AuthenticationViews.pictureSelection);
                          },
                          child: Text('Keys are saved! Let me in!'),
                        ),
                        const SizedBox(
                          height: kDefaultPadding * 2,
                        ),
                        Text(
                          'Or login',
                          style:
                              Theme.of(context).textTheme.titleLarge!.copyWith(
                                    color: Theme.of(context).primaryColorDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        Text(
                          'You can login now if you have already created an account.',
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: kDimGrey,
                                    height: 1.5,
                                  ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 1.5,
                        ),
                        TextButton(
                          onPressed: () {
                            context
                                .read<AuthenticationCubit>()
                                .selectPicture(0);
                            context
                                .read<AuthenticationCubit>()
                                .updateAuthenticationViews(
                                    AuthenticationViews.login);
                          },
                          child: Text('Login'),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                      ],
                    ),
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

class DottedContainer extends StatelessWidget {
  const DottedContainer({
    super.key,
    required this.onClicked,
    required this.value,
    required this.title,
    this.isShown,
    this.fullText,
  });

  final Function() onClicked;
  final String value;
  final String title;
  final bool? isShown;
  final bool? fullText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: isShown != null
              ? Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                  )
              : Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: kDimGrey,
                  ),
        ),
        const SizedBox(
          height: kDefaultPadding / 1.5,
        ),
        DottedBorder(
          color: Theme.of(context).primaryColorDark,
          strokeCap: StrokeCap.round,
          borderType: BorderType.RRect,
          radius: Radius.circular(kDefaultPadding - 5),
          dashPattern: [4],
          child: Row(
            children: [
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Expanded(
                child: Text(
                  isShown == null || isShown!
                      ? fullText != null
                          ? value
                          : '${value.substring(0, 10)}...${value.substring(value.length - 10, value.length)}'
                      : '●●●●●●●●●●●●●●●●',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                onPressed: onClicked,
                icon: isShown == null || isShown!
                    ? SvgPicture.asset(
                        FeatureIcons.copy,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).primaryColorDark,
                          BlendMode.srcIn,
                        ),
                      )
                    : Text(
                        'show',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
