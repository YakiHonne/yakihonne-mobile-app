// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_source_view.dart';
import 'package:yakihonne/views/widgets/content_container.dart';
import 'package:yakihonne/views/widgets/share_view.dart';

class BuzzFeedContainer extends StatelessWidget {
  const BuzzFeedContainer({
    Key? key,
    required this.onClicked,
    required this.isBookmarked,
    required this.onExternalShare,
    required this.buzzFeedModel,
  }) : super(key: key);

  final Function() onClicked;
  final bool isBookmarked;
  final Function() onExternalShare;
  final BuzzFeedModel buzzFeedModel;

  @override
  Widget build(BuildContext context) {
    final f = () => Navigator.pushNamed(
          context,
          BuzzFeedSourceView.routeName,
          arguments: BuzzFeedSource(
            name: buzzFeedModel.sourceName,
            icon: buzzFeedModel.sourceIcon,
            url: buzzFeedModel.sourceDomain,
          ),
        );

    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: ContentContainer(
        id: buzzFeedModel.id,
        isSensitive: false,
        isFollowing: false,
        createdAt: buzzFeedModel.createdAt,
        title: buzzFeedModel.title,
        thumbnail: buzzFeedModel.image,
        description: buzzFeedModel.description,
        tags: buzzFeedModel.tags,
        isBookmarked: isBookmarked,
        hasImportantTag: false,
        author: emptyUserModel.copyWith(
          name: buzzFeedModel.sourceName,
          picture: buzzFeedModel.sourceIcon,
          website: buzzFeedModel.sourceDomain,
        ),
        contentType: ContentType.buzzfeed,
        highlightedTag: '',
        onClicked: onClicked,
        onProfileClicked: f,
        onUncensoredNotes: () {
          openWebPage(url: buzzFeedModel.sourceUrl);
        },
        onBookmark: () {
          showModalBottomSheet(
            context: context,
            elevation: 0,
            builder: (_) {
              return AddBookmarkView(
                kind: EventKind.TEXT_NOTE,
                identifier: buzzFeedModel.id,
                eventPubkey: buzzFeedModel.pubkey,
                image: buzzFeedModel.image,
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
                  if (ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
                    box = context.findRenderObject() as RenderBox?;
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
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          );
        },
      ),
    );
  }
}
