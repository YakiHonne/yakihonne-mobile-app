import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authentication_cubit/authentication_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class AuthenticationName extends HookWidget {
  AuthenticationName({super.key});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();

    return ResponsiveBreakpoints.of(context).largerThan(MOBILE)
        ? TabletAuthenticationName(
            formKey: _formKey,
            nameController: nameController,
          )
        : MobileAuthenticationName(
            formKey: _formKey,
            nameController: nameController,
          );
  }
}

class TabletAuthenticationName extends StatelessWidget {
  const TabletAuthenticationName({
    super.key,
    required GlobalKey<FormState> formKey,
    required this.nameController,
  }) : _formKey = formKey;

  final GlobalKey<FormState> _formKey;
  final TextEditingController nameController;

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pick a username',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Theme.of(context).primaryColorDark,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    Text(
                      'You can change your name whenever you want, it is not permanent and it is not unique.',
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
                        controller: nameController,
                        decoration:
                            InputDecoration(hintText: 'Eg. Smart Nostrich'),
                        validator: fieldValidator,
                      ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 1.5,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).primaryColorLight,
                            side: BorderSide(
                              color: kPurple,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: Theme.of(context).primaryColorDark,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 2,
                        ),
                        TextButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              context.read<AuthenticationCubit>().setName(
                                    name: nameController.text,
                                    onFailed: () {
                                      singleSnackBar(
                                        context: context,
                                        message:
                                            'Error occured. cannot proceed',
                                        color: kRed,
                                        backGroundColor: kRedSide,
                                        icon: ToastsIcons.error,
                                      );
                                    },
                                    onSuccess: () {
                                      Navigator.pop(context);
                                    },
                                  );
                            }
                          },
                          child: Text('Finish'),
                        ),
                      ],
                    )
                  ],
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
                    Images.onboarding5,
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

class MobileAuthenticationName extends StatelessWidget {
  const MobileAuthenticationName({
    super.key,
    required GlobalKey<FormState> formKey,
    required this.nameController,
  }) : _formKey = formKey;

  final GlobalKey<FormState> _formKey;
  final TextEditingController nameController;

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
                        'Pick a username',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Theme.of(context).primaryColorDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding,
                      ),
                      Text(
                        'You can change your name whenever you want, it is not permanent and it is not unique.',
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
                          controller: nameController,
                          decoration:
                              InputDecoration(hintText: 'Eg. Smart Nostrich'),
                          validator: fieldValidator,
                        ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 1.5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).primaryColorLight,
                              side: BorderSide(
                                color: kPurple,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: Theme.of(context).primaryColorDark,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 2,
                          ),
                          TextButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthenticationCubit>().setName(
                                      name: nameController.text,
                                      onFailed: () {
                                        singleSnackBar(
                                          context: context,
                                          message:
                                              'Error occured. cannot proceed',
                                          color: kRed,
                                          backGroundColor: kRedSide,
                                          icon: ToastsIcons.error,
                                        );
                                      },
                                      onSuccess: () {
                                        Navigator.pop(context);
                                      },
                                    );
                              }
                            },
                            child: Text('Finish'),
                          ),
                        ],
                      )
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
