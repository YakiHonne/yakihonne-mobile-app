// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/search_cubit/search_cubit.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/models/buzz_feed_models.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/article_view/article_view.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_container.dart';
import 'package:yakihonne/views/buzz_feed_view/widgets/buzz_feed_details.dart';
import 'package:yakihonne/views/flash_news_details_view/flash_news_details_view.dart';
import 'package:yakihonne/views/profile_view/profile_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/horizontal_video_view.dart';
import 'package:yakihonne/views/videos_feed_view/widgets/vertical_video_view.dart';
import 'package:yakihonne/views/widgets/article_container.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/flash_news_container.dart';
import 'package:yakihonne/views/widgets/note_container.dart';
import 'package:yakihonne/views/widgets/place_holders.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/video_common_container.dart';

class SearchView extends HookWidget {
  SearchView({
    required this.mainScrollController,
  }) {
    FirebaseAnalytics.instance.setCurrentScreen(screenName: 'Search screen');
  }

  final ScrollController mainScrollController;
  final List<String> contentOptions = [
    'Articles',
    'Flash news',
    'Videos',
    'Buzz feed',
    'Notes',
  ];

  @override
  Widget build(BuildContext context) {
    final searchTextEdittingController = useTextEditingController();
    final selectedOption = useState('Articles');

    return BlocProvider(
      create: (context) => SearchCubit(
        nostrRepository: context.read<NostrDataRepository>(),
        context: context,
      ),
      child: Scrollbar(
        controller: mainScrollController,
        child: BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            return CustomScrollView(
              controller: mainScrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Builder(
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: kDefaultPadding,
                          horizontal: kDefaultPadding / 2,
                        ),
                        child: TextField(
                          controller: searchTextEdittingController,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12),
                              child: SvgPicture.asset(
                                FeatureIcons.search,
                                width: 5,
                                colorFilter: ColorFilter.mode(
                                  Theme.of(context).primaryColorDark,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                searchTextEdittingController.clear();
                                context
                                    .read<SearchCubit>()
                                    .getItemsBySearch('');
                              },
                              icon: Icon(Icons.close),
                            ),
                            hintText: 'Type your search here...',
                            hintStyle: Theme.of(context).textTheme.bodyMedium,
                          ),
                          onChanged: (search) {
                            context
                                .read<SearchCubit>()
                                .getItemsBySearch(search);
                          },
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text(
                          'Profiles',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: kDimGrey,
                                  ),
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        SvgPicture.asset(
                          FeatureIcons.user,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColorDark,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                BlocBuilder<SearchCubit, SearchState>(
                  buildWhen: (previous, current) =>
                      previous.profileSearchResult !=
                          current.profileSearchResult ||
                      previous.authors != current.authors,
                  builder: (context, state) {
                    return SliverToBoxAdapter(
                      child: getProfiles(
                        isTablet: ResponsiveBreakpoints.of(context)
                            .largerThan(MOBILE),
                        searchResultsType: state.profileSearchResult,
                      ),
                    );
                  },
                ),
                SliverToBoxAdapter(
                  child: const Divider(
                    height: kDefaultPadding * 2,
                    endIndent: kDefaultPadding / 2,
                    indent: kDefaultPadding / 2,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text(
                          'Content',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: kDimGrey,
                                  ),
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        SvgPicture.asset(
                          FeatureIcons.selfArticles,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColorDark,
                            BlendMode.srcIn,
                          ),
                        ),
                        Spacer(),
                        PullDownButton(
                          animationBuilder: (context, state, child) {
                            return child;
                          },
                          routeTheme: PullDownMenuRouteTheme(
                            backgroundColor:
                                Theme.of(context).primaryColorLight,
                          ),
                          itemBuilder: (context) {
                            return [
                              ...contentOptions
                                  .map(
                                    (e) => PullDownMenuItem.selectable(
                                      onTap: () {
                                        selectedOption.value = e;
                                      },
                                      selected: e == selectedOption.value,
                                      title: e,
                                      itemTheme: PullDownMenuItemTheme(
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .labelMedium!
                                            .copyWith(
                                              fontWeight:
                                                  e == selectedOption.value
                                                      ? FontWeight.w500
                                                      : FontWeight.w400,
                                            ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ];
                          },
                          buttonBuilder: (context, showMenu) => IconButton(
                            onPressed: showMenu,
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).primaryColorLight,
                            ),
                            icon: SvgPicture.asset(
                              FeatureIcons.properties,
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                BlocBuilder<SearchCubit, SearchState>(
                  buildWhen: (previous, current) =>
                      previous.contentSearchResult !=
                          current.contentSearchResult ||
                      previous.content != current.content,
                  builder: (context, state) {
                    return getContent(
                      isTablet:
                          ResponsiveBreakpoints.of(context).largerThan(MOBILE),
                      contentType: selectedOption.value,
                      searchResultsType: state.contentSearchResult,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget getProfiles({
    required bool isTablet,
    required SearchResultsType searchResultsType,
  }) {
    if (searchResultsType == SearchResultsType.loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
          vertical: kDefaultPadding / 2,
        ),
        child: isTablet
            ? Row(
                children: [
                  Expanded(child: SearchProfileSkeleton()),
                  Expanded(child: SearchProfileSkeleton()),
                ],
              )
            : SearchProfileSkeleton(),
      );
    } else if (searchResultsType == SearchResultsType.noSearch) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
        child: SearchIdle(
          text: 'Search profiles by usernames or pubkeys.',
        ),
      );
    } else {
      return AuthorsList();
    }
  }

  Widget getContent({
    required bool isTablet,
    required String contentType,
    required SearchResultsType searchResultsType,
  }) {
    if (searchResultsType == SearchResultsType.loading) {
      return SliverToBoxAdapter(
          child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
          vertical: kDefaultPadding / 2,
        ),
        child: isTablet
            ? Row(
                children: [
                  Expanded(child: SearchProfileSkeleton()),
                  Expanded(child: SearchProfileSkeleton()),
                ],
              )
            : SearchProfileSkeleton(),
      ));
    } else if (searchResultsType == SearchResultsType.noSearch) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: SearchIdle(
            text: 'Search for content by tags.',
          ),
        ),
      );
    } else {
      return ContentList(
        contentType: contentType,
      );
    }
  }
}

class SearchNoResult extends StatelessWidget {
  const SearchNoResult({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding,
        horizontal: kDefaultPadding,
      ),
      child: Column(
        children: [
          Text(
            'No result for this keyword',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Text(
            'No results have been found using this keyword, try to use another keywords in order to get a better results.',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SearchIdle extends StatelessWidget {
  const SearchIdle({
    Key? key,
    required this.text,
  }) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class ContentList extends StatelessWidget {
  const ContentList({
    Key? key,
    required this.contentType,
  }) : super(key: key);

  final String contentType;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      buildWhen: (previous, current) => previous.content != current.content,
      builder: (context, state) {
        final content = getFilteredContent(state.content, contentType);

        if (content.isEmpty) {
          return SliverToBoxAdapter(child: SearchNoResult());
        }

        if (ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
          return SliverToBoxAdapter(
            child: MasonryGridView.count(
              crossAxisCount: 2,
              itemCount: content.length,
              crossAxisSpacing: kDefaultPadding / 2,
              mainAxisSpacing: kDefaultPadding / 2,
              padding: const EdgeInsets.all(kDefaultPadding / 2),
              itemBuilder: (context, index) {
                final item = content[index];

                return getItem(item);
              },
            ),
          );
        } else {
          return SliverPadding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            sliver: SliverList.separated(
              itemCount: content.length,
              separatorBuilder: (context, index) => const SizedBox(
                height: kDefaultPadding / 2,
              ),
              itemBuilder: (context, index) {
                final item = content[index];

                return getItem(item);
              },
            ),
          );
        }
      },
    );
  }

  Widget getItem(CreatedAtTag item) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        if (item is Article) {
          return ArticleContainer(
            article: item,
            isProfileAccessible: true,
            highlightedTag: '',
            padding: 0,
            margin: 0,
            isMuted: state.mutes.contains(item.pubkey),
            isBookmarked: state.bookmarks.contains(item.identifier),
            userStatus: getUserStatus(),
            onClicked: () {
              Navigator.pushNamed(
                context,
                ArticleView.routeName,
                arguments: item,
              );
            },
            isFollowing: state.followings.contains(item.pubkey),
          );
        } else if (item is BuzzFeedModel) {
          return BuzzFeedContainer(
            buzzFeedModel: item,
            isBookmarked: state.bookmarks.contains(item.id),
            onClicked: () {
              Navigator.pushNamed(
                context,
                BuzzFeedDetails.routeName,
                arguments: item,
              );
            },
            onExternalShare: () {
              openWebPage(url: item.sourceUrl);
            },
          );
        } else if (item is FlashNews) {
          return HomeFlashNewsContainer(
            userStatus: getUserStatus(),
            mainFlashNews: MainFlashNews(flashNews: item),
            flashNewsType: FlashNewsType.public,
            trySearch: false,
            isMuted: state.mutes.contains(item.pubkey),
            isBookmarked: state.bookmarks.contains(item.id),
            isFollowing: state.followings.contains(item.id),
            onClicked: () {
              Navigator.pushNamed(
                context,
                FlashNewsDetailsView.routeName,
                arguments: [MainFlashNews(flashNews: item), true],
              );
            },
          );
        } else if (item is VideoModel) {
          final video = item;

          return VideoCommonContainer(
            isBookmarked: state.bookmarks.contains(item.identifier),
            isMuted: state.mutes.contains(video.pubkey),
            isFollowing: state.followings.contains(video.pubkey),
            video: video,
            onTap: () {
              Navigator.pushNamed(
                context,
                video.isHorizontal
                    ? HorizontalVideoView.routeName
                    : VerticalVideoView.routeName,
                arguments: [video],
              );
            },
          );
        } else if (item is DetailedNoteModel) {
          return NoteContainer(note: item);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  List<dynamic> getFilteredContent(
    List<dynamic> totalContent,
    String contentType,
  ) {
    if (contentType == 'Articles') {
      return totalContent.where((element) => element is Article).toList();
    } else if (contentType == 'Flash news') {
      return totalContent.where((element) => element is FlashNews).toList();
    } else if (contentType == 'Videos') {
      return totalContent.where((element) => element is VideoModel).toList();
    } else if (contentType == 'Buzz feed') {
      return totalContent.where((element) => element is BuzzFeedModel).toList();
    } else if (contentType == 'Notes') {
      return totalContent
          .where((element) => element is DetailedNoteModel)
          .toList();
    } else {
      return [];
    }
  }
}

class AuthorsList extends StatelessWidget {
  const AuthorsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      child: BlocBuilder<SearchCubit, SearchState>(
        buildWhen: (previous, current) => previous.authors != current.authors,
        builder: (context, state) {
          if (state.authors.isEmpty) {
            return SearchNoResult();
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: Row(
              children: state.authors
                  .map((author) => SearchAuthorContainer(author: author))
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

class SearchAuthorContainer extends StatelessWidget {
  const SearchAuthorContainer({
    super.key,
    required this.author,
  });

  final UserModel author;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        ProfileView.routeName,
        arguments: author.pubKey,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
          vertical: kDefaultPadding / 2,
        ),
        width: 300,
        margin: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 3,
          horizontal: kDefaultPadding / 4,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding),
          color: Theme.of(context).primaryColorLight,
        ),
        child: Row(
          children: [
            ProfilePicture2(
              image: author.picture,
              placeHolder: author.picturePlaceholder,
              size: 55,
              padding: 3,
              strokeWidth: 1,
              strokeColor: Theme.of(context).primaryColorDark,
              onClicked: () {
                openProfileFastAccess(
                  context: context,
                  pubkey: author.pubKey,
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
                  Text(
                    getAuthorName(author),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  PubKeyContainer(pubKey: author.pubKey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchLoading extends StatelessWidget {
  const SearchLoading({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding,
      ),
      child: SpinKitThreeBounce(
        color: Theme.of(context).primaryColorDark,
        size: 15,
      ),
    );
  }
}
