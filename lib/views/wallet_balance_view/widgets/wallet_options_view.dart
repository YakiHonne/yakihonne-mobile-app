// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/lightning_zaps_cubit/lightning_zaps_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';

class WalletOptions extends HookWidget {
  WalletOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final isMainView = useState(true);
    final link = useTextEditingController();

    return BlocListener<LightningZapsCubit, LightningZapsState>(
      listenWhen: (previous, current) =>
          previous.shouldPopView != current.shouldPopView,
      listener: (context, state) {
        Navigator.pop(context);
      },
      child: Container(
        width: isTablet ? 50.w : double.infinity,
        margin: const EdgeInsets.all(kDefaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(kDefaultPadding),
        ),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Visibility(
                  visible: !isMainView.value,
                  maintainState: true,
                  maintainSize: true,
                  maintainAnimation: true,
                  child: IconButton(
                    onPressed: () {
                      isMainView.value = true;
                    },
                    icon: Icon(Icons.arrow_back_ios),
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity(
                        vertical: -2,
                        horizontal: -4,
                      ),
                    ),
                  ),
                ),
                Text(
                  'Wallet',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                CustomIconButton(
                  onClicked: () {
                    Navigator.pop(context);
                  },
                  icon: FeatureIcons.closeRaw,
                  size: 20,
                  vd: -2,
                  backgroundColor: Theme.of(context).primaryColorLight,
                ),
              ],
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            if (!isMainView.value) ...[
              Text(
                'Click below to connect',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(
                height: kDefaultPadding / 1.5,
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorDark,
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                ),
                child: TextButton(
                  onPressed: () {
                    context.read<LightningZapsCubit>().launchUrl(true);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: kTransparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        FeatureIcons.nwc,
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      Text(
                        'Connect with NWC',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).primaryColorLight,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorDark,
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                ),
                child: TextButton(
                  onPressed: () async {
                    final clipboardData =
                        await Clipboard.getData(Clipboard.kTextPlain);
                    String? clipboardText = clipboardData?.text;

                    if (clipboardText != null && clipboardText.isNotEmpty) {
                      context
                          .read<LightningZapsCubit>()
                          .verifyUri(clipboardText);
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: kTransparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.paste_rounded,
                        color: Theme.of(context).primaryColorLight,
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      Text(
                        'Paste NWC address',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).primaryColorLight,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
            ] else ...[
              WalletOption(
                icon: FeatureIcons.nwc,
                title: 'Nostr wallet connect',
                description: 'Native nostr wallet connection',
                onClicked: () {
                  isMainView.value = false;
                  link.clear();
                },
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              WalletOption(
                icon: FeatureIcons.alby,
                title: 'Alby',
                description: 'Alby connect',
                onClicked: () {
                  context.read<LightningZapsCubit>().launchUrl(false);
                },
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
              Text(
                'Note: All the data related to your wallet will be safely and securely stored locally and are never shared outside the confines of the application.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class WalletOption extends StatelessWidget {
  const WalletOption({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onClicked,
  }) : super(key: key);

  final String title;
  final String description;
  final String icon;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
          color: Theme.of(context).primaryColorLight,
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              width: 30,
              height: 30,
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall!
                        .copyWith(color: kDimGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Icon(Icons.add),
          ],
        ),
      ),
    );
  }
}
