import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authentication_cubit/authentication_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/points_management_view/widgets/points_login_popup.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/modal_with_blur.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class AuthenticationImage extends StatelessWidget {
  const AuthenticationImage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBreakpoints.of(context).largerThan(MOBILE)
        ? TabletAuthenticationImage()
        : MobileAuthenticationImage();
  }
}

class TabletAuthenticationImage extends HookWidget {
  const TabletAuthenticationImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final linkController = useTextEditingController();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pick up an image',
                          style:
                              Theme.of(context).textTheme.titleLarge!.copyWith(
                                    color: Theme.of(context).primaryColorDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        BlocBuilder<AuthenticationCubit, AuthenticationState>(
                          builder: (context, state) {
                            return LayoutBuilder(
                              builder: (context, constraints) => ProfilePicture(
                                size: constraints.maxWidth * 0.35,
                                image: state.picturesType ==
                                        PicturesType.localPicture
                                    ? ''
                                    : state.picturesType ==
                                            PicturesType.linkPicture
                                        ? state.imageLink
                                        : profileImages[
                                            state.selectedProfileImage],
                                padding: 5,
                                strokeWidth: 3,
                                isLocal: state.picturesType !=
                                        PicturesType.localPicture
                                    ? null
                                    : true,
                                file: state.localImage,
                              ),
                            );
                          },
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        BlocBuilder<AuthenticationCubit, AuthenticationState>(
                          builder: (context, state) {
                            return Column(
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) => Row(
                                    children: List.generate(
                                      4,
                                      (index) => SelectedProfilePicture(
                                        size: (constraints.maxWidth / 4),
                                        image: profileImages[index],
                                        isSelected:
                                            state.selectedProfileImage == index,
                                        onSelected: () {
                                          if (linkController.text.isNotEmpty) {
                                            linkController.clear();
                                          }

                                          context
                                              .read<AuthenticationCubit>()
                                              .selectPicture(index);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) => Row(
                                    children: List.generate(
                                      4,
                                      (index) => SelectedProfilePicture(
                                        size: (constraints.maxWidth / 4),
                                        image: profileImages[index + 4],
                                        isSelected:
                                            state.selectedProfileImage ==
                                                index + 4,
                                        onSelected: () {
                                          if (linkController.text.isNotEmpty) {
                                            linkController.clear();
                                          }

                                          context
                                              .read<AuthenticationCubit>()
                                              .selectPicture(index + 4);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Divider(
                                  color: Theme.of(context).hintColor,
                                  thickness: 0.5,
                                  height: kDefaultPadding * 2,
                                ),
                              ),
                            ),
                            Text(
                              'OR',
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Divider(
                                  color: Theme.of(context).hintColor,
                                  thickness: 0.5,
                                  height: kDefaultPadding * 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        BlocBuilder<AuthenticationCubit, AuthenticationState>(
                          builder: (context, state) {
                            return GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  if (state.picturesType !=
                                      PicturesType.localPicture) {
                                    if (linkController.text.isNotEmpty) {
                                      linkController.clear();
                                    }

                                    context
                                        .read<AuthenticationCubit>()
                                        .selectProfileImage(
                                      onFailed: () {
                                        singleSnackBar(
                                          context: context,
                                          message:
                                              'Issue occured while selecting the image.',
                                          color: kRed,
                                          backGroundColor: kRedSide,
                                          icon: ToastsIcons.error,
                                        );
                                      },
                                    );
                                  } else {
                                    context
                                        .read<AuthenticationCubit>()
                                        .removeLocalImage();
                                  }
                                },
                                child: DottedBorder(
                                  color: Theme.of(context).hintColor,
                                  strokeCap: StrokeCap.round,
                                  borderType: BorderType.RRect,
                                  radius: Radius.circular(300),
                                  dashPattern: [4],
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (state.picturesType !=
                                            PicturesType.localPicture) ...[
                                          SvgPicture.asset(
                                            FeatureIcons.image,
                                            width: 20,
                                            height: 20,
                                            colorFilter: ColorFilter.mode(
                                              Theme.of(context)
                                                  .primaryColorDark,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: kDefaultPadding / 2,
                                          ),
                                          Text(
                                            'upload yours',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(
                                                  color: Theme.of(context)
                                                      .hintColor,
                                                ),
                                          ),
                                        ] else ...[
                                          Expanded(
                                            child: Text(
                                              state.localImage!.path,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(
                                                    color: Theme.of(context)
                                                        .hintColor,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: kDefaultPadding / 2,
                                          ),
                                          SvgPicture.asset(
                                            FeatureIcons.trash,
                                            width: 25,
                                            height: 25,
                                            colorFilter: ColorFilter.mode(
                                              Theme.of(context)
                                                  .primaryColorDark,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ));
                          },
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                        BlocBuilder<AuthenticationCubit, AuthenticationState>(
                          builder: (context, state) {
                            return TextFormField(
                              controller: linkController,
                              decoration: InputDecoration(
                                hintText: "Enter your image's link",
                              ),
                              onChanged: (value) {
                                context
                                    .read<AuthenticationCubit>()
                                    .setImageLink(value);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: kDefaultPadding),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              context.read<AuthenticationCubit>().signup(
                                onFailed: (message) {
                                  singleSnackBar(
                                    context: context,
                                    message: message,
                                    color: kRed,
                                    backGroundColor: kRedSide,
                                    icon: ToastsIcons.error,
                                  );
                                },
                                onSuccess: () {
                                  context
                                      .read<AuthenticationCubit>()
                                      .updateAuthenticationViews(
                                        AuthenticationViews.nameSelection,
                                      );

                                  showBlurredModal(
                                    context: context,
                                    view: PointsLoginPopup(),
                                  );
                                },
                              );
                            },
                            child: Text('Next'),
                          ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    Images.onboarding3,
                    fit: BoxFit.cover,
                  ),
                ),
                Align(
                  alignment: Alignment(0.98, -0.98),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: kLightGrey,
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      color: kBlack,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MobileAuthenticationImage extends HookWidget {
  const MobileAuthenticationImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final linkController = useTextEditingController();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: IconButton.styleFrom(
                backgroundColor: kLightGrey,
              ),
              icon: Icon(
                Icons.close_rounded,
                color: kBlack,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
              ),
              child: FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pick up an image',
                          style:
                              Theme.of(context).textTheme.titleLarge!.copyWith(
                                    color: Theme.of(context).primaryColorDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        BlocBuilder<AuthenticationCubit, AuthenticationState>(
                          builder: (context, state) {
                            return ProfilePicture(
                              size: 30.w,
                              image: state.picturesType ==
                                      PicturesType.localPicture
                                  ? ''
                                  : state.picturesType ==
                                          PicturesType.linkPicture
                                      ? state.imageLink
                                      : profileImages[
                                          state.selectedProfileImage],
                              padding: 5,
                              strokeWidth: 3,
                              isLocal: state.picturesType !=
                                      PicturesType.localPicture
                                  ? null
                                  : true,
                              file: state.localImage,
                            );
                          },
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        BlocBuilder<AuthenticationCubit, AuthenticationState>(
                          builder: (context, state) {
                            return Column(
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) => Row(
                                    children: List.generate(
                                      4,
                                      (index) => SelectedProfilePicture(
                                        size: (constraints.maxWidth / 4),
                                        image: profileImages[index],
                                        isSelected:
                                            state.selectedProfileImage == index,
                                        onSelected: () {
                                          if (linkController.text.isNotEmpty) {
                                            linkController.clear();
                                          }

                                          context
                                              .read<AuthenticationCubit>()
                                              .selectPicture(index);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) => Row(
                                    children: List.generate(
                                      4,
                                      (index) => SelectedProfilePicture(
                                        size: (constraints.maxWidth / 4),
                                        image: profileImages[index + 4],
                                        isSelected:
                                            state.selectedProfileImage ==
                                                index + 4,
                                        onSelected: () {
                                          if (linkController.text.isNotEmpty) {
                                            linkController.clear();
                                          }

                                          context
                                              .read<AuthenticationCubit>()
                                              .selectPicture(index + 4);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Divider(
                                  color: Theme.of(context).hintColor,
                                  thickness: 0.5,
                                  height: kDefaultPadding * 2,
                                ),
                              ),
                            ),
                            Text(
                              'OR',
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Divider(
                                  color: Theme.of(context).hintColor,
                                  thickness: 0.5,
                                  height: kDefaultPadding * 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        BlocBuilder<AuthenticationCubit, AuthenticationState>(
                          builder: (context, state) {
                            return GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  if (state.picturesType !=
                                      PicturesType.localPicture) {
                                    if (linkController.text.isNotEmpty) {
                                      linkController.clear();
                                    }

                                    context
                                        .read<AuthenticationCubit>()
                                        .selectProfileImage(
                                      onFailed: () {
                                        singleSnackBar(
                                          context: context,
                                          message:
                                              'Issue occured while selecting the image.',
                                          color: kRed,
                                          backGroundColor: kRedSide,
                                          icon: ToastsIcons.error,
                                        );
                                      },
                                    );
                                  } else {
                                    context
                                        .read<AuthenticationCubit>()
                                        .removeLocalImage();
                                  }
                                },
                                child: DottedBorder(
                                  color: Theme.of(context).hintColor,
                                  strokeCap: StrokeCap.round,
                                  borderType: BorderType.RRect,
                                  radius: Radius.circular(300),
                                  dashPattern: [4],
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (state.picturesType !=
                                            PicturesType.localPicture) ...[
                                          SvgPicture.asset(
                                            FeatureIcons.image,
                                            width: 5.w,
                                            height: 5.w,
                                            colorFilter: ColorFilter.mode(
                                              Theme.of(context)
                                                  .primaryColorDark,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: kDefaultPadding / 2,
                                          ),
                                          Text(
                                            'upload yours',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(
                                                  color: Theme.of(context)
                                                      .hintColor,
                                                ),
                                          ),
                                        ] else ...[
                                          Expanded(
                                            child: Text(
                                              state.localImage!.path,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(
                                                    color: Theme.of(context)
                                                        .hintColor,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: kDefaultPadding / 2,
                                          ),
                                          SvgPicture.asset(
                                            FeatureIcons.trash,
                                            width: 5.w,
                                            height: 5.w,
                                            colorFilter: ColorFilter.mode(
                                              Theme.of(context)
                                                  .primaryColorDark,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ));
                          },
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                        BlocBuilder<AuthenticationCubit, AuthenticationState>(
                          builder: (context, state) {
                            return TextFormField(
                              controller: linkController,
                              decoration: InputDecoration(
                                hintText: "Enter your image's link",
                              ),
                              onChanged: (value) {
                                context
                                    .read<AuthenticationCubit>()
                                    .setImageLink(value);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: kDefaultPadding),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              context.read<AuthenticationCubit>().signup(
                                onFailed: (message) {
                                  singleSnackBar(
                                    context: context,
                                    message: message,
                                    color: kRed,
                                    backGroundColor: kRedSide,
                                    icon: ToastsIcons.error,
                                  );
                                },
                                onSuccess: () {
                                  context
                                      .read<AuthenticationCubit>()
                                      .updateAuthenticationViews(
                                          AuthenticationViews.nameSelection);

                                  showBlurredModal(
                                    context: context,
                                    view: PointsLoginPopup(),
                                  );
                                },
                              );
                            },
                            child: Text('Next'),
                          ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectedProfilePicture extends StatelessWidget {
  const SelectedProfilePicture({
    super.key,
    required this.size,
    required this.image,
    required this.isSelected,
    required this.onSelected,
  });

  final double size;
  final String image;
  final bool isSelected;
  final Function() onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: size,
        width: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: 3,
            color: isSelected ? kPurple : kTransparent,
          ),
          color: kTransparent,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          foregroundDecoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isSelected ? kTransparent : kLightGrey.withValues(alpha: 0.3),
          ),
          child: ClipOval(
            child: image.isEmpty
                ? errorContainer(context)
                : CachedNetworkImage(
                    imageUrl: image,
                    cacheManager: cacheManager,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        errorContainer(context),
                  ),
          ),
        ),
      ),
    );
  }

  Container errorContainer(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColorLight,
      child: Center(
        child: SvgPicture.asset(
          FeatureIcons.image,
          width: size / 4,
          height: size / 4,
          fit: BoxFit.scaleDown,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
