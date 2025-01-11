import 'package:flutter/material.dart';
import 'package:numeral/numeral.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:yakihonne/utils/utils.dart';

class StatButton extends StatelessWidget {
  const StatButton({
    super.key,
    required this.value,
    required this.icon,
    required this.onClicked,
  });

  final num value;
  final String icon;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return TextButton.icon(
      onPressed: onClicked,
      icon: SvgPicture.asset(
        icon,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
        width: 20,
        height: 20,
        fit: BoxFit.scaleDown,
      ),
      label: Text(
        Numeral(value).format(),
        style: (isTablet
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.labelMedium)!
            .copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: kTransparent,
        padding: EdgeInsets.symmetric(vertical: kDefaultPadding / 6),
        minimumSize: Size.zero,
        splashFactory: NoSplash.splashFactory,
      ),
    );
  }
}

class SmallIconButton extends StatelessWidget {
  const SmallIconButton({
    super.key,
    required this.icon,
    required this.onClicked,
  });

  final String icon;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        onPressed: onClicked,
        padding: EdgeInsets.zero,
        icon: SvgPicture.asset(
          icon,
          width: 20,
          height: 20,
          fit: BoxFit.scaleDown,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
