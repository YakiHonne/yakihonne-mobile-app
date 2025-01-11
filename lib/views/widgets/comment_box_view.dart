// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/comment_box_cubit/comment_box_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nips/nip_019.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/global_keys.dart';
import 'package:yakihonne/utils/mentions/mentions.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/article_view/widgets/comment_prefix.dart';
import 'package:yakihonne/views/giphy_view/giphy_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/write_article_view/widgets/article_image_selector.dart';

class CommentBoxView extends HookWidget {
  final String commentId;
  final String commentPubkey;
  final String commentContent;
  final DateTime commentDate;
  final String shareableLink;
  final int kind;
  final bool? isNote;
  final Function(
    String,
    List<String>,
    String,
  ) onAddComment;

  CommentBoxView({
    required this.commentId,
    required this.commentPubkey,
    required this.commentContent,
    required this.commentDate,
    required this.shareableLink,
    required this.kind,
    required this.onAddComment,
    this.isNote,
  });

  @override
  Widget build(BuildContext context) {
    final mentions = useState(<String>{});
    final images = useState(<String>[]);
    final filteredTags = useState(nostrRepository.getFilteredTopics());

    return BlocProvider(
      create: (context) => CommentBoxCubit(),
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
          builder: (context, scrollController) {
            return Column(
              children: [
                ModalBottomSheetHandle(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2),
                  child: Row(
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
                      Spacer(),
                      BlocBuilder<CommentBoxCubit, CommentBoxState>(
                        builder: (context, state) {
                          return TextButton.icon(
                            onPressed: () {
                              final commentText = GlobalKeys.flutterMentionKey
                                  .currentState?.controller?.markupText;

                              if ((commentText == null ||
                                      commentText.trim().isEmpty) &&
                                  images.value.isEmpty) {
                                BotToastUtils.showError('Type a valid reply!');
                              } else {
                                if (isNote != null) {
                                  onAddComment.call(
                                    getUpdatedComment(
                                      commmentText: commentText ?? '',
                                      images: images.value,
                                    ),
                                    mentions.value.toList(),
                                    commentId,
                                  );
                                } else if (state.status ==
                                    CommentPrefixStatus.notSet) {
                                  showModalBottomSheet(
                                    context: context,
                                    elevation: 0,
                                    builder: (_) {
                                      return BlocProvider.value(
                                        value: context.read<CommentBoxCubit>(),
                                        child: CommentPrefix(
                                          comment: commentText ?? '',
                                          kind: kind,
                                          shareableLink: shareableLink,
                                          submitComment: (submit, comment) {
                                            context
                                                .read<CommentBoxCubit>()
                                                .updateCommentPrefixStatus(
                                                    submit)
                                                .then(
                                              (value) {
                                                onAddComment.call(
                                                  getUpdatedComment(
                                                    commmentText:
                                                        commentText ?? '',
                                                    images: images.value,
                                                  ),
                                                  mentions.value.toList(),
                                                  commentId,
                                                );

                                                Navigator.pop(context);
                                              },
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    isScrollControlled: true,
                                    useRootNavigator: true,
                                    useSafeArea: true,
                                    backgroundColor: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                  );
                                } else {
                                  onAddComment.call(
                                    getUpdatedComment(
                                      commmentText: commentText ?? '',
                                      images: images.value,
                                    ),
                                    mentions.value.toList(),
                                    commentId,
                                  );
                                }
                              }
                            },
                            label: SvgPicture.asset(
                              FeatureIcons.send,
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorLight,
                                BlendMode.srcIn,
                              ),
                              fit: BoxFit.scaleDown,
                            ),
                            icon: Text(
                              'Reply',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    color: Theme.of(context).primaryColorLight,
                                  ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).primaryColorDark,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                    ),
                    children: [
                      BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
                        selector: (state) => state.authors[commentPubkey],
                        builder: (context, user) {
                          final author = user ??
                              emptyUserModel.copyWith(
                                pubKey: commentPubkey,
                                picturePlaceholder: getRandomPlaceholder(
                                    input: commentPubkey, isPfp: true),
                              );

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 2,
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Column(
                                    children: [
                                      ProfilePicture2(
                                        size: 35,
                                        image: author.picture,
                                        placeHolder: author.picturePlaceholder,
                                        padding: 0,
                                        strokeWidth: 1,
                                        strokeColor:
                                            Theme.of(context).primaryColorDark,
                                        onClicked: () {
                                          openProfileFastAccess(
                                            context: context,
                                            pubkey: author.pubKey,
                                          );
                                        },
                                      ),
                                      Expanded(
                                        child: VerticalDivider(
                                          indent: kDefaultPadding / 4,
                                          color: kDimGrey,
                                          width: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: kDefaultPadding / 2,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'On ${dateFormat4.format(commentDate)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall!
                                              .copyWith(
                                                color: kDimGrey,
                                              ),
                                        ),
                                        RichText(
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'By ',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall!
                                                    .copyWith(
                                                      color: Theme.of(context)
                                                          .primaryColorDark,
                                                    ),
                                              ),
                                              TextSpan(
                                                text: getAuthorName(author),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall!
                                                    .copyWith(
                                                      color: context
                                                                  .read<
                                                                      ThemeCubit>()
                                                                  .state
                                                                  .theme ==
                                                              AppTheme
                                                                  .purpleWhite
                                                          ? kPurple
                                                          : Colors.purpleAccent,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: kDefaultPadding / 2,
                                          ),
                                          child: linkifiedText(
                                            context: context,
                                            text: getCommentWithoutPrefix(
                                              commentContent,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              'Replying to: ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall!,
                                            ),
                                            Expanded(
                                              child: Text(
                                                getAuthorName(author),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall!
                                                    .copyWith(
                                                      color: kOrange,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: kDefaultPadding / 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      BlocBuilder<CommentBoxCubit, CommentBoxState>(
                        builder: (context, state) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BlocSelector<AuthorsCubit, AuthorsState,
                                  UserModel?>(
                                selector: (state) =>
                                    state.authors[nostrRepository.usm!.pubKey],
                                builder: (context, user) {
                                  final currentUserPubkey =
                                      nostrRepository.usm!.pubKey;
                                  final author = user ??
                                      emptyUserModel.copyWith(
                                        pubKey: currentUserPubkey,
                                        picturePlaceholder:
                                            getRandomPlaceholder(
                                                input: currentUserPubkey,
                                                isPfp: true),
                                      );

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      top: kDefaultPadding / 4,
                                    ),
                                    child: ProfilePicture2(
                                      size: 35,
                                      image: author.picture,
                                      placeHolder: author.picturePlaceholder,
                                      padding: 0,
                                      strokeWidth: 1,
                                      strokeColor:
                                          Theme.of(context).primaryColorDark,
                                      onClicked: () {
                                        openProfileFastAccess(
                                          context: context,
                                          pubkey: author.pubKey,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                              BlocBuilder<AuthorsCubit, AuthorsState>(
                                builder: (context, authorsState) {
                                  List<Map<String, dynamic>> filteredList = [];

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
                                        });
                                      }
                                    },
                                  );

                                  return Expanded(
                                    child: FlutterMentions(
                                      key: GlobalKeys.flutterMentionKey,
                                      autofocus: true,
                                      suggestionPosition:
                                          SuggestionPosition.Bottom,
                                      enableInteractiveSelection: true,
                                      maxLines: null,
                                      keyboardType: TextInputType.multiline,
                                      textInputAction: TextInputAction.newline,
                                      suggestionListHeight: 220,
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
                                        hintText: 'Type your comment...',
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
                                        suffixIconConstraints:
                                            const BoxConstraints(
                                          maxHeight: 40,
                                          maxWidth: 40,
                                        ),
                                      ),
                                      onMentionAdd: (mention) {
                                        mentions.value.add(mention['id']);
                                      },
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
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      images.value.isNotEmpty
                          ? Column(
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
                                        itemCount: images.value.length,
                                        itemBuilder: (context, index) {
                                          final image = images.value[index];

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
                                                      final list =
                                                          List<String>.from(
                                                              images.value)
                                                            ..removeAt(index);

                                                      images.value = list;
                                                    },
                                                    icon: Icon(
                                                      Icons.close,
                                                      color: kWhite,
                                                    ),
                                                    style: IconButton.styleFrom(
                                                      backgroundColor:
                                                          kBlack.withValues(
                                                              alpha: 0.5),
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
                            )
                          : SizedBox.shrink(),
                    ],
                  ),
                ),
                Container(
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
                                  onTap: (imageLink) {
                                    images.value = [...images.value, imageLink];
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
                                  onGifSelected: (link) {
                                    images.value = [...images.value, link];
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
                          icon: SvgPicture.asset(
                            FeatureIcons.giphy,
                            width: 22,
                            height: 22,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            final controller = GlobalKeys
                                .flutterMentionKey.currentState?.controller;

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
                            final controller = GlobalKeys
                                .flutterMentionKey.currentState?.controller;

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
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String getUpdatedComment({
    required String commmentText,
    required List<String> images,
  }) {
    if (images.isEmpty) {
      return commmentText;
    } else {
      String updatedComment = commmentText;

      for (final image in images) {
        updatedComment = '$updatedComment $image';
      }

      return updatedComment;
    }
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
