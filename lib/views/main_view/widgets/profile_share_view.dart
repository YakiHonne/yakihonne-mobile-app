// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/blocs/write_flash_news_cubit/write_flash_news_cubit.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nips/nip_019.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/profile_view/profile_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class ProfileShareView extends HookWidget {
  final UserModel userModel;

  const ProfileShareView({
    Key? key,
    required this.userModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width =
        ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 40.w : 70.w;
    final isPubkeyToggled = useState(true);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple,
            Colors.blueAccent.shade400,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: kTransparent,
        appBar: AppBar(
          elevation: 0,
          forceMaterialTransparency: true,
          leading: Center(
            child: CustomIconButton(
              onClicked: () {
                Navigator.pop(context);
              },
              icon: FeatureIcons.closeRaw,
              size: 20,
              iconColor: kWhite,
              backgroundColor: kBlack.withValues(alpha: 0.5),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding,
            ),
            child: ListView(
              children: [
                Center(
                  child: ProfilePicture2(
                    size: 80,
                    image: userModel.picture.isEmpty
                        ? profileImages.first
                        : userModel.picture,
                    placeHolder: userModel.picturePlaceholder,
                    padding: 0,
                    strokeWidth: 3,
                    strokeColor: kWhite,
                    onClicked: () {},
                  ),
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Builder(
                  builder: (context) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            getAuthorDisplayName(userModel),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: kWhite,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (userModel.nip05.isNotEmpty) ...[
                          DotContainer(color: kWhite),
                          Flexible(
                            child: Text(
                              '@${getAuthorName(userModel)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                    color: kWhite,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(
                  height: kDefaultPadding / 1.5,
                ),
                Row(
                  children: [
                    Expanded(
                      child: tabContainer(
                        isPubkey: true,
                        isPubkeyToggled: isPubkeyToggled,
                        title: 'Public key',
                      ),
                    ),
                    Expanded(
                      child: tabContainer(
                        isPubkey: false,
                        isPubkeyToggled: isPubkeyToggled,
                        title: 'Lightning address',
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: kDefaultPadding * 1.5,
                ),
                Center(
                  child: Container(
                    width: width,
                    height: width,
                    padding: const EdgeInsets.all(
                      kDefaultPadding / 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kDefaultPadding),
                      border: Border.all(
                        color: kWhite,
                        width: 5,
                      ),
                    ),
                    child: PrettyQrView.data(
                      data: isPubkeyToggled.value
                          ? userModel.pubKey
                          : userModel.lud16,
                      decoration: const PrettyQrDecoration(
                        shape: PrettyQrRoundedSymbol(
                          color: kWhite,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: kDefaultPadding,
                ),
                ProfileInfoRow(
                  context: context,
                  title: 'Public key:',
                  content: Nip19.encodePubkey(userModel.pubKey),
                  copyText: 'npub was copied! 👏',
                ),
                if (userModel.lud16.isNotEmpty &&
                    userModel.lud16.contains('@')) ...[
                  const SizedBox(
                    height: kDefaultPadding / 1.5,
                  ),
                  ProfileInfoRow(
                    context: context,
                    title: 'Lightning address:',
                    content: userModel.lud16,
                    copyText: 'lightning address was copied! 👏',
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  LayoutBuilder tabContainer({
    required ValueNotifier<bool> isPubkeyToggled,
    required String title,
    required bool isPubkey,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          isPubkeyToggled.value = isPubkey;
        },
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: kWhite,
                  ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            AnimatedContainer(
              height: 4,
              width: isPubkeyToggled.value && isPubkey ||
                      !isPubkeyToggled.value && !isPubkey
                  ? constraints.maxWidth
                  : 0,
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(kDefaultPadding),
              ),
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget ProfileInfoRow({
    required BuildContext context,
    required String title,
    required String content,
    required String copyText,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: kWhite,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              Text(
                content,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: kWhite,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Clipboard.setData(
              new ClipboardData(
                text: content,
              ),
            );

            BotToastUtils.showSuccess(copyText);
          },
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
            visualDensity: VisualDensity(
              vertical: -4,
              horizontal: -2,
            ),
          ),
          icon: SvgPicture.asset(
            FeatureIcons.copy,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              kWhite,
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
    );
  }
}

class ConnectedUserProfileShareView extends StatefulWidget {
  const ConnectedUserProfileShareView({super.key});

  @override
  State<ConnectedUserProfileShareView> createState() =>
      _ConnectedUserProfileShareViewState();
}

class _ConnectedUserProfileShareViewState
    extends State<ConnectedUserProfileShareView> {
  bool isQRcodeShown = true;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Platform.isAndroid) {
        controller!.pauseCamera();
      } else if (Platform.isIOS) {
        controller!.resumeCamera();
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width =
        ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 50.w : 70.w;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange,
            Colors.purple,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: kTransparent,
        appBar: AppBar(
          elevation: 0,
          forceMaterialTransparency: true,
          leading: Center(
            child: CustomIconButton(
              onClicked: () {
                Navigator.pop(context);
              },
              icon: FeatureIcons.closeRaw,
              size: 20,
              iconColor: kWhite,
              backgroundColor: kBlack.withValues(alpha: 0.5),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding,
            ),
            child: Column(
              children: [
                Expanded(
                  child: isQRcodeShown
                      ? CurrentUserQrCode()
                      : Column(
                          children: [
                            Center(
                              child: Text(
                                'Scan user QR code',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: kWhite,
                                    ),
                              ),
                            ),
                            const SizedBox(
                              height: kDefaultPadding,
                            ),
                            Container(
                              width: width,
                              height: width,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  kDefaultPadding + 5,
                                ),
                                child: QRView(
                                  key: qrKey,
                                  onQRViewCreated: (controller) =>
                                      _onQRViewCreated(
                                    controller,
                                    context: context,
                                  ),
                                  overlay: QrScannerOverlayShape(
                                    borderRadius: kDefaultPadding,
                                    borderColor: kWhite,
                                    borderWidth: 5,
                                    cutOutSize: width,
                                  ),
                                  overlayMargin: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        isQRcodeShown = !isQRcodeShown;
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: kWhite,
                    ),
                    child: Text(
                      isQRcodeShown ? 'Scan QR code' : 'View QR code',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: kBlack,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onQRViewCreated(
    QRViewController controller, {
    required BuildContext context,
  }) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        RegExpMatch? selectedMatch = userRegex.firstMatch(scanData.code!);
        if (selectedMatch != null) {
          var key = selectedMatch.group(2)! + selectedMatch.group(3)!;
          String pubkey = '';

          if (key.startsWith('npub')) {
            pubkey = Nip19.decodePubkey(key);
          } else if (key.startsWith('nprofile')) {
            final data = Nip19.decodeShareableEntity(key);
            pubkey = data['special'];
          }

          Navigator.pop(context);

          Navigator.pushNamed(
            context,
            ProfileView.routeName,
            arguments: pubkey,
          );
        }
      }
    });
  }
}

class CurrentUserQrCode extends StatelessWidget {
  const CurrentUserQrCode({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final width =
        ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 50.w : 70.w;

    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        final npub = 'nostr:${state.pubKey}';

        return ListView(
          children: [
            Center(
              child: ProfilePicture2(
                size: 90,
                image: state.image.isEmpty ? profileImages.first : state.image,
                placeHolder: state.random,
                padding: 0,
                strokeWidth: 3,
                strokeColor: kWhite,
                onClicked: () {
                  openProfileFastAccess(
                    context: context,
                    pubkey: Nip19.decodePubkey(state.pubKey),
                  );
                },
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Center(
              child: Text(
                state.name,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: kWhite,
                    ),
              ),
            ),
            Center(
              child: BlocBuilder<AuthorsCubit, AuthorsState>(
                builder: (context, authState) {
                  final decodedPubkey = Nip19.decodePubkey(state.pubKey);
                  final author = authState.authors[decodedPubkey];

                  final nip05 = author?.nip05 ?? '';

                  if (author != null && nip05.isNotEmpty) {
                    return Text(
                      '@${getAuthorName(author)}',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: kWhite,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  } else {
                    return SizedBox();
                  }
                },
              ),
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Center(
              child: Container(
                width: width,
                height: width,
                padding: const EdgeInsets.all(
                  kDefaultPadding / 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                  border: Border.all(
                    color: kWhite,
                    width: 5,
                  ),
                ),
                child: PrettyQrView.data(
                  data: npub,
                  decoration: const PrettyQrDecoration(
                    shape: PrettyQrRoundedSymbol(
                      color: kWhite,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        ProfileView.routeName,
                        arguments: Nip19.decodePubkey(state.pubKey),
                      );
                    },
                    style: TextButton.styleFrom(
                        backgroundColor: kWhite,
                        visualDensity: VisualDensity(
                          vertical: -2,
                        )),
                    icon: Text(
                      'Visit profile',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: kBlack,
                          ),
                    ),
                    label: Icon(
                      Icons.arrow_outward_rounded,
                      size: 18,
                      color: kBlack,
                    ),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 4,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        new ClipboardData(
                          text: npub,
                        ),
                      );

                      BotToastUtils.showSuccess(
                        'npub was copied! 👏',
                      );
                    },
                    style: TextButton.styleFrom(
                        backgroundColor: kWhite,
                        visualDensity: VisualDensity(
                          vertical: -2,
                        )),
                    icon: Text(
                      'Copy npub',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: kBlack,
                          ),
                    ),
                    label: SvgPicture.asset(
                      FeatureIcons.copy,
                      width: 15,
                      height: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Center(
              child: Text(
                'Follow me on Nostr',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: kWhite,
                    ),
              ),
            ),
            Center(
              child: Text(
                'Scan the QR code',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: kWhite,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
