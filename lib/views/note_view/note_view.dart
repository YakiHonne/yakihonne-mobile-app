import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:yakihonne/blocs/notes_events_cubit/notes_events_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/detailed_note_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/notes_view/notes_view.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';

class NoteView extends HookWidget {
  static const routeName = '/noteView';

  static Route route(RouteSettings settings) {
    final note = settings.arguments as DetailedNoteModel;

    return CupertinoPageRoute(
      builder: (_) => NoteView(
        note: note,
      ),
    );
  }

  NoteView({
    super.key,
    required this.note,
  });

  final DetailedNoteModel note;
  final GlobalKey targetKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isCurrentlyLoading = useState(false);

    useMemoized(() async {
      await Future.delayed(const Duration(milliseconds: 300)).then((value) {
        Scrollable.ensureVisible(
          targetKey.currentContext!,
          alignment: 0.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    });

    return BlocBuilder<NotesEventsCubit, NotesEventsState>(
      builder: (context, state) {
        List<DetailedNoteModel> replies = [];

        final events = state.notesStats[note.id] ?? {};

        for (final event in events.values) {
          if (event.kind == EventKind.TEXT_NOTE &&
              event.isSimpleNote() &&
              !nostrRepository.mutes.contains(event.pubkey)) {
            final reply = event.tags.where(
              (tag) =>
                  canAddNote(tag, note.id) && event.kind == EventKind.TEXT_NOTE,
            );

            if (reply.isNotEmpty) {
              replies.add(DetailedNoteModel.fromEvent(event));
            } else {
              final reply = event.tags.where((tag) =>
                  tag.first == 'e' &&
                  tag.length == 2 &&
                  tag[1] == note.id &&
                  event.kind == EventKind.TEXT_NOTE);

              if (reply.isNotEmpty) {
                replies.add(DetailedNoteModel.fromEvent(event));
              }
            }
          }
        }

        final previousNotes = state.previousNotes[note.id] ?? [];

        return Scaffold(
          appBar: CustomAppBar(
            title: 'Note',
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                notesEventsCubit.getNotePrevious(
                  note,
                  isCurrentlyLoading.value,
                  (val) {
                    isCurrentlyLoading.value = val;
                  },
                );
              },
              child: CustomScrollView(
                slivers: [
                  if (!note.isRoot && previousNotes.isEmpty ||
                      previousNotes.isNotEmpty &&
                          !previousNotes.first.isRoot) ...[
                    SliverToBoxAdapter(
                      child: const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Pull down to load previous post(s)',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            width: kDefaultPadding / 3,
                          ),
                          isCurrentlyLoading.value
                              ? SpinKitCircle(
                                  color: kOrange,
                                  size: 20,
                                )
                              : Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 20,
                                  color: kOrange,
                                ),
                        ],
                      ),
                    ),
                  ],
                  if (previousNotes.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Text(
                        'Previous posts',
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                    ),
                    SliverList.separated(
                      itemBuilder: (context, index) {
                        final note = previousNotes[index];

                        return DetailedNoteContainer(
                          note: note,
                          isMain: false,
                          selfStats: false,
                          addLine: index != previousNotes.length - 1,
                        );
                      },
                      itemCount: previousNotes.length,
                      separatorBuilder: (context, index) => const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ),
                  SliverToBoxAdapter(
                    key: targetKey,
                    child: Text(
                      'Main post',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: DetailedNoteContainer(
                      note: note,
                      isMain: true,
                      selfStats: false,
                      addLine: false,
                    ),
                  ),
                  if (replies.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Text(
                        'Replies',
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                    ),
                    SliverList.separated(
                      itemBuilder: (context, index) {
                        final reply = replies[index];
                        return DetailedNoteContainer(
                          note: reply,
                          selfStats: false,
                          isMain: false,
                          addLine: false,
                        );
                      },
                      itemCount: replies.length,
                      separatorBuilder: (context, index) => const SizedBox(
                        height: kDefaultPadding / 4,
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: const SizedBox(
                      height: kDefaultPadding,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
