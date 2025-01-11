import 'package:flutter/material.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/authentication_view/authentication_view.dart';
import 'package:yakihonne/views/widgets/modal_with_blur.dart';

class NoPrivateWidget extends StatelessWidget {
  const NoPrivateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onClicked,
  });

  final String icon;
  final String title;
  final String description;
  final String buttonText;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      from: 50,
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              icon,
              width: 40.w,
              height: 40.w,
              fit: BoxFit.contain,
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).primaryColorDark,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            TextButton(
              onPressed: onClicked,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

class NotConnectedWidget extends StatelessWidget {
  const NotConnectedWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            PagesIcons.notConnected,
            width: 35.w,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Text(
            "You're not connected",
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).primaryColorDark,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Text(
            "It seems that you're not connected to the NOSTR network, please sign in and join the community.",
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).hintColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          TextButton(
            onPressed: () {
              showBlurredModal(
                context: context,
                view: AuthenticationView(),
              );
            },
            child: Text('Login'),
          ),
        ],
      ),
    );
  }
}

class NoInternetView extends StatelessWidget {
  const NoInternetView({
    super.key,
    required this.onClicked,
    required this.isButtonEnabled,
  });

  final Function() onClicked;
  final bool isButtonEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            PagesIcons.noData,
            width: 35.w,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Text(
            'No internet access',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          NoInternetRow(
            title: 'Check your modem or router',
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          NoInternetRow(
            title: 'Reconnect to a wifi',
          ),
          if (isButtonEnabled) ...[
            const SizedBox(
              height: kDefaultPadding,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onClicked,
                  child: Text(
                    'Try again',
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}

class NoInternetRow extends StatelessWidget {
  const NoInternetRow({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          ToastsIcons.check,
          colorFilter: const ColorFilter.mode(kDimGrey, BlendMode.srcATop),
          width: 5.w,
        ),
        const SizedBox(
          width: 10,
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class WrongView extends StatelessWidget {
  const WrongView({
    super.key,
    required this.onClicked,
  });

  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            PagesIcons.noData,
            width: 35.w,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Text(
            'Something went wrong !',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Text(
            'It looks like something happened while loading the data, try again!',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).hintColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding + 10,
          ),
          TextButton(
            onPressed: onClicked,
            child: Text('refresh'),
          ),
        ],
      ),
    );
  }
}
