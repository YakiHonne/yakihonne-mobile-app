// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/points_management_cubit/points_management_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/utils/text_content.dart';
import 'package:yakihonne/utils/utils.dart';

class PointsLoginPopup extends HookWidget {
  const PointsLoginPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Container(
      width: isTablet ? 50.w : double.infinity,
      margin: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      padding: const EdgeInsets.all(kDefaultPadding),
      child: BlocBuilder<PointsManagementCubit, PointsManagementState>(
        builder: (context, state) {
          if (state.isNew && state.standards.isNotEmpty) {
            return YakiHonneFirstRewards(
              level: state.currentLevel,
              percentage: state.percentage,
              standards: state.standards,
              xp: state.currentXp,
            );
          } else {
            return YakiLoginChest();
          }
        },
      ),
    );
  }
}

class YakiHonneFirstRewards extends HookWidget {
  const YakiHonneFirstRewards({
    Key? key,
    required this.standards,
    required this.xp,
    required this.level,
    required this.percentage,
  }) : super(key: key);

  final List<String> standards;
  final int xp;
  final int level;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    final animation = Tween<double>(begin: 0, end: percentage).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ),
    );

    useEffect(() {
      animationController.forward();
      return;
    }, [animationController]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeInUp(
          duration: const Duration(milliseconds: 200),
          child: Text(
            '🎉',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontSize: 50,
                  height: 1,
                ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        FadeInUp(
          delay: const Duration(milliseconds: 100),
          duration: const Duration(milliseconds: 200),
          child: Text(
            'Congratulations',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        FadeIn(
          delay: const Duration(milliseconds: 200),
          duration: const Duration(milliseconds: 200),
          child: Text(
            'You have been rewarded 90 xp for the following actions, be active and earn rewards!',
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: kDimGrey),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        FadeInUp(
          delay: const Duration(milliseconds: 300),
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) => CircularProgressIndicator(
                      strokeWidth: 4,
                      value: animation.value,
                      color: kRed,
                      strokeCap: StrokeCap.round,
                      backgroundColor: kBlack.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            xp.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 4,
                          ),
                          Text(
                            'xp',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(color: kDimGrey),
                          ),
                        ],
                      ),
                      Text(
                        'Level ${level}',
                        style:
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                  color: kOrange,
                                ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Wrap(
          alignment: WrapAlignment.center,
          runSpacing: kDefaultPadding / 2,
          spacing: kDefaultPadding / 2,
          children: standards
              .map(
                (e) => FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                      Icon(
                        Icons.check_circle,
                        color: kGreen,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        SizedBox(
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Woohoo!'),
          ),
        ),
      ],
    );
  }
}

class YakiLoginChest extends StatelessWidget {
  const YakiLoginChest({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "YakiHonne's Chest!",
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Text(
          TextContent.yakiChestDescription,
          style:
              Theme.of(context).textTheme.bodyMedium!.copyWith(color: kDimGrey),
          textAlign: TextAlign.center,
        ),
        Image.asset(
          Images.yakiChest,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              pointsManagementCubit.login(
                onSuccess: () {
                  Navigator.pop(context);
                },
              );
            },
            child: Text('Log in'),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            "No, I'm good",
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.underline,
                ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
      ],
    );
  }
}
