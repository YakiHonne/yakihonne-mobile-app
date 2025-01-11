// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/polls_cubit/polls_cubit.dart';
import 'package:yakihonne/models/poll_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/polls_view/polls_view.dart';
import 'package:yakihonne/views/widgets/classic_footer.dart';
import 'package:yakihonne/views/widgets/dotted_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/note_container.dart';

import '../../../nostr/nostr.dart';

class SmartWidgetZapPollSelection extends StatefulWidget {
  const SmartWidgetZapPollSelection({
    Key? key,
    required this.onZapPollAdded,
  }) : super(key: key);

  final Function(Event) onZapPollAdded;

  @override
  State<SmartWidgetZapPollSelection> createState() =>
      _SmartWidgetZapPollSelectionState();
}

class _SmartWidgetZapPollSelectionState
    extends State<SmartWidgetZapPollSelection> with TickerProviderStateMixin {
  final refreshController = RefreshController();
  late TabController tabController;

  @override
  void initState() {
    tabController = TabController(
      length: 2,
      initialIndex: 0,
      vsync: this,
    );
    super.initState();
  }

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
      create: (context) => PollsCubit(),
      child: BlocConsumer<PollsCubit, PollsState>(
        listener: (context, state) {
          if (state.loadingState == UpdatingState.success) {
            refreshController.loadComplete();
          } else if (state.loadingState == UpdatingState.idle) {
            refreshController.loadNoData();
          }
        },
        builder: (context, state) {
          return Container(
            child: DraggableScrollableSheet(
              initialChildSize: 0.80,
              minChildSize: 0.40,
              maxChildSize: 0.80,
              expand: false,
              builder: (context, scrollController) => ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(kDefaultPadding),
                  topRight: Radius.circular(kDefaultPadding),
                ),
                child: NestedScrollView(
                  controller: scrollController,
                  floatHeaderSlivers: true,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        automaticallyImplyLeading: false,
                        leadingWidth: 0,
                        elevation: 5,
                        pinned: true,
                        actions: [const SizedBox.shrink()],
                        titleSpacing: 0,
                        toolbarHeight: 64,
                        flexibleSpace: SizedBox(
                          width: double.infinity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ModalBottomSheetHandle(),
                              TabBar(
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                dividerColor:
                                    Theme.of(context).primaryColorLight,
                                controller: tabController,
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: kDefaultPadding / 4,
                                ),
                                unselectedLabelStyle:
                                    Theme.of(context).textTheme.labelMedium,
                                onTap: (index) {
                                  if (index == 0) {
                                    context
                                        .read<PollsCubit>()
                                        .getPolls(isAdd: false, isSelf: false);
                                  } else {
                                    context
                                        .read<PollsCubit>()
                                        .getPolls(isAdd: false, isSelf: true);
                                  }
                                },
                                tabs: [
                                  Tab(
                                    height: 35,
                                    child: Text('Community polls'),
                                  ),
                                  Tab(height: 35, child: Text('My polls')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: Builder(
                    builder: (context) {
                      if (state.isLoading) {
                        return Center(
                          child: SpinKitPulse(
                            color: Theme.of(context).primaryColorDark,
                            size: 20,
                          ),
                        );
                      } else if (state.polls.isEmpty) {
                        return EmptyList(
                          description: 'No polls can be found',
                          icon: FeatureIcons.polls,
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
                          onLoading: () => context
                              .read<PollsCubit>()
                              .getPolls(isAdd: true, isSelf: false),
                          onRefresh: () => onRefresh(
                            onInit: () => context
                                .read<PollsCubit>()
                                .getPolls(isAdd: false, isSelf: false),
                          ),
                          child: isTablet
                              ? MasonryGridView.count(
                                  crossAxisCount: 2,
                                  controller: scrollController,
                                  itemCount: state.polls.length,
                                  crossAxisSpacing: kDefaultPadding / 2,
                                  mainAxisSpacing: kDefaultPadding / 2,
                                  padding:
                                      const EdgeInsets.all(kDefaultPadding / 2),
                                  itemBuilder: (context, index) {
                                    final poll = state.polls[index];

                                    return PollContainer(
                                      poll: poll,
                                      onTap: () {
                                        widget.onZapPollAdded.call(poll.event);
                                      },
                                    );
                                  },
                                )
                              : ListView.separated(
                                  itemCount: state.polls.length,
                                  controller: scrollController,
                                  padding:
                                      const EdgeInsets.all(kDefaultPadding / 2),
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(
                                    height: kDefaultPadding / 2,
                                  ),
                                  itemBuilder: (context, index) {
                                    final poll = state.polls[index];

                                    return GestureDetector(
                                      onTap: () {
                                        widget.onZapPollAdded.call(poll.event);
                                      },
                                      child: PollContainer(
                                        poll: poll,
                                        onTap: () {
                                          widget.onZapPollAdded
                                              .call(poll.event);
                                        },
                                      ),
                                    );
                                  },
                                ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PollContainer extends HookWidget {
  const PollContainer({
    required this.poll,
    required this.onTap,
  });

  final PollModel poll;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    final displayResults = useState(false);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColorLight,
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ProfileInfoHeader(
                    createdAt: poll.createdAt,
                    pubkey: poll.pubkey,
                  ),
                ),
                SizedBox(
                  width: kDefaultPadding / 4,
                ),
                CustomIconButton(
                  onClicked: onTap,
                  icon: FeatureIcons.addRaw,
                  size: 15,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  vd: -2,
                ),
              ],
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Text(
              poll.content.trim(),
              style: Theme.of(context).textTheme.labelMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 4,
            ),
            SizedBox(
              height: kDefaultPadding,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Options',
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'Total: ${poll.options.length}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall!
                      .copyWith(color: kDimGrey),
                ),
              ],
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            ...poll.options
                .map(
                  (e) => PollOptionContainer(
                    pollOption: e,
                    displayResults: displayResults.value,
                    total: 0,
                    val: 0,
                    onClick: () {},
                    selfVote: false,
                  ),
                )
                .toList()
          ],
        ),
      ),
    );
  }
}
