import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/utils/utils.dart';

class RefresherClassicFooter extends StatelessWidget {
  const RefresherClassicFooter({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = context.read<ThemeCubit>().state.theme == AppTheme.purpleDark
        ? Colors.purpleAccent
        : kPurple;

    return ClassicFooter(
      loadStyle: LoadStyle.ShowWhenLoading,
      noMoreIcon: Icon(
        Icons.data_object_rounded,
        color: color,
        size: 15,
      ),
      completeDuration: Duration(milliseconds: 500),
      loadingText: 'loading',
      canLoadingText: 'release to load more',
      idleText: 'finished !',
      noDataText: 'no more data',
      idleIcon: Icon(
        Icons.done,
        color: color,
        size: 15,
      ),
      loadingIcon: SizedBox(
        height: 15.0,
        width: 15.0,
        child: CircularProgressIndicator(
          color: color,
          strokeWidth: 1,
        ),
      ),
    );
  }
}
