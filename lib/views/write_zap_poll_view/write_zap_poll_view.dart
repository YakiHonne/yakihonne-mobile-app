// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/write_note_cubit/write_note_cubit.dart';
import 'package:yakihonne/blocs/write_zap_poll_cubit/write_zap_poll_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/global_keys.dart';
import 'package:yakihonne/utils/mentions/mention_view.dart';
import 'package:yakihonne/utils/mentions/models.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/giphy_view/giphy_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/custom_date_picker.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/write_article_view/widgets/article_image_selector.dart';

class WriteZapPollView extends HookWidget {
  const WriteZapPollView({
    Key? key,
    required this.onZapPollAdded,
  }) : super(key: key);

  final Function(Event) onZapPollAdded;

  @override
  Widget build(BuildContext context) {
    final mentions = useState(<String>{});
    final tags = useState(<String>{});
    final filteredTags = useState(nostrRepository.getFilteredTopics());
    final closedDate = useState<DateTime?>(null);
    final miTec = useTextEditingController();
    final maTec = useTextEditingController();

    return BlocProvider(
      create: (context) => WriteZapPollCubit(),
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
                      'Zap poll',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    BlocBuilder<WriteZapPollCubit, WriteZapPollState>(
                      builder: (context, state) {
                        return TextButton.icon(
                          onPressed: () {
                            final post = GlobalKeys.flutterMentionKey
                                .currentState?.controller?.markupText;

                            if ((post == null || post.trim().isEmpty) &&
                                state.images.isEmpty) {
                              BotToastUtils.showError(
                                'Type a valid poll question!',
                              );
                            } else {
                              context.read<WriteZapPollCubit>().PostZapPoll(
                                    content: post ?? '',
                                    mentions: mentions.value.toList(),
                                    tags: tags.value.toList(),
                                    onSuccess: onZapPollAdded,
                                    closedAt: closedDate.value,
                                    maximumSatoshis: maTec.text,
                                    minimumSatoshis: miTec.text,
                                  );
                            }
                          },
                          label: SvgPicture.asset(
                            FeatureIcons.addRaw,
                            width: 15,
                            height: 15,
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
                                      enableSuggestions: false,
                                      enableInteractiveSelection: true,
                                      maxLines: null,
                                      keyboardType: TextInputType.multiline,
                                      textInputAction: TextInputAction.newline,
                                      suggestionListHeight: 200,
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
                                        hintText: 'Write your poll...',
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
                                                    size: 35,
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
                    BlocBuilder<WriteZapPollCubit, WriteZapPollState>(
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
                    Padding(
                      padding: const EdgeInsets.all(kDefaultPadding / 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Poll options',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          CustomIconButton(
                            onClicked: () {
                              context.read<WriteZapPollCubit>().addPollOption();
                            },
                            icon: FeatureIcons.addRaw,
                            size: 15,
                            backgroundColor:
                                Theme.of(context).primaryColorLight,
                            vd: -2,
                          ),
                        ],
                      ),
                    ),
                    BlocBuilder<WriteZapPollCubit, WriteZapPollState>(
                      builder: (context, state) {
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding / 2,
                          ),
                          shrinkWrap: true,
                          primary: false,
                          itemBuilder: (context, index) {
                            final option = state.options[index];

                            return PollOptionTextField(
                              option: option,
                              index: index,
                              optionsLength: state.options.length,
                              onChanged: (value) {
                                context
                                    .read<WriteZapPollCubit>()
                                    .updatePollOption(value, index);
                              },
                              onRemove: () {
                                context
                                    .read<WriteZapPollCubit>()
                                    .removePollOption(index);
                              },
                            );
                          },
                          separatorBuilder: (context, index) => const SizedBox(
                            height: kDefaultPadding / 4,
                          ),
                          itemCount: state.options.length,
                        );
                      },
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 2,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Minimum satoshis',
                                ),
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: miTec,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: kDefaultPadding / 4,
                          ),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Maximum satoshis',
                                ),
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: maTec,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 2,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Poll close date',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          if (closedDate.value == null)
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  useSafeArea: true,
                                  builder: (_) {
                                    return Dialog(
                                      insetPadding: const EdgeInsets.symmetric(
                                        horizontal: kDefaultPadding,
                                      ),
                                      child: BlocProvider.value(
                                        value:
                                            context.read<WriteZapPollCubit>(),
                                        child: PickDateTimeWidget(
                                          focusedDate: closedDate.value ??
                                              DateTime.now(),
                                          isAfter: true,
                                          onDateSelected: (selectedDate) {
                                            closedDate.value = selectedDate;
                                          },
                                          onClearDate: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).primaryColorLight,
                              ),
                              icon: SvgPicture.asset(
                                FeatureIcons.calendar,
                                width: 22,
                                height: 22,
                                colorFilter: ColorFilter.mode(
                                  Theme.of(context).primaryColorDark,
                                  BlendMode.srcIn,
                                ),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Text(
                                  dateFormat4.format(closedDate.value!),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        color: kOrangeContrasted,
                                      ),
                                ),
                                const SizedBox(
                                  width: kDefaultPadding / 4,
                                ),
                                CustomIconButton(
                                  onClicked: () {
                                    closedDate.value = null;
                                  },
                                  icon: FeatureIcons.close,
                                  size: 20,
                                  backgroundColor:
                                      Theme.of(context).primaryColorLight,
                                  vd: -2,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PublishingMediaContainer(
                onImageAdd: (imageLink) {
                  context.read<WriteZapPollCubit>().addImage(imageLink);
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

class PollOptionTextField extends HookWidget {
  const PollOptionTextField({
    Key? key,
    required this.option,
    required this.index,
    required this.optionsLength,
    required this.onChanged,
    required this.onRemove,
  }) : super(key: key);

  final String option;
  final int index;
  final int optionsLength;
  final Function(String) onChanged;
  final Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final tfc = useTextEditingController(text: option);

    useEffect(
      () {
        tfc.clear();
        tfc.text = option;
        return;
      },
    );

    return Container(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Option: $index',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          Expanded(
            flex: 4,
            child: TextFormField(
              controller: tfc,
              onChanged: onChanged,
            ),
          ),
          if (optionsLength > 2) ...[
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            CustomIconButton(
              onClicked: onRemove,
              icon: FeatureIcons.trash,
              size: 20,
              backgroundColor: kRed,
            ),
          ]
        ],
      ),
    );
  }
}

class PublishingMediaContainer extends StatelessWidget {
  const PublishingMediaContainer({
    Key? key,
    required this.onImageAdd,
  }) : super(key: key);

  final Function(String) onImageAdd;

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
