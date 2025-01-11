// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/article_cubit/article_cubit.dart';
import 'package:yakihonne/models/article_model.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/article_view/widgets/articles_header.dart';
import 'package:yakihonne/views/tag_view/tag_view.dart';
import 'package:yakihonne/views/widgets/article_thumbnail.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';
import 'package:yakihonne/views/widgets/mark_down_widget.dart';
import 'package:yakihonne/views/widgets/scroll_to_top.dart';

class ArticleView extends HookWidget {
  static const routeName = '/articleView';
  static Route route(RouteSettings settings) {
    final article = settings.arguments as Article;

    return CupertinoPageRoute(
      builder: (_) => ArticleView(
        article: article,
      ),
    );
  }

  final Article article;

  ArticleView({
    Key? key,
    required this.article,
  }) : super(key: key) {
    FirebaseAnalytics.instance.setCurrentScreen(screenName: 'Article screen');
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController(
      initialScrollOffset: 0,
    );

    return BlocProvider(
      create: (context) => ArticleCubit(
        article: article,
        nostrRepository: context.read<NostrDataRepository>(),
        localDatabaseRepository: context.read<LocalDatabaseRepository>(),
      )..initView(),
      child: ScrollsToTop(
        onScrollsToTop: (event) async {
          onScrollsToTop(event, scrollController);
        },
        child: Scaffold(
          appBar: CustomAppBar(
            title: 'Article',
          ),
          body: Stack(
            children: [
              Scrollbar(
                controller: scrollController,
                child: Builder(
                  builder: (context) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<ArticleCubit>().emptyArticleState();
                        context.read<ArticleCubit>().initView();
                      },
                      displacement: kDefaultPadding / 2,
                      triggerMode: RefreshIndicatorTriggerMode.anywhere,
                      notificationPredicate: (notification) {
                        return notification.depth == 0;
                      },
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          vertical: kDefaultPadding,
                          horizontal: kDefaultPadding / 2,
                        ),
                        physics: ClampingScrollPhysics(),
                        controller: scrollController,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return GestureDetector(
                                onTap: () {
                                  if (article.image.isNotEmpty) {
                                    final imageProvider =
                                        CachedNetworkImageProvider(
                                      article.image,
                                    );

                                    showImageViewer(
                                      context,
                                      imageProvider,
                                      doubleTapZoomable: true,
                                      swipeDismissible: true,
                                    );
                                  }
                                },
                                child: ArticleThumbnail(
                                  image: article.image,
                                  placeholder: article.placeholder,
                                  width: constraints.maxWidth,
                                  height: 22.h,
                                ),
                              );
                            },
                          ),
                          const SizedBox(
                            height: kDefaultPadding,
                          ),
                          ArticleHeader(
                            article: article,
                          ),
                          const SizedBox(
                            height: kDefaultPadding,
                          ),
                          Builder(
                            builder: (context) {
                              final title = article.title.trim();
                              return SelectableText(
                                title.isEmpty ? 'No title' : title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: title.isEmpty
                                          ? kDimGrey
                                          : Theme.of(context).primaryColorDark,
                                    ),
                              );
                            },
                          ),
                          if (article.summary.isNotEmpty) ...[
                            const SizedBox(
                              height: kDefaultPadding,
                            ),
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  VerticalDivider(
                                    thickness: 4,
                                    width: 0,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(
                                    width: kDefaultPadding,
                                  ),
                                  Expanded(
                                    child: SelectableText(
                                      article.summary.trim(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: kDimGrey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (article.hashTags.isNotEmpty) ...[
                            const SizedBox(
                              height: kDefaultPadding,
                            ),
                            Wrap(
                              spacing: kDefaultPadding / 3,
                              runSpacing: kDefaultPadding / 3,
                              children: article.hashTags.map((tag) {
                                if (tag.trim().isEmpty) {
                                  return SizedBox.shrink();
                                }

                                return InfoRoundedContainer(
                                  tag: tag,
                                  color: Theme.of(context).primaryColor,
                                  textColor: kWhite,
                                  onClicked: () {
                                    Navigator.pushNamed(
                                      context,
                                      TagView.routeName,
                                      arguments: tag,
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(
                            height: kDefaultPadding,
                          ),
                          Builder(builder: (context) {
                            return MarkDownWidget(
                              content: article.content,
                              onLinkClicked: (link) => openWebPage(url: link),
                            );
                          }),
                          const SizedBox(
                            height: kDefaultPadding,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              ResetScrollButton(scrollController: scrollController),
            ],
          ),
        ),
      ),
    );
  }
}
