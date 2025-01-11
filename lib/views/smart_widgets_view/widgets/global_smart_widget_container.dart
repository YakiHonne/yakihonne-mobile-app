// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yakihonne/blocs/smart_widgets_cubit/smart_widgets_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_checker.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_container.dart';
import 'package:yakihonne/views/widgets/note_container.dart';
import 'package:yakihonne/views/widgets/share_view.dart';
import 'package:yakihonne/views/write_smart_widget_view/write_smart_widget_view.dart';

class GlobalSmartWidgetContainer extends StatelessWidget {
  const GlobalSmartWidgetContainer({
    Key? key,
    required this.smartWidgetModel,
    required this.onClone,
    this.onClicked,
    this.canPerformOwnerActions,
  }) : super(key: key);

  final SmartWidgetModel smartWidgetModel;
  final Function() onClone;
  final Function()? onClicked;
  final bool? canPerformOwnerActions;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      child: AbsorbPointer(
        absorbing: onClicked != null,
        child: Container(
          padding: const EdgeInsets.all(
            kDefaultPadding / 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              kDefaultPadding / 2,
            ),
            color: Theme.of(context).primaryColorLight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ProfileInfoHeader(
                      createdAt: smartWidgetModel.createdAt,
                      pubkey: smartWidgetModel.pubkey,
                    ),
                  ),
                  PullDownButton(
                    animationBuilder: (context, state, child) {
                      return child;
                    },
                    routeTheme: PullDownMenuRouteTheme(
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                    ),
                    itemBuilder: (context) {
                      final textStyle = Theme.of(context).textTheme.labelMedium;

                      return [
                        PullDownMenuItem(
                          title: 'Share',
                          onTap: () {
                            showModalBottomSheet(
                              elevation: 0,
                              context: context,
                              builder: (_) {
                                return ShareView(
                                  image: '',
                                  placeholder: '',
                                  data: {
                                    'kind': EventKind.SMART_WIDGET,
                                    'id': smartWidgetModel.identifier,
                                    'createdAt': smartWidgetModel.createdAt,
                                    'textContentType':
                                        TextContentType.smartWidget,
                                    'smartWidget': smartWidgetModel.toJson(),
                                  },
                                  pubkey: smartWidgetModel.pubkey,
                                  title: smartWidgetModel.title,
                                  description: '',
                                  kindText: 'Smart widget',
                                  icon: FeatureIcons.note,
                                  upvotes: 0,
                                  downvotes: 0,
                                  onShare: () {
                                    RenderBox? box;

                                    if (ResponsiveBreakpoints.of(context)
                                        .largerThan(MOBILE)) {
                                      box = context.findRenderObject()
                                          as RenderBox?;
                                    }

                                    Share.share(
                                      externalShearableLink(
                                        kind: EventKind.SMART_WIDGET,
                                        pubkey: smartWidgetModel.pubkey,
                                        id: smartWidgetModel.identifier,
                                      ),
                                      subject:
                                          'Check out www.yakihonne.com for more notes.',
                                      sharePositionOrigin: box != null
                                          ? box.localToGlobal(Offset.zero) &
                                              box.size
                                          : null,
                                    );
                                  },
                                );
                              },
                              isScrollControlled: true,
                              useRootNavigator: true,
                              useSafeArea: true,
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                            );
                          },
                          itemTheme: PullDownMenuItemTheme(
                            textStyle: textStyle,
                          ),
                          iconWidget: SvgPicture.asset(
                            FeatureIcons.share,
                            height: 20,
                            width: 20,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).primaryColorDark,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        PullDownMenuItem(
                          title: 'Copy naddr',
                          onTap: () {
                            Clipboard.setData(
                              new ClipboardData(
                                text: smartWidgetModel.getNaddr(),
                              ),
                            );

                            BotToastUtils.showSuccess('Naddr has been copied!');
                          },
                          itemTheme: PullDownMenuItemTheme(
                            textStyle: textStyle,
                          ),
                          iconWidget: SvgPicture.asset(
                            FeatureIcons.copy,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).primaryColorDark,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        PullDownMenuItem(
                          title: 'Check validity',
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              SmartWidgetChecker.routeName,
                              arguments: [
                                smartWidgetModel.getNaddr(),
                                smartWidgetModel,
                              ],
                            );
                          },
                          itemTheme: PullDownMenuItemTheme(
                            textStyle: textStyle,
                          ),
                          iconWidget: SvgPicture.asset(
                            FeatureIcons.swChecker,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).primaryColorDark,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        if (isUsingPrivatekey())
                          PullDownMenuItem(
                            title: 'Clone',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                WriteSmartWidgetView.routeName,
                                arguments: [
                                  smartWidgetModel,
                                  true,
                                ],
                              );
                            },
                            itemTheme: PullDownMenuItemTheme(
                              textStyle: textStyle,
                            ),
                            iconWidget: SvgPicture.asset(
                              FeatureIcons.clone,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        if (isUsingPrivatekey() &&
                            nostrRepository.usm!.pubKey ==
                                smartWidgetModel.pubkey &&
                            canPerformOwnerActions != null) ...[
                          PullDownMenuItem(
                            title: 'Edit',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                WriteSmartWidgetView.routeName,
                                arguments: [
                                  smartWidgetModel,
                                  false,
                                ],
                              );
                            },
                            itemTheme: PullDownMenuItemTheme(
                              textStyle: textStyle,
                            ),
                            iconWidget: SvgPicture.asset(
                              FeatureIcons.article,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          PullDownMenuItem(
                            title: 'Delete',
                            isDestructive: true,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (alertContext) => AlertDialog(
                                  title: Text(
                                    'Delete "${smartWidgetModel.title}"?',
                                    textAlign: TextAlign.center,
                                  ),
                                  titleTextStyle: Theme.of(context)
                                      .textTheme
                                      .titleLarge!
                                      .copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                  content: Text(
                                    "You're about to delete this smart widget, do you wish to proceed?",
                                    textAlign: TextAlign.center,
                                  ),
                                  actionsAlignment: MainAxisAlignment.center,
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          context
                                              .read<SmartWidgetsCubit>()
                                              .deleteSmartWidget(
                                            smartWidgetModel.smartWidgetId,
                                            () {
                                              final cubit = context
                                                  .read<SmartWidgetsCubit>();
                                              cubit.getSmartWidgets(
                                                  isAdd: false,
                                                  isSelf: cubit.isSelfVal);

                                              Navigator.of(context).pop();
                                            },
                                          );
                                        },
                                        child: Text(
                                          'Delete widget',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .primaryColorDark,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          backgroundColor: kTransparent,
                                          side: BorderSide(
                                            color: kRed,
                                          ),
                                        )),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: kWhite,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        backgroundColor: kRed,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            itemTheme: PullDownMenuItemTheme(
                              textStyle: textStyle,
                            ),
                            iconWidget: SvgPicture.asset(
                              FeatureIcons.trash,
                              colorFilter: ColorFilter.mode(
                                kRed,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ],
                      ];
                    },
                    buttonBuilder: (context, showMenu) => IconButton(
                      onPressed: showMenu,
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColorLight,
                        visualDensity: VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                      ),
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: Theme.of(context).primaryColorDark,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              if (smartWidgetModel.container != null)
                SmartWidget(
                  smartWidgetContainer: smartWidgetModel.container!,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                )
              else
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      kDefaultPadding / 2,
                    ),
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  padding: const EdgeInsets.all(kDefaultPadding / 2),
                  child: Text(
                    'This smart widget does not follow the agreed on convention.',
                    style: Theme.of(context).textTheme.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Builder(
                builder: (context) {
                  final isPresent = smartWidgetModel.title.isNotEmpty;

                  return Text(
                    isPresent ? smartWidgetModel.title : 'Untitled',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isPresent
                              ? Theme.of(context).primaryColorDark
                              : kDimGrey,
                        ),
                  );
                },
              ),
              Builder(
                builder: (context) {
                  final isPresent = smartWidgetModel.summary.isNotEmpty;

                  return Text(
                    isPresent ? smartWidgetModel.summary : 'Untitled',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: isPresent
                              ? Theme.of(context).primaryColorDark
                              : kDimGrey,
                          fontStyle:
                              isPresent ? FontStyle.normal : FontStyle.italic,
                        ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
