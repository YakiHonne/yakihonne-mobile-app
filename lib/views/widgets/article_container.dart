// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/widgets/content_container.dart';
import 'package:yakihonne/views/widgets/share_view.dart';

class ArticleContainer extends HookWidget {
  ArticleContainer({
    required this.article,
    required this.isFollowing,
    required this.highlightedTag,
    required this.isProfileAccessible,
    required this.isBookmarked,
    required this.userStatus,
    required this.onClicked,
    this.isMuted,
    this.padding,
    this.margin,
  });

  final Article article;
  final bool isFollowing;
  final String highlightedTag;
  final bool isProfileAccessible;
  final bool isBookmarked;
  final UserStatus userStatus;
  final bool? isMuted;
  final double? padding;
  final double? margin;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      authorsCubit.getAuthor(article.pubkey);
    });

    return BlocBuilder<AuthorsCubit, AuthorsState>(
      builder: (context, state) {
        final author = state.authors[article.pubkey] ??
            emptyUserModel.copyWith(
              pubKey: article.pubkey,
              picture: article.image,
              picturePlaceholder: getRandomPlaceholder(
                input: article.pubkey,
                isPfp: true,
              ),
            );

        return ContentContainer(
          id: article.identifier,
          isSensitive: article.isSensitive,
          isFollowing: isFollowing,
          createdAt: article.createdAt,
          title: article.title,
          thumbnail: article.image,
          description: article.summary,
          tags: article.hashTags,
          isBookmarked: isBookmarked,
          hasImportantTag: false,
          author: author,
          contentType: ContentType.article,
          highlightedTag: highlightedTag,
          onClicked: onClicked,
          onProfileClicked: () {
            openProfileFastAccess(context: context, pubkey: article.pubkey);
          },
          onBookmark: () {
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
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          },
          onShare: () {
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
                  upvotes: 0,
                  downvotes: 0,
                  onShare: () {
                    RenderBox? box;
                    if (ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
                      box = context.findRenderObject() as RenderBox?;
                    }

                    shareLink(
                      renderBox: box,
                      pubkey: article.pubkey,
                      id: article.identifier,
                      kind: EventKind.LONG_FORM,
                    );
                  },
                );
              },
              isScrollControlled: true,
              useRootNavigator: true,
              useSafeArea: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          },
          isMuted: isMuted,
        );
      },
    );
  }
}

class PublishDateRow extends StatelessWidget {
  const PublishDateRow({
    Key? key,
    required this.publishedAtDate,
    required this.createdAtDate,
  }) : super(key: key);

  final DateTime publishedAtDate;
  final DateTime createdAtDate;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'created at ${dateFormat2.format(publishedAtDate)}, edited on ${dateFormat2.format(createdAtDate)}',
      textStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
      triggerMode: TooltipTriggerMode.tap,
      child: Text(
        '${dateFormat3.format(publishedAtDate)}',
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: Theme.of(context).primaryColorDark,
            ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
