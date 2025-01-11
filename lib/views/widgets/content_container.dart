// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/tag_view/tag_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/muted_mark.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/tooltip_with_text.dart';

class ContentContainer extends HookWidget {
  final bool isSensitive;
  final bool isFollowing;
  final bool isBookmarked;
  final DateTime createdAt;
  final String title;
  final String description;
  final String thumbnail;
  final List<String> tags;
  final bool hasImportantTag;
  final UserModel author;
  final ContentType contentType;
  final String highlightedTag;
  final String id;

  final Function() onClicked;
  final Function() onProfileClicked;
  final Function() onBookmark;
  final Function() onShare;
  final Function()? onUncensoredNotes;
  final bool? isMuted;
  final int? duration;

  ContentContainer({
    required this.isSensitive,
    required this.isFollowing,
    required this.isBookmarked,
    required this.createdAt,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.tags,
    required this.hasImportantTag,
    required this.author,
    required this.contentType,
    required this.highlightedTag,
    required this.id,
    required this.onClicked,
    required this.onProfileClicked,
    required this.onBookmark,
    required this.onShare,
    this.onUncensoredNotes,
    this.isMuted,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final displaySensitiveContent = useState(false);

    Widget main = Container(
      width: double.infinity,
      padding: EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfilePicture2(
                size: 30,
                image: author.picture,
                placeHolder: author.picturePlaceholder,
                padding: 0,
                strokeWidth: 0,
                strokeColor: kTransparent,
                onClicked: onProfileClicked,
              ),
              const SizedBox(
                width: kDefaultPadding / 3,
              ),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contentType == ContentType.buzzfeed
                                ? author.name
                                : getAuthorDisplayName(author),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  color: Theme.of(context).primaryColorDark,
                                  fontWeight: FontWeight.w700,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          contentType == ContentType.buzzfeed
                              ? GestureDetector(
                                  onTap: () => openWebPage(url: author.website),
                                  child: Text(
                                    author.website.split('https://').last,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(
                                          color: kDimGrey,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : BlocBuilder<AuthorsCubit, AuthorsState>(
                                  builder: (context, state) {
                                    final isNip05 =
                                        state.nip05Validations[author.pubKey] ??
                                            false;

                                    return Text(
                                      '@${getAuthorName(author)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall!
                                          .copyWith(
                                              color: isNip05 ? kRed : kDimGrey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                    if (isFollowing) ...[
                      const SizedBox(width: kDefaultPadding / 4),
                      TooltipWithText(
                        message: 'following',
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: kDimGrey.withValues(alpha: 0.5),
                              width: 0.2,
                            ),
                          ),
                          child: SvgPicture.asset(
                            FeatureIcons.userFollowed,
                            width: 17,
                            height: 17,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).primaryColorDark,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isMuted != null && isMuted!) ...[
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                MutedMark(
                  kind: getRawContentName(),
                ),
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
              ],
              Text(
                dateFormat4.format(createdAt),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall!
                    .copyWith(color: kDimGrey),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Builder(
                  builder: (context) {
                    final t = title.trim();
                    final d = description.trim();
                    final kind = getRawContentName();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            return Text(
                              t.isEmpty ? 'This $kind has no title' : t,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge!
                                  .copyWith(
                                    fontWeight:
                                        contentType == ContentType.flashNews
                                            ? FontWeight.w500
                                            : FontWeight.w800,
                                  ),
                              overflow: TextOverflow.ellipsis,
                              maxLines:
                                  contentType == ContentType.flashNews ? 4 : 2,
                            );
                          },
                        ),
                        if (contentType != ContentType.flashNews) ...[
                          const SizedBox(
                            height: kDefaultPadding / 4,
                          ),
                          Text(
                            d.isEmpty ? 'This ${kind} has no description.' : d,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: kDimGrey,
                                  fontStyle: d.isEmpty
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              if (contentType != ContentType.flashNews) ...[
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Flexible(
                  flex: 4,
                  child: AspectRatio(
                    aspectRatio: 16 / 9.5,
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: thumbnail,
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
                            );
                          },
                          errorWidget: (context, url, error) =>
                              NoMediaPlaceHolder(
                            isRound: true,
                            image: getRandomPlaceholder(
                              input: id,
                              isPfp: false,
                            ),
                            isError: true,
                            value: kDefaultPadding / 2,
                          ),
                        ),
                        if (contentType == ContentType.video)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(
                                kDefaultPadding / 3,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kBlack.withValues(alpha: 0.7),
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: kWhite,
                              ),
                            ),
                          ),
                        if (duration != null)
                          Positioned(
                            bottom: kDefaultPadding / 8,
                            right: kDefaultPadding / 8,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(300),
                                color: kBlack.withValues(alpha: 0.7),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: kDefaultPadding / 3,
                                vertical: kDefaultPadding / 6,
                              ),
                              child: Text(
                                formattedTime(timeInSecond: duration!),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                      color: kWhite,
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Row(
            children: [
              TooltipWithText(
                message: getRawContentName().capitalize(),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kDimGrey.withValues(alpha: 0.5),
                      width: 0.2,
                    ),
                  ),
                  child: SvgPicture.asset(
                    getContentIcon(),
                    width: 17,
                    height: 17,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColorDark,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              if (hasImportantTag) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(300),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        FeatureIcons.flame,
                        height: 16,
                        fit: BoxFit.fitHeight,
                        colorFilter: ColorFilter.mode(
                          kWhite,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                      Text(
                        'Important',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: kWhite,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
              ],
              if (tags.isNotEmpty && contentType != ContentType.buzzfeed) ...[
                Expanded(
                  child: SizedBox(
                    height: 24,
                    child: ScrollShadow(
                      color: Theme.of(context).primaryColorLight,
                      size: 10,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: tags.length,
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        separatorBuilder: (context, index) {
                          return const SizedBox(
                            width: kDefaultPadding / 4,
                          );
                        },
                        itemBuilder: (context, index) {
                          final tag = tags[index];
                          if (tag.trim().isEmpty) {
                            return SizedBox.shrink();
                          }

                          return Center(
                            child: InfoRoundedContainer(
                              tag: tag,
                              color: tag == highlightedTag
                                  ? kPurple
                                  : Theme.of(context).highlightColor,
                              textColor: tag == highlightedTag
                                  ? kWhite
                                  : Theme.of(context).primaryColorDark,
                              onClicked: () {
                                if (highlightedTag != tag) {
                                  Navigator.pushNamed(
                                    context,
                                    TagView.routeName,
                                    arguments: tag,
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ] else
                Expanded(
                  child: SizedBox.shrink(),
                ),
              PullDownButton(
                animationBuilder: (context, state, child) {
                  return child;
                },
                routeTheme: PullDownMenuRouteTheme(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                itemBuilder: (context) {
                  final textStyle = Theme.of(context).textTheme.labelMedium;
                  final kind = getRawContentName();

                  return [
                    if (contentType == ContentType.buzzfeed)
                      PullDownMenuItem(
                        title: 'Go to source',
                        onTap: onUncensoredNotes,
                        itemTheme: PullDownMenuItemTheme(
                          textStyle: textStyle,
                        ),
                        iconWidget: SvgPicture.asset(
                          FeatureIcons.shareExternal,
                          height: 20,
                          width: 20,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColorDark,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    if (contentType == ContentType.flashNews)
                      PullDownMenuItem(
                        title: 'See all uncensored notes',
                        onTap: onUncensoredNotes,
                        itemTheme: PullDownMenuItemTheme(
                          textStyle: textStyle,
                        ),
                        iconWidget: SvgPicture.asset(
                          FeatureIcons.uncensoredNote,
                          height: 20,
                          width: 20,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColorDark,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    if (isUsingPrivatekey())
                      PullDownMenuItem(
                        title: 'Bookmark $kind',
                        onTap: onBookmark,
                        itemTheme: PullDownMenuItemTheme(
                          textStyle: textStyle,
                        ),
                        iconWidget: BlocBuilder<ThemeCubit, ThemeState>(
                          builder: (context, themeState) {
                            final isDark =
                                themeState.theme == AppTheme.purpleDark;

                            return SvgPicture.asset(
                              isBookmarked
                                  ? isDark
                                      ? FeatureIcons.bookmarkFilledWhite
                                      : FeatureIcons.bookmarkFilledBlack
                                  : isDark
                                      ? FeatureIcons.bookmarkEmptyWhite
                                      : FeatureIcons.bookmarkEmptyBlack,
                            );
                          },
                        ),
                      ),
                    PullDownMenuItem(
                      title: 'Share $kind',
                      onTap: onShare,
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
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColorLight,
                    visualDensity: VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
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
        ],
      ),
    );

    return GestureDetector(
      onTap: !isSensitive || displaySensitiveContent.value ? onClicked : null,
      behavior: HitTestBehavior.translucent,
      child: FadeIn(
        duration: const Duration(milliseconds: 300),
        child: Stack(
          children: [
            AbsorbPointer(
              absorbing: isSensitive && !displaySensitiveContent.value,
              child: main,
            ),
            if (isSensitive && !displaySensitiveContent.value)
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(kDefaultPadding / 2),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kDefaultPadding),
                      border: Border.all(
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(kDefaultPadding),
                      child: Container(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 5,
                            sigmaY: 5,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(kDefaultPadding),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'This is a sensitive content, do you wish to reveal it?',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(
                                    height: kDefaultPadding / 2,
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      displaySensitiveContent.value = true;
                                    },
                                    child: Text('Reveal'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String getContentIcon() {
    if (contentType == ContentType.article) {
      return FeatureIcons.selfArticles;
    } else if (contentType == ContentType.flashNews) {
      return FeatureIcons.flashNews;
    } else if (contentType == ContentType.curation) {
      return FeatureIcons.curations;
    } else if (contentType == ContentType.video) {
      return FeatureIcons.videoOcta;
    } else if (contentType == ContentType.buzzfeed) {
      return FeatureIcons.buzzFeed;
    } else {
      return FeatureIcons.note;
    }
  }

  String getContentName() {
    if (contentType == ContentType.article) {
      return 'an article.';
    } else if (contentType == ContentType.flashNews) {
      return 'a flash news.';
    } else if (contentType == ContentType.curation) {
      return 'a curation.';
    } else if (contentType == ContentType.video) {
      return 'a video.';
    } else if (contentType == ContentType.buzzfeed) {
      return 'a buzzfeed.';
    } else {
      return 'a note.';
    }
  }

  String getRawContentName() {
    if (contentType == ContentType.article) {
      return 'article';
    } else if (contentType == ContentType.flashNews) {
      return 'flash news';
    } else if (contentType == ContentType.curation) {
      return 'curation';
    } else if (contentType == ContentType.video) {
      return 'video';
    } else if (contentType == ContentType.buzzfeed) {
      return 'buzzfeed';
    } else {
      return 'note';
    }
  }
}
