// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:numeral/numeral.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/smart_widget_components_models.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/self_smart_widgets_view/widgets/self_smart_widget_container.dart';
import 'package:yakihonne/views/smart_widgets_view/widgets/smart_widget_container.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/uncensored_note_component.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class ShareView extends StatefulWidget {
  final String image;
  final String placeholder;
  final String title;
  final String pubkey;
  final String kindText;
  final String icon;
  final String? description;
  final int? upvotes;
  final int? downvotes;
  final int? views;
  final Map<String, dynamic>? data;
  final Function() onShare;

  ShareView({
    Key? key,
    required this.image,
    required this.placeholder,
    required this.title,
    required this.pubkey,
    required this.kindText,
    required this.icon,
    this.description,
    this.upvotes,
    this.downvotes,
    this.views,
    this.data,
    required this.onShare,
  }) : super(key: key);

  @override
  State<ShareView> createState() => _ShareViewState();
}

class _ShareViewState extends State<ShareView> {
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 15.w : kDefaultPadding / 2,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(kDefaultPadding),
          topRight: Radius.circular(kDefaultPadding),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.40,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              ModalBottomSheetHandle(),
              Expanded(
                child: BlocBuilder<AuthorsCubit, AuthorsState>(
                  builder: (context, state) {
                    final author = state.authors[widget.pubkey] ??
                        emptyUserModel.copyWith(
                          pubKey: widget.pubkey,
                          picturePlaceholder: getRandomPlaceholder(
                            input: widget.pubkey,
                            isPfp: true,
                          ),
                        );

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding / 2,
                        horizontal: kDefaultPadding / 4,
                      ),
                      children: [
                        Text(
                          'Share content',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(
                          height: kDefaultPadding,
                        ),
                        if (widget.data!['kind'] == EventKind.TEXT_NOTE ||
                            widget.data!['kind'] == EventKind.SMART_WIDGET)
                          Screenshot(
                            controller: screenshotController,
                            child: ShareableFlashNews(
                              widget: widget,
                              author: author,
                              textContentType: widget.data!['textContentType'],
                              sealedNote: widget.data!['sealedNote'],
                              source: widget.data!['source'],
                              image: widget.data!['image'],
                              smartWidget: widget.data!['smartWidget'],
                            ),
                          )
                        else
                          Screenshot(
                            controller: screenshotController,
                            child: AspectRatio(
                              aspectRatio: 9 / 16,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColorLight,
                                  borderRadius: BorderRadius.circular(
                                    kDefaultPadding / 2,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: widget.image.isEmpty &&
                                              widget.placeholder.isEmpty
                                          ? Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  kDefaultPadding / 2,
                                                ),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Color(0xFF3c1053),
                                                    Color(0xFFad5389),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: widget.image,
                                              fit: BoxFit.cover,
                                              cacheManager: cacheManager,
                                              imageBuilder:
                                                  (context, imageProvider) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      kDefaultPadding / 2,
                                                    ),
                                                    border: Border.all(
                                                      color: Theme.of(context)
                                                          .primaryColorLight,
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
                                                isRound: true,
                                                image: '',
                                                isError: false,
                                                value: kDefaultPadding / 2,
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      NoMediaPlaceHolder(
                                                isRound: true,
                                                image: widget.placeholder,
                                                isError: true,
                                                value: kDefaultPadding / 2,
                                              ),
                                            ),
                                    ),
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          kDefaultPadding / 2,
                                        ),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 5,
                                            sigmaY: 5,
                                          ),
                                          child: Container(),
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: widget.kindText == 'Profile'
                                          ? ProfileContainer(
                                              widget: widget,
                                              author: author,
                                              nip05Validations:
                                                  state.nip05Validations,
                                            )
                                          : Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                horizontal: kDefaultPadding / 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: kWhite,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  kDefaultPadding / 2,
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                      kDefaultPadding / 2,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        SvgPicture.asset(
                                                          widget.icon,
                                                          width: 16,
                                                          height: 16,
                                                          colorFilter:
                                                              ColorFilter.mode(
                                                            kBlack,
                                                            BlendMode.srcIn,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width:
                                                              kDefaultPadding /
                                                                  4,
                                                        ),
                                                        Text(
                                                          widget.kindText,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .labelLarge!
                                                                  .copyWith(
                                                                    color:
                                                                        kBlack,
                                                                  ),
                                                        ),
                                                        Spacer(),
                                                        _screenshotRow(
                                                          context,
                                                          widget.upvotes
                                                              .toString(),
                                                          FeatureIcons.like,
                                                        ),
                                                        if (widget.downvotes !=
                                                            null) ...[
                                                          const SizedBox(
                                                            width:
                                                                kDefaultPadding /
                                                                    2,
                                                          ),
                                                          _screenshotRow(
                                                            context,
                                                            widget.downvotes
                                                                .toString(),
                                                            FeatureIcons
                                                                .dislike,
                                                          ),
                                                        ],
                                                        if (widget.views !=
                                                            null) ...[
                                                          const SizedBox(
                                                            width:
                                                                kDefaultPadding /
                                                                    2,
                                                          ),
                                                          _screenshotRow(
                                                            context,
                                                            widget.views
                                                                .toString(),
                                                            FeatureIcons
                                                                .visible,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  Divider(
                                                    height: 0,
                                                    thickness: 0.5,
                                                    color: kBlack,
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                      kDefaultPadding,
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          widget.title.trim(),
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .titleMedium!
                                                                  .copyWith(
                                                                    color:
                                                                        kBlack,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                  ),
                                                          textAlign:
                                                              TextAlign.center,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 3,
                                                        ),
                                                        if (widget.description !=
                                                                null &&
                                                            widget.description!
                                                                .isNotEmpty) ...[
                                                          const SizedBox(
                                                            height:
                                                                kDefaultPadding /
                                                                    2,
                                                          ),
                                                          Text(
                                                            widget.description!,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .labelSmall!
                                                                .copyWith(
                                                                  color:
                                                                      kDimGrey,
                                                                ),
                                                            textAlign: TextAlign
                                                                .center,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 3,
                                                          ),
                                                        ],
                                                        const SizedBox(
                                                          height:
                                                              kDefaultPadding /
                                                                  2,
                                                        ),
                                                        SizedBox(
                                                          width: 120,
                                                          height: 120,
                                                          child:
                                                              PrettyQrView.data(
                                                            data:
                                                                externalShearableLink(
                                                              kind:
                                                                  widget.data![
                                                                      'kind'],
                                                              pubkey:
                                                                  author.pubKey,
                                                              id: widget
                                                                  .data!['id'],
                                                            ),
                                                            decoration:
                                                                const PrettyQrDecoration(
                                                              shape:
                                                                  PrettyQrRoundedSymbol(
                                                                color: kBlack,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        if (author.nip05
                                                            .isNotEmpty) ...[
                                                          const SizedBox(
                                                            height:
                                                                kDefaultPadding /
                                                                    2,
                                                          ),
                                                          Text(
                                                            'yakihonne.com/users/${author.nip05}',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .labelSmall!
                                                                .copyWith(
                                                                  color:
                                                                      kPurple,
                                                                ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  Divider(
                                                    height: 0,
                                                    thickness: 0.5,
                                                    color: kBlack,
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                      kDefaultPadding / 2,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        ProfilePicture2(
                                                          size: 28,
                                                          image: author.picture,
                                                          placeHolder: author
                                                              .picturePlaceholder,
                                                          padding: 0,
                                                          strokeWidth: 1,
                                                          reduceSize: true,
                                                          strokeColor: kPurple,
                                                          onClicked: () {},
                                                        ),
                                                        const SizedBox(
                                                          width:
                                                              kDefaultPadding /
                                                                  4,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'By ',
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .labelSmall!
                                                                    .copyWith(
                                                                      color:
                                                                          kBlack,
                                                                    ),
                                                              ),
                                                              Text(
                                                                getAuthorName(
                                                                    author),
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .labelSmall!
                                                                    .copyWith(
                                                                      color:
                                                                          kPurple,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        SvgPicture.asset(
                                                          LogosIcons.logoBlack,
                                                          width: 75,
                                                          colorFilter:
                                                              ColorFilter.mode(
                                                            kBlack,
                                                            BlendMode.srcIn,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              SafeArea(
                child: SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButtonWithText(
                          onClicked: shareImage,
                          text: 'Share image',
                          icon: FeatureIcons.imageLink,
                        ),
                        IconButtonWithText(
                          onClicked: widget.onShare,
                          text: 'Share link',
                          icon: FeatureIcons.link,
                        ),
                        Builder(
                          builder: (context) {
                            return IconButtonWithText(
                              onClicked: () {
                                RenderBox? box;
                                if (ResponsiveBreakpoints.of(context)
                                    .largerThan(MOBILE)) {
                                  box =
                                      context.findRenderObject() as RenderBox?;
                                }

                                Share.share(
                                  createShareableLink(
                                    widget.data!['kind'],
                                    widget.pubkey,
                                    widget.data!['id'],
                                  ),
                                  subject:
                                      'Check out www.yakihonne.com for more content.',
                                  sharePositionOrigin: box != null
                                      ? box.localToGlobal(Offset.zero) &
                                          box.size
                                      : null,
                                );
                              },
                              text:
                                  'Share ${widget.data!['kind'] == EventKind.TEXT_NOTE ? 'note ID' : widget.data!['kind'] == EventKind.METADATA ? 'nprofile' : 'naddr'}',
                              icon: FeatureIcons.shareExternal,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Row _screenshotRow(
    BuildContext context,
    String value,
    String icon,
  ) {
    return Row(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: kBlack,
              ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        SvgPicture.asset(
          icon,
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(
            kBlack,
            BlendMode.srcIn,
          ),
        ),
      ],
    );
  }

  void shareImage() async {
    final _cancel = BotToast.showLoading();

    try {
      final temp = await getApplicationDocumentsDirectory();
      final img = await screenshotController.captureAndSave(temp.path);
      _cancel.call();

      if (img != null) {
        await Share.shareXFiles(
          [
            XFile(img),
          ],
          // text: externalShearableLink(
          //   kind: widget.data!['kind'],
          //   pubkey: widget.pubkey,
          //   id: widget.data!['id'] ?? '',
          // ),
        );
      }
    } catch (_) {
      _cancel.call();
    }
  }
}

class ProfileContainer extends StatelessWidget {
  const ProfileContainer({
    Key? key,
    required this.widget,
    required this.author,
    required this.nip05Validations,
  }) : super(key: key);

  final ShareView widget;
  final UserModel author;
  final Map<String, bool> nip05Validations;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final followings = widget.data!['followings']!;
        final followers = widget.data!['followers']!;

        return Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(
                left: kDefaultPadding * 1.5,
                right: kDefaultPadding * 1.5,
                top: 35,
              ),
              height: 430,
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(
                  kDefaultPadding / 2,
                ),
              ),
              padding: const EdgeInsets.all(
                kDefaultPadding / 2,
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: kDefaultPadding * 2,
                    width: double.infinity,
                  ),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: kBlack,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (widget.description != null &&
                      widget.description!.isNotEmpty) ...[
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    Text(
                      'Bio: ${widget.description!}',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall!.copyWith(
                            color: kDimGrey,
                          ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                  if (author.nip05.isNotEmpty) ...[
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${author.nip05}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: kPurple,
                                  ),
                        ),
                        if (nip05Validations[author.pubKey] ?? false) ...[
                          SizedBox(
                            width: kDefaultPadding / 4,
                          ),
                          SvgPicture.asset(
                            FeatureIcons.verified,
                            width: 15,
                            height: 15,
                            colorFilter: ColorFilter.mode(
                              kOrangeContrasted,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  Divider(
                    endIndent: kDefaultPadding,
                    indent: kDefaultPadding,
                    thickness: 0.5,
                    color: kDimGrey,
                    height: kDefaultPadding * 1.5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Followings',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  color: kDimGrey,
                                ),
                          ),
                          Text(
                            Numeral(followings).format(),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  color: kBlack,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Followers',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  color: kDimGrey,
                                ),
                          ),
                          Text(
                            Numeral(followers).format(),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  color: kBlack,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      )
                    ],
                  ),
                  Divider(
                    endIndent: kDefaultPadding,
                    indent: kDefaultPadding,
                    thickness: 0.5,
                    color: kDimGrey,
                    height: kDefaultPadding * 1.5,
                  ),
                  Builder(
                    builder: (context) {
                      final data = externalShearableLink(
                        kind: EventKind.METADATA,
                        pubkey: '',
                        id: author.pubKey,
                      );

                      return SizedBox(
                        width: 120,
                        height: 120,
                        child: PrettyQrView.data(
                          data: data,
                          decoration: const PrettyQrDecoration(
                            shape: PrettyQrRoundedSymbol(
                              color: kBlack,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  SvgPicture.asset(
                    LogosIcons.logoBlack,
                    width: 75,
                    colorFilter: ColorFilter.mode(
                      kBlack,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              child: Center(
                child: ProfilePicture2(
                  size: 70,
                  image: author.picture,
                  placeHolder: author.picturePlaceholder,
                  padding: 0,
                  strokeWidth: 3,
                  reduceSize: true,
                  strokeColor: kPurple,
                  onClicked: () {},
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ShareableFlashNews extends StatelessWidget {
  const ShareableFlashNews({
    Key? key,
    required this.textContentType,
    required this.widget,
    required this.author,
    this.sealedNote,
    this.source,
    this.image,
    this.smartWidget,
  }) : super(key: key);

  final TextContentType textContentType;
  final ShareView widget;
  final UserModel author;
  final SealedNote? sealedNote;
  final String? source;
  final String? image;
  final String? smartWidget;

  @override
  Widget build(BuildContext context) {
    final selectedGradient = textContentType == TextContentType.flashnews
        ? [
            Color(0xff6a3093),
            Color(0xffa044ff),
          ]
        : textContentType == TextContentType.uncensoredNote
            ? [
                Color(0xffDA4453),
                Color(0xff89216B),
              ]
            : textContentType == TextContentType.note
                ? [
                    Color(0xff8360c3),
                    Color(0xff2ebf91),
                  ]
                : textContentType == TextContentType.smartWidget
                    ? [
                        Color(0xffFF416C),
                        Color(0xffFF4B2B),
                      ]
                    : [
                        Color(0xffa8c0ff),
                        Color(0xff3f2b96),
                      ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(
              kDefaultPadding / 2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                  kDefaultPadding / 2,
                ),
                topRight: Radius.circular(
                  kDefaultPadding / 2,
                ),
              ),
              gradient: LinearGradient(
                colors: selectedGradient,
              ),
            ),
            child: SvgPicture.asset(
              LogosIcons.logoWhite,
              height: 50,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(
              kDefaultPadding / 2,
            ),
            child: linkifiedText(
              context: context,
              text: widget.title,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: kBlack,
                  ),
              isScreenshot: true,
            ),
          ),
          Builder(builder: (context) {
            final desc = widget.data!['description'] as String?;

            if (desc != null && desc.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                child: Column(
                  children: [
                    Text(
                      desc,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: Theme.of(context).primaryColorLight,
                          ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ],
                ),
              );
            } else {
              return SizedBox.shrink();
            }
          }),
          if (smartWidget != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
              ),
              child: Builder(
                builder: (context) {
                  final sm = SmartWidgetModel.fromJson(smartWidget!);
                  return sm.container == null
                      ? NoSmartWidgetContainer()
                      : AbsorbPointer(
                          absorbing: true,
                          child: SmartWidget(
                            smartWidgetContainer: sm.container!,
                          ),
                        );
                },
              ),
            ),
          if (image != null)
            CachedNetworkImage(
              imageUrl: image!,
              imageBuilder: (context, imageProvider) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  margin: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                );
              },
              errorWidget: (context, url, error) => NoMediaPlaceHolder(
                isError: true,
                image: Images.invalidMedia,
              ),
            ),
          if (author.nip05.isNotEmpty) ...[
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Text(
              'yakihonne.com/users/${author.nip05}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: kPurple,
                  ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
          if (textContentType == TextContentType.uncensoredNote) ...[
            if (sealedNote != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                child: UncensoredNoteComponent(
                  note: sealedNote!.uncensoredNote,
                  flashNewsPubkey: widget.pubkey,
                  userStatus: getUserStatus(),
                  isUncensoredNoteAuthor: false,
                  sealedNote: sealedNote,
                  isComponent: true,
                  isSealed: true,
                  sealDisable: false,
                  onDelete: (id) {},
                  onLike: () {},
                  onDislike: () {},
                ),
              )
            else
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  color: kDarkGrey,
                ),
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                child: Column(
                  children: [
                    Text(
                      'Earn SATs',
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.w600,
                            color: kGreen,
                          ),
                    ),
                    Divider(),
                    Text(
                      'Help us provide more decentralized insights to review this flash news.',
                      style: Theme.of(context).textTheme.bodyMedium!,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
          Stack(
            children: [
              SizedBox(
                height: 140,
                width: double.infinity,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(
                        kDefaultPadding / 2,
                      ),
                      child: Row(
                        children: [
                          ProfilePicture2(
                            size: 28,
                            image: source != null
                                ? nostrRepository
                                        .buzzFeedSources[source]?.icon ??
                                    ''
                                : author.picture,
                            placeHolder: author.picturePlaceholder,
                            padding: 0,
                            strokeWidth: 1,
                            reduceSize: true,
                            strokeColor: kPurple,
                            onClicked: () {},
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 4,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Posted by ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall!
                                      .copyWith(
                                        color:
                                            Theme.of(context).primaryColorLight,
                                      ),
                                ),
                                Text(
                                  source ?? getAuthorName(author),
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
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                        kDefaultPadding / 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(
                            kDefaultPadding / 2,
                          ),
                          bottomRight: Radius.circular(
                            kDefaultPadding / 2,
                          ),
                        ),
                        gradient: LinearGradient(
                          colors: selectedGradient,
                        ),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            LogosIcons.logoMarkWhite,
                            height: 35,
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 2,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                textContentType == TextContentType.flashnews
                                    ? 'Flash news'
                                    : textContentType ==
                                            TextContentType.uncensoredNote
                                        ? 'Uncensored notes'
                                        : textContentType ==
                                                TextContentType.note
                                            ? 'Note'
                                            : textContentType ==
                                                    TextContentType.smartWidget
                                                ? 'Smart widget'
                                                : 'Buzz feed',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: kWhite,
                                    ),
                              ),
                              Text(
                                'On ${dateFormat3.format(widget.data!['createdAt'])}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                      color: kWhite,
                                    ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (context) {
                  final data = externalShearableLink(
                    kind: widget.data!['kind'],
                    pubkey: widget.pubkey,
                    id: widget.data!['id'],
                    textContentType: textContentType,
                  );

                  return Positioned(
                    right: kDefaultPadding / 2,
                    bottom: kDefaultPadding / 2,
                    child: Container(
                      padding: const EdgeInsets.all(
                        kDefaultPadding / 4,
                      ),
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(
                          kDefaultPadding / 2,
                        ),
                      ),
                      width: 120,
                      height: 120,
                      child: PrettyQrView.data(
                        data: data,
                        decoration: const PrettyQrDecoration(
                          shape: PrettyQrRoundedSymbol(
                            color: kBlack,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class IconButtonWithText extends StatelessWidget {
  const IconButtonWithText({
    super.key,
    required this.onClicked,
    required this.text,
    required this.icon,
  });

  final Function() onClicked;
  final String text;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          CustomIconButton(
            onClicked: onClicked,
            icon: icon,
            size: 20,
            backgroundColor: Theme.of(context).primaryColorLight,
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
