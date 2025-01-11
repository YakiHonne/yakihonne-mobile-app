// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/home_cubit/home_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nips/nips.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/flash_news_details_view/flash_news_details_view.dart';
import 'package:yakihonne/views/tag_view/tag_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/muted_mark.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class FlashNewsPageView extends HookWidget {
  const FlashNewsPageView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    final pageController =
        usePageController(viewportFraction: isTablet ? 1 / 2 : 0.90);

    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) =>
          previous.flashNews != current.flashNews ||
          previous.isFlashNewsLoading != current.isFlashNewsLoading ||
          previous.userStatus != current.userStatus ||
          previous.bookmarks != current.bookmarks ||
          previous.mutes != current.mutes,
      builder: (context, state) {
        return getHeader(
          context,
          state,
          isTablet,
          pageController,
        );
      },
    );
  }

  Widget getHeader(
    BuildContext context,
    HomeState state,
    bool isTablet,
    PageController pageController,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 2,
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      height: 95,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
      ),
      child: state.isFlashNewsLoading
          ? SpinKitThreeBounce(
              color: Theme.of(context).primaryColorDark,
              size: 20,
            )
          : state.flashNews.isEmpty
              ? Center(
                  child: Text(
                    'No flash news can be found',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                )
              : Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 2.5,
                      ),
                      child: DottedBorder(
                        padding: EdgeInsets.zero,
                        child: SizedBox(
                          height: 75,
                          width: 0,
                        ),
                        strokeWidth: 0.7,
                        color: kDimGrey,
                      ),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CarouselSlider.builder(
                          itemCount: state.flashNews.length,
                          itemBuilder: (context, index, realIndex) {
                            final mainFlashNews = state.flashNews[index];

                            return GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                FlashNewsDetailsView.routeName,
                                arguments: [
                                  mainFlashNews,
                                  false,
                                ],
                              ),
                              child: Row(
                                children: [
                                  DotContainer(
                                    color: kOrange,
                                    isNotMarging: true,
                                  ),
                                  const SizedBox(
                                    width: kDefaultPadding / 4,
                                  ),
                                  SvgPicture.asset(
                                    FeatureIcons.flame,
                                    width: 15,
                                    height: 15,
                                    fit: BoxFit.scaleDown,
                                    colorFilter: ColorFilter.mode(
                                      mainFlashNews.flashNews.isImportant
                                          ? kRed
                                          : kDimGrey,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: kDefaultPadding / 4,
                                  ),
                                  Expanded(
                                    child: Text(
                                      mainFlashNews.flashNews.content.trim(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DotContainer(
                                    color: kOrange,
                                    size: 3,
                                  ),
                                  Text(
                                    StringUtil.formatTimeDifference(
                                      mainFlashNews.flashNews.createdAt,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(
                                          color: kDimGrey,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          },
                          options: CarouselOptions(
                            scrollDirection: Axis.vertical,
                            height: 70,
                            viewportFraction: 0.35,
                            autoPlay: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class FlashNewsRow extends StatelessWidget {
  const FlashNewsRow({
    Key? key,
    required this.flashNews,
    required this.onClicked,
    required this.isBookmarked,
    required this.userStatus,
    required this.isMuted,
    required this.highlightedTag,
    this.isReduced,
  }) : super(key: key);

  final FlashNews flashNews;
  final Function() onClicked;
  final bool isBookmarked;
  final UserStatus userStatus;
  final bool? isMuted;
  final String highlightedTag;
  final bool? isReduced;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      margin: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 4),
      child: Column(
        children: [
          BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
            selector: (state) => state.authors[flashNews.pubkey],
            builder: (context, user) {
              final author = user ??
                  emptyUserModel.copyWith(
                    pubKey: flashNews.pubkey,
                    picturePlaceholder: getRandomPlaceholder(
                      input: flashNews.pubkey,
                      isPfp: true,
                    ),
                  );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ProfilePicture2(
                        size: 35,
                        image: author.picture,
                        placeHolder: author.picturePlaceholder,
                        padding: 0,
                        strokeWidth: 1,
                        reduceSize: true,
                        strokeColor: kWhite,
                        onClicked: () {
                          openProfileFastAccess(
                            context: context,
                            pubkey: author.pubKey,
                          );
                        },
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author.name.isEmpty
                                ? Nip19.encodePubkey(
                                    flashNews.pubkey,
                                  ).substring(0, 10)
                                : author.name,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            'On ${dateFormat4.format(flashNews.createdAt)}',
                            style: Theme.of(context).textTheme.labelSmall!,
                          ),
                        ],
                      ),
                      Spacer(),
                      if (isMuted != null && isMuted!)
                        MutedMark(kind: 'curation'),
                      if (userStatus == UserStatus.UsingPrivKey)
                        IconButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              elevation: 0,
                              builder: (_) {
                                return AddBookmarkView(
                                  kind: EventKind.CURATION_ARTICLES,
                                  identifier: flashNews.id,
                                  eventPubkey: flashNews.pubkey,
                                  image: '',
                                );
                              },
                              isScrollControlled: true,
                              useRootNavigator: true,
                              useSafeArea: true,
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                            );
                          },
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            visualDensity: VisualDensity(
                              horizontal: -2,
                              vertical: -1,
                            ),
                          ),
                          icon: BlocBuilder<ThemeCubit, ThemeState>(
                            builder: (context, state) {
                              final isDark = state.theme == AppTheme.purpleDark;

                              return SvgPicture.asset(
                                isBookmarked
                                    ? isDark
                                        ? FeatureIcons.bookmarkFilledWhite
                                        : FeatureIcons.bookmarkFilledBlack
                                    : isDark
                                        ? FeatureIcons.bookmarkEmptyWhite
                                        : FeatureIcons.bookmarkEmptyBlack,
                                width: 20,
                                height: 20,
                                fit: BoxFit.scaleDown,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Text(
                    flashNews.content.capitalize(),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (flashNews.tags.isNotEmpty) ...[
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 24,
                            child: ScrollShadow(
                              color: Theme.of(context).primaryColorLight,
                              size: 10,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: flashNews.tags.length,
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                separatorBuilder: (context, index) {
                                  return const SizedBox(
                                    width: kDefaultPadding / 4,
                                  );
                                },
                                itemBuilder: (context, index) {
                                  final tag = flashNews.tags[index];
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
                      ],
                    ),
                  ],
                  if (flashNews.isImportant || flashNews.source.isNotEmpty) ...[
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    Row(
                      children: [
                        if (flashNews.isImportant)
                          InfoRoundedContainer(
                            tag: 'Important',
                            color: kPurple,
                            textColor: kWhite,
                            onClicked: () {},
                          ),
                        Spacer(),
                        TextButton.icon(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: kTransparent,
                            visualDensity:
                                VisualDensity(horizontal: -2, vertical: -2),
                          ),
                          icon: Text(
                            'source',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  color: kOrange,
                                ),
                          ),
                          label: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: kOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          )
        ],
      ),
    );
  }
}
