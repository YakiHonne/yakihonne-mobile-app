import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/write_article_cubit/image_selector_cubit/article_image_selector_cubit.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class ImageSelector extends HookWidget {
  const ImageSelector({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  final Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final imageUrlController = useTextEditingController();

    return BlocProvider(
      create: (context) => ArticleImageSelectorCubit(
        localDatabaseRepository: context.read<LocalDatabaseRepository>(),
        nostrRepository: context.read<NostrDataRepository>(),
      ),
      child: Material(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        child: Container(
          height: 80.h,
          child: Column(
            children: [
              ModalBottomSheetHandle(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        isTablet ? kDefaultPadding : kDefaultPadding / 2,
                    vertical: kDefaultPadding / 2,
                  ),
                  shrinkWrap: true,
                  primary: false,
                  children: [
                    BlocBuilder<ArticleImageSelectorCubit,
                        ArticleImageSelectorState>(
                      builder: (context, state) {
                        return Stack(
                          children: [
                            Container(
                              height: 20.h,
                              decoration: state.isImageSelected
                                  ? null
                                  : BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        kDefaultPadding,
                                      ),
                                      border: Border.all(
                                        width: 0.5,
                                        color: kDimGrey,
                                      ),
                                    ),
                              foregroundDecoration:
                                  state.isImageSelected && state.isLocalImage
                                      ? BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              kDefaultPadding),
                                          image: DecorationImage(
                                            image: FileImage(
                                              state.localImage!,
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : null,
                              child: state.isImageSelected &&
                                      !state.isLocalImage
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
                                          imageBuilder:
                                              (context, imageProvider) =>
                                                  Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                kDefaultPadding,
                                              ),
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
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium,
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
                                  backgroundColor:
                                      kWhite.withValues(alpha: 0.8),
                                  child: IconButton(
                                    onPressed: () {
                                      context
                                          .read<ArticleImageSelectorCubit>()
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
                          child: Text(
                            'Select & upload a local image',
                          ),
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 2,
                        ),
                        BlocBuilder<ArticleImageSelectorCubit,
                            ArticleImageSelectorState>(
                          builder: (context, state) {
                            return BorderedIconButton(
                              firstSelection: true,
                              onClicked: () {
                                imageUrlController.clear();
                                context
                                    .read<ArticleImageSelectorCubit>()
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
                    const Divider(
                      height: kDefaultPadding * 1.5,
                    ),
                    Text(
                      'Images upload history',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    BlocBuilder<ArticleImageSelectorCubit,
                        ArticleImageSelectorState>(
                      builder: (context, state) {
                        if (state.imagesLinks.isEmpty) {
                          return Text(
                            'No images history has been found',
                            style: Theme.of(context).textTheme.labelMedium,
                          );
                        } else {
                          return GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isTablet ? 3 : 2,
                              childAspectRatio: 16 / 9,
                              crossAxisSpacing: kDefaultPadding / 2,
                              mainAxisSpacing: kDefaultPadding / 2,
                            ),
                            shrinkWrap: true,
                            primary: false,
                            itemBuilder: (context, index) {
                              final link = state.imagesLinks[index];

                              return GestureDetector(
                                onTap: () {
                                  onTap.call(link);
                                  Navigator.pop(context);
                                },
                                child: Stack(
                                  children: [
                                    if (link.isEmpty)
                                      SizedBox(
                                        height: 20.h,
                                        child: NoMediaPlaceHolder(
                                          image: '',
                                          isError: false,
                                        ),
                                      )
                                    else
                                      CachedNetworkImage(
                                        imageUrl: link,
                                        height: 20.h,
                                        width: double.infinity,
                                        imageBuilder:
                                            (context, imageProvider) =>
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
                                      ),
                                    Positioned(
                                      top: kDefaultPadding / 4,
                                      right: kDefaultPadding / 4,
                                      child: CircleAvatar(
                                        child: Icon(
                                          Icons.add,
                                          color: kBlack,
                                        ),
                                        backgroundColor:
                                            kWhite.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            itemCount: state.imagesLinks.length,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: kBottomNavigationBarHeight +
                    MediaQuery.of(context).padding.bottom,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 15.w : kDefaultPadding,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Theme.of(context).primaryColorDark,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: kTransparent,
                              side: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 2,
                        ),
                        BlocBuilder<ArticleImageSelectorCubit,
                            ArticleImageSelectorState>(
                          builder: (context, state) {
                            return Expanded(
                              child: Builder(
                                builder: (context) {
                                  return TextButton(
                                    onPressed: () {
                                      if (state.isImageSelected) {
                                        context
                                            .read<ArticleImageSelectorCubit>()
                                            .addImage(
                                          onSuccess: (link) {
                                            onTap.call(link);
                                            Navigator.pop(context);
                                          },
                                          onFailure: (message) {
                                            singleSnackBar(
                                              context: context,
                                              message: message,
                                              color: kRed,
                                              backGroundColor: kRedSide,
                                              icon: ToastsIcons.error,
                                            );
                                          },
                                        );
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: state.isImageSelected
                                          ? kPurple
                                          : kDimGrey,
                                    ),
                                    child: Text('Upload & use'),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
