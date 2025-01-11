// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/self_notes_cubit/self_notes_cubit.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/classic_footer.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/note_container.dart';
import 'package:yakihonne/views/widgets/place_holders.dart';

class SelfNotesView extends StatefulWidget {
  const SelfNotesView({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  State<SelfNotesView> createState() => _SelfNotesViewState();
}

class _SelfNotesViewState extends State<SelfNotesView> {
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

    return BlocProvider(
      create: (context) => SelfNotesCubit(),
      child: BlocConsumer<SelfNotesCubit, SelfNotesState>(
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
            previous.detailedNotes != current.detailedNotes,
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
            if (state.detailedNotes.isEmpty) {
              return EmptyList(
                description: 'You have no notes',
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
                onLoading: () => context.read<SelfNotesCubit>().getNotes(true),
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
                          final note = state.detailedNotes[index];

                          return GlobalNoteContainer(
                            note: DetailedNoteModel.fromEvent(note),
                          );
                        },
                        itemCount: state.detailedNotes.length,
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
                          final note = state.detailedNotes[index];

                          return GlobalNoteContainer(
                            note: DetailedNoteModel.fromEvent(note),
                          );
                        },
                        itemCount: state.detailedNotes.length,
                      ),
              );
            }
          }
        },
      ),
    );
  }
}
