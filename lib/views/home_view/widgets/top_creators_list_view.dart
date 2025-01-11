import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/home_cubit/home_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/models/top_curator_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/profile_view/profile_view.dart';
import 'package:yakihonne/views/widgets/place_holders.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

import '../../../nostr/nips/nips.dart';

class TopCreatorsListView extends StatelessWidget {
  const TopCreatorsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) =>
          previous.content != current.content ||
          previous.rebuildRelays != current.rebuildRelays,
      builder: (context, state) {
        return Scrollbar(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
                ? getTabletTopCreators(context, state)
                : getMobileTopCreators(context, state),
          ),
        );
      },
    );
  }

  Widget getTabletTopCreators(BuildContext context, HomeState state) {
    return state.isRelaysLoading
        ? ListView(
            children: [
              SkeletonSelector(
                placeHolderWidget: HomeProfileSkeleton(),
              ),
            ],
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: kDefaultPadding / 2),
                child: Text(
                  state.chosenRelay.isEmpty
                      ? '(in all relays)'
                      : '(in ${state.chosenRelay})',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: context.read<ThemeCubit>().state.theme ==
                                AppTheme.purpleWhite
                            ? kPurple
                            : Colors.purpleAccent,
                      ),
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Expanded(
                child: MasonryGridView.count(
                  crossAxisCount: 2,
                  itemCount: state.topCreators.length,
                  padding:
                      const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                  crossAxisSpacing: kDefaultPadding,
                  itemBuilder: (context, index) {
                    final creator = state.topCreators[index];
                    final author = state.authors[creator.pubKey] ??
                        emptyUserModel.copyWith(
                          name: creator.pubKey.nineCharacters(),
                          pubKey: creator.pubKey,
                          picturePlaceholder: getRandomPlaceholder(
                            input: creator.pubKey,
                            isPfp: true,
                          ),
                        );

                    return CreatorCard(
                      author: author,
                      creator: creator,
                      padding: 0,
                    );
                  },
                ),
              ),
            ],
          );
  }

  Widget getMobileTopCreators(BuildContext context, HomeState state) {
    return state.isRelaysLoading
        ? ListView(
            children: [
              SkeletonSelector(
                placeHolderWidget: HomeProfileSkeleton(),
              ),
            ],
          )
        : CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(
                  bottom: kDefaultPadding,
                  top: kDefaultPadding,
                ),
                sliver: SliverList.builder(
                  itemCount: state.topCreators.length,
                  itemBuilder: (context, index) {
                    final creator = state.topCreators[index];
                    final author = state.authors[creator.pubKey] ??
                        emptyUserModel.copyWith(
                          name: creator.pubKey.nineCharacters(),
                          pubKey: creator.pubKey,
                          picturePlaceholder: getRandomPlaceholder(
                            input: creator.pubKey,
                            isPfp: true,
                          ),
                        );

                    return CreatorCard(
                      author: author,
                      creator: creator,
                    );
                  },
                ),
              ),
            ],
          );
  }
}

class CreatorCard extends StatelessWidget {
  const CreatorCard({
    super.key,
    required this.author,
    required this.creator,
    this.padding,
  });

  final UserModel author;
  final TopCreatorModel creator;
  final double? padding;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onNavigate(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColorLight,
          borderRadius: BorderRadius.circular(kDefaultPadding),
        ),
        margin: EdgeInsets.symmetric(
          vertical: kDefaultPadding / 4,
          horizontal: padding ?? kDefaultPadding,
        ),
        child: Row(
          children: [
            ProfilePicture2(
              size: 50,
              image: author.picture,
              placeHolder: author.picturePlaceholder,
              padding: 0,
              strokeWidth: 1,
              strokeColor: Theme.of(context).primaryColorDark,
              onClicked: () => onNavigate(context),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.name.trim().isEmpty
                        ? Nip19.encodePubkey(
                            author.pubKey,
                          ).nineCharacters()
                        : author.name.trim(),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: Theme.of(context).primaryColorDark,
                        ),
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 4,
                  ),
                  RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: creator.articles.length
                              .toString()
                              .padLeft(2, '0'),
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium!
                              .copyWith(
                                color: context.read<ThemeCubit>().state.theme ==
                                        AppTheme.purpleWhite
                                    ? kPurple
                                    : Colors.purpleAccent,
                              ),
                        ),
                        TextSpan(
                          text: ' articles',
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: Theme.of(context).primaryColorDark,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onNavigate(BuildContext context) {
    Navigator.pushNamed(
      context,
      ProfileView.routeName,
      arguments: author.pubKey,
    );
  }
}
