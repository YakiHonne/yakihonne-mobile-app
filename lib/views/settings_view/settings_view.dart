// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/disclosure_cubit/disclosure_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/properties_view/widgets/mute_list_view.dart';
import 'package:yakihonne/views/version_news/version_news.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class SettingsView extends HookWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = useState(themeCubit.state.textScaleFactor);

    return ListView(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding,
        horizontal: kDefaultPadding / 2,
      ),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
            vertical: kDefaultPadding / 2,
          ),
          margin: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
            borderRadius: BorderRadius.circular(kDefaultPadding),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Font Size',
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Icon(
                      Icons.font_download_outlined,
                      size: kDefaultPadding,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              SliderTheme(
                data: SliderThemeData(
                  overlayShape: SliderComponentShape.noOverlay,
                  inactiveTickMarkColor: kTransparent,
                  activeTickMarkColor: kTransparent,
                ),
                child: Slider(
                  value: textScaleFactor.value,
                  min: 0.8,
                  max: 1.25,
                  divisions: 8,
                  onChanged: (double value) {
                    textScaleFactor.value = value;
                    themeCubit.setTextScaleFactor(value);
                  },
                ),
              ),
              AbsorbPointer(
                absorbing: true,
                child: linkifiedText(
                  context: context,
                  text:
                      'note1m80wgfxkh3awamrz8vu0qm45jsq0tyv7zw4uuaclldqgnrjlvmjsccq5v6',
                ),
              ),
            ],
          ),
        ),
        BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) {
            return SettingsOptionRow(
              onClicked: () async {
                context.read<ThemeCubit>().toggleTheme();
              },
              title: 'App theme',
              isToggled: state.theme == AppTheme.purpleWhite,
              firstIcon: Icons.wb_sunny_outlined,
              secondIcon: Icons.nights_stay_outlined,
            );
          },
        ),
        BlocProvider(
          create: (context) => DisclosureCubit(
            localDatabaseRepository: context.read<LocalDatabaseRepository>(),
          ),
          child: BlocBuilder<DisclosureCubit, DisclosureState>(
            builder: (context, state) {
              return SettingsOptionRow(
                onClicked: () async {
                  if (state.isAnalyticsEnabled) {
                    context.read<DisclosureCubit>().setAnalyticsStatus(false);
                    BotToastUtils.showSuccess(
                      'Analytics and crashlytics have been turned off.',
                    );
                  } else {
                    context.read<DisclosureCubit>().setAnalyticsStatus(true);
                    BotToastUtils.showSuccess(
                      'Analytics and crashlytics have been turned on.',
                    );
                  }
                },
                title: 'Crashlytics & Analytics',
                isToggled: state.isAnalyticsEnabled,
                firstIcon: CupertinoIcons.play_circle,
                secondIcon: CupertinoIcons.pause_circle,
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding,
            vertical: kDefaultPadding / 2,
          ),
          margin: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
            borderRadius: BorderRadius.circular(kDefaultPadding),
          ),
          child: Row(
            children: [
              Text(
                'Clear app cache',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Spacer(),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              TextButton(
                onPressed: () {
                  showCupertinoCustomDialogue(
                    context: context,
                    title: 'Clear app cache',
                    description:
                        'You are about to clear the app cache, do you wish to proceed?',
                    buttonText: 'clear',
                    buttonTextColor: kRed,
                    onClicked: () async {
                      final res = await NostrFunctionsRepository.clearCache();
                      if (res) {
                        Navigator.pop(context);
                      }
                    },
                  );
                },
                child: Text(
                  'clear',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium!
                      .copyWith(color: kRed),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: kTransparent,
                  visualDensity: VisualDensity(vertical: -3),
                ),
              ),
            ],
          ),
        ),
        StreamBuilder(
          stream: nostrRepository.userModelStream,
          builder: (context, snapshot) {
            if ((nostrRepository.usm == null ||
                !nostrRepository.usm!.isUsingPrivKey)) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding,
                  vertical: kDefaultPadding / 2,
                ),
                margin:
                    const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorLight,
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                ),
                child: Row(
                  children: [
                    Text(
                      'Mute list',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const Spacer(),
                    const SizedBox(
                      width: kDefaultPadding / 4,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          MuteListView.routeName,
                        );
                      },
                      child: Text(
                        'edit',
                        style:
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  color: Theme.of(context).primaryColorDark,
                                ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: kTransparent,
                        visualDensity: VisualDensity(vertical: -3),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return SizedBox.shrink();
            }
          },
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        Center(
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                decoration: BoxDecoration(
                  color: kPurple,
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                ),
                child: SvgPicture.asset(LogosIcons.logoMarkWhite),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Text(
                appVersion,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    createViewFromBottom(
                      VersionNews(
                        onClosed: () {},
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: kTransparent,
                  visualDensity: VisualDensity(vertical: -4),
                ),
                child: Text(
                  "see what's new",
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        fontStyle: FontStyle.italic,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 1.5,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: Text(
                  'Please take into consideration that the app is still under developement, which might introduce small issues in some cases. We are doing our best to provide and improve the overall experience of the app.',
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsOptionRow extends StatelessWidget {
  const SettingsOptionRow({
    Key? key,
    required this.onClicked,
    required this.title,
    required this.isToggled,
    required this.firstIcon,
    required this.secondIcon,
  }) : super(key: key);

  final Function() onClicked;
  final String title;
  final bool isToggled;
  final IconData firstIcon;
  final IconData secondIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      margin: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClicked,
            behavior: HitTestBehavior.translucent,
            child: SizedBox(
              width: 100,
              height: 30,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        kDefaultPadding * 2,
                      ),
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                  AnimatedPositioned(
                    right: isToggled ? 50 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      height: 30,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          kDefaultPadding * 2,
                        ),
                        color: kPurple,
                      ),
                    ),
                  ),
                  BlocBuilder<ThemeCubit, ThemeState>(
                    builder: (context, state) {
                      return Positioned.fill(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: Icon(
                                key: const Key('sunny'),
                                firstIcon,
                                size: 20,
                                color: !isToggled &&
                                        state.theme == AppTheme.purpleWhite
                                    ? kBlack
                                    : kWhite,
                              ),
                            ),
                            Expanded(
                              child: Icon(
                                key: const Key('night'),
                                secondIcon,
                                size: 20,
                                color: isToggled &&
                                        state.theme == AppTheme.purpleWhite
                                    ? kBlack
                                    : kWhite,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
