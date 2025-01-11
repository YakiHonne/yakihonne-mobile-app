// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/buzz_feed_details_cubit/buzz_feed_details_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_source_view.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/threads_view/threads_view.dart';
import 'package:yakihonne/views/widgets/comment_box_view.dart';
import 'package:yakihonne/views/widgets/comment_main_container.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/share_view.dart';
import 'package:yakihonne/views/widgets/voters_view.dart';

class BuzzFeedDetails extends StatelessWidget {
  const BuzzFeedDetails({
    Key? key,
    required this.buzzFeedModel,
  }) : super(key: key);

  static const routeName = '/buzzFeedDetails';
  static Route route(RouteSettings settings) {
    final aiFeedModel = settings.arguments as BuzzFeedModel;

    return CupertinoPageRoute(
      builder: (_) => BuzzFeedDetails(
        buzzFeedModel: aiFeedModel,
      ),
    );
  }

  final BuzzFeedModel buzzFeedModel;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BuzzFeedDetailsCubit(buzzFeedModel: buzzFeedModel),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: kTextTabBarHeight + 20,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            centerTitle: false,
            stretchModes: [
              StretchMode.zoomBackground,
            ],
            background: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: buzzFeedModel.image,
                  imageBuilder: (context, imageProvider) {
                    return Container(
                      decoration: new BoxDecoration(
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.elliptical(
                            MediaQuery.of(context).size.width,
                            50.0,
                          ),
                        ),
                      ),
                    );
                  },
                  errorWidget: (context, url, error) => NoMediaPlaceHolder(
                    isError: true,
                    image: Images.invalidMedia,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomIconButton(
                          onClicked: () {
                            Navigator.pop(context);
                          },
                          icon: FeatureIcons.close,
                          size: 25,
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                        ),
                        CustomIconButton(
                          onClicked: () {
                            showModalBottomSheet(
                              elevation: 0,
                              context: context,
                              builder: (_) {
                                return ShareView(
                                  image: '',
                                  placeholder: '',
                                  data: {
                                    'kind': EventKind.TEXT_NOTE,
                                    'id': buzzFeedModel.id,
                                    'createdAt': buzzFeedModel.createdAt,
                                    'textContentType': TextContentType.buzzFeed,
                                    'source': buzzFeedModel.sourceName,
                                    'image': buzzFeedModel.image,
                                    'description': buzzFeedModel.description,
                                  },
                                  pubkey: buzzFeedModel.pubkey,
                                  title: buzzFeedModel.title,
                                  description: buzzFeedModel.description,
                                  kindText: 'Buzz feed',
                                  icon: FeatureIcons.buzzFeed,
                                  upvotes: 0,
                                  downvotes: 0,
                                  onShare: () {
                                    RenderBox? box;
                                    if (ResponsiveBreakpoints.of(context)
                                        .largerThan(MOBILE)) {
                                      box = context.findRenderObject()
                                          as RenderBox?;
                                    }

                                    shareLink(
                                      renderBox: box,
                                      pubkey: buzzFeedModel.pubkey,
                                      id: buzzFeedModel.id,
                                      kind: EventKind.TEXT_NOTE,
                                      textContentType: TextContentType.buzzFeed,
                                    );
                                  },
                                );
                              },
                              isScrollControlled: true,
                              useRootNavigator: true,
                              useSafeArea: true,
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                            );
                          },
                          icon: FeatureIcons.share,
                          size: 22,
                          backgroundColor: Theme.of(context).primaryColorLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
            vertical: kDefaultPadding,
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            BuzzFeedSourceView.routeName,
                            arguments: BuzzFeedSource(
                              name: buzzFeedModel.sourceName,
                              icon: buzzFeedModel.sourceIcon,
                              url: buzzFeedModel.sourceDomain,
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            ProfilePicture3(
                              size: 40,
                              image: buzzFeedModel.sourceIcon,
                              placeHolder: getRandomPlaceholder(
                                input: buzzFeedModel.sourceIcon,
                                isPfp: true,
                              ),
                              padding: 0,
                              strokeWidth: 0,
                              strokeColor: kTransparent,
                              onClicked: () {},
                            ),
                            const SizedBox(
                              width: kDefaultPadding / 2,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'On ${dateFormat3.format(buzzFeedModel.publishedAt)}',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                    textAlign: TextAlign.left,
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'By: ',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      Expanded(
                                        child: Text(
                                          buzzFeedModel.sourceName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge!
                                              .copyWith(
                                                color: kOrange,
                                              ),
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (getUserStatus() == UserStatus.UsingPrivKey) ...[
                      const SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      BlocBuilder<BuzzFeedDetailsCubit, BuzzFeedDetailsState>(
                        builder: (context, state) {
                          return TextButton(
                            onPressed: () {
                              NostrFunctionsRepository.setCustomTopics(
                                buzzFeedModel.sourceName,
                              );
                            },
                            child: Text(
                              state.isSubscribed ? 'unsubscribe' : 'subscribe',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                    color:
                                        state.isSubscribed ? kOrange : kGreen,
                                  ),
                            ),
                            style: TextButton.styleFrom(
                              visualDensity:
                                  VisualDensity(vertical: -4, horizontal: -4),
                              padding: EdgeInsets.zero,
                              backgroundColor: kTransparent,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: const SizedBox(
                  height: kDefaultPadding,
                ),
              ),
              SliverToBoxAdapter(
                child: Text(
                  buzzFeedModel.title.trim(),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              SliverToBoxAdapter(
                child: const SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ),
              if (buzzFeedModel.description.trim().isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Text(
                    buzzFeedModel.description.trim(),
                    style: Theme.of(context).textTheme.bodyMedium!,
                  ),
                ),
                SliverToBoxAdapter(
                  child: const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ),
              ],
              BlocBuilder<BuzzFeedDetailsCubit, BuzzFeedDetailsState>(
                builder: (context, state) {
                  return SliverToBoxAdapter(
                    child: Builder(
                      builder: (context) {
                        final calculatedVotes = getVotes(
                          votes: state.votes,
                          pubkey: getUserStatus() == UserStatus.UsingPrivKey
                              ? state.currentUserPubkey
                              : null,
                        );

                        return Row(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Row(
                                  children: [
                                    CustomIconButton(
                                      backgroundColor: kTransparent,
                                      icon: FeatureIcons.comments,
                                      onClicked: () {
                                        if (getUserStatus() ==
                                            UserStatus.UsingPrivKey)
                                          showModalBottomSheet(
                                            context: context,
                                            elevation: 0,
                                            builder: (_) {
                                              return CommentBoxView(
                                                commentId: '',
                                                commentPubkey:
                                                    buzzFeedModel.pubkey,
                                                commentContent:
                                                    buzzFeedModel.title,
                                                commentDate:
                                                    buzzFeedModel.createdAt,
                                                kind: EventKind.TEXT_NOTE,
                                                shareableLink:
                                                    createShareableLink(
                                                  EventKind.TEXT_NOTE,
                                                  buzzFeedModel.pubkey,
                                                  buzzFeedModel.id,
                                                ),
                                                onAddComment: (commentContent,
                                                    mentions, commentId) {
                                                  context
                                                      .read<
                                                          BuzzFeedDetailsCubit>()
                                                      .addComment(
                                                        content: commentContent,
                                                        replyCommentId:
                                                            commentId,
                                                        mentions: mentions,
                                                        onSuccess: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                      );
                                                },
                                              );
                                            },
                                            isScrollControlled: true,
                                            useRootNavigator: true,
                                            useSafeArea: true,
                                            backgroundColor: Theme.of(context)
                                                .scaffoldBackgroundColor,
                                          );
                                      },
                                      value: getCommentsCount(state.comments)
                                          .toString(),
                                      size: 22,
                                    ),
                                    const SizedBox(
                                      width: kDefaultPadding / 4,
                                    ),
                                    CustomIconButton(
                                      backgroundColor: kTransparent,
                                      onLongPress: () {
                                        showModalBottomSheet(
                                          context: context,
                                          elevation: 0,
                                          builder: (_) {
                                            final upvotes = state.votes.entries
                                                .where((element) =>
                                                    element.value.vote);

                                            return VotersView(
                                              voters: Map<String,
                                                  VoteModel>.fromEntries(
                                                upvotes,
                                              ),
                                              title: 'Upvoters',
                                            );
                                          },
                                          isScrollControlled: true,
                                          useRootNavigator: true,
                                          useSafeArea: true,
                                          backgroundColor: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                        );
                                      },
                                      icon: calculatedVotes[1]
                                          ? FeatureIcons.upvoteFilled
                                          : FeatureIcons.upvote,
                                      onClicked: () {
                                        context
                                            .read<BuzzFeedDetailsCubit>()
                                            .setVote(
                                              upvote: true,
                                              eventId: state.aiFeedModel.id,
                                              eventPubkey: buzzFeedModel.pubkey,
                                            );
                                      },
                                      value: calculatedVotes[0].toString(),
                                      size: 22,
                                    ),
                                    const SizedBox(
                                      width: kDefaultPadding / 4,
                                    ),
                                    CustomIconButton(
                                      backgroundColor: kTransparent,
                                      onLongPress: () {
                                        showModalBottomSheet(
                                          context: context,
                                          elevation: 0,
                                          builder: (_) {
                                            final downvotes = state
                                                .votes.entries
                                                .where((element) =>
                                                    !element.value.vote);

                                            return VotersView(
                                              voters: Map<String,
                                                  VoteModel>.fromEntries(
                                                downvotes,
                                              ),
                                              title: 'Downvoters',
                                            );
                                          },
                                          isScrollControlled: true,
                                          useRootNavigator: true,
                                          useSafeArea: true,
                                          backgroundColor: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                        );
                                      },
                                      icon: calculatedVotes[3]
                                          ? FeatureIcons.downvoteFilled
                                          : FeatureIcons.downvote,
                                      onClicked: () {
                                        context
                                            .read<BuzzFeedDetailsCubit>()
                                            .setVote(
                                              upvote: false,
                                              eventId: buzzFeedModel.id,
                                              eventPubkey: buzzFeedModel.pubkey,
                                            );
                                      },
                                      value: calculatedVotes[2].toString(),
                                      size: 22,
                                    ),
                                    Spacer(),
                                    if (buzzFeedModel.sourceDomain.isNotEmpty)
                                      CustomIconButton(
                                        backgroundColor:
                                            Theme.of(context).primaryColorLight,
                                        icon: FeatureIcons.globe,
                                        onClicked: () {
                                          openWebPage(
                                              url: buzzFeedModel.sourceDomain);
                                        },
                                        size: 22,
                                      ),
                                    if (getUserStatus() ==
                                        UserStatus.UsingPrivKey) ...[
                                      IconButton(
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            elevation: 0,
                                            builder: (_) {
                                              return AddBookmarkView(
                                                kind: EventKind.TEXT_NOTE,
                                                identifier: buzzFeedModel.id,
                                                eventPubkey:
                                                    buzzFeedModel.pubkey,
                                                image: buzzFeedModel.image,
                                              );
                                            },
                                            isScrollControlled: true,
                                            useRootNavigator: true,
                                            useSafeArea: true,
                                            backgroundColor: Theme.of(context)
                                                .scaffoldBackgroundColor,
                                          );
                                        },
                                        style: IconButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .primaryColorLight,
                                        ),
                                        icon:
                                            BlocBuilder<ThemeCubit, ThemeState>(
                                          builder: (context, themeState) {
                                            final isDark = themeState.theme ==
                                                AppTheme.purpleDark;

                                            return SvgPicture.asset(
                                              state.bookmarks.contains(
                                                      buzzFeedModel.id)
                                                  ? isDark
                                                      ? FeatureIcons
                                                          .bookmarkFilledWhite
                                                      : FeatureIcons
                                                          .bookmarkFilledBlack
                                                  : isDark
                                                      ? FeatureIcons
                                                          .bookmarkEmptyWhite
                                                      : FeatureIcons
                                                          .bookmarkEmptyBlack,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                    CustomIconButton(
                                      onClicked: () {
                                        openWebPage(
                                            url: buzzFeedModel.sourceUrl);
                                      },
                                      icon: FeatureIcons.shareExternal,
                                      size: 22,
                                      backgroundColor:
                                          Theme.of(context).primaryColorLight,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: kDefaultPadding / 2,
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: const Divider(
                  height: kDefaultPadding * 2,
                ),
              ),
              BlocBuilder<BuzzFeedDetailsCubit, BuzzFeedDetailsState>(
                builder: (context, state) {
                  if (state.comments.isEmpty ||
                      rootComments(comments: state.comments)) {
                    return SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No comments can be found',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                            textAlign: TextAlign.start,
                          ),
                          const SizedBox(
                            height: kDefaultPadding / 4,
                          ),
                          Text(
                            'Be the first to comment on this news !',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    );
                  } else {
                    return AiFeedMainComments(
                      comments: state.comments,
                      authorPubkey: '',
                      kind: EventKind.TEXT_NOTE,
                      shareableLink: createShareableLink(
                        EventKind.TEXT_NOTE,
                        state.aiFeedModel.pubkey,
                        state.aiFeedModel.id,
                      ),
                      onAddComment: (commentContent, mentions, commentId) {
                        context.read<BuzzFeedDetailsCubit>().addComment(
                              content: commentContent,
                              replyCommentId: commentId,
                              mentions: mentions,
                              onSuccess: () {
                                Navigator.pop(context);
                              },
                            );
                      },
                      onDeleteComment: (commentId) {
                        context
                            .read<BuzzFeedDetailsCubit>()
                            .deleteComment(commentId: commentId);
                      },
                      currentUserPubkey: state.currentUserPubkey,
                      userStatus: getUserStatus(),
                      mutes: state.mutes,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AiFeedMainComments extends StatelessWidget {
  const AiFeedMainComments({
    Key? key,
    required this.comments,
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
                        authorPubkey: '',
                        threadsType: ThreadsType.aiFeedDetails,
                        aiFeedDetailsCubit:
                            context.read<BuzzFeedDetailsCubit>(),
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
