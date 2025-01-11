import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/properties_cubit/property_thumbnail_picture_cubit/property_thumbnail_picture_cubit.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/bottom_cancelable_bar.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class ThumbnailUpdate extends HookWidget {
  static const routeName = '/thumbnailView';
  static Route route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (_) => ThumbnailUpdate(),
    );
  }

  const ThumbnailUpdate({super.key});

  @override
  Widget build(BuildContext context) {
    final imageUrlController = useTextEditingController();
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocProvider(
      create: (context) => PropertyThumbnailPictureCubit(
        nostrRepository: context.read<NostrDataRepository>(),
      ),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Set your cover image',
        ),
        bottomNavigationBar: Builder(builder: (context) {
          return BottomCancellableBar(
            onClicked: () {
              context.read<PropertyThumbnailPictureCubit>().updateMetadata(
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
        }),
        body: ListView(
          padding: EdgeInsets.all(isTablet ? 15.w : kDefaultPadding),
          children: [
            BlocBuilder<PropertyThumbnailPictureCubit,
                PropertyThumbnailPictureState>(
              builder: (context, state) {
                return Stack(
                  children: [
                    Container(
                      height: 20.h,
                      decoration: state.isImageSelected
                          ? null
                          : BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(kDefaultPadding),
                              border: Border.all(
                                width: 0.5,
                                color: kDimGrey,
                              ),
                            ),
                      foregroundDecoration:
                          state.isImageSelected && state.isLocalImage
                              ? BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(kDefaultPadding),
                                  image: DecorationImage(
                                    image: FileImage(
                                      state.localImage!,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : null,
                      child: state.isImageSelected && !state.isLocalImage
                          ? state.imageLink.isEmpty
                              ? SizedBox(
                                  height: 20.h,
                                  child: NoMediaPlaceHolder(
                                    image: '',
                                    isError: false,
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: state.imageLink,
                                  height: 20.h,
                                  width: double.infinity,
                                  imageBuilder: (context, imageProvider) =>
                                      Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          kDefaultPadding),
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  placeholder: (context, url) =>
                                      NoMediaPlaceHolder(
                                    image: '',
                                    isError: false,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      NoMediaPlaceHolder(
                                    image: '',
                                    isError: false,
                                  ),
                                )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    FeatureIcons.image,
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.scaleDown,
                                    colorFilter: ColorFilter.mode(
                                      kDimGrey,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: kDefaultPadding / 2,
                                  ),
                                  Text(
                                    'Thumbnail preview',
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                                ],
                              ),
                            ),
                    ),
                    if (state.isImageSelected)
                      Positioned(
                        right: kDefaultPadding / 2,
                        top: kDefaultPadding / 2,
                        child: CircleAvatar(
                          backgroundColor: kWhite.withValues(alpha: 0.8),
                          child: IconButton(
                            onPressed: () {
                              context
                                  .read<PropertyThumbnailPictureCubit>()
                                  .removeImage();
                              imageUrlController.clear();
                            },
                            icon: SvgPicture.asset(
                              FeatureIcons.trash,
                              width: 25,
                              height: 25,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<PropertyThumbnailPictureCubit,
                      PropertyThumbnailPictureState>(
                    builder: (context, state) {
                      return TextFormField(
                        controller: imageUrlController,
                        decoration: InputDecoration(
                          hintText: "Enter the image's link",
                        ),
                        onChanged: (link) {
                          context
                              .read<PropertyThumbnailPictureCubit>()
                              .selectUrlImage(url: link);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                BlocBuilder<PropertyThumbnailPictureCubit,
                    PropertyThumbnailPictureState>(
                  builder: (context, state) {
                    return BorderedIconButton(
                      firstSelection: true,
                      onClicked: () {
                        imageUrlController.clear();
                        context
                            .read<PropertyThumbnailPictureCubit>()
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
                      },
                      primaryIcon: FeatureIcons.upload,
                      secondaryIcon: FeatureIcons.notVisible,
                      borderColor: state.isLocalImage
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).primaryColorLight,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
          ],
        ),
      ),
    );
  }
}
