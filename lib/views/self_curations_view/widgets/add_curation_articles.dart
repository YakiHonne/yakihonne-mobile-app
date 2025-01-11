// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_reorderable_grid_view/entities/order_update_entity.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/self_curations_cubit/add_articles_cubit/add_articles_cubit.dart';
import 'package:yakihonne/blocs/self_curations_cubit/self_curations_cubit.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/self_curations_view/widgets/curation_articles_list.dart';
import 'package:yakihonne/views/widgets/article_thumbnail.dart';
import 'package:yakihonne/views/widgets/bottom_cancelable_bar.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';
import 'package:yakihonne/views/widgets/muted_mark.dart';
import 'package:yakihonne/views/widgets/place_holders.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class AddCurationArticlesView extends StatelessWidget {
  static const routeName = '/addCurationArticlesView';
  static Route route(RouteSettings settings) {
    final list = settings.arguments as List;

    return CupertinoPageRoute(
      builder: (_) => AddCurationArticlesView(
        selfCurationsCubit: list[0],
        curation: list[1],
      ),
    );
  }

  const AddCurationArticlesView({
    super.key,
    required this.selfCurationsCubit,
    required this.curation,
  });

  final SelfCurationsCubit selfCurationsCubit;
  final Curation curation;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddCurationArticlesCubit(
        nostrRepository: context.read<NostrDataRepository>(),
        curation: curation,
      )..initView(),
      child: Scaffold(
        appBar: CustomAppBar(
          title:
              'Curation ${curation.isArticleCuration() ? 'articles' : 'videos'}',
        ),
        bottomNavigationBar: Builder(builder: (context) {
          return BottomCancellableBar(
            onClicked: () {
              context.read<AddCurationArticlesCubit>().addCuration(
                onFailure: (message) {
                  singleSnackBar(
                    context: context,
                    message: message,
                    color: kRed,
                    backGroundColor: kRedSide,
                    icon: ToastsIcons.error,
                  );
                },
                onSuccess: () {
                  singleSnackBar(
                    context: context,
                    message: 'Curation has been updated successfuly',
                    color: kGreen,
                    backGroundColor: kGreenSide,
                    icon: ToastsIcons.success,
                  );

                  selfCurationsCubit.getCurations(
                    relay: selfCurationsCubit.state.chosenRelay,
                  );
                  Navigator.pop(context);
                },
              );
            },
            text: 'Update',
          );
        }),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ArticleThumbnail(
                      image: curation.image,
                      placeholder: curation.placeHolder,
                      width: 20.w,
                      height: 20.w,
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            curation.title.trim().isEmpty
                                ? 'No title'
                                : curation.title.trim().capitalize(),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                            maxLines: 3,
                          ),
                          Text(
                            curation.description.trim().isEmpty
                                ? 'No description'
                                : curation.description.trim().capitalize(),
                            style: Theme.of(context).textTheme.bodySmall!,
                            maxLines: 4,
                          ),
                          Spacer(),
                          if (ResponsiveBreakpoints.of(context)
                              .largerThan(MOBILE))
                            Row(
                              children: [
                                BlocBuilder<AddCurationArticlesCubit,
                                    AddCurationArticlesState>(
                                  builder: (context, state) {
                                    final type = curation.isArticleCuration()
                                        ? 'Articles'
                                        : 'Videos';
                                    final length = curation.isArticleCuration()
                                        ? state.activeArticles.length
                                        : state.activeVideos.length;

                                    return Expanded(
                                      child: Text(
                                        '$type ${length.toString().padLeft(2, '0')}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge!
                                            .copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                BlocBuilder<AddCurationArticlesCubit,
                                    AddCurationArticlesState>(
                                  builder: (context, state) {
                                    return TextButton(
                                      onPressed: () {
                                        context
                                            .read<AddCurationArticlesCubit>()
                                            .getItems(
                                              state.chosenRelay,
                                              false,
                                            );

                                        showModalBottomSheet(
                                          context: context,
                                          elevation: 0,
                                          builder: (_) {
                                            return BlocProvider.value(
                                              value: context.read<
                                                  AddCurationArticlesCubit>(),
                                              child: CurationArticlesList(),
                                            );
                                          },
                                          isScrollControlled: true,
                                          useRootNavigator: true,
                                          useSafeArea: true,
                                          backgroundColor: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                        );
                                      },
                                      child: Text(
                                        'Add',
                                      ),
                                    );
                                  },
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
            if (ResponsiveBreakpoints.of(context).smallerOrEqualTo(MOBILE))
              Padding(
                padding: const EdgeInsets.only(
                  bottom: kDefaultPadding,
                  left: kDefaultPadding,
                  right: kDefaultPadding,
                ),
                child: Row(
                  children: [
                    BlocBuilder<AddCurationArticlesCubit,
                        AddCurationArticlesState>(
                      builder: (context, state) {
                        final type = curation.isArticleCuration()
                            ? 'Articles'
                            : 'Videos';
                        final length = curation.isArticleCuration()
                            ? state.activeArticles.length
                            : state.activeVideos.length;

                        return Expanded(
                          child: Text(
                            '$type ${length.toString().padLeft(2, '0')}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        );
                      },
                    ),
                    BlocBuilder<AddCurationArticlesCubit,
                        AddCurationArticlesState>(
                      builder: (context, state) {
                        return TextButton(
                          onPressed: () {
                            context
                                .read<AddCurationArticlesCubit>()
                                .getItems(state.chosenRelay, false);

                            showModalBottomSheet(
                              context: context,
                              elevation: 0,
                              builder: (_) {
                                return BlocProvider.value(
                                  value:
                                      context.read<AddCurationArticlesCubit>(),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: CurationArticlesList(),
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
                          child: Text(
                            'Add',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            BlocBuilder<AddCurationArticlesCubit, AddCurationArticlesState>(
              buildWhen: (previous, current) =>
                  previous.activeArticles != current.activeArticles ||
                  previous.activeVideos != current.activeVideos,
              builder: (context, state) {
                if (state.isActiveArticlesLoading) {
                  return ArticleSkeleton();
                } else if (curation.isArticleCuration()
                    ? state.activeArticles.isEmpty
                    : state.activeVideos.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${curation.isArticleCuration() ? 'articles' : 'videos'} belong to this curation',
                    ),
                  );
                } else {
                  return Expanded(
                    child: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
                        ? CurationAddedArticleGrid()
                        : CurationAddedArticleList(),
                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }
}

class CurationAddedArticleList extends StatelessWidget {
  CurationAddedArticleList({
    super.key,
  });

  final _listViewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddCurationArticlesCubit, AddCurationArticlesState>(
      builder: (context, state) {
        if (state.isArticlesCuration) {
          return ReorderableListView.builder(
            key: _listViewKey,
            shrinkWrap: true,
            primary: false,
            onReorder: (oldIndex, newIndex) {
              final index = newIndex > oldIndex ? newIndex - 1 : newIndex;

              context
                  .read<AddCurationArticlesCubit>()
                  .setArticlesNewOrder(oldIndex, index);
            },
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            itemBuilder: (context, index) {
              final article = state.activeArticles[index];

              return AddingCurationArticleContainer(
                key: Key(article.articleId),
                isMuted: state.mutes.contains(article.pubkey),
                createdAt: article.createdAt,
                image: article.image,
                muteKind: 'article',
                placeholder: article.placeholder,
                title: article.title,
                isAdding: false,
                isActive: true,
                onDelete: () {
                  context
                      .read<AddCurationArticlesCubit>()
                      .deleteActiveArticle(article.articleId);
                },
              );
            },
            itemCount: state.activeArticles.length,
          );
        } else {
          return ReorderableListView.builder(
            key: _listViewKey,
            shrinkWrap: true,
            primary: false,
            onReorder: (oldIndex, newIndex) {
              final index = newIndex > oldIndex ? newIndex - 1 : newIndex;

              context
                  .read<AddCurationArticlesCubit>()
                  .setVideossNewOrder(oldIndex, index);
            },
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            itemBuilder: (context, index) {
              final video = state.activeVideos[index];

              return AddingCurationArticleContainer(
                key: Key(video.videoId),
                isMuted: state.mutes.contains(video.pubkey),
                createdAt: video.createdAt,
                image: video.thumbnail,
                muteKind: 'video',
                placeholder: video.placeHolder,
                title: video.title,
                isAdding: false,
                isActive: true,
                onDelete: () {
                  context
                      .read<AddCurationArticlesCubit>()
                      .deleteActiveArticle(video.videoId);
                },
              );
            },
            itemCount: state.activeVideos.length,
          );
        }
      },
    );
  }
}

class CurationAddedArticleGrid extends HookWidget {
  CurationAddedArticleGrid({
    super.key,
  });

  final _gridViewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final gridScrollController = useScrollController();

    return BlocBuilder<AddCurationArticlesCubit, AddCurationArticlesState>(
      buildWhen: (previous, current) =>
          previous.activeArticles != current.activeArticles &&
          previous.activeVideos != current.activeVideos &&
          previous.mutes != current.mutes,
      builder: (context, state) {
        List<Widget> generatedChildren = [];
        if (state.isArticlesCuration) {
          generatedChildren = state.activeArticles.map((article) {
            return AddingCurationArticleContainer(
              key: Key(article.articleId),
              muteKind: 'article',
              createdAt: article.createdAt,
              image: article.image,
              placeholder: article.placeholder,
              title: article.title,
              isMuted: state.mutes.contains(article.pubkey),
              isAdding: false,
              isActive: true,
              onDelete: () {
                context
                    .read<AddCurationArticlesCubit>()
                    .deleteActiveArticle(article.articleId);
              },
            );
          }).toList();
        } else {
          generatedChildren = state.activeVideos.map((video) {
            return AddingCurationArticleContainer(
              key: Key(video.videoId),
              createdAt: video.createdAt,
              image: video.thumbnail,
              muteKind: 'video',
              placeholder: video.placeHolder,
              title: video.title,
              isMuted: state.mutes.contains(video.pubkey),
              isAdding: false,
              isActive: true,
              onDelete: () {
                context
                    .read<AddCurationArticlesCubit>()
                    .deleteActiveArticle(video.videoId);
              },
            );
          }).toList();
        }

        return ReorderableBuilder(
          children: generatedChildren,
          scrollController: gridScrollController,
          enableLongPress: false,
          onReorder: (List<OrderUpdateEntity> orderUpdateEntities) {
            for (final orderUpdateEntity in orderUpdateEntities) {
              context.read<AddCurationArticlesCubit>().setArticlesNewOrder(
                  orderUpdateEntity.oldIndex, orderUpdateEntity.newIndex);
            }
          },
          builder: (children) => GridView.builder(
            itemBuilder: (context, index) {
              return children[index];
            },
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            itemCount: children.length,
            key: _gridViewKey,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 120,
              crossAxisSpacing: kDefaultPadding,
            ),
          ),
        );
      },
    );
  }
}

class AddingCurationArticleContainer extends StatelessWidget {
  const AddingCurationArticleContainer({
    Key? key,
    required this.image,
    required this.placeholder,
    required this.createdAt,
    required this.title,
    required this.muteKind,
    required this.onDelete,
    required this.isAdding,
    required this.isActive,
    required this.isMuted,
  }) : super(key: key);

  final String image;
  final String placeholder;
  final DateTime createdAt;
  final String title;
  final String muteKind;
  final bool isAdding;
  final bool isActive;
  final bool isMuted;
  final Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          margin: const EdgeInsets.symmetric(
            vertical: kDefaultPadding,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
            borderRadius: BorderRadius.circular(kDefaultPadding),
            border: Border.all(
              width: 0.5,
              color: isActive ? kTransparent : kGreen,
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  ArticleThumbnail(
                    image: image,
                    placeholder: placeholder,
                    width: 60,
                    height: 60,
                  ),
                  if (isMuted) ...[
                    Positioned(
                      left: kDefaultPadding / 4,
                      top: kDefaultPadding / 4,
                      child: MutedMark(kind: muteKind),
                    ),
                  ]
                ],
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'On ${dateFormat2.format(createdAt)}',
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: kDimGrey,
                          ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: kDefaultPadding,
          child: BorderedIconButton(
            onClicked: onDelete,
            primaryIcon: isAdding ? FeatureIcons.add : FeatureIcons.trash,
            borderColor: Theme.of(context).primaryColorLight,
            iconColor: kWhite,
            firstSelection: true,
            secondaryIcon: FeatureIcons.trash,
            backGroundColor: isAdding ? kGreen : kRed,
          ),
        ),
      ],
    );
  }
}
