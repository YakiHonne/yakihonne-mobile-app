// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/dms_cubit/dms_cubit.dart';
import 'package:yakihonne/blocs/profile_cubit/profile_fast_access_cubit/profile_fast_access_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/dm_view/widgets/dm_details.dart';
import 'package:yakihonne/views/main_view/widgets/profile_share_view.dart';
import 'package:yakihonne/views/profile_view/profile_view.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/zap_view/set_zaps_view.dart';

class ProfileFastAccess extends HookWidget {
  const ProfileFastAccess({
    Key? key,
    required this.pubkey,
  }) : super(key: key);

  final String pubkey;

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      authorsCubit.getAuthor(pubkey);
    });

    return BlocProvider(
      create: (context) => ProfileFastAccessCubit(pubkey: pubkey),
      child: BlocBuilder<AuthorsCubit, AuthorsState>(
        builder: (context, authorState) {
          final user = authorState.authors[pubkey] ?? emptyUserModel.copyWith();

          return Material(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ModalBottomSheetHandle(),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    Column(
                      children: [
                        Center(
                          child: ProfilePicture2(
                            size: 90,
                            image: user.picture.isEmpty
                                ? profileImages.first
                                : user.picture,
                            placeHolder: getRandomPlaceholder(
                                input: user.pubKey, isPfp: true),
                            padding: 0,
                            strokeWidth: 0,
                            strokeColor: kTransparent,
                            onClicked: () {},
                          ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                        Center(
                          child: Text(
                            getAuthorDisplayName(user),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Center(
                          child: BlocBuilder<AuthorsCubit, AuthorsState>(
                            builder: (context, authState) {
                              final decodedPubkey = user.pubKey;
                              final author = authState.authors[decodedPubkey];

                              final nip05 = author?.nip05 ?? '';

                              if (nip05.isNotEmpty) {
                                return Column(
                                  children: [
                                    SizedBox(
                                      height: kDefaultPadding / 2,
                                    ),
                                    AdditionalInformationRow(
                                      icon: FeatureIcons.nip05,
                                      text: nip05,
                                      onClick: () {},
                                    ),
                                  ],
                                );
                              } else {
                                return SizedBox.shrink();
                              }
                            },
                          ),
                        ),
                        if (user.website.isNotEmpty) ...[
                          const SizedBox(
                            height: kDefaultPadding / 2,
                          ),
                          Center(
                            child: AdditionalInformationRow(
                              icon: FeatureIcons.link,
                              text: user.website,
                              onClick: () {
                                openWebPage(url: user.website);
                              },
                            ),
                          ),
                        ],
                        BlocBuilder<ProfileFastAccessCubit,
                            ProfileFastAccessState>(
                          builder: (context, state) {
                            if (state.followers.isNotEmpty) {
                              return Column(
                                children: [
                                  const SizedBox(
                                    height: kDefaultPadding / 2,
                                  ),
                                  Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AdditionalInformationRow(
                                          icon: FeatureIcons.user,
                                          text:
                                              '${state.followers.length} Followers',
                                          onClick: () {},
                                        ),
                                        if (state.commonPubkeys.isNotEmpty) ...[
                                          DotContainer(color: kDimGrey),
                                          CommonUsersRow(
                                            commonPubkeys: state.commonPubkeys,
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return SizedBox.shrink();
                            }
                          },
                        ),
                        if (user.about.isNotEmpty) ...[
                          const SizedBox(
                            height: kDefaultPadding,
                          ),
                          Center(
                            child: Text(
                              user.about,
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BlocBuilder<ProfileFastAccessCubit,
                            ProfileFastAccessState>(
                          buildWhen: (previous, current) =>
                              previous.isFollowing != current.isFollowing,
                          builder: (context, state) {
                            return Builder(
                              builder: (context) {
                                final canBeFollowed = canUserBeFollowed(user);

                                return AbsorbPointer(
                                  absorbing: !canBeFollowed,
                                  child: NewBorderedIconButton(
                                    onClicked: () {
                                      if (canBeFollowed) {
                                        context
                                            .read<ProfileFastAccessCubit>()
                                            .setFollowingState();
                                      }
                                    },
                                    icon: state.isFollowing
                                        ? FeatureIcons.userFollowed
                                        : FeatureIcons.userToFollow,
                                    buttonStatus: !canBeFollowed
                                        ? ButtonStatus.disabled
                                        : state.isFollowing
                                            ? ButtonStatus.active
                                            : ButtonStatus.inactive,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        Builder(
                          builder: (context) {
                            final canBeZapped = canUserBeZapped(user);

                            return AbsorbPointer(
                              absorbing: !canBeZapped,
                              child: NewBorderedIconButton(
                                onClicked: () {
                                  lightningZapsCubit.resetInvoice();

                                  showModalBottomSheet(
                                    context: context,
                                    elevation: 0,
                                    builder: (_) {
                                      return SetZapsView(
                                        author: user,
                                        isZapSplit: false,
                                        zapSplits: [],
                                      );
                                    },
                                    isScrollControlled: true,
                                    useRootNavigator: true,
                                    useSafeArea: true,
                                    backgroundColor: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                  );
                                },
                                icon: FeatureIcons.zaps,
                                buttonStatus: !canBeZapped
                                    ? ButtonStatus.disabled
                                    : ButtonStatus.inactive,
                              ),
                            );
                          },
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        if (isUsingPrivatekey()) ...[
                          NewBorderedIconButton(
                            onClicked: () {
                              context.read<DmsCubit>().updateReadedTime(
                                    user.pubKey,
                                  );
                              Navigator.pushNamed(
                                context,
                                DmDetails.routeName,
                                arguments: [
                                  user.pubKey,
                                ],
                              );
                            },
                            icon: FeatureIcons.startDms,
                            buttonStatus: ButtonStatus.inactive,
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 4,
                          ),
                        ],
                        NewBorderedIconButton(
                          onClicked: () {
                            Navigator.push(
                              context,
                              createViewFromBottom(
                                ProfileShareView(
                                  userModel: user,
                                ),
                              ),
                            );
                          },
                          icon: '',
                          iconData: CupertinoIcons.qrcode,
                          buttonStatus: ButtonStatus.inactive,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);

                                Navigator.pushNamed(
                                  context,
                                  ProfileView.routeName,
                                  arguments: user.pubKey,
                                );
                              },
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).primaryColorLight,
                              ),
                              icon: Text(
                                'Visit profile',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(
                                      color: Theme.of(context).primaryColorDark,
                                    ),
                              ),
                              label: Icon(
                                Icons.arrow_outward_rounded,
                                size: 20,
                                color: Theme.of(context).primaryColorDark,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: kDefaultPadding / 4,
                          ),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                  new ClipboardData(
                                    text: Nip19.encodePubkey(pubkey),
                                  ),
                                );

                                BotToastUtils.showSuccess(
                                  'npub was copied! 👏',
                                );
                              },
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).primaryColorLight,
                              ),
                              icon: Text(
                                'Copy npub',
                                style: Theme.of(context).textTheme.labelLarge!,
                              ),
                              label: SvgPicture.asset(
                                FeatureIcons.copy,
                                width: 15,
                                height: 15,
                                colorFilter: ColorFilter.mode(
                                  Theme.of(context).primaryColorDark,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding * 1.5,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CommonUsersRow extends StatelessWidget {
  const CommonUsersRow({
    Key? key,
    required this.commonPubkeys,
  }) : super(key: key);

  final Set<String> commonPubkeys;

  @override
  Widget build(BuildContext context) {
    return commonPubkeys.isEmpty
        ? Text('Not followed by anyone you follow.')
        : BlocBuilder<AuthorsCubit, AuthorsState>(
            builder: (context, state) {
              List<UserModel> usersToBeShown = [];
              final max = commonPubkeys.length >= 3 ? 3 : commonPubkeys.length;
              List<Widget> images = [];

              for (int i = 0; i < max; i++) {
                final pubkey = commonPubkeys.elementAt(i);

                final user = state.authors[pubkey] ??
                    emptyUserModel.copyWith(
                      pubKey: pubkey,
                      picturePlaceholder:
                          getRandomPlaceholder(input: pubkey, isPfp: true),
                    );

                usersToBeShown.add(user);

                images.add(
                  ProfilePicture2(
                    size: 30,
                    image: user.picture.isEmpty
                        ? profileImages.first
                        : user.picture,
                    placeHolder:
                        getRandomPlaceholder(input: user.pubKey, isPfp: true),
                    padding: 0,
                    strokeWidth: 2,
                    strokeColor: Theme.of(context).primaryColorLight,
                    onClicked: () {},
                  ),
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 30,
                        width: 30 + (images.length - 1) * 15,
                      ),
                      ...images.reversed
                          .map(
                            (e) => Positioned(
                              left: images.indexOf(e) * 15,
                              child: e,
                            ),
                          )
                          .toList(),
                    ],
                  ),
                  if (usersToBeShown.length < commonPubkeys.length) ...[
                    const SizedBox(
                      width: kDefaultPadding / 4,
                    ),
                    Text(
                      '+ ${commonPubkeys.length - usersToBeShown.length} mutual(s)',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: kDimGrey,
                          ),
                    ),
                  ] else ...[
                    const SizedBox(
                      width: kDefaultPadding / 4,
                    ),
                    Text(
                      'mutual(s)',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: kDimGrey,
                          ),
                    ),
                  ],
                ],
              );
            },
          );
  }
}

class AdditionalInformationRow extends StatelessWidget {
  const AdditionalInformationRow({
    Key? key,
    required this.icon,
    required this.text,
    required this.onClick,
  }) : super(key: key);

  final String icon;
  final String text;
  final Function() onClick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.translucent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            icon,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleSmall!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
