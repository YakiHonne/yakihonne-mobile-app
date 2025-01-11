import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/properties_cubit/property_profile_picture_cubit/property_profile_picture_cubit.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/authentication_view/widgets/authentication_image.dart';
import 'package:yakihonne/views/widgets/bottom_cancelable_bar.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class ProfileImageUpdate extends HookWidget {
  const ProfileImageUpdate({super.key});
  static const routeName = '/profileImageView';
  static Route route() {
    return CupertinoPageRoute(
      builder: (_) => ProfileImageUpdate(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linkController = useTextEditingController();
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocProvider(
      create: (context) => PropertyProfilePictureCubit(
        nostrRepository: context.read<NostrDataRepository>(),
      ),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Pick up an image',
        ),
        bottomNavigationBar: Builder(
          builder: (context) {
            return BottomCancellableBar(
              onClicked: () {
                context.read<PropertyProfilePictureCubit>().updateMetadata(
                  onFailure: (message) {
                    singleSnackBar(
                      context: context,
                      message: message,
                      color: kRed,
                      backGroundColor: kRedSide,
                      icon: ToastsIcons.error,
                    );
                  },
                  onSuccess: (message) {
                    singleSnackBar(
                      context: context,
                      message: message,
                      color: kGreen,
                      backGroundColor: kGreenSide,
                      icon: ToastsIcons.success,
                    );
                    Navigator.pop(context);
                  },
                );
              },
              text: 'Update',
            );
          },
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 15.w : kDefaultPadding),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BlocBuilder<PropertyProfilePictureCubit,
                              PropertyProfilePictureState>(
                            builder: (context, state) {
                              final isTablet = ResponsiveBreakpoints.of(context)
                                  .largerThan(MOBILE);

                              return ProfilePicture(
                                size: isTablet ? 15.w : 30.w,
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
                          BlocBuilder<PropertyProfilePictureCubit,
                              PropertyProfilePictureState>(
                            builder: (context, state) {
                              final isTablet = ResponsiveBreakpoints.of(context)
                                  .largerThan(MOBILE);

                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 10.w : 0,
                                ),
                                child: Column(
                                  children: [
                                    LayoutBuilder(
                                      builder: (context, constraints) => Row(
                                        children: List.generate(
                                          4,
                                          (index) => SelectedProfilePicture(
                                            size: (constraints.maxWidth / 4),
                                            image: profileImages[index],
                                            isSelected:
                                                state.selectedProfileImage ==
                                                    index,
                                            onSelected: () {
                                              if (linkController
                                                  .text.isNotEmpty) {
                                                linkController.clear();
                                              }
                                              context
                                                  .read<
                                                      PropertyProfilePictureCubit>()
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
                                                if (linkController
                                                    .text.isNotEmpty) {
                                                  linkController.clear();
                                                }

                                                context
                                                    .read<
                                                        PropertyProfilePictureCubit>()
                                                    .selectPicture(index + 4);
                                              }),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                          BlocBuilder<PropertyProfilePictureCubit,
                              PropertyProfilePictureState>(
                            builder: (context, state) {
                              return GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  if (linkController.text.isNotEmpty) {
                                    linkController.clear();
                                  }

                                  if (state.picturesType !=
                                      PicturesType.localPicture) {
                                    context
                                        .read<PropertyProfilePictureCubit>()
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
                                        .read<PropertyProfilePictureCubit>()
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
                                            width: 25,
                                            height: 25,
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
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: kDefaultPadding),
                          BlocBuilder<PropertyProfilePictureCubit,
                              PropertyProfilePictureState>(
                            builder: (context, state) {
                              return TextFormField(
                                controller: linkController,
                                decoration: InputDecoration(
                                  hintText: "Enter your image's link",
                                ),
                                onChanged: (value) {
                                  context
                                      .read<PropertyProfilePictureCubit>()
                                      .setImageLink(value);
                                },
                              );
                            },
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
      ),
    );
  }
}
