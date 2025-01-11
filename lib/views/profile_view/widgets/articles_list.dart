// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/profile_cubit/profile_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/article_view/article_view.dart';
import 'package:yakihonne/views/widgets/article_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/place_holders.dart';

class ProfileArticles extends StatelessWidget {
  const ProfileArticles({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (previous, current) =>
            previous.isArticlesLoading != current.isArticlesLoading ||
            previous.articles != current.articles ||
            previous.user != current.user ||
            previous.bookmarks != current.bookmarks,
        builder: (context, state) {
          if (state.isArticlesLoading) {
            return MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                children: [
                  SkeletonSelector(
                    placeHolderWidget: ArticleSkeleton(),
                  ),
                ],
              ),
            );
          } else {
            if (state.articles.isEmpty) {
              return EmptyList(
                description: '${state.user.name} has no articles',
                icon: FeatureIcons.selfArticles,
              );
            } else {
              if (ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
                return MasonryGridView.builder(
                  physics: AlwaysScrollableScrollPhysics(),
                  gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  crossAxisSpacing: kDefaultPadding / 2,
                  mainAxisSpacing: kDefaultPadding / 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding,
                    vertical: kDefaultPadding / 2,
                  ),
                  itemBuilder: (context, index) {
                    final article = state.articles[index];

                    return ArticleContainer(
                      isFollowing: false,
                      isProfileAccessible: false,
                      article: article,
                      highlightedTag: '',
                      userStatus: state.userStatus,
                      padding: 0,
                      isBookmarked:
                          state.bookmarks.contains(article.identifier),
                      onClicked: () {
                        Navigator.pushNamed(
                          context,
                          ArticleView.routeName,
                          arguments: article,
                        );
                      },
                    );
                  },
                  itemCount: state.articles.length,
                );
              } else {
                return ListView.separated(
                  separatorBuilder: (context, index) => SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  padding: const EdgeInsets.only(
                    top: kDefaultPadding / 2,
                    bottom: kDefaultPadding,
                    left: kDefaultPadding / 2,
                    right: kDefaultPadding / 2,
                  ),
                  physics: AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final article = state.articles[index];

                    return ArticleContainer(
                      isFollowing: false,
                      isProfileAccessible: false,
                      article: article,
                      highlightedTag: '',
                      userStatus: state.userStatus,
                      isBookmarked:
                          state.bookmarks.contains(article.identifier),
                      onClicked: () {
                        Navigator.pushNamed(
                          context,
                          ArticleView.routeName,
                          arguments: article,
                        );
                      },
                    );
                  },
                  itemCount: state.articles.length,
                );
              }
            }
          }
        },
      ),
    );
  }
}
