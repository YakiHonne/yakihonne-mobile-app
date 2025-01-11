// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:uuid/uuid.dart';
import 'package:yakihonne/blocs/write_smart_widget_cubit/write_smart_widget_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/write_smart_widget_view/widgets/smart_widget_content.dart';
import 'package:yakihonne/views/write_smart_widget_view/widgets/smart_widget_specifications.dart';

class WriteSmartWidgetView extends HookWidget {
  WriteSmartWidgetView({
    this.smartWidgetModel,
    this.isCloning,
  });
  static const routeName = '/frameBuilderView';
  static Route route(RouteSettings settings) {
    final list = settings.arguments as List;

    return CupertinoPageRoute(
      builder: (_) => WriteSmartWidgetView(
        smartWidgetModel: list.length > 0 ? list[0] : null,
        isCloning: list.length > 1 ? list[1] : null,
      ),
    );
  }

  final SmartWidgetModel? smartWidgetModel;
  final bool? isCloning;
  late final WriteSmartWidgetCubit writeSmartWidgetCubit;

  @override
  Widget build(BuildContext context) {
    final toggleFrameSpecifications = useState(false);
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final bg = Theme.of(context).primaryColorLight.toHex();

    useMemoized(
      () async {
        writeSmartWidgetCubit = WriteSmartWidgetCubit(
          uuid: Uuid().v4(),
          backgroundColor: bg,
          sm: smartWidgetModel,
          isCloning: isCloning,
        );
      },
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: nostrRepository.mainCubit),
        BlocProvider.value(value: writeSmartWidgetCubit),
      ],
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
            builder: (context, state) {
              return AppBar(
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                  ),
                ),
                title: Column(
                  children: [
                    Text(
                      '${state.smartWidgetPublishSteps == SmartWidgetPublishSteps.content ? 'Smart widget content' : 'Smart widget specs'}',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      '${state.smartWidgetPublishSteps == SmartWidgetPublishSteps.content ? "what's your smart widget about" : 'set your specifications'}',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: kDimGrey,
                          ),
                    ),
                  ],
                ),
                actions: [
                  if (state.smartWidgetPublishSteps ==
                      SmartWidgetPublishSteps.specifications) ...[
                    BorderedIconButton(
                      firstSelection: toggleFrameSpecifications.value,
                      onClicked: () {
                        toggleFrameSpecifications.value =
                            !toggleFrameSpecifications.value;
                      },
                      primaryIcon: FeatureIcons.visible,
                      secondaryIcon: FeatureIcons.notVisible,
                      borderColor: Theme.of(context).primaryColor,
                      size: 35,
                    ),
                    const SizedBox(
                      width: kDefaultPadding - 5,
                    ),
                  ]
                ],
                centerTitle: true,
              );
            },
          ),
        ),
        bottomNavigationBar:
            BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
          builder: (context, state) {
            final step =
                state.smartWidgetPublishSteps == SmartWidgetPublishSteps.content
                    ? 2
                    : 1;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 2,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(
                      begin: 0,
                      end: step / 2,
                    ),
                    builder: (context, value, _) =>
                        LinearProgressIndicator(value: value),
                  ),
                ),
                _bottomNavBar(context, state, isTablet),
              ],
            );
          },
        ),
        body: BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
          builder: (context, state) {
            return getView(
              state.smartWidgetPublishSteps,
              toggleFrameSpecifications.value,
            );
          },
        ),
      ),
    );
  }

  Container _bottomNavBar(
    BuildContext context,
    WriteSmartWidgetState state,
    bool isTablet,
  ) {
    return Container(
      height:
          kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        left: kDefaultPadding / 2,
        right: kDefaultPadding / 2,
        bottom: MediaQuery.of(context).padding.bottom / 2,
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Visibility(
              visible: state.smartWidgetPublishSteps !=
                  SmartWidgetPublishSteps.specifications,
              child: IconButton(
                onPressed: () {
                  context.read<WriteSmartWidgetCubit>().setFramePublishStep(
                        SmartWidgetPublishSteps.specifications,
                      );
                },
                icon: Icon(
                  Icons.keyboard_arrow_left_rounded,
                  color: kWhite,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: kPurple,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (state.smartWidgetPublishSteps ==
                    SmartWidgetPublishSteps.specifications) {
                  if (!state.smartWidgetContainer.canBeAdded()) {
                    BotToastUtils.showError(
                      'The smart widget should have atleast one component.',
                    );
                  } else {
                    context
                        .read<WriteSmartWidgetCubit>()
                        .setFramePublishStep(SmartWidgetPublishSteps.content);
                  }
                } else {
                  context.read<WriteSmartWidgetCubit>().setSmartWidget(
                        onSuccess: () => Navigator.pop(context),
                      );
                }
              },
              child: Text(
                state.smartWidgetPublishSteps == SmartWidgetPublishSteps.content
                    ? 'Publish'
                    : 'Next',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getView(SmartWidgetPublishSteps framePublishSteps, bool isToggled) {
    if (framePublishSteps == SmartWidgetPublishSteps.content) {
      return FrameContent();
    } else {
      return BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
        builder: (context, state) {
          return FrameSpecifications(
            toggleView: isToggled,
          );
        },
      );
    }
  }
}
