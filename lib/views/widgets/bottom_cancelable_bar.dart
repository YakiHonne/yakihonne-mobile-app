import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_breakpoints.dart';
import 'package:yakihonne/utils/utils.dart';

class BottomCancellableBar extends StatelessWidget {
  const BottomCancellableBar({
    Key? key,
    required this.text,
    required this.onClicked,
  }) : super(key: key);

  final String text;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return SizedBox(
      height:
          kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
      child: Builder(builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 15.w : kDefaultPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: kTransparent,
                    side: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Expanded(
                child: TextButton(
                  onPressed: onClicked,
                  child: Text(
                    text,
                  ),
                ),
              )
            ],
          ),
        );
      }),
    );
  }
}
