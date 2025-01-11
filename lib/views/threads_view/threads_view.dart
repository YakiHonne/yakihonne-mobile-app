// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/article_cubit/article_cubit.dart';
import 'package:yakihonne/blocs/buzz_feed_details_cubit/buzz_feed_details_cubit.dart';
import 'package:yakihonne/blocs/curation_cubit/curation_cubit.dart';
import 'package:yakihonne/blocs/flash_news_details_cubit/flash_news_details_cubit.dart';
import 'package:yakihonne/blocs/horizontal_video_cubit/horizontal_video_cubit.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/comment_main_container.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';

class ThreadsView extends HookWidget {
  const ThreadsView({
    Key? key,
    required this.authorPubkey,
    required this.mainCommentId,
    required this.userStatus,
    required this.currentUserPubkey,
    required this.shareableLink,
    required this.mutes,
    required this.kind,
    required this.onAddComment,
    required this.onDeleteComment,
    required this.threadsType,
    this.articleCubit,
    this.curationCubit,
    this.flashNewsDetailsCubit,
    this.horizontalVideoCubit,
    this.aiFeedDetailsCubit,
  }) : super(key: key);

  final String authorPubkey;
  final String mainCommentId;
  final UserStatus userStatus;
  final String currentUserPubkey;
  final String shareableLink;
  final List<String> mutes;
  final int kind;
  final Function(String, List<String>, String) onAddComment;
  final Function(String) onDeleteComment;

  final ThreadsType threadsType;
  final ArticleCubit? articleCubit;
  final CurationCubit? curationCubit;
  final FlashNewsDetailsCubit? flashNewsDetailsCubit;
  final HorizontalVideoCubit? horizontalVideoCubit;
  final BuzzFeedDetailsCubit? aiFeedDetailsCubit;

  @override
  Widget build(BuildContext context) {
    final controller = useScrollController();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Threads',
      ),
      body: Stack(
        children: [
          threadsType == ThreadsType.flash
              ? BlocProvider.value(
                  value: flashNewsDetailsCubit!,
                  child:
                      BlocBuilder<FlashNewsDetailsCubit, FlashNewsDetailsState>(
                    builder: (context, state) {
                      return getComments(state.comments, controller);
                    },
                  ),
                )
              : threadsType == ThreadsType.article
                  ? BlocProvider.value(
                      value: articleCubit!,
                      child: BlocBuilder<ArticleCubit, ArticleState>(
                        builder: (context, state) {
                          return getComments(state.comments, controller);
                        },
                      ),
                    )
                  : threadsType == ThreadsType.horizontalVideo
                      ? BlocProvider.value(
                          value: horizontalVideoCubit!,
                          child: BlocBuilder<HorizontalVideoCubit,
                              HorizontalVideoState>(
                            builder: (context, state) {
                              return getComments(state.comments, controller);
                            },
                          ),
                        )
                      : threadsType == ThreadsType.curation
                          ? BlocProvider.value(
                              value: curationCubit!,
                              child: BlocBuilder<CurationCubit, CurationState>(
                                builder: (context, state) {
                                  return getComments(
                                      state.comments, controller);
                                },
                              ),
                            )
                          : BlocProvider.value(
                              value: aiFeedDetailsCubit!,
                              child: BlocBuilder<BuzzFeedDetailsCubit,
                                  BuzzFeedDetailsState>(
                                builder: (context, state) {
                                  return getComments(
                                    state.comments,
                                    controller,
                                  );
                                },
                              ),
                            ),
          ResetScrollButton(scrollController: controller),
        ],
      ),
    );
  }

  Builder getComments(List<Comment> comments, ScrollController controller) {
    return Builder(
      builder: (context) {
        if (mainCommentId.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: Scrollbar(
              controller: controller,
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  if (comments
                      .where((element) => element.isRoot)
                      .toList()
                      .isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyList(
                        description: 'No comments can be found on this thread',
                        icon: FeatureIcons.comments,
                      ),
                    )
                  else
                    SliverList.builder(
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
                              isThread: false,
                              userStatus: userStatus,
                              isAuthor: comment.pubKey == authorPubkey,
                              onClicked: () {
                                if (subComments.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => ThreadsView(
                                        authorPubkey: authorPubkey,
                                        mainCommentId: comment.id,
                                        threadsType: threadsType,
                                        articleCubit: articleCubit,
                                        curationCubit: curationCubit,
                                        horizontalVideoCubit:
                                            horizontalVideoCubit,
                                        flashNewsDetailsCubit:
                                            flashNewsDetailsCubit,
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
                              onAddComment: onAddComment,
                              isMain: false,
                              shareableLink: shareableLink,
                              isMuted: mutes.contains(comment.pubKey),
                              comment: comment,
                              count: subComments.length,
                              openLink: (link) => openWebPage(url: link),
                              canBeDeleted:
                                  comment.pubKey == currentUserPubkey &&
                                      userStatus == UserStatus.UsingPrivKey,
                              onDelete: () => onDeleteComment(comment.id),
                            ),
                          );
                        }
                      },
                      itemCount: comments.length,
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: kDefaultPadding,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          final comment =
              comments.firstWhere((element) => element.id == mainCommentId);

          final subComments = getSubComments(
            comments: comments,
            commentId: comment.id,
          );

          final subCommentsList = comments
              .where((element) =>
                  subComments.contains(element.id) &&
                  element.replyTo == comment.id)
              .toList();

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: kDefaultPadding,
                  ),
                ),
                SliverToBoxAdapter(
                  child: MainCommentContainer(
                    kind: kind,
                    onClicked: () {},
                    isThread: true,
                    userStatus: userStatus,
                    isAuthor: comment.pubKey == authorPubkey,
                    onAddComment: onAddComment,
                    isMain: true,
                    shareableLink: shareableLink,
                    isMuted: mutes.contains(comment.pubKey),
                    comment: comment,
                    count: subCommentsList.length,
                    openLink: (link) => openWebPage(url: link),
                    canBeDeleted: comment.pubKey == currentUserPubkey &&
                        userStatus == UserStatus.UsingPrivKey,
                    onDelete: () => onDeleteComment(comment.id),
                  ),
                ),
                SliverList.builder(
                  itemBuilder: (context, index) {
                    final subComment = subCommentsList[index];

                    final subSubComments = getSubComments(
                      comments: comments,
                      commentId: subComment.id,
                    );

                    return MainCommentContainer(
                      kind: kind,
                      isLast:
                          index == (subCommentsList.length - 1) ? true : null,
                      isAuthor: subComment.pubKey == authorPubkey,
                      userStatus: userStatus,
                      onClicked: () {
                        if (subSubComments.isNotEmpty) {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => ThreadsView(
                                authorPubkey: authorPubkey,
                                mainCommentId: subComment.id,
                                threadsType: threadsType,
                                articleCubit: articleCubit,
                                curationCubit: curationCubit,
                                horizontalVideoCubit: horizontalVideoCubit,
                                flashNewsDetailsCubit: flashNewsDetailsCubit,
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
                      onAddComment: onAddComment,
                      isThread: true,
                      isMain: false,
                      shareableLink: shareableLink,
                      isMuted: mutes.contains(subComment.pubKey),
                      comment: subComment,
                      count: subSubComments.length,
                      openLink: (link) => openWebPage(url: link),
                      canBeDeleted: subComment.pubKey == currentUserPubkey &&
                          userStatus == UserStatus.UsingPrivKey,
                      onDelete: () => onDeleteComment(subComment.id),
                    );
                  },
                  itemCount: subCommentsList.length,
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: kDefaultPadding,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
