// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/bookmarks_cubit/bookmarks_cubit.dart';
import 'package:yakihonne/blocs/main_cubit/main_cubit.dart';
import 'package:yakihonne/models/bookmark_list_model.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/bookmarks_view/widgets/add_bookmarks_list_view.dart';
import 'package:yakihonne/views/bookmarks_view/widgets/bookmarks_list_details.dart';
import 'package:yakihonne/views/widgets/article_thumbnail.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/no_content_widgets.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class BookmarksView extends StatelessWidget {
  BookmarksView({super.key, required this.mainScollController}) {
    FirebaseAnalytics.instance.setCurrentScreen(screenName: 'Bookmarks screen');
  }

  final ScrollController mainScollController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookmarksCubit(
        nostrRepository: context.read<NostrDataRepository>(),
      ),
      child: BlocBuilder<BookmarksCubit, BookmarksState>(
        buildWhen: (previous, current) =>
            previous.userStatus != current.userStatus,
        builder: (context, state) {
          return getView(
            userStatus: state.userStatus,
            context: context,
          );
        },
      ),
    );
  }

  Widget getView({
    required UserStatus userStatus,
    required BuildContext context,
  }) {
    if (userStatus != UserStatus.notConnected) {
      if (userStatus == UserStatus.UsingPrivKey) {
        return BookmarksLists(
          mainController: mainScollController,
        );
      } else {
        return NoPrivateWidget(
          title: 'Private key required!',
          description:
              "It seems that you don't own this account, please reconnect with the secret key to commit actions on this account.",
          icon: PagesIcons.noPrivate,
          buttonText: 'Logout',
          onClicked: () {
            context.read<MainCubit>().disconnect();
          },
        );
      }
    } else {
      return NotConnectedWidget();
    }
  }
}

class BookmarksLists extends HookWidget {
  const BookmarksLists({
    required this.mainController,
  });

  final ScrollController mainController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookmarksCubit, BookmarksState>(
      builder: (context, state) {
        return Stack(
          children: [
            ResponsiveBreakpoints.of(context).largerThan(MOBILE)
                ? TabletBookmarksList(
                    scrollController: mainController,
                  )
                : MobileBookmarksList(
                    scrollController: mainController,
                  ),
            ResetScrollButton(
              scrollController: mainController,
              isLeft: true,
              padding: kDefaultPadding,
            ),
          ],
        );
      },
    );
  }
}

class TabletBookmarksList extends StatelessWidget {
  const TabletBookmarksList({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BookmarksHeader(),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        BlocBuilder<BookmarksCubit, BookmarksState>(
          builder: (context, state) {
            if (state.bookmarksLists.isEmpty) {
              return EmptyList(
                description: 'No booksmarks list were found, try to add one!',
                icon: FeatureIcons.bookmark,
              );
            } else {
              return Expanded(
                child: Scrollbar(
                  controller: scrollController,
                  child: MasonryGridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding,
                      vertical: kDefaultPadding,
                    ),
                    crossAxisSpacing: kDefaultPadding / 2,
                    mainAxisSpacing: kDefaultPadding / 2,
                    itemBuilder: (context, index) {
                      final bookmarkList = state.bookmarksLists[index];

                      return BookmarkContainer(
                        bookmarkListModel: bookmarkList,
                        onClicked: () {
                          Navigator.pushNamed(
                            context,
                            BookmarksListDetails.routeName,
                            arguments: [
                              bookmarkList,
                              context.read<BookmarksCubit>(),
                            ],
                          );
                        },
                        onDelete: () {
                          showCupertinoDeletionDialogue(
                            context: context,
                            title: 'Delete bookmark list',
                            description:
                                "You're about to delete this bookmarks list, do you wish to proceed?",
                            buttonText: 'delete',
                            onDelete: () {
                              context
                                  .read<BookmarksCubit>()
                                  .deleteBookmarksList(
                                    bookmarkListEventId: bookmarkList.eventId,
                                    bookmarkListIdentifier:
                                        bookmarkList.identifier,
                                    onSuccess: () {
                                      Navigator.pop(context);
                                    },
                                  );
                            },
                          );
                        },
                      );
                    },
                    itemCount: state.bookmarksLists.length,
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class MobileBookmarksList extends StatelessWidget {
  const MobileBookmarksList({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: scrollController,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: BookmarksHeader(),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(
              bottom: kDefaultPadding,
              left: kDefaultPadding / 2,
              right: kDefaultPadding / 2,
            ),
            sliver: BlocBuilder<BookmarksCubit, BookmarksState>(
              builder: (context, state) {
                if (state.bookmarksLists.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyList(
                      description:
                          'No booksmarks list were found, try to add one!',
                      icon: FeatureIcons.bookmark,
                    ),
                  );
                } else {
                  return SliverList.separated(
                    separatorBuilder: (context, index) => const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    itemBuilder: (context, index) {
                      final bookmarkList = state.bookmarksLists[index];

                      return BookmarkContainer(
                        bookmarkListModel: bookmarkList,
                        onClicked: () {
                          Navigator.pushNamed(
                            context,
                            BookmarksListDetails.routeName,
                            arguments: [
                              bookmarkList,
                              context.read<BookmarksCubit>(),
                            ],
                          );
                        },
                        onDelete: () {
                          showCupertinoDeletionDialogue(
                            context: context,
                            title: 'Delete bookmark list',
                            description:
                                "You're about to delete this bookmarks list, do you wish to proceed?",
                            buttonText: 'delete',
                            onDelete: () {
                              context
                                  .read<BookmarksCubit>()
                                  .deleteBookmarksList(
                                    bookmarkListEventId: bookmarkList.eventId,
                                    bookmarkListIdentifier:
                                        bookmarkList.identifier,
                                    onSuccess: () {
                                      Navigator.pop(context);
                                    },
                                  );
                            },
                          );
                        },
                      );
                    },
                    itemCount: state.bookmarksLists.length,
                  );
                }
              },
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: kDefaultPadding,
            ),
          ),
        ],
      ),
    );
  }
}

class BookmarksHeader extends StatelessWidget {
  const BookmarksHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookmarksCubit, BookmarksState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
            vertical: kDefaultPadding,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.bookmarksLists.length.toString().padLeft(2, '0')} Bookmarks lists',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      'All bookmarks',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            fontWeight: FontWeight.w500,
                            color: kOrange,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AddBookmarksListView.routeName,
                    arguments: [
                      context.read<BookmarksCubit>(),
                    ],
                  );
                },
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColorLight,
                ),
                icon: SvgPicture.asset(
                  FeatureIcons.add,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BookmarkContainer extends StatelessWidget {
  const BookmarkContainer({
    Key? key,
    required this.bookmarkListModel,
    required this.onClicked,
    required this.onDelete,
  }) : super(key: key);

  final BookmarkListModel bookmarkListModel;
  final Function() onClicked;
  final Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final String title = bookmarkListModel.title.trim().isEmpty
        ? 'No title'
        : bookmarkListModel.title.trim().capitalize();
    final String description = bookmarkListModel.description.trim().isEmpty
        ? 'No description'
        : bookmarkListModel.description.trim().capitalize();

    return GestureDetector(
      onTap: onClicked,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColorLight,
          borderRadius: BorderRadius.circular(kDefaultPadding),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColorLight,
                    kTransparent,
                  ],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  stops: [
                    0.12,
                    0.0,
                  ],
                ),
              ),
              child: ArticleThumbnail(
                image: bookmarkListModel.image,
                placeholder: bookmarkListModel.placeholder,
                width: 120,
                height: 120,
                radius: kDefaultPadding / 2,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: kDefaultPadding / 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: kDimGrey,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    Text(
                      'Edited on: ${dateFormat2.format(bookmarkListModel.createAt)}',
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: kDimGrey,
                          ),
                    ),
                    Text(
                      "${(bookmarkListModel.bookmarkedEvents.length + bookmarkListModel.bookmarkedReplaceableEvents.length).toString().padLeft(2, '0')} items",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: kOrange,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(kDefaultPadding / 2),
              child: BorderedIconButton(
                onClicked: onDelete,
                primaryIcon: FeatureIcons.trash,
                borderColor: Theme.of(context).primaryColorLight,
                iconColor: kWhite,
                firstSelection: true,
                secondaryIcon: FeatureIcons.trash,
                backGroundColor: kRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
