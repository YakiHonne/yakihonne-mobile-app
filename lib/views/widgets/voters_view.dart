// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/users_info_list_cubit/users_info_list_cubit.dart';
import 'package:yakihonne/models/vote_model.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/loading_indicators.dart';
import 'package:yakihonne/views/widgets/user_profile_container.dart';

class VotersView extends StatelessWidget {
  const VotersView({
    Key? key,
    required this.voters,
    required this.title,
  }) : super(key: key);

  final Map<String, VoteModel> voters;
  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UsersInfoListCubit(
        nostrRepository: context.read<NostrDataRepository>(),
      )..getAuthor(
          voters.keys.toList(),
        ),
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
                  title: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                  ),
                ),
                Expanded(
                  child: BlocBuilder<UsersInfoListCubit, UsersInfoListState>(
                    buildWhen: (previous, current) =>
                        previous.isLoading != current.isLoading,
                    builder: (context, state) {
                      return getView(
                        state.isLoading,
                        voters,
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
    );
  }

  Widget getView(
    bool isLoading,
    Map<String, VoteModel> voters,
    ScrollController controller,
  ) {
    if (isLoading) {
      return Center(
        child: LoadingWidget(),
      );
    } else {
      return VotersList(
        voters: voters,
        controller: controller,
      );
    }
  }
}

class VotersList extends StatelessWidget {
  const VotersList({
    Key? key,
    required this.voters,
    required this.controller,
  }) : super(key: key);

  final Map<String, VoteModel> voters;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersInfoListCubit, UsersInfoListState>(
      buildWhen: (previous, current) =>
          previous.zapAuthors != current.zapAuthors ||
          previous.currentUserPubKey != current.currentUserPubKey ||
          previous.mutes != current.mutes ||
          previous.pendings != current.pendings,
      builder: (context, state) {
        if (state.zapAuthors.isEmpty) {
          return Center(
            child: EmptyList(
              description: 'No zappers were found on this article',
              icon: FeatureIcons.user,
            ),
          );
        } else {
          return Scrollbar(
            controller: controller,
            child: ListView.builder(
              padding: const EdgeInsets.all(kDefaultPadding / 2),
              controller: controller,
              itemBuilder: (context, index) {
                final author = state.zapAuthors.entries.elementAt(index).value;

                if (state.mutes.contains(author.pubKey)) {
                  return SizedBox.shrink();
                }

                return FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: BlocBuilder<UsersInfoListCubit, UsersInfoListState>(
                    builder: (context, state) {
                      final isFollowing =
                          state.followings.contains(author.pubKey);
                      final isSameUser =
                          state.currentUserPubKey == author.pubKey;

                      return UserProfileContainer(
                        author: author,
                        currentUserPubKey: state.currentUserPubKey,
                        isFollowing: isFollowing,
                        isDisabled: !state.isValidUser || isSameUser,
                        zaps: 0,
                        isPending: state.pendings.contains(author.pubKey),
                        onClicked: () {
                          context
                              .read<UsersInfoListCubit>()
                              .setFollowingOnStop(author.pubKey);
                        },
                      );
                    },
                  ),
                );
              },
              itemCount: state.zapAuthors.length,
            ),
          );
        }
      },
    );
  }
}
