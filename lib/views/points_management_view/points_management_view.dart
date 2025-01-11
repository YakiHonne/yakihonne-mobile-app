import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/points_management_cubit/points_management_cubit.dart';
import 'package:yakihonne/main.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/points_management_view/widgets/points_stats_containers.dart';
import 'package:yakihonne/views/widgets/profile_picture.dart';

class PointsStatisticsView extends StatelessWidget {
  const PointsStatisticsView({super.key});
  static const routeName = '/pointsStatisticsView';

  static Route route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (_) => PointsStatisticsView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PointsManagementCubit, PointsManagementState>(
      builder: (context, state) {
        final isConnected = state.userGlobalStats != null;

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: kToolbarHeight + 80,
                  pinned: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  stretch: true,
                  leading: FadeInRight(
                    duration: const Duration(milliseconds: 500),
                    from: 30,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Center(
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context)
                              .primaryColorLight
                              .withValues(alpha: 0.7),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    GestureDetector(
                      onTap: () {
                        openWebPage(
                          url: pointsSystemUrl,
                          inAppWebView: true,
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context)
                            .primaryColorLight
                            .withValues(alpha: 0.7),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    )
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    centerTitle: false,
                    stretchModes: [
                      StretchMode.zoomBackground,
                    ],
                    background: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) => SizedBox(
                                height: constraints.maxHeight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context)
                                                  .scaffoldBackgroundColor,
                                              Color(0xff16222A),
                                              Color(0xff243B55),
                                            ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 50,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: ProfilePicture2(
                                  size: 120,
                                  image: nostrRepository.user.picture,
                                  placeHolder:
                                      nostrRepository.user.picturePlaceholder,
                                  padding: 0,
                                  strokeWidth: 3,
                                  strokeColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  onClicked: () {},
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ];
            },
            body: isConnected ? PointsStatContainers() : SizedBox(),
          ),
        );
      },
    );
  }
}
