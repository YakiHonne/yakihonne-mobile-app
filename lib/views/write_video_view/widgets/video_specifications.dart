// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/write_video_cubit/write_video_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/auto_complete_textfield.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';
import 'package:yakihonne/views/write_article_view/widgets/article_details.dart';

class VideoSpecifications extends HookWidget {
  const VideoSpecifications({
    required this.image,
    required this.isAdding,
  });
  final String image;
  final bool isAdding;

  @override
  Widget build(BuildContext context) {
    final imageUrlController = useTextEditingController(text: image);
    final keywordController = useTextEditingController(text: '');
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<WriteVideoCubit, WriteVideoState>(
      builder: (context, state) {
        return ListView(
          padding: EdgeInsets.all(isTablet ? 10.w : kDefaultPadding / 2),
          children: [
            const SizedBox(
              height: kDefaultPadding,
            ),
            Stack(
              children: [
                Container(
                  height: 20.h,
                  decoration: state.isImageSelected
                      ? null
                      : BoxDecoration(
                          borderRadius: BorderRadius.circular(kDefaultPadding),
                          border: Border.all(
                            width: 0.5,
                            color: kDimGrey,
                          ),
                        ),
                  foregroundDecoration: state.isImageSelected &&
                          state.isLocalImage
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(kDefaultPadding),
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
                                  borderRadius:
                                      BorderRadius.circular(kDefaultPadding),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      state.imageLink,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              placeholder: (context, url) => NoMediaPlaceHolder(
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
                                style: Theme.of(context).textTheme.labelMedium,
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
                          context.read<WriteVideoCubit>().removeImage();
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
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<WriteVideoCubit, WriteVideoState>(
                    builder: (context, state) {
                      return TextFormField(
                        controller: imageUrlController,
                        decoration: InputDecoration(
                          hintText: 'Image url',
                        ),
                        onChanged: (link) {
                          context.read<WriteVideoCubit>().selectUrlImage(
                                url: link,
                                onFailed: () {
                                  singleSnackBar(
                                    context: context,
                                    message: 'Select a valid url image.',
                                    color: kRed,
                                    backGroundColor: kRedSide,
                                    icon: ToastsIcons.error,
                                  );
                                },
                              );
                        },
                        onFieldSubmitted: (url) {},
                      );
                    },
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                BlocBuilder<WriteVideoCubit, WriteVideoState>(
                  builder: (context, state) {
                    return BorderedIconButton(
                      firstSelection: true,
                      onClicked: () {
                        imageUrlController.clear();
                        context.read<WriteVideoCubit>().selectProfileImage(
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
              height: kDefaultPadding / 2,
            ),
            ArticleCheckBoxListTile(
              isEnabled: true,
              onToggle: () {
                context.read<WriteVideoCubit>().toggleVideoOrientation();
              },
              status: state.isHorizontal,
              text:
                  'This is ${state.isHorizontal ? 'an horizontal' : 'a vertical'} video',
              textColor: Theme.of(context).primaryColorDark,
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            BlocBuilder<WriteVideoCubit, WriteVideoState>(
              builder: (context, state) {
                return Row(
                  children: [
                    Expanded(
                      child: SimpleAutoCompleteTextField(
                        key: ArticleDetailsKey.key,
                        cursorColor: Theme.of(context).primaryColorDark,
                        decoration: InputDecoration(
                          hintText: 'Add your topics',
                        ),
                        controller: keywordController,
                        suggestions: state.suggestions,
                        clearOnSubmit: true,
                        isBottom: false,
                        textSubmitted: (text) {
                          if (text.isNotEmpty &&
                              !state.tags.contains(text.trim())) {
                            context
                                .read<WriteVideoCubit>()
                                .addKeyword(keywordController.text);
                            keywordController.clear();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final text = keywordController.text;

                        if (text.isNotEmpty &&
                            !state.tags.contains(text.trim())) {
                          context
                              .read<WriteVideoCubit>()
                              .addKeyword(keywordController.text);
                          keywordController.clear();
                        }
                      },
                      icon: Icon(Icons.add),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            BlocBuilder<WriteVideoCubit, WriteVideoState>(
              buildWhen: (previous, current) => previous.tags != current.tags,
              builder: (context, state) {
                return Wrap(
                  runSpacing: kDefaultPadding / 4,
                  spacing: kDefaultPadding / 4,
                  children: state.tags
                      .map(
                        (keyword) => Chip(
                          visualDensity: VisualDensity(vertical: -4),
                          label: Text(
                            keyword,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  height: 1.5,
                                ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(200),
                          ),
                          onDeleted: () {
                            context
                                .read<WriteVideoCubit>()
                                .deleteKeyword(keyword);
                          },
                        ),
                      )
                      .toList(),
                );
              },
            )
          ],
        );
      },
    );
  }
}
