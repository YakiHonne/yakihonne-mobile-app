// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/blocs/bookmarks_cubit/bookmarks_cubit.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/widgets/custom_app_bar.dart';
import 'package:yakihonne/views/widgets/response_snackbar.dart';

class AddBookmarksListView extends StatelessWidget {
  const AddBookmarksListView({
    Key? key,
    required this.bookmarksCubit,
  }) : super(key: key);

  static const routeName = '/addBookmarksListView';
  static Route route(RouteSettings settings) {
    final bookmarksCubit = (settings.arguments as List).first as BookmarksCubit;

    return CupertinoPageRoute(
      builder: (_) => AddBookmarksListView(
        bookmarksCubit: bookmarksCubit,
      ),
    );
  }

  final BookmarksCubit bookmarksCubit;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocProvider.value(
      value: bookmarksCubit,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Add bookmarks list',
        ),
        body: BlocBuilder<BookmarksCubit, BookmarksState>(
          builder: (context, state) {
            return ListView(
              padding: EdgeInsets.all(isTablet ? 15.w : kDefaultPadding / 2),
              children: [
                const SizedBox(
                  height: kDefaultPadding,
                ),
                Text(
                  'Set a title & a description for your bookmark list.',
                  style: Theme.of(context).textTheme.labelMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                TextFormField(
                  onChanged: (title) {
                    context.read<BookmarksCubit>().setText(
                          text: title,
                          isTitle: true,
                        );
                  },
                  decoration: InputDecoration(
                    hintText: 'Title',
                  ),
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                TextFormField(
                  onChanged: (description) {
                    context.read<BookmarksCubit>().setText(
                          text: description,
                          isTitle: false,
                        );
                  },
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      context.read<BookmarksCubit>().addBookmarkList(
                            context: context,
                            onFailure: (message) {
                              singleSnackBar(
                                context: context,
                                message: message,
                                color: kRed,
                                backGroundColor: kRedSide,
                                icon: ToastsIcons.error,
                              );
                            },
                            onSuccess: () {
                              Navigator.pop(context);
                            },
                          );
                    },
                    child: Text('Add'),
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
