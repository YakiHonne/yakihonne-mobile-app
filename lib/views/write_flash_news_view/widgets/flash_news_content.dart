import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/write_flash_news_cubit/write_flash_news_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/nostr/nips/nip_019.dart';
import 'package:yakihonne/utils/mentions/mention_view.dart';
import 'package:yakihonne/utils/mentions/models.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/widgets/auto_complete_textfield.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/custom_drop_down.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/write_article_view/widgets/article_image_selector.dart';
import 'package:yakihonne/views/write_flash_news_view/widgets/flash_user_content.dart';

class FlashNewsDetailsKey {
  static final GlobalKey<AutoCompleteTextFieldState<String>> key = GlobalKey();
  static final GlobalKey<FlutterMentionsState> flutterMentionKey =
      GlobalKey<FlutterMentionsState>();
}

const flashNewsKinds = [
  'plain post',
  'link with article',
  'link with curation',
];

class FlashNewsContent extends HookWidget {
  const FlashNewsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final keywordController = useTextEditingController(text: '');
    final counterText = useState(
      getTextLengthWithoutParsables(
        context.read<WriteFlashNewsCubit>().state.content,
      ),
    );

    final sourceController = useTextEditingController(
      text: context.read<WriteFlashNewsCubit>().state.source,
    );

    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final text = context.read<WriteFlashNewsCubit>().state.content;
        FlashNewsDetailsKey.flutterMentionKey.currentState!.controller!.text =
            text;
        TextEditingValue(text: text);
      });
    });

    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocConsumer<WriteFlashNewsCubit, WriteFlashNewsState>(
      listenWhen: (previous, current) =>
          previous.flashNewsKinds != current.flashNewsKinds ||
          previous.updateKind != current.updateKind,
      listener: (context, state) {
        if (state.flashNewsKinds == FlashNewsKinds.article &&
            state.article != null) {
          sourceController.text = nostrRepository.shareableLink(
            isArticle: true,
            identifier: state.article!.identifier,
            pubkey: state.article!.pubkey,
          );

          FlashNewsDetailsKey.flutterMentionKey.currentState?.controller?.text =
              state.article!.summary;

          context.read<WriteFlashNewsCubit>().setSource(sourceController.text);
          context.read<WriteFlashNewsCubit>().setContent(
                FlashNewsDetailsKey
                        .flutterMentionKey.currentState?.controller?.text ??
                    '',
              );
        } else if (state.flashNewsKinds == FlashNewsKinds.curation &&
            state.curation != null) {
          sourceController.text = nostrRepository.shareableLink(
            isArticle: false,
            identifier: state.curation!.identifier,
            pubkey: state.curation!.pubKey,
          );

          FlashNewsDetailsKey.flutterMentionKey.currentState?.controller?.text =
              state.curation!.description;
          context.read<WriteFlashNewsCubit>().setSource(sourceController.text);
          context.read<WriteFlashNewsCubit>().setContent(
                FlashNewsDetailsKey
                        .flutterMentionKey.currentState?.controller?.text ??
                    '',
              );
        } else {
          sourceController.text = '';
          FlashNewsDetailsKey.flutterMentionKey.currentState?.controller?.text =
              '';
          context.read<WriteFlashNewsCubit>().setSource('');
          context.read<WriteFlashNewsCubit>().setContent('');
        }
      },
      builder: (context, state) {
        final isLinkReady = (state.flashNewsKinds == FlashNewsKinds.article &&
                state.article != null) ||
            (state.flashNewsKinds == FlashNewsKinds.curation &&
                state.curation != null);

        return Container(
          child: ListView(
            padding: EdgeInsets.all(isTablet ? 10.w : kDefaultPadding / 2),
            children: [
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomDropDown(
                      list: flashNewsKinds,
                      defaultValue: state.flashNewsKinds == FlashNewsKinds.plain
                          ? flashNewsKinds.first
                          : state.flashNewsKinds == FlashNewsKinds.article
                              ? flashNewsKinds[1]
                              : flashNewsKinds[2],
                      onChanged: (kind) {
                        context.read<WriteFlashNewsCubit>().setFlashNewsKind(
                              kind == flashNewsKinds.first
                                  ? FlashNewsKinds.plain
                                  : kind == flashNewsKinds[1]
                                      ? FlashNewsKinds.article
                                      : FlashNewsKinds.curation,
                            );
                      },
                    ),
                  ),
                  if (state.flashNewsKinds != FlashNewsKinds.plain) ...[
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    ),
                    TextButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          elevation: 0,
                          builder: (_) {
                            return BlocProvider.value(
                              value: context.read<WriteFlashNewsCubit>(),
                              child: FlashUserContent(
                                isArticles: state.flashNewsKinds ==
                                    FlashNewsKinds.article,
                              ),
                            );
                          },
                          isScrollControlled: true,
                          useRootNavigator: true,
                          useSafeArea: true,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                        );
                      },
                      child: Text(
                        'Select ${state.flashNewsKinds == FlashNewsKinds.article ? 'article' : 'curation'}',
                      ),
                    ),
                  ]
                ],
              ),
              if (isLinkReady) ...[
                Padding(
                  padding: const EdgeInsets.all(kDefaultPadding / 2),
                  child: Text(
                    '${state.flashNewsKinds == FlashNewsKinds.article ? 'Article: ${state.article!.title}' : 'Curation: ${state.curation!.title}'}',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: kOrange,
                        ),
                  ),
                ),
              ],
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorLight,
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: kDefaultPadding / 1.5,
                    ),
                    BlocBuilder<AuthorsCubit, AuthorsState>(
                      builder: (context, authorState) {
                        List<Map<String, dynamic>> filteredList = [];

                        authorState.authors.values.forEach(
                          (user) {
                            if (user.name.isNotEmpty) {
                              filteredList.add({
                                'id': user.pubKey,
                                'display':
                                    '${user.name}${user.nip05.isNotEmpty ? ' - ${user.nip05}' : ''}',
                                'name': '${user.name}',
                                'display_name': user.name,
                                'image': user.picture,
                                'random': user.picturePlaceholder,
                              });
                            }
                          },
                        );

                        return FlutterMentions(
                          key: FlashNewsDetailsKey.flutterMentionKey,
                          autofocus: true,
                          suggestionPosition: SuggestionPosition.Bottom,
                          enableInteractiveSelection: true,
                          minLines: 5,
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          suggestionListHeight: 150,
                          onSearchChanged: (trigger, value) {
                            if (trigger == '@') {
                              authorsCubit.getUsersBySearch(value);
                            }
                          },
                          suggestionListDecoration: BoxDecoration(
                            color: Theme.of(context).primaryColorLight,
                            borderRadius: BorderRadius.circular(
                              kDefaultPadding / 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                spreadRadius: 3,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Content...',
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding,
                            ),
                          ),
                          onChanged: (value) {
                            final text = FlashNewsDetailsKey.flutterMentionKey
                                .currentState!.controller!.markupText;

                            context
                                .read<WriteFlashNewsCubit>()
                                .setContent(text);

                            counterText.value =
                                getTextLengthWithoutParsables(text);
                          },
                          mentions: [
                            Mention(
                              trigger: '@',
                              style: TextStyle(
                                color: Colors.amber,
                              ),
                              markupBuilder: (trigger, mention, value) {
                                return 'nostr:${Nip19.encodePubkey(mention)}';
                              },
                              data: filteredList,
                              suggestionBuilder: (data) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: kDefaultPadding / 4,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: kDefaultPadding / 2,
                                    vertical: kDefaultPadding / 8,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      ProfilePicture2(
                                        size: 35,
                                        image: data['image'],
                                        placeHolder: data['random'],
                                        padding: 0,
                                        strokeWidth: 1,
                                        strokeColor:
                                            Theme.of(context).primaryColorDark,
                                        onClicked: () {},
                                      ),
                                      SizedBox(
                                        width: kDefaultPadding / 2,
                                      ),
                                      Expanded(
                                        child: Text(
                                          data['display_name'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium!
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: kDefaultPadding / 2,
                                      ),
                                      PubKeyContainer(
                                        pubKey: data['id'],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5, bottom: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CustomIconButton(
                              onClicked: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (_) {
                                    return ImageSelector(
                                      onTap: (imageLink) {
                                        String newText = '';
                                        final text = FlashNewsDetailsKey
                                                .flutterMentionKey
                                                .currentState
                                                ?.controller
                                                ?.text ??
                                            '';
                                        if (text.isEmpty) {
                                          newText = imageLink;
                                          FlashNewsDetailsKey
                                              .flutterMentionKey
                                              .currentState
                                              ?.controller
                                              ?.text = imageLink;
                                        } else {
                                          final selection = FlashNewsDetailsKey
                                              .flutterMentionKey
                                              .currentState!
                                              .controller!
                                              .selection;

                                          newText = text.replaceRange(
                                            selection.start,
                                            selection.end,
                                            ' ${imageLink} ',
                                          );

                                          FlashNewsDetailsKey
                                              .flutterMentionKey
                                              .currentState
                                              ?.controller
                                              ?.value = TextEditingValue(
                                            text: newText,
                                            selection: TextSelection.collapsed(
                                              offset:
                                                  selection.baseOffset.toInt() +
                                                      imageLink.length +
                                                      2,
                                            ),
                                          );
                                        }

                                        context
                                            .read<WriteFlashNewsCubit>()
                                            .setContent(newText);
                                      },
                                    );
                                  },
                                  isScrollControlled: true,
                                  useRootNavigator: true,
                                  useSafeArea: true,
                                  elevation: 0,
                                  backgroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                );
                              },
                              icon: FeatureIcons.imageUpload,
                              size: 20,
                              backgroundColor:
                                  Theme.of(context).primaryColorLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              Align(
                alignment: Alignment(0.9, 0),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.labelMedium,
                    children: [
                      TextSpan(
                        text: '${counterText.value}',
                        style: TextStyle(
                          color: counterText.value > FN_MAX_LENGTH
                              ? kRed
                              : Theme.of(context).primaryColorDark,
                        ),
                      ),
                      TextSpan(
                        text: '/$FN_MAX_LENGTH',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              TextFormField(
                controller: sourceController,
                decoration: InputDecoration(
                  hintText: 'Source (optional)',
                ),
                enabled: !isLinkReady,
                maxLines: 1,
                onChanged: (text) {
                  context.read<WriteFlashNewsCubit>().setSource(text);
                },
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              ListTile(
                tileColor: Theme.of(context).primaryColorLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
                ),
                leading: Checkbox(
                  value: state.isImportant,
                  onChanged: (importance) {
                    context
                        .read<WriteFlashNewsCubit>()
                        .setImportant(importance ?? false);
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
                  'Flash news importance',
                  style: TextStyle(
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
                subtitle: Text(
                  '${nostrRepository.importantTagPrice} SATS',
                  style: TextStyle(
                    color: kOrange,
                  ),
                ),
                onTap: () {
                  context
                      .read<WriteFlashNewsCubit>()
                      .setImportant(!state.isImportant);
                },
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              BlocBuilder<WriteFlashNewsCubit, WriteFlashNewsState>(
                builder: (context, state) {
                  return Row(
                    children: [
                      Expanded(
                        child: AbsorbPointer(
                          absorbing: state.keywords.length >= 3,
                          child: SimpleAutoCompleteTextField(
                            key: FlashNewsDetailsKey.key,
                            cursorColor: Theme.of(context).primaryColorDark,
                            decoration: InputDecoration(
                              hintText: 'keywords (3 allowed)',
                            ),
                            controller: keywordController,
                            suggestions: state.suggestions,
                            clearOnSubmit: true,
                            isBottom: false,
                            textSubmitted: (text) {
                              if (text.isNotEmpty &&
                                  !state.keywords.contains(text.trim())) {
                                context
                                    .read<WriteFlashNewsCubit>()
                                    .addKeyword(keywordController.text);
                                keywordController.clear();
                              }
                            },
                          ),
                        ),
                      ),
                      Visibility(
                        visible: state.keywords.length < 3,
                        child: IconButton(
                          onPressed: () {
                            final text = keywordController.text;

                            if (text.isNotEmpty &&
                                !state.keywords.contains(text.trim())) {
                              context
                                  .read<WriteFlashNewsCubit>()
                                  .addKeyword(keywordController.text);
                              keywordController.clear();
                            }
                          },
                          icon: Icon(Icons.add),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              BlocBuilder<WriteFlashNewsCubit, WriteFlashNewsState>(
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
                                  .read<WriteFlashNewsCubit>()
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
      },
    );
  }
}
