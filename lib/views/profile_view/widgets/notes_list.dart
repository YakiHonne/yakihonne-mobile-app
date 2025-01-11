// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/blocs/profile_cubit/profile_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/classic_footer.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/note_container.dart';
import 'package:yakihonne/views/widgets/place_holders.dart';

class ProfileNotes extends StatefulWidget {
  const ProfileNotes({
    Key? key,
  }) : super(key: key);

  @override
  State<ProfileNotes> createState() => _ProfileNotesState();
}

class _ProfileNotesState extends State<ProfileNotes> {
  final refreshController = RefreshController();

  void onRefresh({required Function onInit}) {
    refreshController.resetNoData();
    onInit.call();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Scrollbar(
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state.notesLoading == UpdatingState.success) {
            refreshController.loadComplete();
          } else if (state.notesLoading == UpdatingState.idle) {
            refreshController.loadNoData();
          }
        },
        buildWhen: (previous, current) =>
            previous.isNotesLoading != current.isNotesLoading ||
            previous.notesLoading != current.notesLoading ||
            previous.notes != current.notes ||
            previous.user != current.user,
        builder: (context, state) {
          if (state.isNotesLoading) {
            return MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                children: [
                  SkeletonSelector(
                    placeHolderWidget: ArticleSkeleton(),
                  ),
                ],
              ),
            );
          } else {
            if (state.notes.isEmpty) {
              return EmptyList(
                description: '${state.user.name} has no notes',
                icon: FeatureIcons.note,
              );
            } else {
              return SmartRefresher(
                controller: refreshController,
                enablePullDown: false,
                enablePullUp: true,
                header: const MaterialClassicHeader(
                  color: kPurple,
                ),
                footer: const RefresherClassicFooter(),
                onLoading: () => context.read<ProfileCubit>().getMoreNotes(),
                child: isTablet
                    ? MasonryGridView.builder(
                        physics: AlwaysScrollableScrollPhysics(),
                        gridDelegate:
                            SliverSimpleGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                        ),
                        crossAxisSpacing: kDefaultPadding / 2,
                        mainAxisSpacing: kDefaultPadding / 2,
                        padding: const EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 2,
                          horizontal: kDefaultPadding,
                        ),
                        itemBuilder: (context, index) {
                          final note = state.notes[index];

                          return GlobalNoteContainer(
                            note: note,
                          );
                        },
                        itemCount: state.notes.length,
                      )
                    : ListView.separated(
                        separatorBuilder: (context, index) => SizedBox(
                          height: kDefaultPadding / 2,
                        ),
                        padding: const EdgeInsets.only(
                          top: kDefaultPadding / 2,
                          bottom: kDefaultPadding,
                          left: kDefaultPadding / 2,
                          right: kDefaultPadding / 2,
                        ),
                        physics: AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final note = state.notes[index];

                          return GlobalNoteContainer(
                            note: note,
                          );
                        },
                        itemCount: state.notes.length,
                      ),
              );
            }
          }
        },
      ),
    );
  }
}
