// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:numeral/numeral.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class UserProfileContainer extends StatelessWidget {
  const UserProfileContainer({
    super.key,
    required this.author,
    required this.currentUserPubKey,
    required this.isFollowing,
    required this.isDisabled,
    required this.onClicked,
    required this.zaps,
    required this.isPending,
  });

  final UserModel author;
  final String currentUserPubKey;
  final bool isFollowing;
  final bool isDisabled;
  final bool isPending;
  final num zaps;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    final npub = author.pubKey;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: kDefaultPadding / 1.5,
        horizontal:
            ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 10.w : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProfilePicture2(
            size: 35,
            image: author.picture,
            placeHolder: author.picturePlaceholder,
            padding: 0,
            strokeWidth: 2,
            strokeColor: kPurple,
            onClicked: () {
              openProfileFastAccess(
                context: context,
                pubkey: author.pubKey,
              );
            },
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.name.trim().isEmpty
                            ? Nip19.encodePubkey(npub).nineCharacters()
                            : author.name.trim(),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 4,
                      ),
                      PubKeyContainer(
                        pubKey: npub,
                      ),
                    ],
                  ),
                ),
                if (zaps != 0) ...[
                  SvgPicture.asset(
                    FeatureIcons.zap,
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
                  Text(
                    Numeral(zaps).toString(),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          NewBorderedIconButton(
            onClicked: onClicked,
            icon: isPending && isFollowing
                ? FeatureIcons.userToUnfollow
                : isFollowing
                    ? FeatureIcons.userFollowed
                    : FeatureIcons.userToFollow,
            buttonStatus: isDisabled
                ? ButtonStatus.disabled
                : isPending
                    ? ButtonStatus.loading
                    : isFollowing
                        ? ButtonStatus.active
                        : ButtonStatus.inactive,
          ),
        ],
      ),
    );
  }
}

class UserNoteStatContainer extends StatelessWidget {
  const UserNoteStatContainer({
    Key? key,
    required this.author,
    required this.currentUserPubKey,
    required this.isFollowing,
    required this.isDisabled,
    required this.isPending,
    required this.event,
    required this.onClicked,
  }) : super(key: key);

  final UserModel author;
  final String currentUserPubKey;
  final bool isFollowing;
  final bool isDisabled;
  final bool isPending;
  final Event event;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    final npub = author.pubKey;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: kDefaultPadding / 1.5,
        horizontal:
            ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 10.w : 0,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (event.kind == EventKind.REACTION)
              if (event.content == '+' ||
                  event.content.isEmpty ||
                  event.content.length > 2)
                SvgPicture.asset(
                  FeatureIcons.heartFilled,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                )
              else
                SizedBox(
                  height: 22,
                  width: 22,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: Text(
                      event.content.trim(),
                    ),
                  ),
                )
            else if (event.kind == EventKind.REPOST)
              SvgPicture.asset(
                FeatureIcons.refresh,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              )
            else
              SvgPicture.asset(
                FeatureIcons.quote,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            VerticalDivider(
              indent: kDefaultPadding / 2,
              endIndent: kDefaultPadding / 2,
            ),
            ProfilePicture2(
              size: 35,
              image: author.picture,
              placeHolder: author.picturePlaceholder,
              padding: 0,
              strokeWidth: 2,
              strokeColor: kPurple,
              onClicked: () {
                openProfileFastAccess(
                  context: context,
                  pubkey: author.pubKey,
                );
              },
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author.name.trim().isEmpty
                              ? Nip19.encodePubkey(npub).nineCharacters()
                              : author.name.trim(),
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(
                          height: kDefaultPadding / 4,
                        ),
                        PubKeyContainer(
                          pubKey: npub,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            NewBorderedIconButton(
              onClicked: onClicked,
              icon: isPending && isFollowing
                  ? FeatureIcons.userToUnfollow
                  : isFollowing
                      ? FeatureIcons.userFollowed
                      : FeatureIcons.userToFollow,
              buttonStatus: isDisabled
                  ? ButtonStatus.disabled
                  : isPending
                      ? ButtonStatus.loading
                      : isFollowing
                          ? ButtonStatus.active
                          : ButtonStatus.inactive,
            ),
          ],
        ),
      ),
    );
  }
}
