// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/app_clients_cubit/app_clients_cubit.dart';
import 'package:yakihonne/blocs/article_cubit/article_cubit.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/article_view/widgets/article_curations_add.dart';
import 'package:yakihonne/views/article_view/widgets/article_report.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/threads_view/threads_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/comment_box_view.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/share_view.dart';
import 'package:yakihonne/views/widgets/voters_view.dart';
import 'package:yakihonne/views/widgets/zappers_view.dart';
import 'package:yakihonne/views/zap_view/set_zaps_view.dart';

import '../../../nostr/nips/nips.dart';

class ArticleHeader extends StatelessWidget {
  const ArticleHeader({
    Key? key,
    required this.article,
  }) : super(key: key);

  final Article article;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<ArticleCubit, ArticleState>(
          builder: (context, state) {
            final isTablet =
                ResponsiveBreakpoints.of(context).largerThan(MOBILE);

            return Column(
              children: [
                Row(
                  children: [
                    AbsorbPointer(
                      absorbing: state.userStatus != UserStatus.UsingPrivKey,
                      child: Row(
                        children: [
                          BlocBuilder<ArticleCubit, ArticleState>(
                            builder: (context, state) {
                              return NewBorderedIconButton(
                                onClicked: () {
                                  context
                                      .read<ArticleCubit>()
                                      .setFollowingState();
                                },
                                icon: state.isFollowingAuthor
                                    ? FeatureIcons.userFollowed
                                    : FeatureIcons.userToFollow,
                                buttonStatus: state.userStatus !=
                                            UserStatus.UsingPrivKey ||
                                        state.isSameArticleAuthor
                                    ? ButtonStatus.disabled
                                    : state.isFollowingAuthor
                                        ? ButtonStatus.active
                                        : ButtonStatus.inactive,
                              );
                            },
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 4,
                          ),
                          NewBorderedIconButton(
                            onClicked: () {
                              showModalBottomSheet(
                                elevation: 0,
                                context: context,
                                builder: (_) {
                                  return SetZapsView(
                                    author: state.author,
                                    isZapSplit: article.zapsSplits.isNotEmpty,
                                    zapSplits: article.zapsSplits,
                                    aTag:
                                        '${EventKind.LONG_FORM}:${article.pubkey}:${article.identifier}',
                                  );
                                },
                                isScrollControlled: true,
                                useRootNavigator: true,
                                useSafeArea: true,
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                              );
                            },
                            icon: FeatureIcons.zaps,
                            buttonStatus: !state.canBeZapped
                                ? ButtonStatus.disabled
                                : ButtonStatus.inactive,
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    if (state.userStatus == UserStatus.UsingPrivKey)
                      BlocBuilder<ArticleCubit, ArticleState>(
                        buildWhen: (previous, current) =>
                            previous.isBookmarked != current.isBookmarked,
                        builder: (context, state) {
                          return IconButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                elevation: 0,
                                builder: (_) {
                                  return AddBookmarkView(
                                    kind: EventKind.LONG_FORM,
                                    identifier: article.identifier,
                                    eventPubkey: article.pubkey,
                                    image: article.image,
                                  );
                                },
                                isScrollControlled: true,
                                useRootNavigator: true,
                                useSafeArea: true,
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                              );
                            },
                            icon: BlocBuilder<ThemeCubit, ThemeState>(
                              builder: (context, themeState) {
                                final isDark =
                                    themeState.theme == AppTheme.purpleDark;

                                return SvgPicture.asset(
                                  state.isBookmarked
                                      ? isDark
                                          ? FeatureIcons.bookmarkFilledWhite
                                          : FeatureIcons.bookmarkFilledBlack
                                      : isDark
                                          ? FeatureIcons.bookmarkEmptyWhite
                                          : FeatureIcons.bookmarkEmptyBlack,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    if (state.userStatus == UserStatus.UsingPrivKey)
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            elevation: 0,
                            builder: (_) {
                              return AddItemToCurationView(
                                articleId: state.article.identifier,
                                articlePubkey: state.article.pubkey,
                                kind: EventKind.CURATION_ARTICLES,
                              );
                            },
                            isScrollControlled: true,
                            useRootNavigator: true,
                            useSafeArea: true,
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                          );
                        },
                        icon: SvgPicture.asset(
                          FeatureIcons.addCuration,
                          width: 25,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColorDark,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    PullDownButton(
                      animationBuilder: (context, state, child) {
                        return child;
                      },
                      routeTheme: PullDownMenuRouteTheme(
                        backgroundColor: Theme.of(context).primaryColorLight,
                      ),
                      itemBuilder: (context) {
                        final textStyle =
                            Theme.of(context).textTheme.labelMedium;

                        return [
                          PullDownMenuItem(
                            title: 'Share',
                            onTap: () {
                              showModalBottomSheet(
                                elevation: 0,
                                context: context,
                                builder: (_) {
                                  return ShareView(
                                    image: article.image,
                                    placeholder: article.placeholder,
                                    pubkey: article.pubkey,
                                    title: article.title,
                                    description: article.summary,
                                    kindText: 'Article',
                                    icon: FeatureIcons.selfArticles,
                                    data: {
                                      'kind': EventKind.LONG_FORM,
                                      'id': article.identifier,
                                    },
                                    upvotes: state.votes.values
                                        .where((element) => element.vote)
                                        .toList()
                                        .length,
                                    downvotes: state.votes.values
                                        .where((element) => !element.vote)
                                        .toList()
                                        .length,
                                    onShare: () {
                                      RenderBox? box;
                                      if (ResponsiveBreakpoints.of(context)
                                          .largerThan(MOBILE)) {
                                        box = context.findRenderObject()
                                            as RenderBox?;
                                      }

                                      context
                                          .read<ArticleCubit>()
                                          .shareLink(box);
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
                            itemTheme: PullDownMenuItemTheme(
                              textStyle: textStyle,
                            ),
                            iconWidget: SvgPicture.asset(
                              FeatureIcons.share,
                              height: 20,
                              width: 20,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          PullDownMenuItem(
                            title: 'Report',
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                elevation: 0,
                                builder: (_) {
                                  return BlocProvider.value(
                                    value: context.read<ArticleCubit>(),
                                    child: ArticleReports(
                                      title: article.title,
                                      isArticle: true,
                                      onReport: (reason, comment) {
                                        context.read<ArticleCubit>().report(
                                              reason: reason,
                                              comment: comment,
                                              onSuccess: () {
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
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                              );
                            },
                            itemTheme: PullDownMenuItemTheme(
                              textStyle: textStyle,
                            ),
                            iconWidget: SvgPicture.asset(
                              FeatureIcons.report,
                              height: 20,
                              width: 20,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ];
                      },
                      buttonBuilder: (context, showMenu) => IconButton(
                        onPressed: showMenu,
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          visualDensity: VisualDensity(
                            horizontal: -4,
                            vertical: -1,
                          ),
                        ),
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: Theme.of(context).primaryColorDark,
                          size: 25,
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
                    BlocBuilder<ArticleCubit, ArticleState>(
                      builder: (context, state) {
                        final isTablet = ResponsiveBreakpoints.of(context)
                            .largerThan(MOBILE);

                        return ProfilePicture2(
                          size: isTablet ? 80 : 55,
                          image: state.author.picture,
                          placeHolder: state.author.picturePlaceholder,
                          padding: 1,
                          strokeWidth: 2,
                          strokeColor: Theme.of(context).primaryColor,
                          onClicked: () {
                            openProfileFastAccess(
                              context: context,
                              pubkey: state.author.pubKey,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BlocBuilder<ArticleCubit, ArticleState>(
                            builder: (context, state) {
                              return Row(
                                children: [
                                  Text(
                                    'By ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium!
                                        .copyWith(
                                          color: Theme.of(context)
                                              .primaryColorDark,
                                        ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            state.author.name.trim().isEmpty
                                                ? Nip19.encodePubkey(
                                                    state.author.pubKey,
                                                  ).nineCharacters()
                                                : state.author.name.trim(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium!
                                                .copyWith(
                                                  color: kOrangeContrasted,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        BlocBuilder<AuthorsCubit, AuthorsState>(
                                          buildWhen: (previous, current) {
                                            final currentAuthor =
                                                current.nip05Validations[
                                                    article.pubkey];
                                            final previousAuthor =
                                                previous.nip05Validations[
                                                    article.pubkey];

                                            return currentAuthor !=
                                                previousAuthor;
                                          },
                                          builder: (context, state) {
                                            final isValid =
                                                state.nip05Validations[
                                                            article.pubkey] !=
                                                        null &&
                                                    state.nip05Validations[
                                                        article.pubkey]!;

                                            if (isValid) {
                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const SizedBox(
                                                    width: kDefaultPadding / 4,
                                                  ),
                                                  SvgPicture.asset(
                                                    FeatureIcons.verified,
                                                    width: 15,
                                                    height: 15,
                                                    colorFilter:
                                                        ColorFilter.mode(
                                                      kOrangeContrasted,
                                                      BlendMode.srcIn,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            } else {
                                              return const SizedBox.shrink();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    width: kDefaultPadding / 4,
                                  ),
                                  PubKeyContainer(
                                    pubKey: state.article.pubkey,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(
                            height: kDefaultPadding / 4,
                          ),
                          Row(
                            children: [
                              Text(
                                '${dateFormat6.format(
                                  article.publishedAt,
                                )}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                      color: Theme.of(context).primaryColorDark,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Tooltip(
                                message:
                                    'created at ${dateFormat2.format(article.publishedAt)}, edited on ${dateFormat2.format(article.createdAt)}',
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                triggerMode: TooltipTriggerMode.tap,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: kDefaultPadding / 4,
                                  ),
                                  child: SvgPicture.asset(
                                    FeatureIcons.article,
                                    width: 20,
                                    height: 20,
                                    colorFilter: ColorFilter.mode(
                                      Theme.of(context).primaryColorDark,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                '${dateFormat2.format(
                                  article.createdAt,
                                )}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                      color: Theme.of(context).primaryColorDark,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: kDefaultPadding / 4,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: BlocBuilder<AppClientsCubit,
                                    AppClientsState>(
                                  builder: (context, appClientsState) {
                                    if (article.client.isEmpty ||
                                        !article.client.contains(EventKind
                                            .APPLICATION_INFO
                                            .toString())) {
                                      return RichText(
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Posted from ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium!
                                                  .copyWith(
                                                    color: Theme.of(context)
                                                        .primaryColorDark,
                                                  ),
                                            ),
                                            TextSpan(
                                              text: article.client.isEmpty
                                                  ? 'N/A'
                                                  : article.client,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium!
                                                  .copyWith(
                                                    color: kOrangeContrasted,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      final appApplication =
                                          appClientsState.appClients[context
                                              .read<ArticleCubit>()
                                              .identifier];

                                      return RichText(
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Posted from ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium!
                                                  .copyWith(
                                                    color: Theme.of(context)
                                                        .primaryColorDark,
                                                  ),
                                            ),
                                            TextSpan(
                                              text: appApplication == null
                                                  ? 'N/A'
                                                  : appApplication.name
                                                      .trim()
                                                      .capitalize(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium!
                                                  .copyWith(
                                                    color: kOrange,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              if (isTablet) Expanded(child: StatContainer()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: kDefaultPadding,
                ),
                if (!isTablet) ...[
                  StatContainer(),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class StatContainer extends StatelessWidget {
  const StatContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArticleCubit, ArticleState>(
      builder: (context, state) {
        final calculatedVotes = getVotes(
          votes: state.votes,
          pubkey: state.userStatus == UserStatus.UsingPrivKey
              ? state.currentUserPubkey
              : null,
        );

        final zaps =
            state.zaps.isEmpty ? 0 : state.zaps.values.reduce((a, b) => a + b);

        return Row(
          children: [
            Expanded(
              child: CustomIconButton(
                backgroundColor: kTransparent,
                icon: FeatureIcons.zap,
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    elevation: 0,
                    builder: (_) {
                      return ZappersView(
                        zappers: state.zaps,
                      );
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
                onClicked: () {},
                value: zaps.toStringAsFixed(0),
                size: 22,
              ),
            ),
            Expanded(
              child: CustomIconButton(
                backgroundColor: kTransparent,
                icon: FeatureIcons.comments,
                onClicked: () {
                  if (state.userStatus == UserStatus.UsingPrivKey)
                    showModalBottomSheet(
                      context: context,
                      elevation: 0,
                      builder: (_) {
                        return CommentBoxView(
                          commentId: '',
                          commentPubkey: state.article.pubkey,
                          commentContent: state.article.title,
                          commentDate: state.article.createdAt,
                          kind: EventKind.LONG_FORM,
                          shareableLink: createShareableLink(
                            EventKind.LONG_FORM,
                            state.article.pubkey,
                            state.article.identifier,
                          ),
                          onAddComment: (commentContent, mentions, commentId) {
                            context.read<ArticleCubit>().addComment(
                                  content: commentContent,
                                  replyCommentId: commentId,
                                  mentions: mentions,
                                  onSuccess: () {
                                    Navigator.pop(context);
                                  },
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
                onLongPress: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => ThreadsView(
                        mainCommentId: '',
                        authorPubkey: state.article.pubkey,
                        threadsType: ThreadsType.article,
                        articleCubit: context.read<ArticleCubit>(),
                        userStatus: state.userStatus,
                        currentUserPubkey: state.currentUserPubkey,
                        shareableLink: createShareableLink(
                          EventKind.LONG_FORM,
                          state.article.pubkey,
                          state.article.identifier,
                        ),
                        mutes: state.mutes,
                        kind: EventKind.LONG_FORM,
                        onAddComment: (commentContent, mentions, commentId) {
                          context.read<ArticleCubit>().addComment(
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
                              .read<ArticleCubit>()
                              .deleteComment(commentId: commentId);
                        },
                      ),
                    ),
                  );
                },
                value: getCommentsCount(state.comments).toString(),
                size: 22,
              ),
            ),
            Expanded(
              child: CustomIconButton(
                backgroundColor: kTransparent,
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    elevation: 0,
                    builder: (_) {
                      final upvotes = state.votes.entries
                          .where((element) => element.value.vote);

                      return VotersView(
                        voters: Map<String, VoteModel>.fromEntries(
                          upvotes,
                        ),
                        title: 'Upvoters',
                      );
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
                icon: calculatedVotes[1]
                    ? FeatureIcons.upvoteFilled
                    : FeatureIcons.upvote,
                onClicked: () {
                  context.read<ArticleCubit>().setVote(
                        upvote: true,
                        eventId: state.article.articleId,
                        eventPubkey: state.article.pubkey,
                      );
                },
                value: calculatedVotes[0].toString(),
                size: 22,
              ),
            ),
            Expanded(
              child: CustomIconButton(
                backgroundColor: kTransparent,
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    elevation: 0,
                    builder: (_) {
                      final downvotes = state.votes.entries
                          .where((element) => !element.value.vote);

                      return VotersView(
                        voters: Map<String, VoteModel>.fromEntries(
                          downvotes,
                        ),
                        title: 'Downvoters',
                      );
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
                icon: calculatedVotes[3]
                    ? FeatureIcons.downvoteFilled
                    : FeatureIcons.downvote,
                onClicked: () {
                  context.read<ArticleCubit>().setVote(
                        upvote: false,
                        eventId: state.article.articleId,
                        eventPubkey: state.article.pubkey,
                      );
                },
                value: calculatedVotes[2].toString(),
                size: 22,
              ),
            ),
            Expanded(
              child: CustomIconButton(
                backgroundColor: kTransparent,
                onLongPress: () {},
                icon: FeatureIcons.report,
                onClicked: () {},
                value: state.reports.length.toString(),
                size: 22,
              ),
            ),
          ],
        );
      },
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
