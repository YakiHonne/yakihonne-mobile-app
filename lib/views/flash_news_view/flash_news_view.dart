// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:yakihonne/blocs/flash_news_cubit/flash_news_cubit.dart';
import 'package:yakihonne/models/flash_news_model.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/flash_news_details_view/flash_news_details_view.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/search_view/search_view.dart';
import 'package:yakihonne/views/widgets/classic_footer.dart';
import 'package:yakihonne/views/widgets/custom_date_picker.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';

class FlashNewsView extends StatefulWidget {
  const FlashNewsView({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  State<FlashNewsView> createState() => _FlashNewsViewState();
}

class _FlashNewsViewState extends State<FlashNewsView> {
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
    return BlocProvider(
      create: (context) => FlashNewsCubit()
        ..getFlashNews(
          add: false,
        ),
      lazy: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
        child: BlocConsumer<FlashNewsCubit, FlashNewsState>(
          listener: (context, state) {
            if (state.loadingFlashNews == UpdatingState.success) {
              refreshController.loadComplete();
            } else if (state.loadingFlashNews == UpdatingState.idle) {
              refreshController.loadNoData();
            }
          },
          builder: (context, state) {
            return SmartRefresher(
              controller: refreshController,
              scrollController: widget.scrollController,
              enablePullDown: false,
              enablePullUp: true,
              header: const MaterialClassicHeader(
                color: kPurple,
              ),
              footer: const RefresherClassicFooter(),
              onLoading: () =>
                  context.read<FlashNewsCubit>().getFlashNews(add: true),
              onRefresh: () => onRefresh(
                onInit: () =>
                    context.read<FlashNewsCubit>().getFlashNews(add: false),
              ),
              child: CustomScrollView(
                controller: widget.scrollController,
                slivers: [
                  SliverStickyHeader(
                    sticky: true,
                    header: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding / 2,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'News',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Spacer(),
                          IconButton(
                            onPressed: () => context
                                .read<FlashNewsCubit>()
                                .filterByImportance(),
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor: state.isImportant
                                  ? Theme.of(context).primaryColorDark
                                  : Theme.of(context).primaryColorLight,
                            ),
                            icon: SvgPicture.asset(
                              FeatureIcons.flame,
                              width: 22,
                              height: 22,
                              colorFilter: ColorFilter.mode(
                                !state.isImportant
                                    ? Theme.of(context).primaryColorDark
                                    : Theme.of(context).primaryColorLight,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                useSafeArea: true,
                                builder: (_) {
                                  return Dialog(
                                    insetPadding: const EdgeInsets.symmetric(
                                      horizontal: kDefaultPadding,
                                    ),
                                    child: BlocProvider.value(
                                      value: context.read<FlashNewsCubit>(),
                                      child: PickDateTimeWidget(
                                        focusedDate: state.selectedDate,
                                        isAfter: false,
                                        onDateSelected: (selectedDate) {
                                          context
                                              .read<FlashNewsCubit>()
                                              .getFlashNews(
                                                selectedDate: selectedDate,
                                                add: false,
                                              );

                                          Navigator.pop(context);
                                        },
                                        onClearDate: () {
                                          context
                                              .read<FlashNewsCubit>()
                                              .getFlashNews(add: false);

                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).primaryColorLight,
                            ),
                            icon: SvgPicture.asset(
                              FeatureIcons.calendar,
                              width: 22,
                              height: 22,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.isFlashNewsLoading)
                    SliverToBoxAdapter(
                      child: SearchLoading(),
                    )
                  else if (state.flashNews.isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyList(
                        description: 'No flash news can be found.',
                        icon: FeatureIcons.flashNews,
                      ),
                    )
                  else
                    ...state.flashNews.entries.map(
                      (flashNews) {
                        return FlashNewsDetailedContainer(
                          flashNews: flashNews,
                        );
                      },
                    ).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class FlashNewsDetailedContainer extends StatelessWidget {
  const FlashNewsDetailedContainer({
    Key? key,
    required this.flashNews,
  }) : super(key: key);

  final MapEntry<String, List<MainFlashNews>> flashNews;

  @override
  Widget build(BuildContext context) {
    final flashNewsValues = flashNews.value;
    List<Widget> children = <Widget>[];

    for (int i = 0; i < flashNewsValues.length; i++) {
      final mainFlashNews = flashNewsValues[i];

      Widget container = FlashNewsTimelineContainer(
        mainFlashNews: mainFlashNews,
        date: flashNews.key,
        isFirst: i == 0,
        isLast: i == flashNewsValues.length - 1,
        onClicked: () => Navigator.pushNamed(
          context,
          FlashNewsDetailsView.routeName,
          arguments: [
            mainFlashNews,
          ],
        ),
      );

      children.add(container);
    }

    return SliverStickyHeader(
      sticky: true,
      header: Container(
        padding: const EdgeInsets.only(
          bottom: kDefaultPadding / 1.5,
          top: kDefaultPadding / 4,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              flashNews.key,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Container(
              height: 2.5,
              width: 80,
              margin: const EdgeInsets.only(top: kDefaultPadding / 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding),
                color: Theme.of(context).primaryColorDark,
              ),
            )
          ],
        ),
      ),
      sliver: SliverPadding(
        padding: const EdgeInsets.only(
          top: kDefaultPadding / 4,
          bottom: kDefaultPadding,
        ),
        sliver: flashNews.value.isEmpty
            ? SliverToBoxAdapter(
                child: Text(
                  'No flash news can be found on this date.',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: kDimGrey,
                      ),
                ),
              )
            : SliverList(
                delegate: SliverChildListDelegate(children),
              ),
      ),
    );
  }
}
