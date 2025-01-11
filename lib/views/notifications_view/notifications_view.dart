// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/notifications_cubit/notifications_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/nostr/nostr.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/notifications_view/widgets/common_notifications_container.dart';
import 'package:yakihonne/views/notifications_view/widgets/mention_notifications_container.dart';
import 'package:yakihonne/views/notifications_view/widgets/reaction_notification_container.dart';
import 'package:yakihonne/views/notifications_view/widgets/zap_notification_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';

class NotificationsView extends HookWidget {
  const NotificationsView({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(
      initialLength: 5,
      initialIndex: notificationsCubit.state.index,
    );

    return BlocBuilder<NotificationsCubit, NotificationsState>(
      buildWhen: (previous, current) =>
          previous.index != current.index || previous.events != current.events,
      builder: (context, state) {
        return DefaultTabController(
          length: 5,
          child: NestedScrollView(
            controller: scrollController,
            floatHeaderSlivers: false,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                  leadingWidth: 0,
                  elevation: 5,
                  toolbarHeight: 50,
                  floating: true,
                  actions: [const SizedBox.shrink()],
                  titleSpacing: 0,
                  title: SizedBox(
                    width: double.infinity,
                    child: TabBar(
                      labelStyle: Theme.of(context).textTheme.labelMedium,
                      dividerColor: Theme.of(context).primaryColorLight,
                      isScrollable: true,
                      controller: tabController,
                      onTap: (index) {
                        context.read<NotificationsCubit>().setIndex(index);
                      },
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(
                          text: 'All',
                        ),
                        Tab(
                          text: 'Mentions',
                        ),
                        Tab(
                          text: 'Zaps',
                        ),
                        Tab(
                          text: 'Reactions',
                        ),
                        Tab(
                          text: 'Followings',
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: tabController,
              children: [
                SelectedNotifications(
                  index: 0,
                  key: ValueKey('0'),
                ),
                SelectedNotifications(
                  index: 1,
                  key: ValueKey('1'),
                ),
                SelectedNotifications(
                  index: 2,
                  key: ValueKey('2'),
                ),
                SelectedNotifications(
                  index: 3,
                  key: ValueKey('3'),
                ),
                SelectedNotifications(
                  index: 4,
                  key: ValueKey('4'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SelectedNotifications extends StatelessWidget {
  const SelectedNotifications({
    Key? key,
    required this.index,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return BlocBuilder<NotificationsCubit, NotificationsState>(
      buildWhen: (previous, current) => previous.events != current.events,
      builder: (context, state) {
        final usedEvents = List<Event>.from(
          index == 0
              ? state.events
              : index == 1
                  ? state.events.where((event) =>
                      (event.kind == EventKind.LONG_FORM ||
                          event.kind == EventKind.CURATION_ARTICLES ||
                          event.kind == EventKind.SMART_WIDGET ||
                          event.kind == EventKind.VIDEO_HORIZONTAL ||
                          event.kind == EventKind.VIDEO_VERTICAL ||
                          event.kind == EventKind.TEXT_NOTE) &&
                      event.isUserTagged())
                  : index == 2
                      ? state.events
                          .where((event) => event.kind == EventKind.ZAP)
                      : index == 3
                          ? state.events.where(
                              (event) => event.kind == EventKind.REACTION)
                          : state.events.where((event) =>
                              (event.kind == EventKind.LONG_FORM ||
                                  event.kind == EventKind.CURATION_ARTICLES ||
                                  event.kind == EventKind.SMART_WIDGET ||
                                  event.kind == EventKind.TEXT_NOTE ||
                                  event.kind == EventKind.VIDEO_HORIZONTAL ||
                                  event.kind == EventKind.VIDEO_VERTICAL) &&
                              !event.isUserTagged()),
        );

        if (usedEvents.isEmpty) {
          return EmptyList(
            description: 'No notifications can be found',
            icon: FeatureIcons.notification,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            vertical: kDefaultPadding / 2,
            horizontal: isMobile ? kDefaultPadding / 2 : 20.w,
          ),
          itemBuilder: (context, index) {
            final event = usedEvents[index];

            if (event.kind == EventKind.ZAP) {
              return ZapNotificationContainer(
                event: event,
              );
            } else if (event.kind == EventKind.REACTION) {
              return ReactionNotificationContainer(
                event: event,
              );
            } else if (event.kind == EventKind.LONG_FORM ||
                event.kind == EventKind.CURATION_ARTICLES ||
                event.kind == EventKind.SMART_WIDGET ||
                event.kind == EventKind.APP_CUSTOM ||
                event.kind == EventKind.TEXT_NOTE ||
                event.kind == EventKind.VIDEO_HORIZONTAL ||
                event.kind == EventKind.VIDEO_VERTICAL) {
              if (event.isUserTagged()) {
                return MentionNotificationContainer(event: event);
              } else {
                return CommonNotificationContainer(event: event);
              }
            }

            return SizedBox();
          },
          itemCount: usedEvents.length,
        );
      },
    );
  }
}
