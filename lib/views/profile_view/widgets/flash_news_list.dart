// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/profile_cubit/profile_cubit.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_details_view/flash_news_details_view.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/flash_news_container.dart';
import 'package:yakihonne/views/widgets/place_holders.dart';

class ProfileFlashNews extends StatelessWidget {
  const ProfileFlashNews({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (previous, current) =>
            previous.isFlashNewsLoading != current.isFlashNewsLoading ||
            previous.flashNews != current.flashNews ||
            previous.user != current.user ||
            previous.bookmarks != current.bookmarks,
        builder: (context, state) {
          if (state.isFlashNewsLoading) {
            return MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                children: [
                  SkeletonSelector(
                    placeHolderWidget: ArticleSkeleton(),
                  ),
                ],
              ),
            );
          } else {
            if (state.flashNews.isEmpty) {
              return EmptyList(
                description: '${state.user.name} has no flash news',
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
                    final flashNews = state.flashNews[index];

                    return HomeFlashNewsContainer(
                      userStatus: state.userStatus,
                      mainFlashNews: MainFlashNews(flashNews: flashNews),
                      flashNewsType: FlashNewsType.public,
                      isMuted: state.mutes.contains(flashNews.pubkey),
                      isFollowing: state.followings.contains(flashNews.pubkey),
                      isBookmarked: state.bookmarks.contains(flashNews.id),
                      onClicked: () {
                        Navigator.pushNamed(
                          context,
                          FlashNewsDetailsView.routeName,
                          arguments: [
                            MainFlashNews(flashNews: flashNews),
                            true
                          ],
                        );
                      },
                    );
                  },
                  itemCount: state.flashNews.length,
                );
              } else {
                return ListView.separated(
                  separatorBuilder: (context, index) => const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  padding: const EdgeInsets.only(
                    top: kDefaultPadding / 2,
                    bottom: kBottomNavigationBarHeight,
                    left: kDefaultPadding / 2,
                    right: kDefaultPadding / 2,
                  ),
                  physics: AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final flashNews = state.flashNews[index];

                    return HomeFlashNewsContainer(
                      userStatus: state.userStatus,
                      isFollowing: state.followings.contains(flashNews.pubkey),
                      isMuted: state.mutes.contains(flashNews.pubkey),
                      mainFlashNews: MainFlashNews(flashNews: flashNews),
                      flashNewsType: FlashNewsType.public,
                      trySearch: false,
                      isBookmarked: state.bookmarks.contains(flashNews.id),
                      onClicked: () {
                        Navigator.pushNamed(
                          context,
                          FlashNewsDetailsView.routeName,
                          arguments: [
                            MainFlashNews(flashNews: flashNews),
                            true
                          ],
                        );
                      },
                    );
                  },
                  itemCount: state.flashNews.length,
                );
              }
            }
          }
        },
      ),
    );
  }
}
