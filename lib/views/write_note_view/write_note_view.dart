// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/write_note_cubit/write_note_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/global_keys.dart';
import 'package:yakihonne/utils/mentions/mention_view.dart';
import 'package:yakihonne/utils/mentions/models.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/giphy_view/giphy_view.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_container.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/note_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/smart_widget_selection.dart';
import 'package:yakihonne/views/write_article_view/widgets/article_image_selector.dart';

class WriteNoteView extends HookWidget {
  const WriteNoteView({
    Key? key,
    this.quotedNote,
    this.replyNote,
  }) : super(key: key);

  final DetailedNoteModel? replyNote;
  final DetailedNoteModel? quotedNote;

  @override
  Widget build(BuildContext context) {
    final mentions = useState(<String>{});
    final tags = useState(<String>{});
    final filteredTags = useState(nostrRepository.getFilteredTopics());

    return BlocProvider(
      create: (context) => WriteNoteCubit(quotedNote),
      child: Container(
        width: double.infinity,
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.60,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Center(child: ModalBottomSheetHandle()),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style:
                            Theme.of(context).textTheme.labelMedium!.copyWith(
                                  color: kWhite,
                                ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: kRed,
                      ),
                    ),
                    Text(
                      'Compose',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    BlocBuilder<WriteNoteCubit, WriteNoteState>(
                      builder: (context, state) {
                        return TextButton.icon(
                          onPressed: () {
                            final post = GlobalKeys.flutterMentionKey
                                .currentState?.controller?.markupText;

                            if ((post == null || post.trim().isEmpty) &&
                                state.images.isEmpty) {
                              BotToastUtils.showError('Type a valid note!');
                            } else {
                              context.read<WriteNoteCubit>().postNote(
                                    content: post ?? '',
                                    mentions: mentions.value.toList(),
                                    tags: tags.value.toList(),
                                    onSuccess: () =>
                                        Navigator.of(context).pop(),
                                  );
                            }
                          },
                          label: SvgPicture.asset(
                            FeatureIcons.add,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).primaryColorLight,
                              BlendMode.srcIn,
                            ),
                            fit: BoxFit.scaleDown,
                          ),
                          icon: Text(
                            'Post',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  color: Theme.of(context).primaryColorLight,
                                ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColorDark,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Divider(
                height: 0,
                thickness: 0.5,
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(
                        kDefaultPadding / 2,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
                            selector: (state) =>
                                state.authors[nostrRepository.usm!.pubKey],
                            builder: (context, user) {
                              final currentUserPubkey =
                                  nostrRepository.usm!.pubKey;
                              final author = user ??
                                  emptyUserModel.copyWith(
                                    pubKey: currentUserPubkey,
                                    picturePlaceholder: getRandomPlaceholder(
                                        input: currentUserPubkey, isPfp: true),
                                  );

                              return ProfilePicture2(
                                size: 40,
                                image: author.picture,
                                placeHolder: author.picturePlaceholder,
                                padding: 0,
                                strokeWidth: 0,
                                strokeColor: kTransparent,
                                onClicked: () {
                                  openProfileFastAccess(
                                    context: context,
                                    pubkey: author.pubKey,
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 2,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                BlocBuilder<AuthorsCubit, AuthorsState>(
                                  builder: (context, authorsState) {
                                    List<Map<String, dynamic>> filteredList =
                                        [];

                                    authorsState.authors.values.forEach(
                                      (user) {
                                        if (user.name.isNotEmpty) {
                                          filteredList.add({
                                            'id': user.pubKey,
                                            'display':
                                                '${user.name}${user.nip05.isNotEmpty ? ' - ${user.nip05}' : ''}',
                                            'name': user.name,
                                            'image': user.picture,
                                            'random': user.picturePlaceholder,
                                            'type': 'mention',
                                          });
                                        }
                                      },
                                    );

                                    return FlutterMentions(
                                      key: GlobalKeys.flutterMentionKey,
                                      autofocus: true,
                                      suggestionPosition:
                                          SuggestionPosition.Bottom,
                                      enableInteractiveSelection: true,
                                      maxLines: null,
                                      keyboardType: TextInputType.multiline,
                                      textInputAction: TextInputAction.newline,
                                      suggestionListHeight: 150,
                                      onSearchChanged: (trigger, value) {
                                        if (trigger == '@') {
                                          authorsCubit.getUsersBySearch(value);
                                        }
                                      },
                                      suggestionListDecoration: BoxDecoration(
                                        color:
                                            Theme.of(context).primaryColorLight,
                                        borderRadius: BorderRadius.circular(
                                          kDefaultPadding / 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .scaffoldBackgroundColor,
                                            spreadRadius: 3,
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Write your note...',
                                        hintStyle: Theme.of(context)
                                            .textTheme
                                            .labelMedium,
                                        fillColor: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        focusColor:
                                            Theme.of(context).primaryColorLight,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onMentionAdd: (mention) {
                                        if (mention['type'] == 'mention') {
                                          mentions.value.add(mention['id']);
                                        } else {
                                          tags.value.add(mention['id']);
                                        }
                                      },
                                      appendSpaceOnAdd: true,
                                      mentions: [
                                        Mention(
                                          trigger: '@',
                                          style: TextStyle(
                                            color: Colors.amber,
                                          ),
                                          markupBuilder:
                                              (trigger, mention, value) {
                                            return 'nostr:${Nip19.encodePubkey(mention)}';
                                          },
                                          data: filteredList,
                                          suggestionBuilder: (data) {
                                            return Container(
                                              padding: EdgeInsets.symmetric(
                                                vertical: kDefaultPadding / 4,
                                              ),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                horizontal: kDefaultPadding / 2,
                                                vertical: kDefaultPadding / 8,
                                              ),
                                              child: Row(
                                                children: <Widget>[
                                                  ProfilePicture2(
                                                    size: 25,
                                                    image: data['image'],
                                                    placeHolder: data['random'],
                                                    padding: 0,
                                                    strokeWidth: 1,
                                                    strokeColor:
                                                        Theme.of(context)
                                                            .primaryColorDark,
                                                    onClicked: () {},
                                                  ),
                                                  SizedBox(
                                                    width: kDefaultPadding / 2,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      data['name'],
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelMedium!
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
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
                                        Mention(
                                          trigger: '#',
                                          style: TextStyle(
                                            color: Colors.pink,
                                          ),
                                          data: getTags(filteredTags.value),
                                          markupBuilder:
                                              (trigger, mention, value) {
                                            return '#$mention';
                                          },
                                          suggestionBuilder: (data) {
                                            return Container(
                                              padding: EdgeInsets.symmetric(
                                                vertical: kDefaultPadding / 4,
                                              ),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                horizontal: kDefaultPadding / 2,
                                                vertical: kDefaultPadding / 8,
                                              ),
                                              child: Row(
                                                children: <Widget>[
                                                  Text(
                                                    '#',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelMedium!
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  SizedBox(
                                                    width: kDefaultPadding / 2,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      data['id'],
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelMedium!,
                                                    ),
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    BlocBuilder<WriteNoteCubit, WriteNoteState>(
                      builder: (context, state) {
                        if (state.widgets.isNotEmpty) {
                          return ListView.separated(
                            separatorBuilder: (context, index) => SizedBox(
                              width: kDefaultPadding / 2,
                            ),
                            padding: const EdgeInsets.all(
                              kDefaultPadding / 2,
                            ),
                            itemCount: state.widgets.length,
                            shrinkWrap: true,
                            primary: false,
                            itemBuilder: (context, index) {
                              final sw = state.widgets[index];

                              if (sw.container != null)
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SmartWidget(
                                      smartWidgetContainer: sw.container!,
                                    ),
                                    const SizedBox(
                                      height: kDefaultPadding / 4,
                                    ),
                                    CustomIconButton(
                                      onClicked: () {
                                        context
                                            .read<WriteNoteCubit>()
                                            .removeWidget(index);
                                        GlobalKeys
                                                .flutterMentionKey
                                                .currentState!
                                                .controller!
                                                .text =
                                            GlobalKeys.flutterMentionKey
                                                .currentState!.controller!.text
                                                .replaceAll(
                                          sw.getNaddr(),
                                          '',
                                        );
                                      },
                                      icon: FeatureIcons.trash,
                                      size: 20,
                                      backgroundColor: kRed,
                                      vd: -2,
                                    ),
                                  ],
                                );
                              else
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      kDefaultPadding / 2,
                                    ),
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                  ),
                                  padding:
                                      const EdgeInsets.all(kDefaultPadding / 2),
                                  child: Text(
                                    'This smart widget does not follow the agreed on convention.',
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                );
                            },
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      },
                    ),
                    BlocBuilder<WriteNoteCubit, WriteNoteState>(
                      builder: (context, state) {
                        if (state.images.isNotEmpty) {
                          return Column(
                            children: [
                              Column(
                                children: [
                                  SizedBox(
                                    height: 140,
                                    child: ListView.separated(
                                      separatorBuilder: (context, index) =>
                                          SizedBox(
                                        width: kDefaultPadding / 2,
                                      ),
                                      padding: const EdgeInsets.all(
                                        kDefaultPadding / 2,
                                      ),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: state.images.length,
                                      itemBuilder: (context, index) {
                                        final image = state.images[index];

                                        return AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: CachedNetworkImage(
                                            fit: BoxFit.cover,
                                            imageUrl: image,
                                            imageBuilder:
                                                (context, imageProvider) {
                                              return Container(
                                                alignment: Alignment.topRight,
                                                decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                    image: imageProvider,
                                                    fit: BoxFit.cover,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    kDefaultPadding / 2,
                                                  ),
                                                ),
                                                child: IconButton(
                                                  onPressed: () {
                                                    context
                                                        .read<WriteNoteCubit>()
                                                        .removeImage(index);
                                                    GlobalKeys
                                                            .flutterMentionKey
                                                            .currentState!
                                                            .controller!
                                                            .text =
                                                        GlobalKeys
                                                            .flutterMentionKey
                                                            .currentState!
                                                            .controller!
                                                            .text
                                                            .replaceAll(
                                                                image, '');
                                                  },
                                                  icon: Icon(
                                                    Icons.close,
                                                    color: kWhite,
                                                  ),
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: kBlack
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                ),
                                              );
                                            },
                                            placeholder: (context, url) =>
                                                ImageLoadingPlaceHolder(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    NoImagePlaceHolder(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      },
                    ),
                    BlocBuilder<WriteNoteCubit, WriteNoteState>(
                      builder: (context, state) {
                        if (state.isQuotedNoteAvailable) {
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(
                                  kDefaultPadding / 2,
                                ),
                                child: Stack(
                                  children: [
                                    NoteContainer(
                                      note: state.quotedNote!,
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: IconButton(
                                        onPressed: () {
                                          context
                                              .read<WriteNoteCubit>()
                                              .removeQuotedNote();
                                        },
                                        icon: Icon(
                                          Icons.close,
                                          color: kWhite,
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              kBlack.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      },
                    ),
                  ],
                ),
              ),
              PublishingMediaContainer(
                onImageAdd: (imageLink) {
                  context.read<WriteNoteCubit>().addImage(imageLink);
                  GlobalKeys.flutterMentionKey.currentState!.controller!.text =
                      '${GlobalKeys.flutterMentionKey.currentState!.controller!.text} $imageLink';
                },
                onSmartWidgetAdded: (sw) {
                  GlobalKeys.flutterMentionKey.currentState!.controller!.text =
                      '${GlobalKeys.flutterMentionKey.currentState!.controller!.text} ${baseUrl + 'smart-widget-checker?naddr=' + sw.getNaddr()}';
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> getTags(List<String> suggestions) {
    List<Map<String, String>> filteredList = [];

    suggestions.forEach(
      (element) {
        if (!element.contains(' ')) {
          final el = element.startsWith('#')
              ? element.removeFirstCharacter()
              : element;

          filteredList.add(
            {
              'id': el,
              'display': el,
              'name': el,
              'type': 'tag',
            },
          );
        }
      },
    );

    return filteredList;
  }
}

class PublishingMediaContainer extends StatelessWidget {
  const PublishingMediaContainer({
    Key? key,
    required this.onImageAdd,
    required this.onSmartWidgetAdded,
  }) : super(key: key);

  final Function(String) onImageAdd;
  final Function(SmartWidgetModel) onSmartWidgetAdded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return BlocProvider.value(
                      value: context.read<WriteNoteCubit>(),
                      child: SmartWidgetSelection(
                        onWidgetAdded: (sw) {
                          context.read<WriteNoteCubit>().addWidget(sw);
                          onSmartWidgetAdded.call(sw);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  elevation: 0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              icon: SvgPicture.asset(
                FeatureIcons.smartWidget,
                width: 25,
                height: 25,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return ImageSelector(
                      onTap: onImageAdd,
                    );
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  elevation: 0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              icon: SvgPicture.asset(
                FeatureIcons.imageLink,
                width: 25,
                height: 25,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return GiphyView(
                      onGifSelected: onImageAdd,
                    );
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  elevation: 0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              icon: SvgPicture.asset(
                FeatureIcons.giphy,
                width: 22,
                height: 22,
              ),
            ),
            IconButton(
              onPressed: () {
                final controller =
                    GlobalKeys.flutterMentionKey.currentState?.controller;

                controller?.text = controller.text + '@';
              },
              icon: Text(
                '@',
                style: TextStyle(
                  fontSize: 22,
                  height: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                final controller =
                    GlobalKeys.flutterMentionKey.currentState?.controller;

                controller?.text = controller.text + '#';
              },
              icon: Text(
                '#',
                style: TextStyle(
                  fontSize: 22,
                  height: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
