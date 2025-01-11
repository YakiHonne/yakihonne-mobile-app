// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:numeral/numeral.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/lightning_zaps_cubit/lightning_zaps_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/properties_view/widgets/update_zap_value.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';

class ZapsView extends HookWidget {
  const ZapsView({super.key});

  static const routeName = '/zapsView';
  static Route route() {
    return CupertinoPageRoute(
      builder: (_) => ZapsView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWalletListCollapsed = useState(true);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Zaps configuration',
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
            vertical: kDefaultPadding,
          ),
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
              child: Text(
                'Set custom zaps',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: kDimGrey,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            GridView.builder(
              shrinkWrap: true,
              primary: false,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    ResponsiveBreakpoints.of(context).largerThan(MOBILE)
                        ? 8
                        : 4,
              ),
              itemBuilder: (context, index) {
                return ZapContainer(
                  index: index,
                  isSelected: false,
                );
              },
              itemCount: 8,
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Builder(builder: (context) {
              return Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () {
                    context.read<LightningZapsCubit>().setDefaultZapsValues();
                  },
                  child: Text('Restore defaults'),
                ),
              );
            }),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
              child: Text(
                'Set default wallet',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: kDimGrey,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            ExternalWalletContainer(
                isWalletListCollapsed: isWalletListCollapsed),
          ],
        ),
      ),
    );
  }
}

class ExternalWalletContainer extends StatelessWidget {
  const ExternalWalletContainer({
    super.key,
    required this.isWalletListCollapsed,
  });

  final ValueNotifier<bool> isWalletListCollapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        color: Theme.of(context).primaryColorLight,
      ),
      child: GestureDetector(
        onTap: () {
          isWalletListCollapsed.value = !isWalletListCollapsed.value;
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
                vertical: kDefaultPadding / 1.5,
              ),
              child: BlocBuilder<LightningZapsCubit, LightningZapsState>(
                buildWhen: (previous, current) =>
                    previous.defaultExternalWallet !=
                    current.defaultExternalWallet,
                builder: (context, state) {
                  String title = '';
                  String icon = '';

                  title = wallets[state.defaultExternalWallet]!['name']!;
                  icon = wallets[state.defaultExternalWallet]!['icon']!;

                  return Row(
                    children: [
                      Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            kDefaultPadding / 4,
                          ),
                          image: DecorationImage(
                            image: AssetImage(
                              icon,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 1.5,
                      ),
                      Expanded(
                        child: Text(
                          title.isEmpty ? 'Local default' : title,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      Icon(
                        isWalletListCollapsed.value
                            ? Icons.keyboard_arrow_down_outlined
                            : Icons.keyboard_arrow_up_outlined,
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ],
                  );
                },
              ),
            ),
            BlocBuilder<LightningZapsCubit, LightningZapsState>(
              builder: (context, state) {
                if (isWalletListCollapsed.value) {
                  return SizedBox.shrink();
                } else {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kDefaultPadding,
                        ),
                        child: Divider(
                          height: 0,
                        ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                      ...wallets.keys.map((wallet) {
                        if (wallet.isEmpty) {
                          return SizedBox.shrink();
                        } else {
                          final title = wallets[wallet]!['name']!;
                          final icon = wallets[wallet]!['icon']!;
                          return WalletContainer(
                            title: title,
                            icon: icon,
                            isSelected: wallet == state.defaultExternalWallet,
                            onClicked: () {
                              context
                                  .read<LightningZapsCubit>()
                                  .setDefaultWallet(wallet);

                              isWalletListCollapsed.value =
                                  !isWalletListCollapsed.value;
                            },
                          );
                        }
                      }).toList(),
                      const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class WalletContainer extends StatelessWidget {
  const WalletContainer({
    Key? key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onClicked,
  }) : super(key: key);

  final String title;
  final String icon;
  final bool isSelected;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
          vertical: kDefaultPadding / 2,
        ),
        child: Row(
          children: [
            Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                image: DecorationImage(
                  image: AssetImage(
                    icon,
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 1.5,
            ),
            Expanded(
              child: Text(
                title.isEmpty ? 'Local default' : title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            if (isSelected)
              SvgPicture.asset(
                ToastsIcons.check,
                width: 20,
                height: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class ZapContainer extends StatelessWidget {
  const ZapContainer({
    Key? key,
    required this.index,
    required this.isSelected,
  }) : super(key: key);

  final int index;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LightningZapsCubit, LightningZapsState>(
      builder: (context, state) {
        final zap = state.zapsValues.values.toList()[index];
        final icon = zap['icon'];
        final value = zap['value'];

        return GestureDetector(
          onTap: () {
            updateZap(
              context: context,
              index: index,
              value: zap,
            );
          },
          behavior: HitTestBehavior.translucent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              color: Theme.of(context).primaryColorLight,
              border: Border.all(
                width: 0.5,
                color: isSelected ? kPurple : kTransparent,
              ),
            ),
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            margin: const EdgeInsets.all(5),
            child: LayoutBuilder(
              builder: (context, constraint) {
                return SizedBox(
                  height: constraint.maxHeight,
                  child: Column(
                    children: [
                      Flexible(
                        child: SvgPicture.asset(
                          icon,
                          fit: BoxFit.scaleDown,
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: Text(
                          Numeral(num.parse(value.toString())).toString(),
                          style: TextStyle(height: 1),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void updateZap({
    required BuildContext context,
    required int index,
    required Map<String, dynamic> value,
  }) {
    showModalBottomSheet(
      context: context,
      elevation: 0,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<LightningZapsCubit>(),
          child: UpdateZapValue(
            index: index,
            values: value,
          ),
        );
      },
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}
