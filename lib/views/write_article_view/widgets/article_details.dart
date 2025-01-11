import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/write_article_cubit/write_article_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/auto_complete_textfield.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class ArticleDetailsKey {
  static final GlobalKey<AutoCompleteTextFieldState<String>> key = GlobalKey();
}

class ArticleDetails extends HookWidget {
  ArticleDetails({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrlController = useTextEditingController(
      text: !context.read<WriteArticleCubit>().state.isLocalImage
          ? context.read<WriteArticleCubit>().state.imageLink
          : '',
    );

    final keywordController = useTextEditingController(text: '');

    final excerptController = useTextEditingController(
      text: context.read<WriteArticleCubit>().state.excerpt,
    );

    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return FadeInRight(
      duration: const Duration(milliseconds: 300),
      child: ListView(
        padding: EdgeInsets.all(isTablet ? 10.w : kDefaultPadding / 2),
        children: [
          const SizedBox(
            height: kDefaultPadding,
          ),
          BlocBuilder<WriteArticleCubit, WriteArticleState>(
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
                              mainAxisAlignment: MainAxisAlignment.center,
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
                            context.read<WriteArticleCubit>().removeImage();
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
                child: BlocBuilder<WriteArticleCubit, WriteArticleState>(
                  builder: (context, state) {
                    return TextFormField(
                      controller: imageUrlController,
                      decoration: InputDecoration(
                        hintText: 'Image url',
                      ),
                      onChanged: (url) {
                        context.read<WriteArticleCubit>().selectUrlImage(
                              url: url,
                              onFailed: () {
                                if (url.isEmpty ||
                                    !url.startsWith('https://')) {
                                  singleSnackBar(
                                    context: context,
                                    message: 'Select a valid url image.',
                                    color: kRed,
                                    backGroundColor: kRedSide,
                                    icon: ToastsIcons.error,
                                  );
                                }
                              },
                            );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              BlocBuilder<WriteArticleCubit, WriteArticleState>(
                builder: (context, state) {
                  return BorderedIconButton(
                    firstSelection: true,
                    onClicked: () {
                      imageUrlController.clear();
                      context.read<WriteArticleCubit>().selectProfileImage(
                        onFailed: () {
                          singleSnackBar(
                            context: context,
                            message: 'Issue occured while selecting the image.',
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
          TextFormField(
            controller: excerptController,
            decoration: InputDecoration(
              hintText: 'Description',
            ),
            minLines: 4,
            maxLines: 4,
            onChanged: (text) {
              context.read<WriteArticleCubit>().setDescription(text);
            },
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          BlocBuilder<WriteArticleCubit, WriteArticleState>(
            buildWhen: (previous, current) =>
                previous.isSensitive != current.isSensitive,
            builder: (context, state) {
              return ArticleCheckBoxListTile(
                isEnabled: true,
                status: state.isSensitive,
                text: 'This is a sensitive content',
                onToggle: () {
                  context.read<WriteArticleCubit>().toggleSensitive();
                },
              );
            },
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          BlocBuilder<WriteArticleCubit, WriteArticleState>(
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
                            !state.keywords.contains(text.trim())) {
                          context
                              .read<WriteArticleCubit>()
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
                          !state.keywords.contains(text.trim())) {
                        context
                            .read<WriteArticleCubit>()
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
          BlocBuilder<WriteArticleCubit, WriteArticleState>(
            buildWhen: (previous, current) =>
                previous.keywords != current.keywords,
            builder: (context, state) {
              return Wrap(
                runSpacing: kDefaultPadding / 4,
                spacing: kDefaultPadding / 4,
                children: state.keywords
                    .map(
                      (keyword) => Chip(
                        visualDensity: VisualDensity(vertical: -4),
                        label: Text(
                          keyword,
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    height: 1.5,
                                  ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(200),
                        ),
                        onDeleted: () {
                          context
                              .read<WriteArticleCubit>()
                              .deleteKeyword(keyword);
                        },
                      ),
                    )
                    .toList(),
              );
            },
          )
        ],
      ),
    );
  }
}

class ArticleCheckBoxListTile extends StatelessWidget {
  const ArticleCheckBoxListTile({
    super.key,
    required this.isEnabled,
    required this.status,
    required this.text,
    required this.onToggle,
    this.textColor,
  });

  final bool isEnabled;
  final bool status;
  final String text;
  final Color? textColor;
  final Function() onToggle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).primaryColorLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
      ),
      enabled: isEnabled,
      leading: Checkbox(
        value: status,
        onChanged: (value) {
          onToggle.call();
        },
        side: BorderSide(
          color: Theme.of(context).primaryColorDark,
          width: 1.5,
        ),
        visualDensity: VisualDensity(horizontal: -4, vertical: -4),
        activeColor: kPurple,
        checkColor: kWhite,
      ),
      dense: true,
      title: Text(
        text,
        style: TextStyle(
          color: textColor,
        ),
      ),
      onTap: onToggle,
    );
  }
}
