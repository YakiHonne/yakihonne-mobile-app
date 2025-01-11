import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yakihonne/blocs/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/utils/utils.dart';

void showBlurredModal({required BuildContext context, required Widget view}) {
  showGeneralDialog(
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: context.read<ThemeCubit>().state.theme == AppTheme.purpleDark
        ? Colors.black45.withValues(alpha: 0.8)
        : kDimGrey.withValues(alpha: 0.5),
    useRootNavigator: true,
    transitionDuration: Duration(milliseconds: 300),
    pageBuilder: (ctx, anim1, anim2) => Center(
      child: view,
    ),
    transitionBuilder: (ctx, anim1, anim2, child) => FadeTransition(
      child: child,
      opacity: anim1,
    ),
    context: context,
  );
}
