// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/lightning_zaps_cubit/lightning_zaps_cubit.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/models/uncensored_notes_models.dart';
import 'package:yakihonne/models/user_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/add_bookmark_view/add_bookmark_view.dart';
import 'package:yakihonne/views/flash_news_details_view/widgets/flash_news_details_data.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_tags_row.dart';
import 'package:yakihonne/views/uncensored_notes_view/widgets/un_flashnews_details.dart';
import 'package:yakihonne/views/widgets/content_container.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';
import 'package:yakihonne/views/widgets/share_view.dart';

class FlashNewsContainer extends StatelessWidget {
  final MainFlashNews mainFlashNews;
  final FlashNewsType flashNewsType;
  final UserStatus userStatus;
  final bool? trySearch;
  final String? selectedTag;
  final bool? isMuted;
  final bool? isComponent;
  final bool? isBookmarked;
  final Function()? onDelete;

  final Function()? onCopyInvoice;
  final Function()? onConfirmPayment;
  final Function()? onPayWithAlby;
  final Function()? onClicked;

  const FlashNewsContainer({
    Key? key,
    required this.mainFlashNews,
    required this.flashNewsType,
    required this.userStatus,
    this.trySearch,
    this.selectedTag,
    this.isMuted,
    this.isComponent,
    this.isBookmarked,
    this.onDelete,
    this.onCopyInvoice,
    this.onConfirmPayment,
    this.onPayWithAlby,
    this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: flashNewsType != FlashNewsType.userPending ? onClicked : null,
        behavior: HitTestBehavior.translucent,
        child: Container(
          padding: const EdgeInsets.all(kDefaultPadding / 1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: isComponent != null
                ? Theme.of(context).scaffoldBackgroundColor
                : Theme.of(context).primaryColorLight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: flashNewsType == FlashNewsType.public
                        ? BlocSelector<AuthorsCubit, AuthorsState, UserModel?>(
                            selector: (state) =>
                                state.authors[mainFlashNews.flashNews.pubkey],
                            builder: (context, user) {
                              final author = user ??
                                  emptyUserModel.copyWith(
                                    pubKey: mainFlashNews.flashNews.pubkey,
                                    picturePlaceholder: getRandomPlaceholder(
                                      input: mainFlashNews.flashNews.pubkey,
                                      isPfp: true,
                                    ),
                                  );
                              return Row(
                                children: [
                                  ProfilePicture2(
                                    size: 30,
                                    image: author.picture,
                                    placeHolder: author.picturePlaceholder,
                                    padding: 0,
                                    strokeWidth: 0,
                                    reduceSize: true,
                                    strokeColor: kTransparent,
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
                                        Row(
                                          children: [
                                            Text(
                                              'By: ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium!,
                                            ),
                                            Expanded(
                                              child: Text(
                                                getAuthorName(author),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium!
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'On: ${dateFormat4.format(
                                            mainFlashNews.flashNews.createdAt,
                                          )}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall!
                                              .copyWith(
                                                color: kOrange,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (userStatus == UserStatus.UsingPrivKey &&
                                      flashNewsType == FlashNewsType.public)
                                    IconButton(
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          elevation: 0,
                                          builder: (_) {
                                            return AddBookmarkView(
                                              kind: EventKind.TEXT_NOTE,
                                              identifier:
                                                  mainFlashNews.flashNews.id,
                                              eventPubkey: mainFlashNews
                                                  .flashNews.pubkey,
                                              image: '',
                                            );
                                          },
                                          isScrollControlled: true,
                                          useRootNavigator: true,
                                          useSafeArea: true,
                                          backgroundColor: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                        );
                                      },
                                      icon: BlocBuilder<ThemeCubit, ThemeState>(
                                        builder: (context, state) {
                                          final isDark = state.theme ==
                                              AppTheme.purpleDark;

                                          return SvgPicture.asset(
                                            isBookmarked!
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
                                  IconButton(
                                    onPressed: onClicked,
                                    style: IconButton.styleFrom(
                                      visualDensity: VisualDensity(
                                        horizontal: -2,
                                        vertical: -2,
                                      ),
                                    ),
                                    icon: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Publish on',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Text(
                                dateFormat4.format(
                                  mainFlashNews.flashNews.createdAt,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(
                                      color: kOrange,
                                    ),
                              ),
                            ],
                          ),
                  ),
                  if (flashNewsType == FlashNewsType.userActive)
                    CustomIconButton(
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      icon: FeatureIcons.trash,
                      onClicked: onDelete!,
                      size: 22,
                    ),
                ],
              ),
              if (mainFlashNews.flashNews.tags.isNotEmpty ||
                  mainFlashNews.flashNews.isImportant) ...[
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                FlashTagsRow(
                  isImportant: mainFlashNews.flashNews.isImportant,
                  tags: mainFlashNews.flashNews.tags,
                  selectedTag: selectedTag,
                ),
              ],
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              linkifiedText(
                context: context,
                text: mainFlashNews.flashNews.content,
                onClicked: onClicked,
              ),
              if (flashNewsType == FlashNewsType.public) ...[
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                SealedComponent(
                  mainFlashNews: mainFlashNews,
                  trySearch: trySearch ?? true,
                  hideSealed: trySearch,
                  isComponent: false,
                ),
              ],
              if (mainFlashNews.flashNews.source.isNotEmpty ||
                  (userStatus == UserStatus.UsingPrivKey &&
                      flashNewsType == FlashNewsType.public)) ...[
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Spacer(),
                    if (mainFlashNews.flashNews.source.isNotEmpty)
                      CustomIconButton(
                        backgroundColor: isComponent != null
                            ? Theme.of(context).primaryColorLight
                            : Theme.of(context).scaffoldBackgroundColor,
                        icon: FeatureIcons.globe,
                        onClicked: () {
                          openWebPage(url: mainFlashNews.flashNews.source);
                        },
                        size: 22,
                      ),
                  ],
                ),
              ],
              if (flashNewsType == FlashNewsType.userPending) ...[
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                            ),
                            onPressed: onCopyInvoice,
                            child: Text(
                              'Copy invoice',
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                            ),
                            onPressed: onConfirmPayment,
                            child: Text(
                              'Confirm payment',
                            ),
                          ),
                        ),
                      ],
                    ),
                    BlocBuilder<LightningZapsCubit, LightningZapsState>(
                      builder: (context, state) {
                        if (state.selectedWalletId.isNotEmpty &&
                            state.wallets[state.selectedWalletId] != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(
                                height: kDefaultPadding / 2,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange,
                                      Colors.yellow,
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(kDefaultPadding),
                                ),
                                child: TextButton(
                                  onPressed: onPayWithAlby,
                                  style: TextButton.styleFrom(
                                    backgroundColor: kTransparent,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        LogosIcons.alby,
                                        width: 30,
                                        height: 30,
                                      ),
                                      const SizedBox(
                                        width: kDefaultPadding / 2,
                                      ),
                                      Text(
                                        'Pay with NWC Alby',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color: kBlack,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      },
                    ),
                  ],
                )
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class HomeFlashNewsContainer extends HookWidget {
  final MainFlashNews mainFlashNews;
  final FlashNewsType flashNewsType;
  final UserStatus userStatus;
  final bool isFollowing;
  final bool? trySearch;
  final String? selectedTag;
  final bool? isMuted;
  final bool? isComponent;
  final bool? isBookmarked;
  final Function()? onDelete;

  final Function()? onCopyInvoice;
  final Function()? onConfirmPayment;
  final Function()? onPayWithAlby;
  final Function()? onClicked;

  const HomeFlashNewsContainer({
    Key? key,
    required this.mainFlashNews,
    required this.flashNewsType,
    required this.userStatus,
    required this.isFollowing,
    this.trySearch,
    this.selectedTag,
    this.isMuted,
    this.isComponent,
    this.isBookmarked,
    this.onDelete,
    this.onCopyInvoice,
    this.onConfirmPayment,
    this.onPayWithAlby,
    this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      authorsCubit.getAuthor(mainFlashNews.flashNews.pubkey);
    });

    return BlocBuilder<AuthorsCubit, AuthorsState>(
      builder: (context, state) {
        final author = state.authors[mainFlashNews.flashNews.pubkey] ??
            emptyUserModel.copyWith(
              pubKey: mainFlashNews.flashNews.pubkey,
              picture: '',
              picturePlaceholder: getRandomPlaceholder(
                input: mainFlashNews.flashNews.pubkey,
                isPfp: true,
              ),
            );

        return FadeIn(
          duration: const Duration(milliseconds: 300),
          child: ContentContainer(
            id: mainFlashNews.flashNews.id,
            isSensitive: false,
            isFollowing: isFollowing,
            createdAt: mainFlashNews.flashNews.createdAt,
            title: mainFlashNews.flashNews.content,
            thumbnail: '',
            description: '',
            tags: mainFlashNews.flashNews.tags,
            isBookmarked: isBookmarked!,
            hasImportantTag: mainFlashNews.flashNews.isImportant,
            author: author,
            contentType: ContentType.flashNews,
            highlightedTag: selectedTag ?? '',
            onClicked: onClicked!,
            onUncensoredNotes: () {
              Navigator.pushNamed(
                context,
                UnFlashNewsDetails.routeName,
                arguments: UnFlashNews(
                  flashNews: mainFlashNews.flashNews,
                  sealedNote: mainFlashNews.sealedNote,
                  uncensoredNotes: [],
                  isSealed: mainFlashNews.sealedNote != null,
                ),
              );
            },
            onProfileClicked: () {
              openProfileFastAccess(
                context: context,
                pubkey: mainFlashNews.flashNews.pubkey,
              );
            },
            onBookmark: () {
              showModalBottomSheet(
                context: context,
                elevation: 0,
                builder: (_) {
                  return AddBookmarkView(
                    kind: EventKind.TEXT_NOTE,
                    identifier: mainFlashNews.flashNews.id,
                    eventPubkey: mainFlashNews.flashNews.pubkey,
                    image: '',
                  );
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            },
            onShare: () {
              showModalBottomSheet(
                elevation: 0,
                context: context,
                builder: (_) {
                  return ShareView(
                    image: '',
                    placeholder: '',
                    data: {
                      'kind': EventKind.TEXT_NOTE,
                      'id': mainFlashNews.flashNews.id,
                      'createdAt': mainFlashNews.flashNews.createdAt,
                      'textContentType': TextContentType.flashnews,
                    },
                    pubkey: mainFlashNews.flashNews.pubkey,
                    title: mainFlashNews.flashNews.content,
                    description: '',
                    kindText: 'Flash news',
                    icon: FeatureIcons.flashNews,
                    upvotes: 0,
                    downvotes: 0,
                    onShare: () {
                      RenderBox? box;
                      if (ResponsiveBreakpoints.of(context)
                          .largerThan(MOBILE)) {
                        box = context.findRenderObject() as RenderBox?;
                      }

                      shareLink(
                        renderBox: box,
                        pubkey: mainFlashNews.flashNews.pubkey,
                        id: mainFlashNews.flashNews.id,
                        kind: EventKind.TEXT_NOTE,
                        textContentType: TextContentType.flashnews,
                      );
                    },
                  );
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            },
            isMuted: isMuted,
          ),
        );
      },
    );
  }
}
