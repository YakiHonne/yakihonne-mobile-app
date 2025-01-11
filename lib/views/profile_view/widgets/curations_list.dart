// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/profile_cubit/profile_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/curation_view/curation_view.dart';
import 'package:yakihonne/views/widgets/curation_container.dart';
import 'package:yakihonne/views/widgets/empty_list.dart';

class ProfileCurations extends StatelessWidget {
  const ProfileCurations({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (previous, current) =>
            previous.curations != current.curations ||
            previous.bookmarks != current.bookmarks ||
            previous.user != current.user,
        builder: (context, state) {
          if (state.curations.isEmpty) {
            return EmptyList(
              icon: FeatureIcons.selfArticles,
              description: '${state.user.name} has no curations',
            );
          } else {
            if (ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
              return MasonryGridView.builder(
                gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                crossAxisSpacing: kDefaultPadding / 2,
                mainAxisSpacing: kDefaultPadding / 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding,
                  vertical: kDefaultPadding / 2,
                ),
                itemBuilder: (context, index) {
                  final curation = state.curations.elementAt(index);

                  return CurationContainer(
                    curation: curation,
                    userStatus: state.userStatus,
                    isBookmarked: state.bookmarks.contains(curation.identifier),
                    onClicked: () {
                      Navigator.pushNamed(
                        context,
                        CurationView.routeName,
                        arguments: curation,
                      );
                    },
                    padding: 0,
                  );
                },
                itemCount: state.curations.length,
              );
            } else {
              return ListView.separated(
                separatorBuilder: (context, index) => SizedBox(
                  height: kDefaultPadding / 2,
                ),
                padding: const EdgeInsets.all(
                  kDefaultPadding / 2,
                ),
                itemBuilder: (context, index) {
                  final curation = state.curations.elementAt(index);

                  return CurationContainer(
                    curation: curation,
                    userStatus: state.userStatus,
                    isBookmarked: state.bookmarks.contains(curation.identifier),
                    onClicked: () {
                      Navigator.pushNamed(
                        context,
                        CurationView.routeName,
                        arguments: curation,
                      );
                    },
                    padding: 0,
                  );
                },
                itemCount: state.curations.length,
              );
            }
          }
        },
      ),
    );
  }
}
