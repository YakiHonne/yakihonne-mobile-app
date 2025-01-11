import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/onboarding_cubit/onboarding_cubit.dart';
import 'package:yakihonne/blocs/routing_cubit/routing_cubit.dart';
import 'package:yakihonne/utils/utils.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final pageController = PageController();

  late AnimationController controller;
  late Image image1;
  late Image image2;
  late Image image3;
  late Image image4;
  late Image image5;
  bool isLaunching = false;
  List<Image> images = [];

  @override
  void initState() {
    super.initState();
    image1 = Image.asset(Images.onboarding1);
    image2 = Image.asset(Images.onboarding2);
    image3 = Image.asset(Images.onboarding3);
    image4 = Image.asset(Images.onboarding4);
    image5 = Image.asset(Images.onboarding5);

    images = [
      image1,
      image2,
      image3,
      image4,
      image5,
    ];
  }

  @override
  void didChangeDependencies() {
    precacheImage(image1.image, context);
    precacheImage(image2.image, context);
    precacheImage(image3.image, context);
    precacheImage(image4.image, context);
    precacheImage(image5.image, context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingCubit(),
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: kDimPurple,
            body: Stack(
              children: [
                Container(
                  height: 100.h,
                  width: double.infinity,
                  foregroundDecoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kDimPurple,
                        kTransparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: [0.2, 0.8],
                    ),
                  ),
                  child: FadeIn(
                    controller: (currentController) {
                      controller = currentController;
                    },
                    manualTrigger: true,
                    child: Image(
                      image: images[state.index].image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 5.w,
                  left: 5.w,
                  bottom: kBottomNavigationBarHeight,
                  top: kToolbarHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            context.read<RoutingCubit>().setDisclosureView();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: kBlack.withValues(alpha: 0.7),
                          ),
                          child: Text('Skip'),
                        ),
                      ),
                      const Spacer(),
                      FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        from: 50,
                        child: SvgPicture.asset(
                          LogosIcons.logoMarkWhite,
                          height: 120,
                          width: 120,
                        ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding * 2,
                      ),
                      FadeIn(
                        duration: const Duration(milliseconds: 400),
                        child: ZoomIn(
                          duration: const Duration(milliseconds: 400),
                          child: getTextWidget(state.index),
                        ),
                      ),
                      const SizedBox(
                        height: kDefaultPadding * 2,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (state.index > 0) {
                                context.read<OnboardingCubit>().decreaseIndex();
                                controller.reset();
                                controller.forward();
                              }
                            },
                            icon: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: kWhite,
                              size: 20,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (index) => AnimatedContainer(
                                margin: const EdgeInsets.only(right: 5.0),
                                duration: const Duration(milliseconds: 200),
                                height: 6.0,
                                width: state.index == index ? 25.0 : 6.0,
                                decoration: BoxDecoration(
                                  color:
                                      state.index == index ? kPurple : kWhite,
                                  borderRadius: BorderRadius.circular(
                                    kDefaultPadding,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor: kPurple,
                            radius: 22,
                            child: IconButton(
                              onPressed: () {
                                if (state.index < 4) {
                                  context
                                      .read<OnboardingCubit>()
                                      .increaseIndex();
                                  controller.reset();
                                  controller.forward();
                                } else {
                                  context
                                      .read<RoutingCubit>()
                                      .setDisclosureView();
                                }
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: kWhite,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget getTextWidget(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          getTitle(
            index,
          ),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: kWhite,
                fontWeight: FontWeight.w900,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        Text(
          getDescription(
            index,
          ),
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: kWhite,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String getTitle(int index) {
    return index == 0
        ? 'Spark Your Passion'
        : index == 1
            ? 'Unleash Your Potential'
            : index == 2
                ? 'From Words to Worlds'
                : index == 3
                    ? 'Journeys Through Imagination'
                    : 'Unleashing the Possibilities';
  }

  String getDescription(int index) {
    return index == 0
        ? 'Elevate Your Insights: Where Sharing Shines Bright!'
        : index == 1
            ? 'Fuel your personal growth with YakiHonne'
            : index == 2
                ? 'Amplify Your Voice: YakiHonne, Your Loudest Advocate!'
                : index == 3
                    ? 'YakiHonne: Your Tale, Your Tone, Your Total Control!'
                    : 'Unlocking Creativity, Shattering Boundaries!';
  }
}
