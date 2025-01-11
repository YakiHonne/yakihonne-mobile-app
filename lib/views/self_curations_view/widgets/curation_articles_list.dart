// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/self_curations_cubit/add_articles_cubit/add_articles_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/self_curations_view/widgets/add_curation_articles.dart';
import 'package:yakihonne/views/widgets/classic_footer.dart';
import 'package:yakihonne/views/widgets/custom_drop_down.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/place_holders.dart';

import '../../profile_view/widgets/profile_follow_authors_view.dart';

class CurationArticlesList extends StatefulWidget {
  const CurationArticlesList({super.key});

  @override
  State<CurationArticlesList> createState() => _CurationArticlesListState();
}

class _CurationArticlesListState extends State<CurationArticlesList> {
  final refreshController = RefreshController();
  final scrollController = ScrollController();
  final textEditingController = TextEditingController();

  void onRefresh({required Function onInit}) {
    refreshController.resetNoData();
    onInit.call();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget relaysDropdown =
        BlocBuilder<AddCurationArticlesCubit, AddCurationArticlesState>(
      buildWhen: (previous, current) => previous.relays != current.relays,
      builder: (context, state) {
        return RelaysCustomDropDown(
          defaultValue: state.chosenRelay,
          list: state.relays.toList(),
          onChanged: (relay) {
            context.read<AddCurationArticlesCubit>().getItems(relay, false);
          },
        );
      },
    );

    Widget searchTextField = TextField(
      decoration: InputDecoration(
        hintText: 'Search articles by title',
      ),
      controller: textEditingController,
      onChanged: (text) {
        context.read<AddCurationArticlesCubit>().setSearchText(text);
      },
    );

    return BlocConsumer<AddCurationArticlesCubit, AddCurationArticlesState>(
      listener: (context, state) {
        if (state.relaysAddingData == UpdatingState.success) {
          refreshController.loadComplete();
        } else if (state.relaysAddingData == UpdatingState.idle) {
          refreshController.loadNoData();
        }
      },
      builder: (context, state) {
        return Container(
          height: 90.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Scrollbar(
            child: Column(
              children: [
                ModalBottomSheetHandle(),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                BlocBuilder<AddCurationArticlesCubit, AddCurationArticlesState>(
                  builder: (context, state) {
                    return CustomToggleButton(
                      state: state.isAllRelays,
                      firstText: 'All relays',
                      secondText: state.isArticlesCuration
                          ? 'My articles'
                          : 'My videos',
                      onClicked: () async {
                        context.read<AddCurationArticlesCubit>().toggleView();
                        context
                            .read<AddCurationArticlesCubit>()
                            .getItems(null, false);
                        textEditingController.clear();
                      },
                    );
                  },
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Expanded(
                  child: SmartRefresher(
                    primary: true,
                    controller: refreshController,
                    enablePullDown: true,
                    enablePullUp: true,
                    header: const MaterialClassicHeader(
                      color: kPurple,
                    ),
                    footer: const RefresherClassicFooter(),
                    onLoading: () =>
                        context.read<AddCurationArticlesCubit>().getMoreItems(),
                    onRefresh: () => onRefresh(
                      onInit: () => context
                          .read<AddCurationArticlesCubit>()
                          .getItems(state.chosenRelay, false),
                    ),
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding / 2,
                              vertical: kDefaultPadding / 2,
                            ),
                            child: ResponsiveBreakpoints.of(context)
                                    .largerThan(MOBILE)
                                ? Row(
                                    children: [
                                      if (state.isAllRelays) ...[
                                        Expanded(
                                          child: relaysDropdown,
                                        ),
                                        const SizedBox(
                                          width: kDefaultPadding / 2,
                                        ),
                                      ],
                                      Expanded(
                                        child: searchTextField,
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      if (state.isAllRelays) relaysDropdown,
                                      const SizedBox(
                                        height: kDefaultPadding / 2,
                                      ),
                                      searchTextField,
                                    ],
                                  ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            vertical: kDefaultPadding / 2,
                          ),
                          sliver: BlocBuilder<AddCurationArticlesCubit,
                              AddCurationArticlesState>(
                            builder: (context, state) {
                              if (state.isArticlesLoading) {
                                return SliverToBoxAdapter(
                                  child: ArticleSkeleton(),
                                );
                              } else if (state.isArticlesCuration
                                  ? state.articles.isEmpty
                                  : state.videos.isEmpty) {
                                return SliverToBoxAdapter(
                                  child: Center(
                                    child: Text(
                                      'No ${state.isArticlesCuration ? 'articles' : 'videos'} belong to this curation',
                                    ),
                                  ),
                                );
                              } else {
                                if (state.isArticlesCuration) {
                                  return SliverPadding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: kDefaultPadding / 2,
                                    ),
                                    sliver: SliverList.builder(
                                      itemBuilder: (context, index) {
                                        final article = state.articles[index];

                                        if (state.searchText
                                                .trim()
                                                .isNotEmpty &&
                                            !article.title
                                                .trim()
                                                .toLowerCase()
                                                .contains(state.searchText
                                                    .toLowerCase()
                                                    .trim())) {
                                          return SizedBox.shrink();
                                        }

                                        final isAdding = state.activeArticles
                                            .where((activeArticle) =>
                                                activeArticle.articleId ==
                                                article.articleId)
                                            .isEmpty;

                                        return AddingCurationArticleContainer(
                                          createdAt: article.createdAt,
                                          image: article.image,
                                          muteKind: 'article',
                                          placeholder: article.placeholder,
                                          title: article.title,
                                          isAdding: isAdding,
                                          isActive: isAdding,
                                          isMuted: false,
                                          onDelete: () {
                                            if (isAdding) {
                                              context
                                                  .read<
                                                      AddCurationArticlesCubit>()
                                                  .setArticleToActive(article);
                                            } else {
                                              context
                                                  .read<
                                                      AddCurationArticlesCubit>()
                                                  .deleteActiveArticle(
                                                    article.articleId,
                                                  );
                                            }
                                          },
                                        );
                                      },
                                      itemCount: state.articles.length,
                                    ),
                                  );
                                } else {
                                  return SliverPadding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: kDefaultPadding,
                                    ),
                                    sliver: SliverList.builder(
                                      itemBuilder: (context, index) {
                                        final video = state.videos[index];

                                        if (state.searchText
                                                .trim()
                                                .isNotEmpty &&
                                            !video.title
                                                .trim()
                                                .toLowerCase()
                                                .contains(state.searchText
                                                    .toLowerCase()
                                                    .trim())) {
                                          return SizedBox.shrink();
                                        }

                                        final isAdding = state.activeVideos
                                            .where((activeVideo) =>
                                                activeVideo.videoId ==
                                                video.videoId)
                                            .isEmpty;

                                        return AddingCurationArticleContainer(
                                          createdAt: video.createdAt,
                                          image: video.thumbnail,
                                          muteKind: 'video',
                                          placeholder: video.placeHolder,
                                          title: video.title,
                                          isAdding: isAdding,
                                          isActive: isAdding,
                                          isMuted: false,
                                          onDelete: () {
                                            if (isAdding) {
                                              context
                                                  .read<
                                                      AddCurationArticlesCubit>()
                                                  .setVideoToActive(video);
                                            } else {
                                              context
                                                  .read<
                                                      AddCurationArticlesCubit>()
                                                  .deleteActiveArticle(
                                                    video.videoId,
                                                  );
                                            }
                                          },
                                        );
                                      },
                                      itemCount: state.videos.length,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
