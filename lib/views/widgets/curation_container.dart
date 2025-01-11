// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/models/curation_model.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/nostr/nips/nips.dart';
import 'package:yakihonne/utils/botToast_util.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/widgets/muted_mark.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

import 'buttons_containers_widgets.dart';

class CurationContainer extends HookWidget {
  const CurationContainer({
    required this.curation,
    required this.onClicked,
    required this.padding,
    required this.isBookmarked,
    required this.userStatus,
    this.isMuted,
  });

  final Curation curation;
  final bool? isMuted;
  final Function() onClicked;
  final double padding;
  final bool isBookmarked;
  final UserStatus userStatus;

  @override
  Widget build(BuildContext context) {
    final isShrinked = useState(true);

    return Stack(
      children: [
        CurationPlaceHolder(),
        Positioned.fill(
          child: GestureDetector(
            onTap: onClicked,
            child: FadeInUp(
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: padding,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) =>
                            curation.image.isEmpty
                                ? NoMediaPlaceHolder(
                                    isError: true,
                                    image: curation.placeHolder,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: curation.image,
                                    imageBuilder: (context, imageProvider) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            kDefaultPadding + 10,
                                          ),
                                          image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                    placeholder: (context, url) =>
                                        NoMediaPlaceHolder(
                                      isError: false,
                                      image: '',
                                    ),
                                    errorWidget: (context, url, error) =>
                                        NoMediaPlaceHolder(
                                      isError: true,
                                      image: curation.placeHolder,
                                    ),
                                  ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      top: isShrinked.value ? null : 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kBlack.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(
                            kDefaultPadding + 5,
                          ),
                          border: Border.all(
                            color: kLightGrey.withValues(alpha: 0.5),
                            width: 0.5,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                        width: double.infinity,
                        padding: const EdgeInsets.all(kDefaultPadding / 1.5),
                        margin: const EdgeInsets.all(kDefaultPadding / 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BlocSelector<AuthorsCubit, AuthorsState,
                                UserModel?>(
                              selector: (state) =>
                                  state.authors[curation.pubKey],
                              builder: (context, user) {
                                final author = user ??
                                    emptyUserModel.copyWith(
                                      pubKey: curation.pubKey,
                                      picturePlaceholder: getRandomPlaceholder(
                                        input: curation.pubKey,
                                        isPfp: true,
                                      ),
                                    );

                                return Row(
                                  children: [
                                    ProfilePicture2(
                                      size: 35,
                                      image: author.picture,
                                      placeHolder: author.picturePlaceholder,
                                      padding: 0,
                                      strokeWidth: 1,
                                      reduceSize: true,
                                      strokeColor: kWhite,
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
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          RichText(
                                            overflow: TextOverflow.ellipsis,
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: 'Posted by ',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall!
                                                      .copyWith(
                                                        color: kWhite,
                                                      ),
                                                ),
                                                TextSpan(
                                                  text: author.name.isEmpty
                                                      ? Nip19.encodePubkey(
                                                          curation.pubKey,
                                                        ).substring(0, 10)
                                                      : author.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall!
                                                      .copyWith(
                                                        color: kGreen,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              DateRow(
                                                createdAt: curation.createdAt,
                                                publishedAt:
                                                    curation.publishedAt,
                                                color: kWhite,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                ),
                                                child: DotContainer(
                                                  color: kWhite,
                                                  size: 3,
                                                  isNotMarging: true,
                                                ),
                                              ),
                                              Text(
                                                '${curation.eventsIds.length.toString().padLeft(2, '0')} ${curation.isArticleCuration() ? 'arts' : 'vids'}.',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall!
                                                    .copyWith(
                                                      color: kLightGrey,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 35,
                                      height: 35,
                                      child: IconButton(
                                        onPressed: () {
                                          isShrinked.value = !isShrinked.value;
                                        },
                                        style: IconButton.styleFrom(
                                          padding: const EdgeInsets.all(0),
                                        ),
                                        icon: RotatedBox(
                                          quarterTurns:
                                              isShrinked.value ? 0 : 2,
                                          child: Icon(
                                            Icons.keyboard_arrow_up_sharp,
                                            color: kDimGrey,
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                );
                              },
                            ),
                            if (!isShrinked.value)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    height: kDefaultPadding / 2,
                                  ),
                                  Text(
                                    curation.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium!
                                        .copyWith(
                                          color: kLightGrey,
                                          fontWeight: FontWeight.w800,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.left,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(
                                    height: kDefaultPadding / 2,
                                  ),
                                  Text(
                                    curation.description.trim(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(
                                          color: kLightGrey,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.left,
                                    maxLines: 3,
                                  )
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: kDefaultPadding / 2,
                      right: kDefaultPadding / 2,
                      child: Visibility(
                        visible: isShrinked.value,
                        child: Column(
                          children: [
                            if (userStatus == UserStatus.UsingPrivKey)
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      BotToastUtils.showInformation(
                                        'This curation contains ${curation.isArticleCuration() ? 'articles' : 'videos'}',
                                      );
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColorLight,
                                      visualDensity: VisualDensity(
                                        horizontal: -1,
                                        vertical: -1,
                                      ),
                                    ),
                                    icon: Text(
                                      curation.isArticleCuration()
                                          ? 'Articles'
                                          : 'Videos',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        elevation: 0,
                                        builder: (_) {
                                          return AddBookmarkView(
                                            kind: EventKind.CURATION_ARTICLES,
                                            identifier: curation.identifier,
                                            eventPubkey: curation.pubKey,
                                            image: curation.image,
                                          );
                                        },
                                        isScrollControlled: true,
                                        useRootNavigator: true,
                                        useSafeArea: true,
                                        backgroundColor: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                      );
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColorLight,
                                    ),
                                    icon: BlocBuilder<ThemeCubit, ThemeState>(
                                      builder: (context, state) {
                                        final isDark =
                                            state.theme == AppTheme.purpleDark;

                                        return SvgPicture.asset(
                                          isBookmarked
                                              ? isDark
                                                  ? FeatureIcons
                                                      .bookmarkFilledWhite
                                                  : FeatureIcons
                                                      .bookmarkFilledBlack
                                              : isDark
                                                  ? FeatureIcons
                                                      .bookmarkEmptyWhite
                                                  : FeatureIcons
                                                      .bookmarkEmptyBlack,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            if (isMuted != null && isMuted!)
                              MutedMark(kind: 'curation'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DateRow extends StatelessWidget {
  const DateRow({
    Key? key,
    required this.publishedAt,
    required this.createdAt,
    required this.color,
  }) : super(key: key);

  final DateTime publishedAt;
  final DateTime createdAt;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'created at ${dateFormat2.format(publishedAt)}, edited on ${dateFormat2.format(createdAt)}',
      textStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
      triggerMode: TooltipTriggerMode.tap,
      child: Text(
        '${dateFormat3.format(
          publishedAt,
        )}',
        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: color),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

class NoMediaPlaceHolder extends StatelessWidget {
  const NoMediaPlaceHolder({
    Key? key,
    this.isRound,
    this.value,
    this.isTopRounded,
    required this.isError,
    required this.image,
  }) : super(key: key);

  final bool? isRound;
  final bool? isTopRounded;
  final double? value;
  final bool isError;
  final String image;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        decoration: BoxDecoration(
          borderRadius: isTopRounded != null
              ? BorderRadius.only(
                  topLeft: Radius.circular(kDefaultPadding),
                  topRight: Radius.circular(kDefaultPadding),
                )
              : BorderRadius.circular(
                  isRound != null
                      ? isRound!
                          ? value ?? 300
                          : 0
                      : kDefaultPadding,
                ),
          image: DecorationImage(
            image: AssetImage(
              isError
                  ? image.isEmpty
                      ? randomCovers.first
                      : image
                  : Images.invalidMedia,
            ),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class NoImagePlaceHolder extends StatelessWidget {
  const NoImagePlaceHolder({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          gradient: LinearGradient(
            colors: [
              Color(0xffED213A),
              Color(0xff93291E),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            child: SvgPicture.asset(
              FeatureIcons.forbidden,
              colorFilter: ColorFilter.mode(kWhite, BlendMode.srcIn),
              width: 30,
              height: 30,
            ),
          ),
        ),
      ),
    );
  }
}

class NoImage2PlaceHolder extends StatelessWidget {
  const NoImage2PlaceHolder({
    Key? key,
    required this.icon,
  }) : super(key: key);

  final String icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            child: SvgPicture.asset(
              icon,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
              width: 30,
              height: 30,
            ),
          ),
        ),
      ),
    );
  }
}

class ImageLoadingPlaceHolder extends StatelessWidget {
  const ImageLoadingPlaceHolder({
    Key? key,
    this.round,
  }) : super(key: key);

  final double? round;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          gradient: LinearGradient(
            colors: [
              Color(0xffD66D75),
              Color(0xffE29587),
            ],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: kWhite,
            ),
          ),
        ),
      ),
    );
  }
}

class NoThumbnailPlaceHolder extends StatelessWidget {
  const NoThumbnailPlaceHolder({
    Key? key,
    this.isRound,
    this.value,
    this.isTopRounded,
    this.isRightRounded,
    this.isMonoColor,
    required this.isError,
    required this.icon,
  }) : super(key: key);

  final bool? isRound;
  final bool? isTopRounded;
  final bool? isRightRounded;
  final double? value;
  final String? icon;
  final bool? isMonoColor;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: isTopRounded != null
            ? BorderRadius.only(
                topLeft: Radius.circular(kDefaultPadding),
                topRight: Radius.circular(kDefaultPadding),
              )
            : isRightRounded != null
                ? BorderRadius.only(
                    bottomRight: Radius.circular(kDefaultPadding),
                    topRight: Radius.circular(kDefaultPadding),
                  )
                : BorderRadius.circular(
                    isRound != null
                        ? isRound!
                            ? value ?? 300
                            : 0
                        : kDefaultPadding,
                  ),
        gradient: isMonoColor == null
            ? LinearGradient(
                colors: [
                  Color(0xff8E2DE2),
                  Color(0xff4B1248),
                ],
              )
            : null,
        color: isMonoColor != null ? kDimGrey2 : null,
      ),
      child: Center(
        child: SvgPicture.asset(
          icon != null && icon!.isNotEmpty ? icon! : LogosIcons.logoMarkWhite,
          colorFilter: ColorFilter.mode(kWhite, BlendMode.srcIn),
          width: 35,
          height: 35,
        ),
      ),
    );
  }
}

class HomeCurationPlaceHolder extends StatelessWidget {
  HomeCurationPlaceHolder({
    super.key,
    this.color,
  });

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding + 5),
        color: color,
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 130,
          ),
        ],
      ),
    );
  }
}

class CurationPlaceHolder extends StatelessWidget {
  CurationPlaceHolder({
    super.key,
    this.color,
  });

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: kDefaultPadding,
        horizontal: kDefaultPadding / 4,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(kDefaultPadding / 1.5),
        margin: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding + 5),
          color: color,
        ),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 35,
            ),
            SizedBox(
              width: double.infinity,
              height: 16,
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            SizedBox(
              width: double.infinity,
              height: 32,
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
            ),
          ],
        ),
      ),
    );
  }
}
