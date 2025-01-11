// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/authentication_view/widgets/authentication_keys.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

import '../../../nostr/nips/nips.dart';

class KeysView extends HookWidget {
  const KeysView({
    required this.pubkey,
    required this.secKey,
    required this.isUsingSigner,
  });

  static const routeName = '/keysView';
  static Route route(RouteSettings settings) {
    final keys = settings.arguments as List<dynamic>;

    return CupertinoPageRoute(
      builder: (_) => KeysView(
        pubkey: keys[0],
        secKey: keys[1],
        isUsingSigner: keys[2],
      ),
    );
  }

  final String pubkey;
  final String secKey;
  final bool isUsingSigner;

  @override
  Widget build(BuildContext context) {
    final secretKey = useState(false);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My keys',
      ),
      body: ListView(
        padding: const EdgeInsets.all(kDefaultPadding),
        children: [
          DottedContainer(
            title: 'My public key',
            onClicked: () {
              Clipboard.setData(
                new ClipboardData(
                  text: Nip19.encodePubkey(
                    pubkey,
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
            isShown: true,
            value: Nip19.encodePubkey(
              pubkey,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            'This key can be shared publicly anywhere with anyone.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          DottedContainer(
            title: 'My secret key',
            isShown: secretKey.value,
            onClicked: () {
              if (!secretKey.value) {
                showDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          secretKey.value = true;
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: kTransparent,
                        ),
                        child: Text(
                          'show',
                          style: TextStyle(
                            color: Theme.of(context).primaryColorDark,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'cancel',
                          style: TextStyle(color: kRed),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: kTransparent,
                        ),
                      ),
                    ],
                    title: Text(
                      'Show secret key!',
                      style: TextStyle(
                        height: 1.5,
                      ),
                    ),
                    content: Text(
                      'Make sure to keep it safe as it gives a full access to your account.',
                    ),
                  ),
                );
              } else {
                if (isUsingSigner) {
                  BotToastUtils.showError('You are using an external signer');
                } else {
                  Clipboard.setData(
                    new ClipboardData(
                      text: Nip19.encodePrivkey(
                        secKey,
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
                }
              }
            },
            fullText: true,
            value: isUsingSigner
                ? 'Using an external signer'
                : Nip19.encodePrivkey(
                    secKey,
                  ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: kOrange,
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Expanded(
                child: Text(
                  'This key should be kept safe. You can copy it to either securely store it or to connect to another Nostr clients.',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        height: 1.5,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding * 2,
          ),
          Text(
            'Note',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            SECURE_STORAGE,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  final SECURE_STORAGE =
      "Your keys are stored exclusively within the app's local secure storage, fortified against external threats. Rest assured, we uphold a strict policy of non-disclosure, ensuring your keys remain confidential and are never shared outside the confines of the application.";
}
