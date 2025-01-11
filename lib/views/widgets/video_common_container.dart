// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/widgets/content_container.dart';
import 'package:yakihonne/views/widgets/share_view.dart';

class VideoCommonContainer extends HookWidget {
  const VideoCommonContainer({
    Key? key,
    required this.video,
    required this.onTap,
    this.isBookmarked,
    this.selectedTag,
    this.isMuted,
    this.isFollowing,
  }) : super(key: key);

  final VideoModel video;
  final Function() onTap;
  final bool? isFollowing;
  final bool? isBookmarked;
  final bool? isMuted;
  final String? selectedTag;

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      authorsCubit.getAuthor(video.pubkey);
    });

    return BlocBuilder<AuthorsCubit, AuthorsState>(
      builder: (context, authorState) {
        final author = authorState.authors[video.pubkey] ??
            emptyUserModel.copyWith(
              pubKey: video.pubkey,
              picturePlaceholder: getRandomPlaceholder(
                input: video.pubkey,
                isPfp: true,
              ),
            );

        return FadeIn(
          duration: const Duration(milliseconds: 300),
          child: ContentContainer(
            id: video.identifier,
            duration: video.duration.toInt(),
            isSensitive: false,
            isFollowing: isFollowing ?? false,
            createdAt: video.createdAt,
            title: video.title,
            thumbnail: video.thumbnail,
            description: video.summary,
            tags: video.tags,
            isBookmarked: isBookmarked ?? false,
            hasImportantTag: false,
            author: author,
            contentType: ContentType.video,
            highlightedTag: selectedTag ?? '',
            onClicked: onTap,
            onProfileClicked: () {
              openProfileFastAccess(context: context, pubkey: video.pubkey);
            },
            onBookmark: () {
              showModalBottomSheet(
                context: context,
                elevation: 0,
                builder: (_) {
                  return AddBookmarkView(
                    kind: video.kind,
                    identifier: video.identifier,
                    eventPubkey: video.pubkey,
                    image: video.thumbnail.isNotEmpty ? video.thumbnail : '',
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
                    image: video.thumbnail,
                    data: {
                      'kind': EventKind.VIDEO_HORIZONTAL,
                      'id': video.identifier,
                    },
                    placeholder: video.placeHolder,
                    pubkey: video.pubkey,
                    title: video.title,
                    description: video.summary,
                    kindText: 'Video',
                    icon: FeatureIcons.curations,
                    upvotes: 0,
                    downvotes: 0,
                    views: 0,
                    onShare: () {
                      RenderBox? box;
                      if (ResponsiveBreakpoints.of(context)
                          .largerThan(MOBILE)) {
                        box = context.findRenderObject() as RenderBox?;
                      }

                      shareLink(
                          renderBox: box,
                          pubkey: video.pubkey,
                          id: video.identifier,
                          kind: video.kind);
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
          ),
        );
      },
    );
  }
}
