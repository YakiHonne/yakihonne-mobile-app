// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/videos_cubit/videos_cubit.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/share_view.dart';

class VerticalVideoContainer extends StatelessWidget {
  const VerticalVideoContainer({
    Key? key,
    required this.video,
    required this.onClicked,
  }) : super(key: key);

  final VideoModel video;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onClicked,
      child: Padding(
        key: ValueKey(video.videoId),
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 2,
        ),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 9 / 15,
              child: CachedNetworkImage(
                imageUrl: video.thumbnail,
                fit: BoxFit.cover,
                imageBuilder: (context, imageProvider) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        kDefaultPadding / 2,
                      ),
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        kDefaultPadding / 2,
                      ),
                      gradient: LinearGradient(
                        colors: [kBlack, kTransparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  );
                },
                errorWidget: (context, url, error) => Container(
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      kDefaultPadding,
                    ),
                    gradient: LinearGradient(
                      colors: [kBlack, kTransparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: NoThumbnailPlaceHolder(
                    isError: true,
                    icon: video.placeHolder,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BlocBuilder<AuthorsCubit, AuthorsState>(
                builder: (context, authorState) {
                  final author = authorState.authors[video.pubkey] ??
                      emptyUserModel.copyWith(
                        pubKey: video.pubkey,
                        picturePlaceholder: getRandomPlaceholder(
                          input: video.pubkey,
                          isPfp: true,
                        ),
                      );

                  return Padding(
                    padding: const EdgeInsets.all(kDefaultPadding / 2),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ProfilePicture2(
                              size: 25,
                              image: author.picture,
                              placeHolder: author.picturePlaceholder,
                              padding: 0,
                              strokeWidth: 0,
                              reduceSize: true,
                              strokeColor: kTransparent,
                              onClicked: () {
                                openProfileFastAccess(
                                  context: context,
                                  pubkey: author.pubKey,
                                );
                              },
                            ),
                            const Spacer(),
                            PullDownButton(
                              animationBuilder: (context, state, child) {
                                return child;
                              },
                              routeTheme: PullDownMenuRouteTheme(
                                backgroundColor:
                                    Theme.of(context).primaryColorLight,
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
                                            image: video.thumbnail,
                                            data: {
                                              'kind': EventKind.VIDEO_VERTICAL,
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
                                              if (ResponsiveBreakpoints.of(
                                                      context)
                                                  .largerThan(MOBILE)) {
                                                box = context.findRenderObject()
                                                    as RenderBox?;
                                              }

                                              context
                                                  .read<VideosCubit>()
                                                  .shareLink(box, video);
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
                                ];
                              },
                              buttonBuilder: (context, showMenu) => IconButton(
                                onPressed: showMenu,
                                style: IconButton.styleFrom(
                                  visualDensity: VisualDensity(
                                    horizontal: -2,
                                    vertical: -2,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  color: Theme.of(context).primaryColorDark,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                video.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(
                                height: kDefaultPadding / 8,
                              ),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      getAuthorName(author),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DotContainer(
                                    color: kDimGrey,
                                    size: 3,
                                  ),
                                  Text(
                                    '${StringUtil.formatTimeDifference(video.createdAt)}',
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: kDefaultPadding / 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
