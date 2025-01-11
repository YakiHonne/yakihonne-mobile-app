// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/authors_cubit/authors_cubit.dart';
import 'package:yakihonne/blocs/dms_cubit/dms_cubit.dart';
import 'package:yakihonne/blocs/notifications_cubit/notifications_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/models/dm_models.dart';
import 'package:yakihonne/utils/string_utils.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/dm_view/widgets/dm_details.dart';
import 'package:yakihonne/views/dm_view/widgets/dm_user_search.dart';
import 'package:yakihonne/views/flash_news_view/widgets/flash_news_timeline_container.dart';
import 'package:yakihonne/views/widgets/buttons_containers_widgets.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class DmsView extends HookWidget {
  const DmsView({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final textController = useState('');
    final tabController = useTabController(
      initialLength: 3,
      initialIndex: dmsCubit.state.index,
    );

    return BlocBuilder<DmsCubit, DmsState>(
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
                  toolbarHeight: 100,
                  floating: true,
                  actions: [const SizedBox.shrink()],
                  titleSpacing: 0,
                  title: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding / 2,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  onChanged: (value) {
                                    textController.value = value;
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Search by username...',
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: kDefaultPadding / 2,
                              ),
                              CustomIconButton(
                                onClicked: () {
                                  Navigator.pushNamed(
                                    context,
                                    DmUserSearch.routeName,
                                  );
                                },
                                icon: FeatureIcons.startDms,
                                size: 22,
                                backgroundColor:
                                    Theme.of(context).primaryColorLight,
                              ),
                            ],
                          ),
                        ),
                        TabBar(
                          labelStyle:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                          dividerColor: Theme.of(context).primaryColorLight,
                          controller: tabController,
                          unselectedLabelStyle:
                              Theme.of(context).textTheme.labelMedium,
                          onTap: (index) {
                            context.read<NotificationsCubit>().setIndex(index);
                          },
                          tabs: [
                            DmTab(
                              dmsType: DmsType.followings,
                              title: 'Followings',
                            ),
                            DmTab(
                              dmsType: DmsType.known,
                              title: 'Known',
                            ),
                            DmTab(
                              dmsType: DmsType.unknown,
                              title: 'Unknown',
                            ),
                          ],
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
                SelectedDms(
                  dmsType: DmsType.followings,
                  key: ValueKey(DmsType.followings.name),
                  search: textController.value.trim(),
                ),
                SelectedDms(
                  dmsType: DmsType.known,
                  key: ValueKey(DmsType.known.name),
                  search: textController.value.trim(),
                ),
                SelectedDms(
                  dmsType: DmsType.unknown,
                  key: ValueKey(DmsType.unknown.name),
                  search: textController.value.trim(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DmTab extends StatelessWidget {
  const DmTab({
    Key? key,
    required this.dmsType,
    required this.title,
    this.removeCount,
  }) : super(key: key);

  final DmsType dmsType;
  final String title;
  final bool? removeCount;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Builder(
        builder: (context) {
          final count = dmsCubit.howManyNewDMSessionsWithNewMessages(dmsType);

          return Badge(
            isLabelVisible: count != 0,
            backgroundColor: kRed,
            textColor: kWhite,
            label: Text(
              removeCount != null ? '' : count.toString(),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
                vertical: kDefaultPadding / 4,
              ),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.fade,
              ),
            ),
          );
        },
      ),
    );
  }
}

class SelectedDms extends StatelessWidget {
  const SelectedDms({
    Key? key,
    required this.dmsType,
    required this.search,
  }) : super(key: key);

  final DmsType dmsType;
  final String search;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return BlocBuilder<DmsCubit, DmsState>(
      builder: (context, state) {
        final dmsSessions = dmsCubit.getSessionDetailsByType(
          search.isNotEmpty ? DmsType.all : dmsType,
        );

        List<DMSessionDetail> usedDmSessions = [];

        if (search.isNotEmpty) {
          usedDmSessions.clear();

          for (final dmSessionDetail in dmsSessions) {
            final author = authorsCubit
                .getSpecificAuthor(dmSessionDetail.dmSession.pubkey);
            if (author != null &&
                (author.name.contains(search) ||
                    author.nip05.contains(search))) {
              usedDmSessions.add(dmSessionDetail);
            }
          }
        } else {
          usedDmSessions = dmsSessions;
        }

        if (usedDmSessions.isEmpty) {
          return EmptyList(
            description: 'No dms can be found',
            icon: FeatureIcons.dms,
          );
        }

        usedDmSessions.removeWhere(
          (element) => state.mutes.contains(element.info.peerPubkey),
        );

        return ListView.separated(
          separatorBuilder: (context, index) => SizedBox(
            height: kDefaultPadding / 1.5,
          ),
          padding: EdgeInsets.symmetric(
            vertical: kDefaultPadding,
            horizontal: isMobile ? kDefaultPadding / 1.5 : 20.w,
          ),
          itemBuilder: (context, index) {
            final dm = usedDmSessions[index];

            return DmContainer(
              dmSessionDetail: dm,
              onClicked: () {
                context.read<DmsCubit>().updateReadedTime(
                      dm.dmSession.pubkey,
                    );

                Navigator.pushNamed(
                  context,
                  DmDetails.routeName,
                  arguments: [
                    dm.dmSession.pubkey,
                  ],
                );
              },
            );
          },
          itemCount: usedDmSessions.length,
        );
      },
    );
  }
}

class DmContainer extends HookWidget {
  const DmContainer({
    Key? key,
    required this.dmSessionDetail,
    required this.onClicked,
  }) : super(key: key);

  final DMSessionDetail dmSessionDetail;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      authorsCubit.getAuthor(dmSessionDetail.dmSession.pubkey);
    });

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onClicked,
      child: Container(
        child: BlocBuilder<AuthorsCubit, AuthorsState>(
          builder: (context, state) {
            final author = state.authors[dmSessionDetail.dmSession.pubkey] ??
                emptyUserModel.copyWith(
                  pubKey: dmSessionDetail.dmSession.pubkey,
                  picturePlaceholder: getRandomPlaceholder(
                    input: dmSessionDetail.dmSession.pubkey,
                    isPfp: true,
                  ),
                );

            final newestEvent = dmSessionDetail.dmSession.newestEvent;

            return Row(
              children: [
                ProfilePicture3(
                  size: 45,
                  image: author.picture,
                  placeHolder: author.picturePlaceholder,
                  padding: 0,
                  strokeWidth: 0,
                  reduceSize: true,
                  strokeColor: kTransparent,
                  onClicked: () {},
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              getAuthorName(author),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Spacer(),
                          if (dmSessionDetail.hasNewMessage())
                            DotContainer(
                              color: kRed,
                              isNotMarging: true,
                              size: 8,
                            ),
                        ],
                      ),
                      if (newestEvent != null) ...[
                        const SizedBox(
                          height: kDefaultPadding / 8,
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: FutureBuilder(
                                future: nostrRepository.getMessage(newestEvent),
                                builder: (context, snapshot) {
                                  String text = '';

                                  if (snapshot.hasData) {
                                    text = snapshot.data!.first.trim();
                                  }

                                  return RichText(
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                      children: [
                                        if (nostrRepository.usm!.pubKey ==
                                            newestEvent.pubkey)
                                          TextSpan(
                                            text: 'You: ',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium!
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        TextSpan(
                                          text: text.isEmpty
                                              ? 'Decrypting message...'
                                              : text,
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            DotContainer(
                              color: kDimGrey,
                              size: 3,
                            ),
                            Text(
                              StringUtil.getLastDate(
                                DateTime.fromMillisecondsSinceEpoch(
                                  dmSessionDetail.dmSession.lastTime() * 1000,
                                ),
                              ),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
