// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/flash_news_details_cubit/flash_news_details_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/article_view/widgets/articles_buttons.dart';
import 'package:yakihonne/views/threads_view/threads_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/comment_box_view.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class FlashNewsMainComments extends StatelessWidget {
  const FlashNewsMainComments({
    Key? key,
    required this.comments,
    required this.scrollController,
    required this.mutes,
    required this.userStatus,
    required this.currentUserPubkey,
    required this.onAddComment,
    required this.onDeleteComment,
    required this.kind,
    required this.authorPubkey,
    required this.shareableLink,
  }) : super(key: key);

  final List<Comment> comments;
  final ScrollController scrollController;
  final List<String> mutes;
  final UserStatus userStatus;
  final String currentUserPubkey;
  final String authorPubkey;
  final Function(String, List<String>, String) onAddComment;
  final Function(String) onDeleteComment;
  final int kind;
  final String shareableLink;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemBuilder: (context, index) {
        final comment = comments[index];

        if (!comment.isRoot) {
          return SizedBox.shrink();
        } else {
          final subComments = getSubComments(
            comments: comments,
            commentId: comment.id,
          );

          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding / 4,
            ),
            child: MainCommentContainer(
              kind: kind,
              userStatus: userStatus,
              isThread: false,
              onAddComment: onAddComment,
              isAuthor: comment.pubKey == authorPubkey,
              onClicked: () {
                if (subComments.isNotEmpty) {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => ThreadsView(
                        mainCommentId: comment.id,
                        authorPubkey: authorPubkey,
                        threadsType: ThreadsType.flash,
                        flashNewsDetailsCubit:
                            context.read<FlashNewsDetailsCubit>(),
                        userStatus: userStatus,
                        currentUserPubkey: currentUserPubkey,
                        shareableLink: shareableLink,
                        mutes: mutes,
                        kind: kind,
                        onAddComment: onAddComment,
                        onDeleteComment: onDeleteComment,
                      ),
                    ),
                  );
                }
              },
              isMain: false,
              shareableLink: shareableLink,
              isMuted: mutes.contains(comment.pubKey),
              comment: comment,
              count: subComments.length,
              openLink: (link) => openWebPage(url: link),
              canBeDeleted: comment.pubKey == currentUserPubkey &&
                  userStatus == UserStatus.UsingPrivKey,
              onDelete: () => onDeleteComment(comment.id),
            ),
          );
        }
      },
      itemCount: comments.length,
    );
  }

  List<String> getSubComments({
    required List<Comment> comments,
    required String commentId,
  }) {
    Set<String> subCommentsIds = {};

    for (final subComment in comments) {
      if (!subComment.isRoot && !subCommentsIds.contains(subComment.id)) {
        if (commentId == subComment.replyTo) {
          subCommentsIds.add(subComment.id);

          final list = getSubComments(
            comments: comments,
            commentId: subComment.id,
          );

          subCommentsIds.addAll(list);
        }
      }
    }

    return subCommentsIds.toList();
  }
}

class MainCommentContainer extends HookWidget {
  const MainCommentContainer({
    Key? key,
    required this.comment,
    required this.isThread,
    required this.isMain,
    required this.count,
    required this.shareableLink,
    required this.isMuted,
    required this.isAuthor,
    required this.kind,
    required this.canBeDeleted,
    this.isLast,
    required this.userStatus,
    required this.onClicked,
    required this.openLink,
    required this.onDelete,
    required this.onAddComment,
  }) : super(key: key);

  final Comment comment;
  final bool isThread;
  final bool isMain;
  final int count;
  final String shareableLink;
  final bool isMuted;
  final bool isAuthor;
  final int kind;
  final bool canBeDeleted;
  final bool? isLast;
  final UserStatus userStatus;
  final Function() onClicked;
  final Function(String) openLink;
  final Function() onDelete;
  final Function(String, List<String>, String) onAddComment;

  @override
  Widget build(BuildContext context) {
    final isHidden = useState(true);

    return BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
      selector: (state) => authorsCubit.getAuthor(comment.pubKey),
      builder: (context, user) {
        final author = user ??
            emptyUserModel.copyWith(
              pubKey: comment.pubKey,
              picturePlaceholder:
                  getRandomPlaceholder(input: comment.pubKey, isPfp: true),
            );

        return GestureDetector(
          onTap: () {
            onClicked.call();
          },
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: !isThread
                ? const EdgeInsets.symmetric(vertical: kDefaultPadding / 4)
                : EdgeInsets.zero,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isThread && !isMain)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 35,
                          height: isLast == null ? null : 27.5,
                        ),
                        SizedBox(
                          height: isLast == null ? null : 2,
                          child: VerticalDivider(
                            color: kDimGrey,
                            width: 0.4,
                            thickness: 1.5,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            height: 27.5,
                            width: 13.5,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(
                                  kDefaultPadding / 1.5,
                                ),
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: kDimGrey,
                                  width: 1.5,
                                ),
                                left: BorderSide(
                                  color: kDimGrey,
                                  width: 1.5,
                                ),
                                right: BorderSide(
                                  color: kDimGrey,
                                  width: 0.001,
                                ),
                                top: BorderSide(
                                  color: kDimGrey,
                                  width: 0.001,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  Expanded(
                    child: Padding(
                      padding: (isThread && !isMain)
                          ? const EdgeInsets.symmetric(
                              vertical: kDefaultPadding / 2,
                            )
                          : EdgeInsets.zero,
                      child: Row(
                        children: [
                          Column(
                            children: [
                              ProfilePicture2(
                                size: isThread && !isMain ? 30 : 35,
                                image: isMuted && !isHidden.value || !isMuted
                                    ? author.picture
                                    : '',
                                placeHolder: author.picturePlaceholder,
                                padding: 0,
                                strokeWidth: 1,
                                strokeColor: Theme.of(context).primaryColorDark,
                                onClicked: () {
                                  if (isMuted && !isHidden.value || !isMuted) {
                                    openProfileFastAccess(
                                      context: context,
                                      pubkey: author.pubKey,
                                    );
                                  }
                                },
                              ),
                              if (isThread && isMain)
                                Expanded(
                                  child: VerticalDivider(
                                    indent: 4,
                                    color: kDimGrey,
                                    width: 0.2,
                                    thickness: 1.5,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 2,
                          ),
                          Expanded(
                            child: Padding(
                              padding: (isThread && isMain)
                                  ? EdgeInsets.only(bottom: kDefaultPadding / 2)
                                  : EdgeInsets.zero,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'On ${dateFormat4.format(comment.createdAt)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall!
                                                  .copyWith(
                                                    color: kDimGrey,
                                                  ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  'By ',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall!
                                                      .copyWith(
                                                        color: Theme.of(context)
                                                            .primaryColorDark,
                                                      ),
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    isMuted &&
                                                                !isHidden
                                                                    .value ||
                                                            !isMuted
                                                        ? getAuthorName(author)
                                                        : 'Muted user',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                              : Colors
                                                                  .purpleAccent,
                                                        ),
                                                  ),
                                                ),
                                                BlocBuilder<AuthorsCubit,
                                                    AuthorsState>(
                                                  buildWhen:
                                                      (previous, current) {
                                                    final currentAuthor =
                                                        current.nip05Validations[
                                                            comment.pubKey];
                                                    final previousAuthor =
                                                        previous.nip05Validations[
                                                            comment.pubKey];

                                                    return currentAuthor !=
                                                        previousAuthor;
                                                  },
                                                  builder: (context, state) {
                                                    final isValid = state
                                                                    .nip05Validations[
                                                                comment
                                                                    .pubKey] !=
                                                            null &&
                                                        state.nip05Validations[
                                                            comment.pubKey]!;

                                                    if (isValid) {
                                                      return Row(
                                                        children: [
                                                          const SizedBox(
                                                            width:
                                                                kDefaultPadding /
                                                                    4,
                                                          ),
                                                          SvgPicture.asset(
                                                            FeatureIcons
                                                                .verified,
                                                            width: 15,
                                                            height: 15,
                                                            colorFilter:
                                                                ColorFilter
                                                                    .mode(
                                                              kOrangeContrasted,
                                                              BlendMode.srcIn,
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    } else {
                                                      return const SizedBox
                                                          .shrink();
                                                    }
                                                  },
                                                ),
                                                if (isAuthor) ...[
                                                  DotContainer(color: kDimGrey),
                                                  Text(
                                                    'Author',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall!
                                                        .copyWith(
                                                          color: kDimGrey,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isMuted)
                                        SmallIconButton(
                                          icon: isHidden.value
                                              ? FeatureIcons.visible
                                              : FeatureIcons.notVisible,
                                          onClicked: () {
                                            isHidden.value = !isHidden.value;
                                          },
                                        ),
                                      if (canBeDeleted)
                                        Row(
                                          children: [
                                            const SizedBox(
                                              width: kDefaultPadding / 2,
                                            ),
                                            SmallIconButton(
                                              icon: FeatureIcons.trash,
                                              onClicked: onDelete,
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: kDefaultPadding / 2,
                                  ),
                                  BlocBuilder<AuthorsCubit, AuthorsState>(
                                    builder: (context, mentionState) {
                                      return BlocBuilder<AuthorsCubit,
                                          AuthorsState>(
                                        buildWhen: (previous, current) {
                                          final currentAuthor =
                                              current.authors[author.pubKey];
                                          final previousAuthor =
                                              previous.authors[author.pubKey];

                                          return currentAuthor !=
                                              previousAuthor;
                                        },
                                        builder: (context, state) {
                                          if (isMuted && isHidden.value) {
                                            return Text(
                                              'Hidden comment.',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium!
                                                  .copyWith(
                                                    color: kRed,
                                                  ),
                                            );
                                          }

                                          return linkifiedText(
                                            context: context,
                                            text: getCommentWithoutPrefix(
                                              comment.content.trim(),
                                            ),
                                            onClicked: onClicked,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(
                                    height: kDefaultPadding / 2,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        onPressed: onClicked,
                                        icon: SvgPicture.asset(
                                          FeatureIcons.comments,
                                          colorFilter: ColorFilter.mode(
                                            Theme.of(context).primaryColorDark,
                                            BlendMode.srcIn,
                                          ),
                                          width: kDefaultPadding,
                                          height: kDefaultPadding,
                                        ),
                                        label: Text(
                                          '${count}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium,
                                        ),
                                        style: TextButton.styleFrom(
                                          backgroundColor: kTransparent,
                                          padding: EdgeInsets.symmetric(
                                            vertical: kDefaultPadding / 6,
                                          ),
                                          minimumSize: Size.zero,
                                          splashFactory: NoSplash.splashFactory,
                                        ),
                                      ),
                                      if (userStatus == UserStatus.UsingPrivKey)
                                        TextButton.icon(
                                          onPressed: () {
                                            if (userStatus ==
                                                UserStatus.UsingPrivKey)
                                              showModalBottomSheet(
                                                context: context,
                                                elevation: 0,
                                                builder: (_) {
                                                  return CommentBoxView(
                                                    commentId: comment.id,
                                                    commentPubkey:
                                                        comment.pubKey,
                                                    commentContent:
                                                        comment.content,
                                                    commentDate:
                                                        comment.createdAt,
                                                    shareableLink:
                                                        shareableLink,
                                                    kind: kind,
                                                    onAddComment: onAddComment,
                                                  );
                                                },
                                                isScrollControlled: true,
                                                useRootNavigator: true,
                                                useSafeArea: true,
                                                backgroundColor: Theme.of(
                                                        context)
                                                    .scaffoldBackgroundColor,
                                              );
                                          },
                                          label: SvgPicture.asset(
                                            FeatureIcons.reply,
                                            width: 17,
                                            height: 17,
                                            colorFilter: ColorFilter.mode(
                                              Theme.of(context)
                                                  .primaryColorDark,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          icon: Text(
                                            'Reply',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall!,
                                          ),
                                          style: TextButton.styleFrom(
                                            visualDensity:
                                                VisualDensity(vertical: -2),
                                            backgroundColor: Theme.of(context)
                                                .primaryColorLight,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (isThread && isLast == null) Divider()
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String getCommentWithoutPrefix(String comment) {
    return comment.split(' — This is a comment on: https').first.trim();
  }
}
