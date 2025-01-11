// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:yakihonne/utils/utils.dart';

class TooltipWithText extends StatelessWidget {
  const TooltipWithText({
    Key? key,
    required this.message,
    required this.child,
  }) : super(key: key);

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      textStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: Theme.of(context).primaryColorDark,
          ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        border: Border.all(
          color: kDimGrey.withValues(
            alpha: 0.5,
          ),
        ),
      ),
      triggerMode: TooltipTriggerMode.tap,
      child: child,
    );
  }
}
