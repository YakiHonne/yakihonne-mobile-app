// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/profile_cubit/profile_cubit.dart';
import 'package:yakihonne/blocs/profile_cubit/profile_follow_authors_cubit/profile_follow_authors_cubit.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/loading_indicators.dart';
import 'package:yakihonne/views/widgets/user_profile_container.dart';

class ProfileFollowAuthorsView extends StatelessWidget {
  const ProfileFollowAuthorsView({
    super.key,
    required this.followers,
    required this.followings,
  });

  final Set<String> followers;
  final Set<String> followings;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileFollowAuthorsCubit(
        nostrRepository: context.read<NostrDataRepository>(),
      )..initView(
          followings: followings.toList(),
          followers: followers.toList(),
        ),
      child: BlocListener<ProfileCubit, ProfileState>(
        listenWhen: (previous, current) =>
            previous.followers != current.followers ||
            previous.followings != current.followings,
        listener: (context, state) {
          context.read<ProfileFollowAuthorsCubit>().initView(
                followings: state.followings.toList(),
                followers: state.followers.toList(),
              );
        },
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.60,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, controller) => Column(
                children: [
                  ModalBottomSheetHandle(),
                  AppBar(
                    elevation: 3,
                    automaticallyImplyLeading: false,
                    centerTitle: true,
                    title: BlocBuilder<ProfileFollowAuthorsCubit,
                        ProfileFollowAuthorsState>(
                      buildWhen: (previous, current) =>
                          previous.isFollowers != current.isFollowers,
                      builder: (context, state) {
                        return CustomToggleButton(
                          state: state.isFollowers,
                          firstText: 'followers',
                          secondText: 'followings',
                          onClicked: () async {
                            context
                                .read<ProfileFollowAuthorsCubit>()
                                .toggleFollowers();
                          },
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<ProfileFollowAuthorsCubit,
                        ProfileFollowAuthorsState>(
                      buildWhen: (previous, current) =>
                          previous.isFollowers != current.isFollowers ||
                          previous.isFollowersLoading !=
                              current.isFollowersLoading ||
                          previous.isFollowingLoading !=
                              current.isFollowingLoading,
                      builder: (context, state) {
                        return getView(
                          (state.isFollowers && state.isFollowersLoading) ||
                              (!state.isFollowers && state.isFollowingLoading),
                          controller,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getView(
    bool isLoading,
    ScrollController controller,
  ) {
    if (isLoading) {
      return Center(
        child: LoadingWidget(),
      );
    } else {
      return FollowList(
        controller: controller,
      );
    }
  }
}

class CustomToggleButton extends StatelessWidget {
  const CustomToggleButton({
    Key? key,
    required this.state,
    required this.firstText,
    required this.secondText,
    required this.onClicked,
  }) : super(key: key);

  final bool state;
  final String firstText;
  final String secondText;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: 200,
        height: 30,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  kDefaultPadding * 2,
                ),
                color: Theme.of(context).shadowColor,
              ),
            ),
            AnimatedPositioned(
              right: state ? 100 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                height: 30,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    kDefaultPadding * 2,
                  ),
                  color: kPurple,
                ),
              ),
            ),
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      firstText,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: state
                                ? kWhite
                                : Theme.of(context).primaryColorDark,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      secondText,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: !state
                                ? kWhite
                                : Theme.of(context).primaryColorDark,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FollowList extends StatelessWidget {
  const FollowList({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileFollowAuthorsCubit, ProfileFollowAuthorsState>(
      buildWhen: (previous, current) =>
          previous.isFollowers != current.isFollowers ||
          previous.followers != current.followers ||
          previous.followings != current.followings ||
          previous.ownFollowings != current.ownFollowings ||
          previous.isValidUser != current.isValidUser ||
          previous.pendings != current.pendings,
      builder: (context, state) {
        if ((state.isFollowers && state.followers.isEmpty) ||
            (!state.isFollowers && state.followings.isEmpty)) {
          return Center(
            child: EmptyList(
              description:
                  'No ${state.isFollowers ? 'followers' : 'followings'} were found for this user',
              icon: FeatureIcons.user,
            ),
          );
        } else {
          return Scrollbar(
            controller: controller,
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.all(kDefaultPadding / 2),
              itemBuilder: (context, index) {
                final author = state.isFollowers
                    ? state.followers.entries.elementAt(index).value
                    : state.followings.entries.elementAt(index).value;

                final isFollowing = state.ownFollowings.contains(author.pubKey);
                final isSameUser = state.currentUserPubKey == author.pubKey;

                return FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: UserProfileContainer(
                    author: author,
                    zaps: 0,
                    currentUserPubKey: state.currentUserPubKey,
                    isFollowing: isFollowing,
                    isDisabled: !state.isValidUser || isSameUser,
                    isPending: state.pendings.contains(author.pubKey),
                    onClicked: () {
                      context
                          .read<ProfileFollowAuthorsCubit>()
                          .setFollowingOnStop(author.pubKey);
                    },
                  ),
                );
              },
              itemCount: state.isFollowers
                  ? state.followers.length
                  : state.followings.length,
            ),
          );
        }
      },
    );
  }
}
