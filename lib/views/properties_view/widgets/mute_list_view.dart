// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/properties_cubit/mute_list_cubit/mute_list_cubit.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nips/nip_019.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/profile_view/profile_view.dart';
import 'package:yakihonne/views/widgets/article_thumbnail.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class MuteListView extends StatelessWidget {
  const MuteListView({super.key});

  static const routeName = '/mutelistView';
  static Route route() {
    return CupertinoPageRoute(
      builder: (_) => MuteListView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = !ResponsiveBreakpoints.of(context).isMobile;

    return BlocProvider(
      create: (context) => MuteListCubit(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Mute list',
        ),
        body: BlocBuilder<MuteListCubit, MuteListState>(
          builder: (context, state) {
            return getView(
              isEmpty: state.mutes.isEmpty,
              isTablet: isTablet,
            );
          },
        ),
      ),
    );
  }

  Widget getView({required isEmpty, required bool isTablet}) {
    if (isEmpty) {
      return EmptyList(
        description: 'No muted users have been found.',
        icon: FeatureIcons.mute,
      );
    } else if (isTablet) {
      return TabletMuteListView();
    } else {
      return MobileMuteListView();
    }
  }
}

class TabletMuteListView extends StatelessWidget {
  const TabletMuteListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MuteListCubit, MuteListState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: MasonryGridView.builder(
            itemCount: state.mutes.length,
            gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            mainAxisSpacing: kDefaultPadding / 2,
            crossAxisSpacing: kDefaultPadding / 2,
            itemBuilder: (context, index) {
              final pubkey = state.mutes[index];

              return MutedUserContainer(
                pubkey: pubkey,
                onUnmute: (name) {
                  final isMuted = state.mutes.contains(pubkey);

                  showCupertinoCustomDialogue(
                    context: context,
                    title: isMuted ? 'Unmute user' : 'Mute user',
                    description:
                        'You are about to ${isMuted ? 'unmute' : 'mute'} "${name}", do you wish to proceed?',
                    buttonText: isMuted ? 'Unmute' : 'Mute',
                    buttonTextColor: isMuted ? kGreen : kRed,
                    onClicked: () {
                      context.read<MuteListCubit>().setMuteStatus(
                            pubkey: pubkey,
                            onSuccess: () => Navigator.pop(context),
                          );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class MobileMuteListView extends StatelessWidget {
  const MobileMuteListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MuteListCubit, MuteListState>(
      builder: (context, state) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
            vertical: kDefaultPadding,
          ),
          separatorBuilder: (context, index) => const SizedBox(
            height: kDefaultPadding / 2,
          ),
          itemBuilder: (context, index) {
            final pubkey = state.mutes[index];

            return MutedUserContainer(
              pubkey: pubkey,
              onUnmute: (name) {
                final isMuted = state.mutes.contains(pubkey);

                showCupertinoCustomDialogue(
                  context: context,
                  title: isMuted ? 'Unmute user' : 'Mute user',
                  description:
                      'You are about to ${isMuted ? 'unmute' : 'mute'} "${name}", do you wish to proceed?',
                  buttonText: isMuted ? 'Unmute' : 'Mute',
                  buttonTextColor: isMuted ? kGreen : kRed,
                  onClicked: () {
                    context.read<MuteListCubit>().setMuteStatus(
                          pubkey: pubkey,
                          onSuccess: () => Navigator.pop(context),
                        );
                  },
                );
              },
            );
          },
          itemCount: state.mutes.length,
        );
      },
    );
  }
}

class MutedUserContainer extends StatelessWidget {
  const MutedUserContainer({
    Key? key,
    required this.pubkey,
    required this.onUnmute,
  }) : super(key: key);

  final String pubkey;
  final Function(String) onUnmute;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
      selector: (state) => state.authors[pubkey],
      builder: (context, user) {
        final author = user ??
            emptyUserModel.copyWith(
              pubKey: pubkey,
              picturePlaceholder:
                  getRandomPlaceholder(input: pubkey, isPfp: true),
            );

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              ProfileView.routeName,
              arguments: author.pubKey,
            );
          },
          behavior: HitTestBehavior.translucent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding + 5),
              color: Theme.of(context).primaryColorLight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(
                        bottom: kDefaultPadding,
                      ),
                      foregroundDecoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColorLight,
                            kTransparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: [
                            0.1,
                            0.5,
                          ],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(kDefaultPadding),
                          topRight: Radius.circular(kDefaultPadding),
                        ),
                        child: ArticleThumbnail(
                          image: author.banner,
                          placeholder: author.bannerPlaceholder,
                          width: double.infinity,
                          height: 70,
                          radius: 0,
                          isRound: false,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: kDefaultPadding / 2,
                          ),
                          child: ProfilePicture2(
                            size: 60,
                            image: author.picture,
                            placeHolder: author.picturePlaceholder,
                            padding: 0,
                            strokeWidth: 3,
                            strokeColor: Theme.of(context).primaryColorLight,
                            onClicked: () {},
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton.icon(
                          onPressed: () => onUnmute.call(author.name),
                          style: TextButton.styleFrom(
                            backgroundColor: kTransparent,
                            visualDensity: const VisualDensity(
                              horizontal: -4,
                              vertical: -4,
                            ),
                          ),
                          icon: SvgPicture.asset(
                            FeatureIcons.unmute,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).primaryColorDark,
                              BlendMode.srcIn,
                            ),
                          ),
                          label: Text(
                            'Unmute',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: kDefaultPadding,
                    left: kDefaultPadding,
                    right: kDefaultPadding,
                    top: kDefaultPadding / 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.name.trim().isEmpty
                            ? Nip19.encodePubkey(author.pubKey).substring(0, 10)
                            : author.name.trim(),
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (author.about.isNotEmpty) ...[
                        const SizedBox(
                          height: kDefaultPadding / 4,
                        ),
                        SelectableText(
                          author.about.trim(),
                          scrollPhysics: NeverScrollableScrollPhysics(),
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 3,
                        ),
                      ],
                    ],
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
