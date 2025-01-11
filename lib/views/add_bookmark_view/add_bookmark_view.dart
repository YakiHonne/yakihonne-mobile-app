// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/add_bookmark_cubit/add_bookmark_cubit.dart';
import 'package:yakihonne/models/bookmark_list_model.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/views/widgets/article_thumbnail.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

import '../../../utils/utils.dart';

class AddBookmarkLists extends StatelessWidget {
  const AddBookmarkLists({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<AddBookmarkCubit, AddBookmarkState>(
      builder: (context, state) {
        return ScrollShadow(
          color: Theme.of(context).primaryColorLight,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 15.w : kDefaultPadding / 2,
            ),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ),
                if (state.bookmarks.isEmpty)
                  SliverToBoxAdapter(
                    child: EmptyList(
                      description:
                          'No bookmarks list can be found, try to add one!',
                      icon: FeatureIcons.bookmark,
                    ),
                  )
                else
                  SliverList.separated(
                    separatorBuilder: (context, index) => const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    itemBuilder: (context, index) {
                      final bookmarkList = state.bookmarks[index];

                      final isAbsorbing = state.loadingBookmarksList
                          .contains(bookmarkList.identifier);

                      final isActive = state.kind == EventKind.TEXT_NOTE
                          ? bookmarkList.bookmarkedEvents
                              .contains(state.eventId)
                          : bookmarkList.bookmarkedReplaceableEvents
                              .where((element) =>
                                  element.identifier == state.eventId)
                              .isNotEmpty;

                      return BookmarkListContainer(
                        isAbsorbing: isAbsorbing,
                        bookmarkList: bookmarkList,
                        isActive: isActive,
                        onSetBookmark: () => context
                            .read<AddBookmarkCubit>()
                            .setBookmark(
                              bookmarkListIdentifier: bookmarkList.identifier,
                            ),
                      );
                    },
                    itemCount: state.bookmarks.length,
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: kDefaultPadding,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String getBookmarkListType(int kind) {
    if (kind == EventKind.LONG_FORM) {
      return 'articles';
    } else {
      return 'curations';
    }
  }
}

class submitBookmarkList extends HookWidget {
  const submitBookmarkList({
    required this.controller,
  });

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<AddBookmarkCubit, AddBookmarkState>(
      builder: (context, state) {
        return ListView(
          controller: controller,
          padding: EdgeInsets.all(isTablet ? 15.w : kDefaultPadding / 2),
          children: [
            const SizedBox(
              height: kDefaultPadding,
            ),
            Text(
              'Set a title & a description for your bookmark list.',
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            TextFormField(
              onChanged: (title) {
                context.read<AddBookmarkCubit>().setText(
                      text: title,
                      isTitle: true,
                    );
              },
              decoration: InputDecoration(
                hintText: 'Title',
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            TextFormField(
              onChanged: (description) {
                context.read<AddBookmarkCubit>().setText(
                      text: description,
                      isTitle: false,
                    );
              },
              decoration: InputDecoration(
                hintText: 'Description (optional)',
              ),
              maxLines: 3,
            ),
          ],
        );
      },
    );
  }
}

class BookmarkListContainer extends StatelessWidget {
  const BookmarkListContainer({
    Key? key,
    required this.isAbsorbing,
    required this.isActive,
    required this.bookmarkList,
    required this.onSetBookmark,
  }) : super(key: key);

  final bool isAbsorbing;
  final bool isActive;
  final BookmarkListModel bookmarkList;
  final Function() onSetBookmark;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          ArticleThumbnail(
            image: bookmarkList.image,
            placeholder: bookmarkList.placeholder,
            width: 50,
            height: 50,
            radius: 300,
            isRound: true,
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookmarkList.title.trim().capitalize(),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  bookmarkList.description.trim().capitalize(),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: kDimGrey,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          Builder(builder: (context) {
            return AbsorbPointer(
              absorbing: isAbsorbing,
              child: IconButton(
                onPressed: onSetBookmark,
                icon: isAbsorbing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 1,
                        ),
                      )
                    : SvgPicture.asset(
                        isActive
                            ? FeatureIcons.bookmarkChecked
                            : FeatureIcons.bookmarkAdd,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).primaryColorDark,
                          BlendMode.srcIn,
                        ),
                      ),
              ),
            );
          })
        ],
      ),
    );
  }
}

class AddBookmarkView extends StatelessWidget {
  const AddBookmarkView({
    Key? key,
    required this.identifier,
    required this.eventPubkey,
    required this.image,
    required this.kind,
  }) : super(key: key);

  final String identifier;
  final String eventPubkey;
  final String image;
  final int kind;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddBookmarkCubit(
        kind: kind,
        identifier: identifier,
        eventPubkey: eventPubkey,
        image: image,
        nostrRepository: context.read<NostrDataRepository>(),
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
            initialChildSize: 0.8,
            minChildSize: 0.40,
            maxChildSize: 0.8,
            expand: false,
            builder: (_, controller) => Column(
              children: [
                ModalBottomSheetHandle(),
                BlocBuilder<AddBookmarkCubit, AddBookmarkState>(
                  buildWhen: (previous, current) =>
                      previous.isBookmarksLists != current.isBookmarksLists,
                  builder: (context, state) {
                    return SizedBox(
                      height: kToolbarHeight - 5,
                      child: Center(
                        child: Stack(
                          children: [
                            if (!state.isBookmarksLists)
                              IconButton(
                                onPressed: () {
                                  context
                                      .read<AddBookmarkCubit>()
                                      .setView(true);
                                },
                                icon: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 20,
                                ),
                              ),
                            Center(
                              child: Text(
                                state.isBookmarksLists
                                    ? 'Bookmark lists'
                                    : 'Submit',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 0,
                ),
                BlocBuilder<AddBookmarkCubit, AddBookmarkState>(
                  builder: (context, state) {
                    return Expanded(
                      child: getView(state.isBookmarksLists, controller),
                    );
                  },
                ),
                AddBookmarkBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget getView(bool isCurationsList, ScrollController controller) {
    return isCurationsList
        ? AddBookmarkLists(
            scrollController: controller,
          )
        : submitBookmarkList(
            controller: controller,
          );
  }
}

class AddBookmarkBottomBar extends HookWidget {
  AddBookmarkBottomBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddBookmarkCubit, AddBookmarkState>(
      buildWhen: (previous, current) =>
          previous.isBookmarksLists != current.isBookmarksLists,
      builder: (context, articleState) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding,
            vertical: kDefaultPadding / 4,
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          alignment: Alignment.center,
          child: TextButton.icon(
            onPressed: () {
              if (articleState.isBookmarksLists) {
                context.read<AddBookmarkCubit>().setView(false);
              } else {
                context.read<AddBookmarkCubit>().addBookmarkList(
                  onFailure: (message) {
                    singleSnackBar(
                      context: context,
                      message: message,
                      color: kRed,
                      backGroundColor: kRedSide,
                      icon: ToastsIcons.error,
                    );
                  },
                );
              }
            },
            icon: Icon(
              articleState.isBookmarksLists ? Icons.add_rounded : Icons.check,
              size: 20,
            ),
            label: Text(
              articleState.isBookmarksLists
                  ? 'Add bookmark list'
                  : 'submit bookmark list',
            ),
          ),
        );
      },
    );
  }
}
