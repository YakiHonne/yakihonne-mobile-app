// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/home_cubit/topcis_cubit/topics_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/topic.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/home_view/widgets/add_custom_topic.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';

class TopicsView extends HookWidget {
  const TopicsView({super.key});

  static const routeName = '/topicsView';

  static Route route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (_) => TopicsView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTopicsToggled = useState(false);
    final isBuzzFeedToggled = useState(false);

    return BlocProvider(
      create: (context) => TopicsCubit(
        localDatabaseRepository: context.read<LocalDatabaseRepository>(),
        nostrRepository: context.read<NostrDataRepository>(),
      ),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Topics',
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding,
                ),
              ),
              SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'My topics',
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    BlocBuilder<TopicsCubit, TopicsState>(
                      builder: (context, state) {
                        if (state.isSameTopics) {
                          return SizedBox.shrink();
                        } else {
                          return IconButton(
                            onPressed: () {
                              context.read<TopicsCubit>().setTopics();
                            },
                            icon: Icon(
                              Icons.cloud_upload_outlined,
                              color: kGreen,
                            ),
                            style: TextButton.styleFrom(
                              visualDensity:
                                  VisualDensity(horizontal: -4, vertical: -4),
                            ),
                          );
                        }
                      },
                    ),
                    Builder(
                      builder: (context) {
                        return IconButton(
                          onPressed: () {
                            context.read<TopicsCubit>().setSuggestions();

                            showModalBottomSheet(
                              context: context,
                              elevation: 0,
                              builder: (_) {
                                return BlocProvider.value(
                                  value: context.read<TopicsCubit>(),
                                  child: AddCustomTopic(),
                                );
                              },
                              isScrollControlled: true,
                              useRootNavigator: true,
                              useSafeArea: true,
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                            );
                          },
                          icon: Icon(
                            Icons.add,
                          ),
                          style: TextButton.styleFrom(
                            visualDensity:
                                VisualDensity(horizontal: -4, vertical: -4),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              BlocBuilder<TopicsCubit, TopicsState>(
                builder: (context, state) {
                  if (state.activeTopics.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Text(
                        'No topic has been selected yet',
                      ),
                    );
                  } else {
                    return SliverPadding(
                      padding: const EdgeInsets.only(top: kDefaultPadding / 2),
                      sliver: SliverToBoxAdapter(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: state.activeTopics.map(
                            (topic) {
                              return TopicChip(
                                topic: topic,
                                icon: getIcon(topic),
                                onDelete: () {
                                  context.read<TopicsCubit>().addTopic(topic);
                                },
                              );
                            },
                          ).toList(),
                          spacing: kDefaultPadding / 4,
                          runSpacing: kDefaultPadding / 4,
                        ),
                      ),
                    );
                  }
                },
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding,
                ),
              ),
              SliverToBoxAdapter(
                child: Row(
                  children: [
                    BlocBuilder<TopicsCubit, TopicsState>(
                      builder: (context, state) {
                        return Text(
                          'All topics - ${state.generalTopics.length.toString().padLeft(2, '0')}',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        );
                      },
                    ),
                    IconButton(
                      onPressed: () {
                        isTopicsToggled.value = !isTopicsToggled.value;
                      },
                      icon: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: isTopicsToggled.value ? 1 : 0.75,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: kTransparent,
                        visualDensity:
                            VisualDensity(horizontal: -4, vertical: -4),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedCrossFade(
                  firstChild: BlocBuilder<TopicsCubit, TopicsState>(
                    builder: (context, state) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: kDefaultPadding,
                        ),
                        child: GridView.builder(
                          itemCount: state.generalTopics.length,
                          shrinkWrap: true,
                          primary: false,
                          physics: ClampingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final topic = state.generalTopics[index];

                            return FadeInUp(
                              duration: const Duration(
                                milliseconds: 300,
                              ),
                              child: TopicContainer(
                                topic: topic,
                                icon: getIcon(topic),
                                onClicked: () {
                                  context.read<TopicsCubit>().addTopic(topic);
                                },
                                status: state.activeTopics.contains(topic),
                              ),
                            );
                          },
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: ResponsiveBreakpoints.of(context)
                                    .largerThan(MOBILE)
                                ? 6
                                : 3,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: kDefaultPadding / 2,
                            mainAxisSpacing: kDefaultPadding / 2,
                          ),
                        ),
                      );
                    },
                  ),
                  secondChild: const SizedBox(
                    width: double.infinity,
                  ),
                  crossFadeState: isTopicsToggled.value
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(
                    milliseconds: 300,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Row(
                  children: [
                    BlocBuilder<TopicsCubit, TopicsState>(
                      builder: (context, state) {
                        return Text(
                          'All buzz feed sources - ${nostrRepository.buzzFeedSources.length.toString().padLeft(2, '0')}',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        );
                      },
                    ),
                    IconButton(
                      onPressed: () {
                        isBuzzFeedToggled.value = !isBuzzFeedToggled.value;
                      },
                      icon: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: isBuzzFeedToggled.value ? 1 : 0.75,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: kTransparent,
                        visualDensity:
                            VisualDensity(horizontal: -4, vertical: -4),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedCrossFade(
                  firstChild: BlocBuilder<TopicsCubit, TopicsState>(
                    builder: (context, state) {
                      final buzzFeed =
                          nostrRepository.buzzFeedSources.values.toList();
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: kDefaultPadding,
                        ),
                        child: GridView.builder(
                          itemCount: buzzFeed.length,
                          shrinkWrap: true,
                          primary: false,
                          physics: ClampingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final topic = buzzFeed[index];
                            return FadeInUp(
                              duration: const Duration(
                                milliseconds: 300,
                              ),
                              child: TopicContainer(
                                topic: topic.name,
                                icon: getIcon(topic.name),
                                onClicked: () {
                                  context
                                      .read<TopicsCubit>()
                                      .addTopic(topic.name);
                                },
                                status: state.activeTopics.contains(topic.name),
                              ),
                            );
                          },
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: ResponsiveBreakpoints.of(context)
                                    .largerThan(MOBILE)
                                ? 6
                                : 3,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: kDefaultPadding / 2,
                            mainAxisSpacing: kDefaultPadding / 2,
                          ),
                        ),
                      );
                    },
                  ),
                  secondChild: const SizedBox(
                    width: double.infinity,
                  ),
                  crossFadeState: isBuzzFeedToggled.value
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(
                    milliseconds: 300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getIcon(String selectedTopic) {
    if (nostrRepository.buzzFeedSources.keys.contains(selectedTopic)) {
      return nostrRepository.buzzFeedSources[selectedTopic]?.icon ?? '';
    } else {
      return nostrRepository.topics.firstWhere(
        (topic) => topic.topic.toLowerCase() == selectedTopic.toLowerCase(),
        orElse: () {
          return Topic(
            topic: selectedTopic,
            icon: Images.defaultTopicIcon,
            subTopics: [],
          );
        },
      ).icon;
    }
  }
}

class TopicChip extends StatelessWidget {
  const TopicChip({
    Key? key,
    required this.topic,
    required this.icon,
    required this.onDelete,
  }) : super(key: key);

  final String topic;
  final String icon;
  final Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Chip(
      padding: EdgeInsets.zero,
      backgroundColor: Theme.of(context).primaryColorLight,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon.isEmpty
              ? Image.asset(
                  Images.defaultTopicIcon,
                  width: 15,
                  height: 15,
                )
              : CachedNetworkImage(
                  width: 15,
                  height: 15,
                  imageUrl: icon,
                  errorWidget: (context, url, error) =>
                      Image.asset(Images.defaultTopicIcon),
                ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          Text(
            topic,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  height: 1,
                ),
          ),
        ],
      ),
      shape: StadiumBorder(),
      side: BorderSide(width: 0),
      deleteButtonTooltipMessage: null,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity(
        vertical: -2,
      ),
      onDeleted: onDelete,
    );
  }
}

class TopicContainer extends StatelessWidget {
  const TopicContainer({
    Key? key,
    required this.topic,
    required this.icon,
    required this.onClicked,
    required this.status,
  }) : super(key: key);

  final String topic;
  final String icon;
  final Function() onClicked;
  final bool status;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding - 5),
          color: Theme.of(context).primaryColorLight,
          border: Border.all(
            color: status ? kGreen : kTransparent,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(kDefaultPadding / 4),
        child: Column(
          children: [
            Text(
              topic,
              style: Theme.of(context).textTheme.labelSmall!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Expanded(
              child: CachedNetworkImage(
                imageUrl: icon,
                errorWidget: (context, url, error) =>
                    Image.asset(Images.defaultTopicIcon),
                placeholder: (context, url) =>
                    Image.asset(Images.defaultTopicIcon),
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Text(
              status ? 'unsubscribe' : 'subscribe',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: kOrange,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
