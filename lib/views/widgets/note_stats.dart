// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/users_info_list_cubit/users_info_list_cubit.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/nostr/event.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/note_view/note_view.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/loading_indicators.dart';
import 'package:yakihonne/views/widgets/user_profile_container.dart';

class NetStatsView extends HookWidget {
  const NetStatsView({
    Key? key,
    required this.events,
    required this.type,
  }) : super(key: key);

  final List<Event> events;
  final NoteStatType type;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UsersInfoListCubit(
        nostrRepository: context.read<NostrDataRepository>(),
      )..getAuthor(events.map((e) => e.pubkey).toList()),
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
                    type == NoteStatType.reaction
                        ? 'Reactions'
                        : type == NoteStatType.repost
                            ? 'Reposts'
                            : 'Quotes',
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
                        events,
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
    List<Event> events,
    ScrollController controller,
  ) {
    if (isLoading) {
      return Center(
        child: LoadingWidget(),
      );
    } else {
      return NoteUsersList(
        events: events,
        controller: controller,
      );
    }
  }
}

class NoteUsersList extends StatelessWidget {
  const NoteUsersList({
    Key? key,
    required this.events,
    required this.controller,
  }) : super(key: key);

  final List<Event> events;
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
              description: 'No users were found',
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
                      final event = events.firstWhere(
                          (element) => element.pubkey == author.pubKey);

                      return GestureDetector(
                        onTap: event.isQuote()
                            ? () {
                                Navigator.pushNamed(
                                  context,
                                  NoteView.routeName,
                                  arguments: DetailedNoteModel.fromEvent(event),
                                );
                              }
                            : null,
                        child: UserNoteStatContainer(
                          author: author,
                          currentUserPubKey: state.currentUserPubKey,
                          isFollowing: isFollowing,
                          isDisabled: !state.isValidUser || isSameUser,
                          event: event,
                          isPending: state.pendings.contains(author.pubKey),
                          onClicked: () {
                            context
                                .read<UsersInfoListCubit>()
                                .setFollowingOnStop(author.pubKey);
                          },
                        ),
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
